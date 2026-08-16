import type { INestApplication } from "@nestjs/common";
import { Test } from "@nestjs/testing";
import request from "supertest";
import { afterEach, beforeEach, describe, expect, it } from "vitest";

import { AppModule } from "../src/app.module.js";
import { configureApp } from "../src/configure-app.js";

describe("patient profiles and medications", () => {
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

  async function login(phoneNumber: string, installationId: string) {
    const challenge = await request(app!.getHttpServer())
      .post("/api/v1/auth/otp/requests")
      .send({
        deviceInstallationId: installationId,
        locale: "en-BD",
        phoneNumber,
        purpose: "LOGIN",
      })
      .expect(201);
    const verified = await request(app!.getHttpServer())
      .post("/api/v1/auth/otp/verifications")
      .send({
        challengeId: challenge.body.data.challengeId,
        device: {
          appVersion: "1.0.0",
          deviceName: "Test phone",
          installationId,
          platform: "ANDROID",
        },
        otp: "123456",
      })
      .expect(201);
    return `Bearer ${verified.body.data.accessToken}`;
  }

  it("creates, lists, and updates the signed-in user's patient profile", async () => {
    const authorization = await login(
      "01700123456",
      "01K2OWNERDEVICE000000000001",
    );
    const created = await request(app!.getHttpServer())
      .post("/api/v1/patient-profiles")
      .set("Authorization", authorization)
      .send({ displayName: "Abu Sufyan", timezone: "Asia/Dhaka" })
      .expect(201);

    expect(created.body.data).toMatchObject({
      displayName: "Abu Sufyan",
      status: "ACTIVE",
      timezone: "Asia/Dhaka",
      version: 1,
    });

    const listed = await request(app!.getHttpServer())
      .get("/api/v1/patient-profiles")
      .set("Authorization", authorization)
      .expect(200);
    expect(listed.body.data).toHaveLength(1);

    const updated = await request(app!.getHttpServer())
      .patch(`/api/v1/patient-profiles/${created.body.data.id}`)
      .set("Authorization", authorization)
      .send({ displayName: "Sufyan", expectedVersion: 1 })
      .expect(200);
    expect(updated.body.data).toMatchObject({
      displayName: "Sufyan",
      version: 2,
    });
  });

  it("creates and edits a medication with explicit dose instructions", async () => {
    const authorization = await login(
      "01700123456",
      "01K2OWNERDEVICE000000000001",
    );
    const profile = await request(app!.getHttpServer())
      .post("/api/v1/patient-profiles")
      .set("Authorization", authorization)
      .send({ displayName: "Abu Sufyan", timezone: "Asia/Dhaka" })
      .expect(201);

    const medication = await request(app!.getHttpServer())
      .post(`/api/v1/patient-profiles/${profile.body.data.id}/medications`)
      .set("Authorization", authorization)
      .send({
        displayName: "Napa",
        form: "TABLET",
        instructions: {
          mealRelation: "AFTER",
          quantityUnit: "TABLET",
          quantityValue: 1,
          route: "ORAL",
          sourceText: "Take one tablet after food",
        },
        notes: "User-entered medicine",
        strengthUnit: "mg",
        strengthValue: 500,
      })
      .expect(201);

    expect(medication.body.data).toMatchObject({
      displayName: "Napa",
      form: "TABLET",
      instructions: { mealRelation: "AFTER", quantityValue: 1 },
      status: "ACTIVE",
      version: 1,
    });

    const updated = await request(app!.getHttpServer())
      .patch(`/api/v1/medications/${medication.body.data.id}`)
      .set("Authorization", authorization)
      .send({ expectedVersion: 1, notes: "Keep in a dry place" })
      .expect(200);
    expect(updated.body.data).toMatchObject({
      notes: "Keep in a dry place",
      version: 2,
    });
  });

  it("returns not found when another user requests an owner's profile", async () => {
    const owner = await login("01700123456", "01K2OWNERDEVICE000000000001");
    const stranger = await login("01800123456", "01K2OTHERDEVICE000000000001");
    const profile = await request(app!.getHttpServer())
      .post("/api/v1/patient-profiles")
      .set("Authorization", owner)
      .send({ displayName: "Private profile", timezone: "Asia/Dhaka" })
      .expect(201);

    await request(app!.getHttpServer())
      .get(`/api/v1/patient-profiles/${profile.body.data.id}`)
      .set("Authorization", stranger)
      .expect(404);
  });
});
