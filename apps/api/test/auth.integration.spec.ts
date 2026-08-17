import type { INestApplication } from "@nestjs/common";
import { Test } from "@nestjs/testing";
import request from "supertest";
import { afterEach, beforeEach, describe, expect, it } from "vitest";

import { AppModule } from "../src/app.module.js";
import { configureApp } from "../src/configure-app.js";

describe("CareMate authentication", () => {
  let app: INestApplication | undefined;

  beforeEach(async () => {
    process.env.NODE_ENV = "development";
    process.env.TURSO_DATABASE_URL = ":memory:";
    delete process.env.TURSO_AUTH_TOKEN;
    process.env.ACCESS_TOKEN_SECRET = "test-access-secret-that-is-long-enough";
    process.env.REFRESH_TOKEN_PEPPER =
      "test-refresh-pepper-that-is-long-enough";
    process.env.PHONE_LOOKUP_PEPPER =
      "test-phone-lookup-pepper-that-is-long-enough";
    process.env.PHONE_ENCRYPTION_KEY =
      "test-phone-encryption-key-that-is-long-enough";
    process.env.LOGIN_OTP_PROVIDER = "development";
    process.env.LOGIN_OTP_DEVELOPMENT_CODE = "123456";
    process.env.OTP_RESEND_COOLDOWN_SECONDS = "0";

    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication();
    configureApp(app);
    await app.init();
  });

  afterEach(async () => {
    await app?.close();
  });

  function requestOtp(phoneNumber = "01700 123-456") {
    return request(app!.getHttpServer())
      .post("/api/v1/auth/otp/requests")
      .set("X-Forwarded-For", "203.0.113.10")
      .send({
        deviceInstallationId: "01K2DEVICEINSTALLATION000001",
        locale: "bn-BD",
        phoneNumber,
        purpose: "LOGIN",
      });
  }

  function verifyOtp(challengeId: string, otp = "123456") {
    return request(app!.getHttpServer())
      .post("/api/v1/auth/otp/verifications")
      .send({
        challengeId,
        device: {
          appVersion: "1.0.0",
          deviceName: "Test Android phone",
          installationId: "01K2DEVICEINSTALLATION000001",
          platform: "ANDROID",
        },
        otp,
      });
  }

  it("normalizes a Bangladesh number and consumes a valid login OTP once", async () => {
    const otpResponse = await requestOtp().expect(201);

    expect(otpResponse.body.data).toEqual({
      challengeId: expect.any(String),
      deliveryHint: "••••••3456",
      expiresInSeconds: 300,
      resendAfterSeconds: 0,
    });
    expect(JSON.stringify(otpResponse.body)).not.toContain("123456");

    const verified = await verifyOtp(otpResponse.body.data.challengeId).expect(
      201,
    );

    expect(verified.body.data).toMatchObject({
      accessToken: expect.any(String),
      expiresInSeconds: 900,
      isNewUser: true,
      refreshToken: expect.any(String),
      tokenType: "Bearer",
      user: {
        locale: "bn-BD",
        maskedPhoneNumber: "••••••3456",
      },
    });

    const replay = await verifyOtp(otpResponse.body.data.challengeId).expect(
      400,
    );
    expect(replay.body.error.code).toBe("OTP_EXPIRED");
  });

  it("uses the labelled development adapter when no provider is configured", async () => {
    delete process.env.LOGIN_OTP_PROVIDER;

    const response = await requestOtp("01500123456").expect(201);

    expect(response.body.meta.deliveryMode).toBe("DEVELOPMENT");
    expect(JSON.stringify(response.body)).not.toContain("123456");
  });

  it("refuses an implicit development adapter in production", async () => {
    delete process.env.LOGIN_OTP_PROVIDER;
    process.env.NODE_ENV = "production";

    const response = await requestOtp("01400123456").expect(503);

    expect(response.body.error.code).toBe("DELIVERY_UNAVAILABLE");
  });

  it("invalidates an earlier challenge when a replacement is requested", async () => {
    const first = await requestOtp().expect(201);
    const replacement = await requestOtp().expect(201);

    await verifyOtp(first.body.data.challengeId).expect(400);
    await verifyOtp(replacement.body.data.challengeId).expect(201);
  });

  it("counts incorrect codes and locks the challenge after five attempts", async () => {
    const otpResponse = await requestOtp().expect(201);
    const challengeId = otpResponse.body.data.challengeId;

    for (let attempt = 1; attempt < 5; attempt += 1) {
      const response = await verifyOtp(challengeId, "000000").expect(400);
      expect(response.body.error.code).toBe("OTP_INVALID");
    }

    const locked = await verifyOtp(challengeId, "000000").expect(400);
    expect(locked.body.error.code).toBe("OTP_ATTEMPTS_EXCEEDED");
    const correctAfterLock = await verifyOtp(challengeId).expect(400);
    expect(correctAfterLock.body.error.code).toBe("OTP_ATTEMPTS_EXCEEDED");
  });

  it("rotates refresh tokens and revokes the family if an old token is reused", async () => {
    const otpResponse = await requestOtp().expect(201);
    const login = await verifyOtp(otpResponse.body.data.challengeId).expect(
      201,
    );
    const firstRefreshToken = login.body.data.refreshToken;

    const rotated = await request(app!.getHttpServer())
      .post("/api/v1/auth/token/refresh")
      .send({ refreshToken: firstRefreshToken })
      .expect(201);

    expect(rotated.body.data.refreshToken).not.toBe(firstRefreshToken);
    expect(rotated.body.data.user).toEqual({ id: login.body.data.user.id });

    const reuse = await request(app!.getHttpServer())
      .post("/api/v1/auth/token/refresh")
      .send({ refreshToken: firstRefreshToken })
      .expect(401);
    expect(reuse.body.error.code).toBe("REFRESH_TOKEN_REUSED");

    const revokedChild = await request(app!.getHttpServer())
      .post("/api/v1/auth/token/refresh")
      .send({ refreshToken: rotated.body.data.refreshToken })
      .expect(401);
    expect(revokedChild.body.error.code).toBe("SESSION_REVOKED");
  });

  it("revokes the current device session on authenticated logout", async () => {
    const otpResponse = await requestOtp().expect(201);
    const login = await verifyOtp(otpResponse.body.data.challengeId).expect(
      201,
    );

    await request(app!.getHttpServer())
      .post("/api/v1/auth/logout")
      .set("Authorization", `Bearer ${login.body.data.accessToken}`)
      .expect(204);

    const refresh = await request(app!.getHttpServer())
      .post("/api/v1/auth/token/refresh")
      .send({ refreshToken: login.body.data.refreshToken })
      .expect(401);
    expect(refresh.body.error.code).toBe("SESSION_REVOKED");
  });

  it("lists device sessions and logout-all invalidates the access token", async () => {
    const otpResponse = await requestOtp().expect(201);
    const login = await verifyOtp(otpResponse.body.data.challengeId).expect(
      201,
    );
    const authorization = `Bearer ${login.body.data.accessToken}`;

    const sessions = await request(app!.getHttpServer())
      .get("/api/v1/me/sessions")
      .set("Authorization", authorization)
      .expect(200);
    expect(sessions.body.data).toEqual([
      expect.objectContaining({
        current: true,
        deviceName: "Test Android phone",
        platform: "ANDROID",
        status: "ACTIVE",
      }),
    ]);

    await request(app!.getHttpServer())
      .post("/api/v1/auth/logout-all")
      .set("Authorization", authorization)
      .expect(204);
    await request(app!.getHttpServer())
      .get("/api/v1/me/sessions")
      .set("Authorization", authorization)
      .expect(401);
  });

  it("allows only one verifier to consume a challenge", async () => {
    const otpResponse = await requestOtp().expect(201);
    const challengeId = otpResponse.body.data.challengeId;
    const outcomes = await Promise.all([
      verifyOtp(challengeId),
      verifyOtp(challengeId),
    ]);

    expect(outcomes.map((response) => response.status).sort()).toEqual([
      201, 400,
    ]);
  });
});
