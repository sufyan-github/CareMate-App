import type { INestApplication } from "@nestjs/common";
import { Test } from "@nestjs/testing";
import request from "supertest";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { AppModule } from "../src/app.module.js";
import { configureApp } from "../src/configure-app.js";

describe("app-based adherence reporting", () => {
  let app: INestApplication | undefined;

  beforeEach(async () => {
    vi.useFakeTimers({ toFake: ["Date", "setInterval", "clearInterval"] });
    vi.setSystemTime(new Date("2026-08-17T02:05:00.000Z"));
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

  afterEach(async () => {
    await app?.close();
    vi.useRealTimers();
  });

  it("explains the numerator, denominator, outcomes, and exclusions", async () => {
    const context = await createReportingContext(app!);
    await request(app!.getHttpServer())
      .post(`/api/v1/dose-occurrences/${context.occurrenceIds[0]}/commands`)
      .set("Authorization", context.authorization)
      .send({
        clientAt: "2026-08-17T08:05:00+06:00",
        clientMutationId: "01K2REPORTCONFIRM0000000001",
        command: "CONFIRM",
        expectedVersion: 1,
      })
      .expect(201);
    await request(app!.getHttpServer())
      .post(`/api/v1/dose-occurrences/${context.occurrenceIds[1]}/commands`)
      .set("Authorization", context.authorization)
      .send({
        clientAt: "2026-08-17T08:05:00+06:00",
        clientMutationId: "01K2REPORTSKIP0000000000001",
        command: "SKIP",
        expectedVersion: 1,
      })
      .expect(201);

    const report = await request(app!.getHttpServer())
      .get(`/api/v1/patient-profiles/${context.profileId}/indicators`)
      .set("Authorization", context.authorization)
      .query({ from: "2026-08-17", to: "2026-08-17" })
      .expect(200);
    expect(report.body.data).toMatchObject({
      appBased: true,
      counts: {
        cancelledExcluded: 0,
        futureExcluded: 1,
        lateConfirmed: 0,
        missed: 0,
        onTimeConfirmed: 1,
        skipped: 1,
        unresolved: 1,
      },
      denominator: 2,
      label: "App-based adherence indicator",
      numerator: 1,
      percentage: 50,
      period: {
        from: "2026-08-17",
        timezone: "Asia/Dhaka",
        to: "2026-08-17",
      },
      selfReported: true,
    });
    expect(report.body.data.disclaimer).toContain("not a clinical");
    expect(report.body.data.daily).toEqual([
      expect.objectContaining({
        date: "2026-08-17",
        eligibleCompleted: 2,
        eligibleConfirmed: 1,
        percentage: 50,
      }),
    ]);
    expect(report.body.data.medications).toEqual([
      expect.objectContaining({
        eligibleCompleted: 2,
        medicationName: "Napa",
        percentage: 50,
      }),
    ]);
  });

  it("returns no score for an empty period and rejects unsafe windows", async () => {
    const context = await createReportingContext(app!);
    const empty = await request(app!.getHttpServer())
      .get(`/api/v1/patient-profiles/${context.profileId}/indicators`)
      .set("Authorization", context.authorization)
      .query({ from: "2026-08-16", to: "2026-08-16" })
      .expect(200);
    expect(empty.body.data).toMatchObject({
      denominator: 0,
      numerator: 0,
      percentage: null,
    });

    const reversed = await request(app!.getHttpServer())
      .get(`/api/v1/patient-profiles/${context.profileId}/indicators`)
      .set("Authorization", context.authorization)
      .query({ from: "2026-08-18", to: "2026-08-17" })
      .expect(400);
    expect(reversed.body.error.code).toBe("INDICATOR_WINDOW_INVALID");

    const tooLong = await request(app!.getHttpServer())
      .get(`/api/v1/patient-profiles/${context.profileId}/indicators`)
      .set("Authorization", context.authorization)
      .query({ from: "2025-08-16", to: "2026-08-17" })
      .expect(400);
    expect(tooLong.body.error.code).toBe("INDICATOR_WINDOW_INVALID");
  });
});

async function createReportingContext(app: INestApplication) {
  const challenge = await request(app.getHttpServer())
    .post("/api/v1/auth/otp/requests")
    .send({
      deviceInstallationId: "01K2REPORTINGDEVICE0000001",
      locale: "en-BD",
      phoneNumber: "01700112233",
      purpose: "LOGIN",
    })
    .expect(201);
  const verified = await request(app.getHttpServer())
    .post("/api/v1/auth/otp/verifications")
    .send({
      challengeId: challenge.body.data.challengeId,
      device: {
        appVersion: "1.0.0",
        deviceName: "Reporting test phone",
        installationId: "01K2REPORTINGDEVICE0000001",
        platform: "ANDROID",
      },
      otp: "123456",
    })
    .expect(201);
  const authorization = `Bearer ${verified.body.data.accessToken}`;
  const profile = await request(app.getHttpServer())
    .post("/api/v1/patient-profiles")
    .set("Authorization", authorization)
    .send({ displayName: "Report owner", timezone: "Asia/Dhaka" })
    .expect(201);
  const medication = await request(app.getHttpServer())
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
      },
    })
    .expect(201);
  await request(app.getHttpServer())
    .post(`/api/v1/medications/${medication.body.data.id}/schedules`)
    .set("Authorization", authorization)
    .send({
      activation: "ACTIVATE",
      endDate: "2026-08-17",
      startDate: "2026-08-17",
      times: ["08:00", "08:02", "08:04", "09:00"],
      timezone: "Asia/Dhaka",
    })
    .expect(201);
  const occurrences = await request(app.getHttpServer())
    .get(`/api/v1/patient-profiles/${profile.body.data.id}/dose-occurrences`)
    .set("Authorization", authorization)
    .query({ from: "2026-08-17", to: "2026-08-17" })
    .expect(200);
  return {
    authorization,
    occurrenceIds: occurrences.body.data.map(
      (occurrence: { id: string }) => occurrence.id,
    ) as string[],
    profileId: profile.body.data.id as string,
  };
}
