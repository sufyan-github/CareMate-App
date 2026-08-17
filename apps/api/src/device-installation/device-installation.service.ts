import { ForbiddenException, Injectable } from "@nestjs/common";
import { ulid } from "ulid";

import { DatabaseService } from "../database/database.service.js";
import { AuthCryptoService } from "../auth/auth-crypto.service.js";
import type { RegisterDeviceInstallationDto } from "./device-installation.dto.js";

@Injectable()
export class DeviceInstallationService {
  constructor(
    private readonly crypto: AuthCryptoService,
    private readonly database: DatabaseService,
  ) {}

  async register(
    userId: string,
    sessionId: string,
    installationId: string,
    input: RegisterDeviceInstallationDto,
  ) {
    const session = await this.database.authSession.findFirst({
      where: { id: sessionId, installationId, revokedAt: null, userId },
    });
    if (!session) {
      throw new ForbiddenException({
        error: {
          code: "INSTALLATION_SESSION_MISMATCH",
          message: "This session cannot register another installation.",
        },
      });
    }
    const now = new Date();
    const token = input.pushToken
      ? {
          encrypted: this.crypto.encryptOpaqueValue(input.pushToken),
          lookupHash: this.crypto.riskLookupHash(`push:${input.pushToken}`),
        }
      : null;
    const registration = await this.database.$transaction(
      async (transaction) => {
        if (token) {
          await transaction.deviceInstallation.updateMany({
            data: {
              pushStatus: "UNREGISTERED",
              pushTokenEncrypted: null,
              pushTokenLookupHash: null,
            },
            where: { pushTokenLookupHash: token.lookupHash },
          });
        }
        return transaction.deviceInstallation.upsert({
          create: {
            appVersion: input.appVersion,
            deviceName: input.deviceName,
            id: ulid(),
            installationId,
            lastSeenAt: now,
            locale: input.locale,
            platform: input.platform,
            pushStatus: token ? "ACTIVE" : "UNREGISTERED",
            pushTokenEncrypted: token?.encrypted ?? null,
            pushTokenLookupHash: token?.lookupHash ?? null,
            userId,
          },
          update: {
            appVersion: input.appVersion,
            deviceName: input.deviceName,
            lastSeenAt: now,
            locale: input.locale,
            platform: input.platform,
            ...(input.pushToken === undefined
              ? {}
              : {
                  pushStatus: token ? "ACTIVE" : "UNREGISTERED",
                  pushTokenEncrypted: token?.encrypted ?? null,
                  pushTokenLookupHash: token?.lookupHash ?? null,
                }),
            revokedAt: null,
            status: "ACTIVE",
          },
          where: { userId_installationId: { installationId, userId } },
        });
      },
    );
    return {
      data: {
        appVersion: registration.appVersion,
        deviceName: registration.deviceName,
        installationId: registration.installationId,
        lastSeenAt: registration.lastSeenAt.toISOString(),
        locale: registration.locale,
        platform: registration.platform,
        status: registration.status,
      },
      meta: { requestId: `req_${ulid()}` },
    };
  }

  async detachPushToken(
    userId: string,
    sessionId: string,
    installationId: string,
  ): Promise<void> {
    const session = await this.database.authSession.findFirst({
      where: { id: sessionId, installationId, revokedAt: null, userId },
    });
    if (!session) {
      throw new ForbiddenException({
        error: {
          code: "INSTALLATION_SESSION_MISMATCH",
          message: "This session cannot change another installation.",
        },
      });
    }
    await this.database.deviceInstallation.updateMany({
      data: {
        pushStatus: "UNREGISTERED",
        pushTokenEncrypted: null,
        pushTokenLookupHash: null,
      },
      where: { installationId, userId },
    });
  }
}
