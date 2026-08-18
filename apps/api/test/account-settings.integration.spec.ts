import type { INestApplication } from "@nestjs/common";
import { Test } from "@nestjs/testing";
import request from "supertest";
import { afterEach, beforeEach, describe, expect, it } from "vitest";

import { AppModule } from "../src/app.module.js";
import { configureApp } from "../src/configure-app.js";

describe("account settings", () => {
  let app: INestApplication | undefined;

  beforeEach(async () => {
    process.env.TURSO_DATABASE_URL = ":memory:";
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

  afterEach(async () => app?.close());

  async function signIn(installationId: string, deviceName: string) {
    const challenge = await request(app!.getHttpServer())
      .post("/api/v1/auth/otp/requests")
      .send({
        deviceInstallationId: installationId,
        locale: "en-BD",
        phoneNumber: "01700123456",
        purpose: "LOGIN",
      })
      .expect(201);
    const verified = await request(app!.getHttpServer())
      .post("/api/v1/auth/otp/verifications")
      .send({
        challengeId: challenge.body.data.challengeId,
        device: {
          appVersion: "1.0.0",
          deviceName,
          installationId,
          platform: "ANDROID",
        },
        otp: "123456",
      })
      .expect(201);
    return {
      authorization: `Bearer ${verified.body.data.accessToken}`,
      refreshToken: verified.body.data.refreshToken as string,
    };
  }

  it("persists preferences and lists and revokes real sessions", async () => {
    const first = await signIn("01K2SETTINGSDEVICE00000001", "Motorola phone");
    const second = await signIn("01K2SETTINGSDEVICE00000002", "Tablet");

    const defaults = await request(app!.getHttpServer())
      .get("/api/v1/me/preferences")
      .set("Authorization", first.authorization)
      .expect(200);
    expect(defaults.body.data).toEqual({
      allowAnalytics: false,
      locale: "en-BD",
      showMedicineOnLockScreen: false,
      simpleMode: false,
      voicePromptsEnabled: true,
    });
    const updated = await request(app!.getHttpServer())
      .patch("/api/v1/me/preferences")
      .set("Authorization", first.authorization)
      .send({
        allowAnalytics: true,
        locale: "bn-BD",
        showMedicineOnLockScreen: true,
        simpleMode: true,
        voicePromptsEnabled: false,
      })
      .expect(200);
    expect(updated.body.data).toMatchObject({
      allowAnalytics: true,
      locale: "bn-BD",
      showMedicineOnLockScreen: true,
      simpleMode: true,
      voicePromptsEnabled: false,
    });

    const sessions = await request(app!.getHttpServer())
      .get("/api/v1/me/sessions")
      .set("Authorization", first.authorization)
      .expect(200);
    expect(sessions.body.data).toHaveLength(2);
    const tablet = sessions.body.data.find(
      (session: { deviceName: string }) => session.deviceName === "Tablet",
    );
    await request(app!.getHttpServer())
      .delete(`/api/v1/me/sessions/${tablet.id}`)
      .set("Authorization", first.authorization)
      .expect(204);
    await request(app!.getHttpServer())
      .post("/api/v1/auth/token/refresh")
      .send({ refreshToken: second.refreshToken })
      .expect(401);
  });

  it("requires explicit confirmation and disables a deletion-pending account", async () => {
    const session = await signIn(
      "01K2SETTINGSDEVICE00000003",
      "Deletion test phone",
    );
    await request(app!.getHttpServer())
      .post("/api/v1/me/deletion-requests")
      .set("Authorization", session.authorization)
      .send({ confirmation: "wrong" })
      .expect(400);

    const deletion = await request(app!.getHttpServer())
      .post("/api/v1/me/deletion-requests")
      .set("Authorization", session.authorization)
      .send({ confirmation: "DELETE" })
      .expect(202);
    expect(deletion.body.data.status).toBe("DELETION_PENDING");
    await request(app!.getHttpServer())
      .post("/api/v1/auth/token/refresh")
      .send({ refreshToken: session.refreshToken })
      .expect(401);
    await request(app!.getHttpServer())
      .get("/api/v1/me/preferences")
      .set("Authorization", session.authorization)
      .expect(401);
  });
});
