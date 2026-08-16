import type { INestApplication } from "@nestjs/common";
import { Test } from "@nestjs/testing";
import request from "supertest";
import { afterEach, beforeEach, describe, expect, it } from "vitest";

import { AppModule } from "../src/app.module.js";
import { configureApp } from "../src/configure-app.js";

describe("prescription extraction", () => {
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
    process.env.PRESCRIPTION_OCR_PROVIDER = "development";
    delete process.env.OPENAI_API_KEY;
    delete process.env.GOOGLE_DOCUMENT_AI_PROCESSOR_ID;
    delete process.env.GOOGLE_DOCUMENT_AI_PROJECT_ID;

    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    configureApp(app);
    await app.init();
  });

  afterEach(async () => app?.close());

  async function authenticatedProfile() {
    const challenge = await request(app!.getHttpServer())
      .post("/api/v1/auth/otp/requests")
      .send({
        deviceInstallationId: "01K2OCRDEVICE0000000000001",
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
          deviceName: "OCR test phone",
          installationId: "01K2OCRDEVICE0000000000001",
          platform: "ANDROID",
        },
        otp: "123456",
      })
      .expect(201);
    const authorization = `Bearer ${verified.body.data.accessToken}`;
    const profile = await request(app!.getHttpServer())
      .post("/api/v1/patient-profiles")
      .set("Authorization", authorization)
      .send({ displayName: "OCR patient", timezone: "Asia/Dhaka" })
      .expect(201);
    return { authorization, profileId: profile.body.data.id as string };
  }

  it("stores extraction output as an unverified draft", async () => {
    const { authorization, profileId } = await authenticatedProfile();
    const extracted = await request(app!.getHttpServer())
      .post(`/api/v1/patient-profiles/${profileId}/prescription-extractions`)
      .set("Authorization", authorization)
      .field("localOcrText", "Napa 500 mg")
      .attach(
        "image",
        Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
        {
          contentType: "image/png",
          filename: "prescription.png",
        },
      )
      .expect(201);

    expect(extracted.body.data).toMatchObject({
      documentType: "PRESCRIPTION",
      provider: "development",
      rawText: "Napa 500 mg",
      status: "REVIEW_REQUIRED",
    });
    expect(extracted.body.data.medicines[0]).toMatchObject({
      displayName: "Napa 500 mg",
      evidenceText: "Napa 500 mg",
    });
  });

  it("fails closed when no primary OCR evidence is available", async () => {
    process.env.PRESCRIPTION_OCR_PROVIDER = "disabled";
    const { authorization, profileId } = await authenticatedProfile();
    const response = await request(app!.getHttpServer())
      .post(`/api/v1/patient-profiles/${profileId}/prescription-extractions`)
      .set("Authorization", authorization)
      .attach("image", Buffer.from([0xff, 0xd8, 0xff, 0xd9]), {
        contentType: "image/jpeg",
        filename: "prescription.jpg",
      })
      .expect(503);

    expect(response.body.error.code).toBe("OCR_PROVIDER_UNAVAILABLE");
  });

  it("rejects a file whose bytes do not match the claimed image type", async () => {
    const { authorization, profileId } = await authenticatedProfile();
    const response = await request(app!.getHttpServer())
      .post(`/api/v1/patient-profiles/${profileId}/prescription-extractions`)
      .set("Authorization", authorization)
      .attach("image", Buffer.from("not-an-image"), {
        contentType: "image/png",
        filename: "prescription.png",
      })
      .expect(400);

    expect(response.body.message).toContain("does not match");
  });
});
