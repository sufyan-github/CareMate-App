import { HttpStatus, Inject, Injectable } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { randomBytes, randomInt } from "node:crypto";
import { ulid } from "ulid";

import { DatabaseService } from "../database/database.service.js";
import { AuthCryptoService } from "./auth-crypto.service.js";
import type {
  AuthDeviceDto,
  RefreshTokenDto,
  RequestOtpDto,
  VerifyOtpDto,
} from "./auth.dto.js";
import { AuthError } from "./auth-error.js";
import { AuthTokenService } from "./auth-token.service.js";
import {
  DevelopmentOtpDeliveryProvider,
  OTP_DELIVERY_PROVIDER,
  type OtpDeliveryProvider,
} from "./otp-delivery.provider.js";
import {
  maskPhoneNumber,
  normalizeBangladeshPhoneNumber,
} from "./phone-number.js";

const OTP_LIFETIME_SECONDS = 300;
const ACCESS_TOKEN_LIFETIME_SECONDS = 900;
const REFRESH_TOKEN_LIFETIME_DAYS = 30;

@Injectable()
export class AuthService {
  constructor(
    private readonly config: ConfigService,
    private readonly crypto: AuthCryptoService,
    private readonly database: DatabaseService,
    private readonly developmentOtp: DevelopmentOtpDeliveryProvider,
    private readonly tokens: AuthTokenService,
    @Inject(OTP_DELIVERY_PROVIDER)
    private readonly otpDelivery: OtpDeliveryProvider,
  ) {}

  async requestOtp(input: RequestOtpDto, requestIp: string) {
    const phoneNumber = normalizeBangladeshPhoneNumber(input.phoneNumber);
    const phoneLookupHash = this.crypto.phoneLookupHash(phoneNumber);
    const requestIpHash = this.crypto.riskLookupHash(requestIp);
    const now = new Date();
    const resendAfterSeconds = Number(
      this.config.get<string>("OTP_RESEND_COOLDOWN_SECONDS") ?? "60",
    );
    const latest = await this.database.otpChallenge.findFirst({
      orderBy: { createdAt: "desc" },
      where: {
        deviceInstallationId: input.deviceInstallationId,
        phoneLookupHash,
        purpose: input.purpose,
      },
    });
    if (latest && latest.resendAvailableAt > now) {
      throw new AuthError(
        HttpStatus.TOO_MANY_REQUESTS,
        "OTP_RESEND_TOO_SOON",
        "Please wait before requesting another code.",
      );
    }

    await this.enforceSendLimits(
      phoneLookupHash,
      input.deviceInstallationId,
      requestIpHash,
      now,
    );
    await this.database.otpChallenge.updateMany({
      data: { invalidatedAt: now },
      where: {
        consumedAt: null,
        deviceInstallationId: input.deviceInstallationId,
        invalidatedAt: null,
        phoneLookupHash,
        purpose: input.purpose,
      },
    });

    const challengeId = ulid();
    const code = this.developmentOtp.isEnabled()
      ? this.developmentOtp.code()
      : randomInt(0, 1_000_000).toString().padStart(6, "0");
    const expiresAt = new Date(now.getTime() + OTP_LIFETIME_SECONDS * 1000);
    const resendAvailableAt = new Date(
      now.getTime() + resendAfterSeconds * 1000,
    );
    await this.database.otpChallenge.create({
      data: {
        codeHash: this.crypto.otpHash(challengeId, code, input.purpose),
        deviceInstallationId: input.deviceInstallationId,
        expiresAt,
        id: challengeId,
        locale: input.locale,
        phoneE164Encrypted: this.crypto.encryptPhone(phoneNumber),
        phoneLookupHash,
        purpose: input.purpose,
        requestIpHash,
        resendAvailableAt,
      },
    });

    try {
      const deliveryReference = await this.otpDelivery.send({
        challengeId,
        code,
        locale: input.locale,
        phoneNumber,
        purpose: input.purpose,
      });
      await this.database.otpChallenge.update({
        data: { deliveryReference },
        where: { id: challengeId },
      });
    } catch {
      await this.database.otpChallenge.update({
        data: { invalidatedAt: new Date() },
        where: { id: challengeId },
      });
      throw new AuthError(
        HttpStatus.SERVICE_UNAVAILABLE,
        "DELIVERY_UNAVAILABLE",
        "The code could not be sent. Please try again later.",
      );
    }

    return {
      data: {
        challengeId,
        deliveryHint: maskPhoneNumber(phoneNumber),
        expiresInSeconds: OTP_LIFETIME_SECONDS,
        resendAfterSeconds,
      },
      meta: { deliveryMode: "DEVELOPMENT", requestId: `req_${ulid()}` },
    };
  }

  async verifyOtp(input: VerifyOtpDto) {
    const now = new Date();
    const result = await this.database.$transaction(async (transaction) => {
      const challenge = await transaction.otpChallenge.findUnique({
        where: { id: input.challengeId },
      });
      if (!challenge || challenge.purpose !== "LOGIN") {
        return { error: "OTP_EXPIRED" } as const;
      }
      if (challenge.attempts >= challenge.maxAttempts) {
        return { error: "OTP_ATTEMPTS_EXCEEDED" } as const;
      }
      if (
        challenge.consumedAt ||
        challenge.invalidatedAt ||
        challenge.expiresAt <= now
      ) {
        return { error: "OTP_EXPIRED" } as const;
      }

      const attempted = await transaction.otpChallenge.update({
        data: { attempts: { increment: 1 } },
        where: { id: challenge.id },
      });
      const suppliedHash = this.crypto.otpHash(
        challenge.id,
        input.otp,
        challenge.purpose,
      );
      if (
        input.device.installationId !== challenge.deviceInstallationId ||
        !this.crypto.hashesMatch(suppliedHash, challenge.codeHash)
      ) {
        if (attempted.attempts >= attempted.maxAttempts) {
          await transaction.otpChallenge.update({
            data: { invalidatedAt: now },
            where: { id: challenge.id },
          });
          return { error: "OTP_ATTEMPTS_EXCEEDED" } as const;
        }
        return { error: "OTP_INVALID" } as const;
      }

      await transaction.otpChallenge.update({
        data: { consumedAt: now },
        where: { id: challenge.id },
      });
      let user = await transaction.user.findUnique({
        where: { phoneLookupHash: challenge.phoneLookupHash },
      });
      const isNewUser = !user;
      if (!user) {
        user = await transaction.user.create({
          data: {
            id: ulid(),
            locale: challenge.locale,
            phoneE164Encrypted: challenge.phoneE164Encrypted,
            phoneLookupHash: challenge.phoneLookupHash,
          },
        });
      }
      if (user.status !== "ACTIVE") {
        return { error: "USER_DISABLED" } as const;
      }

      const sessionId = ulid();
      const refreshToken = this.newRefreshToken();
      const refreshCredentialId = ulid();
      const expiresAt = this.refreshExpiry(now);
      const session = await transaction.authSession.create({
        data: {
          ...input.device,
          id: sessionId,
          tokenFamilyId: ulid(),
          userId: user.id,
          expiresAt,
        },
      });
      await transaction.refreshCredential.create({
        data: {
          expiresAt,
          id: refreshCredentialId,
          sessionId,
          tokenHash: this.crypto.refreshTokenHash(refreshToken),
        },
      });

      return {
        isNewUser,
        maskedPhoneNumber: maskPhoneNumber(
          this.crypto.decryptPhone(challenge.phoneE164Encrypted),
        ),
        refreshToken,
        session,
        user,
      } as const;
    });

    if ("error" in result) {
      this.throwVerificationError(result.error);
    }
    const accessToken = await this.tokens.issueAccessToken({
      sessionId: result.session.id,
      tokenVersion: result.user.tokenVersion,
      userId: result.user.id,
    });

    return {
      data: {
        accessToken,
        expiresInSeconds: ACCESS_TOKEN_LIFETIME_SECONDS,
        isNewUser: result.isNewUser,
        refreshToken: result.refreshToken,
        tokenType: "Bearer",
        user: {
          id: result.user.id,
          locale: result.user.locale,
          maskedPhoneNumber: result.maskedPhoneNumber,
        },
      },
      meta: { requestId: `req_${ulid()}` },
    };
  }

  async refresh(input: RefreshTokenDto) {
    const now = new Date();
    const tokenHash = this.crypto.refreshTokenHash(input.refreshToken);
    const result = await this.database.$transaction(async (transaction) => {
      const credential = await transaction.refreshCredential.findUnique({
        include: { session: { include: { user: true } } },
        where: { tokenHash },
      });
      if (!credential) {
        return { error: "REFRESH_TOKEN_INVALID" } as const;
      }
      if (credential.usedAt) {
        await transaction.authSession.update({
          data: { reuseDetectedAt: now, revokedAt: now },
          where: { id: credential.sessionId },
        });
        await transaction.refreshCredential.updateMany({
          data: { revokedAt: now },
          where: { sessionId: credential.sessionId, revokedAt: null },
        });
        await transaction.deviceInstallation.updateMany({
          data: {
            pushStatus: "UNREGISTERED",
            pushTokenEncrypted: null,
            pushTokenLookupHash: null,
          },
          where: {
            installationId: credential.session.installationId,
            userId: credential.session.userId,
          },
        });
        return { error: "REFRESH_TOKEN_REUSED" } as const;
      }
      if (
        credential.session.revokedAt ||
        credential.session.expiresAt <= now ||
        credential.session.user.status !== "ACTIVE"
      ) {
        return { error: "SESSION_REVOKED" } as const;
      }
      if (credential.revokedAt || credential.expiresAt <= now) {
        return { error: "REFRESH_TOKEN_INVALID" } as const;
      }

      const claim = await transaction.refreshCredential.updateMany({
        data: { usedAt: now },
        where: { id: credential.id, usedAt: null },
      });
      if (claim.count !== 1) {
        await transaction.authSession.update({
          data: { reuseDetectedAt: now, revokedAt: now },
          where: { id: credential.sessionId },
        });
        await transaction.refreshCredential.updateMany({
          data: { revokedAt: now },
          where: { sessionId: credential.sessionId, revokedAt: null },
        });
        await transaction.deviceInstallation.updateMany({
          data: {
            pushStatus: "UNREGISTERED",
            pushTokenEncrypted: null,
            pushTokenLookupHash: null,
          },
          where: {
            installationId: credential.session.installationId,
            userId: credential.session.userId,
          },
        });
        return { error: "REFRESH_TOKEN_REUSED" } as const;
      }

      const refreshToken = this.newRefreshToken();
      const replacementId = ulid();
      await transaction.refreshCredential.create({
        data: {
          expiresAt: this.refreshExpiry(now),
          id: replacementId,
          sessionId: credential.sessionId,
          tokenHash: this.crypto.refreshTokenHash(refreshToken),
        },
      });
      await transaction.refreshCredential.update({
        data: { replacedById: replacementId },
        where: { id: credential.id },
      });
      await transaction.authSession.update({
        data: { lastSeenAt: now },
        where: { id: credential.sessionId },
      });
      return {
        refreshToken,
        session: credential.session,
        user: credential.session.user,
      } as const;
    });

    if ("error" in result) {
      throw new AuthError(
        HttpStatus.UNAUTHORIZED,
        result.error,
        "Your session is not valid. Sign in again.",
      );
    }
    const accessToken = await this.tokens.issueAccessToken({
      sessionId: result.session.id,
      tokenVersion: result.user.tokenVersion,
      userId: result.user.id,
    });
    return {
      data: {
        accessToken,
        expiresInSeconds: ACCESS_TOKEN_LIFETIME_SECONDS,
        refreshToken: result.refreshToken,
        tokenType: "Bearer",
        user: { id: result.user.id },
      },
      meta: { requestId: `req_${ulid()}` },
    };
  }

  async logout(sessionId: string): Promise<void> {
    const now = new Date();
    const session = await this.database.authSession.findUnique({
      select: { installationId: true, userId: true },
      where: { id: sessionId },
    });
    await this.database.$transaction(async (transaction) => {
      await transaction.authSession.updateMany({
        data: { revokedAt: now },
        where: { id: sessionId, revokedAt: null },
      });
      await transaction.refreshCredential.updateMany({
        data: { revokedAt: now },
        where: { sessionId, revokedAt: null },
      });
      if (session) {
        await transaction.deviceInstallation.updateMany({
          data: {
            pushStatus: "UNREGISTERED",
            pushTokenEncrypted: null,
            pushTokenLookupHash: null,
          },
          where: {
            installationId: session.installationId,
            userId: session.userId,
          },
        });
      }
    });
  }

  async logoutAll(userId: string): Promise<void> {
    const now = new Date();
    const sessions = await this.database.authSession.findMany({
      select: { id: true },
      where: { userId },
    });
    const sessionIds = sessions.map((session) => session.id);
    await this.database.$transaction([
      this.database.user.update({
        data: { tokenVersion: { increment: 1 } },
        where: { id: userId },
      }),
      this.database.authSession.updateMany({
        data: { revokedAt: now },
        where: { userId, revokedAt: null },
      }),
      this.database.refreshCredential.updateMany({
        data: { revokedAt: now },
        where: { sessionId: { in: sessionIds }, revokedAt: null },
      }),
      this.database.deviceInstallation.updateMany({
        data: {
          pushStatus: "UNREGISTERED",
          pushTokenEncrypted: null,
          pushTokenLookupHash: null,
        },
        where: { userId },
      }),
    ]);
  }

  async listSessions(userId: string, currentSessionId: string) {
    const sessions = await this.database.authSession.findMany({
      orderBy: { lastSeenAt: "desc" },
      where: { userId },
    });
    return {
      data: sessions.map((session) => ({
        appVersion: session.appVersion,
        createdAt: session.createdAt.toISOString(),
        current: session.id === currentSessionId,
        deviceName: session.deviceName,
        id: session.id,
        lastSeenAt: session.lastSeenAt.toISOString(),
        platform: session.platform,
        status: session.revokedAt ? "REVOKED" : "ACTIVE",
      })),
      meta: { requestId: `req_${ulid()}` },
    };
  }

  async revokeSession(userId: string, sessionId: string): Promise<void> {
    const session = await this.database.authSession.findFirst({
      select: { id: true },
      where: { id: sessionId, userId },
    });
    if (!session) {
      return;
    }
    await this.logout(session.id);
  }

  private async enforceSendLimits(
    phoneLookupHash: string,
    deviceInstallationId: string,
    requestIpHash: string,
    now: Date,
  ): Promise<void> {
    const hourAgo = new Date(now.getTime() - 60 * 60 * 1000);
    const dayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);
    const [hourly, daily, deviceHourly, ipHourly] = await Promise.all([
      this.database.otpChallenge.count({
        where: { createdAt: { gte: hourAgo }, phoneLookupHash },
      }),
      this.database.otpChallenge.count({
        where: { createdAt: { gte: dayAgo }, phoneLookupHash },
      }),
      this.database.otpChallenge.count({
        where: { createdAt: { gte: hourAgo }, deviceInstallationId },
      }),
      this.database.otpChallenge.count({
        where: { createdAt: { gte: hourAgo }, requestIpHash },
      }),
    ]);
    if (hourly >= 5 || daily >= 10 || deviceHourly >= 8 || ipHourly >= 20) {
      throw new AuthError(
        HttpStatus.TOO_MANY_REQUESTS,
        "RATE_LIMITED",
        "Too many code requests. Please try again later.",
      );
    }
  }

  private newRefreshToken(): string {
    return randomBytes(32).toString("base64url");
  }

  private refreshExpiry(now: Date): Date {
    return new Date(
      now.getTime() + REFRESH_TOKEN_LIFETIME_DAYS * 24 * 60 * 60 * 1000,
    );
  }

  private throwVerificationError(code: string): never {
    const message =
      code === "OTP_INVALID"
        ? "The code is incorrect. Check it and try again."
        : code === "OTP_ATTEMPTS_EXCEEDED"
          ? "Too many incorrect attempts. Request a new code."
          : code === "USER_DISABLED"
            ? "This account is not available."
            : "This code has expired. Request a new code.";
    throw new AuthError(
      code === "USER_DISABLED" ? HttpStatus.FORBIDDEN : HttpStatus.BAD_REQUEST,
      code,
      message,
    );
  }
}
