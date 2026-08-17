import type { INestApplication } from "@nestjs/common";
import { Test } from "@nestjs/testing";
import request from "supertest";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { AppModule } from "../src/app.module.js";
import { configureApp } from "../src/configure-app.js";

describe("medication schedules", () => {
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

  it("previews and activates a reviewed daily schedule with deterministic occurrences", async () => {
    const challenge = await request(app!.getHttpServer())
      .post("/api/v1/auth/otp/requests")
      .send({
        deviceInstallationId: "01K2SCHEDULEDEVICE000000001",
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
          deviceName: "Schedule test phone",
          installationId: "01K2SCHEDULEDEVICE000000001",
          platform: "ANDROID",
        },
        otp: "123456",
      })
      .expect(201);
    const authorization = `Bearer ${verified.body.data.accessToken}`;
    const profile = await request(app!.getHttpServer())
      .post("/api/v1/patient-profiles")
      .set("Authorization", authorization)
      .send({ displayName: "Schedule owner", timezone: "Asia/Dhaka" })
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
        },
      })
      .expect(201);
    const scheduleInput = {
      activation: "PREVIEW",
      endDate: "2026-08-19",
      startDate: "2026-08-17",
      times: ["08:00", "20:00"],
      timezone: "Asia/Dhaka",
    };

    const preview = await request(app!.getHttpServer())
      .post(`/api/v1/medications/${medication.body.data.id}/schedules`)
      .set("Authorization", authorization)
      .send(scheduleInput)
      .expect(201);
    expect(preview.body.data).toMatchObject({
      activation: "PREVIEW",
      quantityRequired: 6,
      quantityUnit: "TABLET",
    });
    expect(preview.body.data.occurrences).toEqual([
      expect.objectContaining({
        plannedAt: "2026-08-17T02:00:00.000Z",
        plannedLocalDateTime: "2026-08-17T08:00",
      }),
      expect.objectContaining({
        plannedAt: "2026-08-17T14:00:00.000Z",
        plannedLocalDateTime: "2026-08-17T20:00",
      }),
      expect.objectContaining({
        plannedLocalDateTime: "2026-08-18T08:00",
      }),
      expect.objectContaining({
        plannedLocalDateTime: "2026-08-18T20:00",
      }),
      expect.objectContaining({
        plannedLocalDateTime: "2026-08-19T08:00",
      }),
      expect.objectContaining({
        plannedLocalDateTime: "2026-08-19T20:00",
      }),
    ]);

    const beforeActivation = await request(app!.getHttpServer())
      .get(`/api/v1/patient-profiles/${profile.body.data.id}/dose-occurrences`)
      .set("Authorization", authorization)
      .query({ from: "2026-08-17", to: "2026-08-19" })
      .expect(200);
    expect(beforeActivation.body.data).toEqual([]);

    const activated = await request(app!.getHttpServer())
      .post(`/api/v1/medications/${medication.body.data.id}/schedules`)
      .set("Authorization", authorization)
      .send({ ...scheduleInput, activation: "ACTIVATE" })
      .expect(201);
    expect(activated.body.data.schedule).toMatchObject({
      revision: 1,
      status: "ACTIVE",
      times: ["08:00", "20:00"],
      version: 1,
    });
    const medicationWithSchedule = await request(app!.getHttpServer())
      .get(`/api/v1/medications/${medication.body.data.id}`)
      .set("Authorization", authorization)
      .expect(200);
    expect(medicationWithSchedule.body.data.activeSchedule).toMatchObject({
      id: activated.body.data.schedule.id,
      status: "ACTIVE",
      times: ["08:00", "20:00"],
      version: 1,
    });

    const occurrences = await request(app!.getHttpServer())
      .get(`/api/v1/patient-profiles/${profile.body.data.id}/dose-occurrences`)
      .set("Authorization", authorization)
      .query({ from: "2026-08-17", to: "2026-08-19" })
      .expect(200);
    expect(occurrences.body.data).toHaveLength(6);
    expect(occurrences.body.data[0]).toMatchObject({
      medication: { displayName: "Napa" },
      quantityUnit: "TABLET",
      quantityValue: 1,
      status: "SCHEDULED",
      version: 1,
    });

    const openMedication = await request(app!.getHttpServer())
      .post(`/api/v1/patient-profiles/${profile.body.data.id}/medications`)
      .set("Authorization", authorization)
      .send({
        displayName: "Rolling medicine",
        form: "TABLET",
        instructions: {
          mealRelation: "UNSPECIFIED",
          quantityUnit: "TABLET",
          quantityValue: 1,
          route: "ORAL",
        },
      })
      .expect(201);
    const openSchedule = await request(app!.getHttpServer())
      .post(`/api/v1/medications/${openMedication.body.data.id}/schedules`)
      .set("Authorization", authorization)
      .send({
        activation: "ACTIVATE",
        startDate: "2026-08-17",
        times: ["07:00"],
        timezone: "Asia/Dhaka",
      })
      .expect(201);
    expect(openSchedule.body.data.schedule.generatedThroughDate).toBe(
      "2026-09-15",
    );
    vi.useFakeTimers({ toFake: ["Date"] });
    vi.setSystemTime(new Date("2026-08-18T00:00:00.000Z"));
    try {
      const refreshed = await request(app!.getHttpServer())
        .post("/api/v1/auth/token/refresh")
        .send({ refreshToken: verified.body.data.refreshToken })
        .expect(201);
      const extended = await request(app!.getHttpServer())
        .get(
          `/api/v1/patient-profiles/${profile.body.data.id}/dose-occurrences`,
        )
        .set("Authorization", `Bearer ${refreshed.body.data.accessToken}`)
        .query({ from: "2026-09-16", to: "2026-09-16" })
        .expect(200);
      expect(extended.body.data).toEqual([
        expect.objectContaining({
          medication: expect.objectContaining({
            displayName: "Rolling medicine",
          }),
          plannedLocalDateTime: "2026-09-16T07:00",
        }),
      ]);
    } finally {
      vi.useRealTimers();
    }
  });

  it("revises, pauses, resumes, and ends only the owned schedule", async () => {
    const challenge = await request(app!.getHttpServer())
      .post("/api/v1/auth/otp/requests")
      .send({
        deviceInstallationId: "01K2LIFECYCLEDEVICE0000001",
        locale: "en-BD",
        phoneNumber: "01800123456",
        purpose: "LOGIN",
      })
      .expect(201);
    const verified = await request(app!.getHttpServer())
      .post("/api/v1/auth/otp/verifications")
      .send({
        challengeId: challenge.body.data.challengeId,
        device: {
          appVersion: "1.0.0",
          deviceName: "Lifecycle test phone",
          installationId: "01K2LIFECYCLEDEVICE0000001",
          platform: "ANDROID",
        },
        otp: "123456",
      })
      .expect(201);
    const authorization = `Bearer ${verified.body.data.accessToken}`;
    const profile = await request(app!.getHttpServer())
      .post("/api/v1/patient-profiles")
      .set("Authorization", authorization)
      .send({ displayName: "Lifecycle owner", timezone: "Asia/Dhaka" })
      .expect(201);
    const medication = await request(app!.getHttpServer())
      .post(`/api/v1/patient-profiles/${profile.body.data.id}/medications`)
      .set("Authorization", authorization)
      .send({
        displayName: "Future medicine",
        form: "CAPSULE",
        instructions: {
          mealRelation: "UNSPECIFIED",
          quantityUnit: "CAPSULE",
          quantityValue: 2,
          route: "ORAL",
        },
      })
      .expect(201);
    const activated = await request(app!.getHttpServer())
      .post(`/api/v1/medications/${medication.body.data.id}/schedules`)
      .set("Authorization", authorization)
      .send({
        activation: "ACTIVATE",
        endDate: "2099-01-03",
        startDate: "2099-01-01",
        times: ["08:00"],
        timezone: "Asia/Dhaka",
      })
      .expect(201);
    const scheduleId = activated.body.data.schedule.id as string;

    const revised = await request(app!.getHttpServer())
      .patch(`/api/v1/schedules/${scheduleId}`)
      .set("Authorization", authorization)
      .send({ expectedVersion: 1, times: ["09:30", "21:30"] })
      .expect(200);
    expect(revised.body.data).toMatchObject({
      revision: 2,
      status: "ACTIVE",
      times: ["09:30", "21:30"],
      version: 2,
    });
    const revisedOccurrences = await request(app!.getHttpServer())
      .get(`/api/v1/patient-profiles/${profile.body.data.id}/dose-occurrences`)
      .set("Authorization", authorization)
      .query({ from: "2099-01-01", to: "2099-01-03" })
      .expect(200);
    expect(revisedOccurrences.body.data).toHaveLength(6);
    expect(
      revisedOccurrences.body.data.map(
        (item: { plannedLocalDateTime: string }) => item.plannedLocalDateTime,
      ),
    ).toEqual([
      "2099-01-01T09:30",
      "2099-01-01T21:30",
      "2099-01-02T09:30",
      "2099-01-02T21:30",
      "2099-01-03T09:30",
      "2099-01-03T21:30",
    ]);

    const paused = await request(app!.getHttpServer())
      .post(`/api/v1/schedules/${scheduleId}/pause`)
      .set("Authorization", authorization)
      .send({ expectedVersion: 2 })
      .expect(201);
    expect(paused.body.data).toMatchObject({ status: "PAUSED", version: 3 });
    const whilePaused = await request(app!.getHttpServer())
      .get(`/api/v1/patient-profiles/${profile.body.data.id}/dose-occurrences`)
      .set("Authorization", authorization)
      .query({ from: "2099-01-01", to: "2099-01-03" })
      .expect(200);
    expect(whilePaused.body.data).toEqual([]);

    const resumed = await request(app!.getHttpServer())
      .post(`/api/v1/schedules/${scheduleId}/resume`)
      .set("Authorization", authorization)
      .send({ expectedVersion: 3 })
      .expect(201);
    expect(resumed.body.data).toMatchObject({
      revision: 3,
      status: "ACTIVE",
      version: 4,
    });

    const ended = await request(app!.getHttpServer())
      .post(`/api/v1/schedules/${scheduleId}/end`)
      .set("Authorization", authorization)
      .send({ expectedVersion: 4 })
      .expect(201);
    expect(ended.body.data).toMatchObject({ status: "ENDED", version: 5 });
    const afterEnd = await request(app!.getHttpServer())
      .get(`/api/v1/patient-profiles/${profile.body.data.id}/dose-occurrences`)
      .set("Authorization", authorization)
      .query({ from: "2099-01-01", to: "2099-01-03" })
      .expect(200);
    expect(afterEnd.body.data).toEqual([]);

    await request(app!.getHttpServer())
      .post(`/api/v1/schedules/${scheduleId}/resume`)
      .set("Authorization", authorization)
      .send({ expectedVersion: 5 })
      .expect(409);

    const concurrentInput = {
      activation: "ACTIVATE",
      endDate: "2099-02-02",
      startDate: "2099-02-01",
      times: ["07:00"],
      timezone: "Asia/Dhaka",
    };
    const concurrentActivations = await Promise.all([
      request(app!.getHttpServer())
        .post(`/api/v1/medications/${medication.body.data.id}/schedules`)
        .set("Authorization", authorization)
        .send(concurrentInput),
      request(app!.getHttpServer())
        .post(`/api/v1/medications/${medication.body.data.id}/schedules`)
        .set("Authorization", authorization)
        .send(concurrentInput),
    ]);
    expect(concurrentActivations.map((result) => result.status).sort()).toEqual(
      [201, 409],
    );
  });
});
