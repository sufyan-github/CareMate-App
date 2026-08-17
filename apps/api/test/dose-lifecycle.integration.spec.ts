import type { INestApplication } from "@nestjs/common";
import { Test } from "@nestjs/testing";
import request from "supertest";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { AppModule } from "../src/app.module.js";
import { configureApp } from "../src/configure-app.js";
import { DatabaseService } from "../src/database/database.service.js";

describe("dose lifecycle", () => {
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

  it("records one self-reported confirmation when a client mutation is retried", async () => {
    const context = await createScheduledOccurrence(app!);
    const command = {
      clientAt: "2026-08-17T08:05:00+06:00",
      clientMutationId: "01K2DOSECONFIRM000000000001",
      command: "CONFIRM",
      expectedVersion: 1,
    };

    const confirmed = await request(app!.getHttpServer())
      .post(`/api/v1/dose-occurrences/${context.occurrenceId}/commands`)
      .set("Authorization", context.authorization)
      .send(command)
      .expect(201);
    expect(confirmed.body.data).toMatchObject({
      confirmedAt: "2026-08-17T02:05:00.000Z",
      id: context.occurrenceId,
      status: "CONFIRMED",
      timingClassification: "ON_TIME",
      version: 2,
    });

    const retried = await request(app!.getHttpServer())
      .post(`/api/v1/dose-occurrences/${context.occurrenceId}/commands`)
      .set("Authorization", context.authorization)
      .send(command)
      .expect(201);
    expect(retried.body.data).toEqual(confirmed.body.data);

    const occurrence = await request(app!.getHttpServer())
      .get(`/api/v1/dose-occurrences/${context.occurrenceId}`)
      .set("Authorization", context.authorization)
      .expect(200);
    expect(occurrence.body.data.events).toEqual([
      expect.objectContaining({
        clientMutationId: command.clientMutationId,
        eventType: "CONFIRMED",
      }),
    ]);
    const confirmation = await app!
      .get(DatabaseService)
      .doseConfirmation.findUniqueOrThrow({
        where: { occurrenceId: context.occurrenceId },
      });
    expect(confirmation).toMatchObject({
      authSessionId: expect.any(String),
      deviceInstallationId: "01K2DOSELIFECYCLEDEVICE001",
    });
  });

  it("snoozes a due occurrence once and makes it due again after expiry", async () => {
    const context = await createScheduledOccurrence(app!);

    const snoozed = await request(app!.getHttpServer())
      .post(`/api/v1/dose-occurrences/${context.occurrenceId}/commands`)
      .set("Authorization", context.authorization)
      .send({
        clientAt: "2026-08-17T08:05:00+06:00",
        clientMutationId: "01K2DOSESNOOZE000000000001",
        command: "SNOOZE",
        expectedVersion: 1,
        payload: { snoozeMinutes: 10 },
      })
      .expect(201);
    expect(snoozed.body.data).toMatchObject({
      id: context.occurrenceId,
      reminderSentAt: "2026-08-17T02:05:00.000Z",
      snoozeCount: 1,
      snoozedUntil: "2026-08-17T02:15:00.000Z",
      status: "SNOOZED",
      version: 2,
    });

    vi.setSystemTime(new Date("2026-08-17T02:16:00.000Z"));
    const dueAgain = await request(app!.getHttpServer())
      .get(`/api/v1/dose-occurrences/${context.occurrenceId}`)
      .set("Authorization", context.authorization)
      .expect(200);
    expect(dueAgain.body.data).toMatchObject({
      snoozeCount: 1,
      snoozedUntil: null,
      status: "REMINDER_SENT",
      version: 3,
    });
    expect(
      dueAgain.body.data.events.map(
        (event: { eventType: string }) => event.eventType,
      ),
    ).toEqual(["SNOOZED", "REMINDER_SENT"]);
  });

  it("marks an unresolved occurrence missed and preserves that history after a late confirmation", async () => {
    const context = await createScheduledOccurrence(app!);
    vi.setSystemTime(new Date("2026-08-17T03:01:00.000Z"));
    const refreshed = await request(app!.getHttpServer())
      .post("/api/v1/auth/token/refresh")
      .send({ refreshToken: context.refreshToken })
      .expect(201);
    const authorization = `Bearer ${refreshed.body.data.accessToken}`;

    const missed = await request(app!.getHttpServer())
      .get(`/api/v1/dose-occurrences/${context.occurrenceId}`)
      .set("Authorization", authorization)
      .expect(200);
    expect(missed.body.data).toMatchObject({
      confirmedAt: null,
      missedAt: "2026-08-17T03:01:00.000Z",
      status: "MISSED",
      version: 2,
    });
    expect(missed.body.data.events).toEqual([
      expect.objectContaining({ eventType: "MISSED" }),
    ]);

    const late = await request(app!.getHttpServer())
      .post(`/api/v1/dose-occurrences/${context.occurrenceId}/commands`)
      .set("Authorization", authorization)
      .send({
        clientAt: "2026-08-17T09:02:00+06:00",
        clientMutationId: "01K2DOSELATECONFIRM00000001",
        command: "CONFIRM",
        expectedVersion: 2,
      })
      .expect(201);
    expect(late.body.data).toMatchObject({
      missedAt: "2026-08-17T03:01:00.000Z",
      status: "CONFIRMED",
      timingClassification: "LATE",
      version: 3,
    });

    const history = await request(app!.getHttpServer())
      .get(`/api/v1/dose-occurrences/${context.occurrenceId}`)
      .set("Authorization", authorization)
      .expect(200);
    expect(
      history.body.data.events.map(
        (event: { eventType: string }) => event.eventType,
      ),
    ).toEqual(["MISSED", "CONFIRMED"]);
  });

  it("stores an optional skip statement and prevents a later terminal outcome", async () => {
    const context = await createScheduledOccurrence(app!);

    const skipped = await request(app!.getHttpServer())
      .post(`/api/v1/dose-occurrences/${context.occurrenceId}/commands`)
      .set("Authorization", context.authorization)
      .send({
        clientAt: "2026-08-17T08:05:00+06:00",
        clientMutationId: "01K2DOSESKIP00000000000001",
        command: "SKIP",
        expectedVersion: 1,
        payload: { reason: "User chose not to take this planned dose." },
      })
      .expect(201);
    expect(skipped.body.data).toMatchObject({
      status: "SKIPPED",
      version: 2,
    });

    const history = await request(app!.getHttpServer())
      .get(`/api/v1/dose-occurrences/${context.occurrenceId}`)
      .set("Authorization", context.authorization)
      .expect(200);
    expect(history.body.data.events).toEqual([
      expect.objectContaining({
        eventType: "SKIPPED",
        metadata: { reason: "User chose not to take this planned dose." },
      }),
    ]);

    await request(app!.getHttpServer())
      .post(`/api/v1/dose-occurrences/${context.occurrenceId}/commands`)
      .set("Authorization", context.authorization)
      .send({
        clientAt: "2026-08-17T08:06:00+06:00",
        clientMutationId: "01K2DOSECONFIRMAFTERSKIP01",
        command: "CONFIRM",
        expectedVersion: 2,
      })
      .expect(409);
  });

  it("repairs overdue state through the Today occurrence window", async () => {
    const context = await createScheduledOccurrence(app!);
    vi.setSystemTime(new Date("2026-08-17T03:01:00.000Z"));
    const refreshed = await request(app!.getHttpServer())
      .post("/api/v1/auth/token/refresh")
      .send({ refreshToken: context.refreshToken })
      .expect(201);

    const today = await request(app!.getHttpServer())
      .get(`/api/v1/patient-profiles/${context.profileId}/dose-occurrences`)
      .set("Authorization", `Bearer ${refreshed.body.data.accessToken}`)
      .query({ from: "2026-08-17", to: "2026-08-17" })
      .expect(200);
    expect(today.body.data).toEqual([
      expect.objectContaining({
        id: context.occurrenceId,
        missedAt: "2026-08-17T03:01:00.000Z",
        status: "MISSED",
        version: 2,
      }),
    ]);
  });

  it("classifies a direct post-deadline confirmation as late", async () => {
    const context = await createScheduledOccurrence(app!);
    vi.setSystemTime(new Date("2026-08-17T03:01:00.000Z"));
    const refreshed = await request(app!.getHttpServer())
      .post("/api/v1/auth/token/refresh")
      .send({ refreshToken: context.refreshToken })
      .expect(201);
    const authorization = `Bearer ${refreshed.body.data.accessToken}`;

    const confirmed = await request(app!.getHttpServer())
      .post(`/api/v1/dose-occurrences/${context.occurrenceId}/commands`)
      .set("Authorization", authorization)
      .send({
        clientAt: "2026-08-17T09:01:00+06:00",
        clientMutationId: "01K2DOSEDIRECTLATE00000001",
        command: "CONFIRM",
        expectedVersion: 1,
      })
      .expect(201);
    expect(confirmed.body.data).toMatchObject({
      missedAt: "2026-08-17T03:01:00.000Z",
      status: "CONFIRMED",
      timingClassification: "LATE",
      version: 3,
    });

    const history = await request(app!.getHttpServer())
      .get(`/api/v1/dose-occurrences/${context.occurrenceId}`)
      .set("Authorization", authorization)
      .expect(200);
    expect(
      history.body.data.events.map(
        (event: { eventType: string }) => event.eventType,
      ),
    ).toEqual(["MISSED", "CONFIRMED"]);
  });

  it("accepts only one of two concurrent terminal outcomes", async () => {
    const context = await createScheduledOccurrence(app!);
    const base = {
      clientAt: "2026-08-17T08:05:00+06:00",
      expectedVersion: 1,
    };

    const outcomes = await Promise.all([
      request(app!.getHttpServer())
        .post(`/api/v1/dose-occurrences/${context.occurrenceId}/commands`)
        .set("Authorization", context.authorization)
        .send({
          ...base,
          clientMutationId: "01K2DOSECONCURRENTCONFIRM01",
          command: "CONFIRM",
        }),
      request(app!.getHttpServer())
        .post(`/api/v1/dose-occurrences/${context.occurrenceId}/commands`)
        .set("Authorization", context.authorization)
        .send({
          ...base,
          clientMutationId: "01K2DOSECONCURRENTSKIP0001",
          command: "SKIP",
        }),
    ]);
    expect(outcomes.map((outcome) => outcome.status).sort()).toEqual([
      201, 409,
    ]);

    const history = await request(app!.getHttpServer())
      .get(`/api/v1/dose-occurrences/${context.occurrenceId}`)
      .set("Authorization", context.authorization)
      .expect(200);
    expect(history.body.data.events).toHaveLength(1);
    expect(["CONFIRMED", "SKIPPED"]).toContain(history.body.data.status);
  });

  it("rejects every outcome command before the planned dose time", async () => {
    vi.setSystemTime(new Date("2026-08-17T01:55:00.000Z"));
    const context = await createScheduledOccurrence(app!);

    for (const [index, command] of ["CONFIRM", "SNOOZE", "SKIP"].entries()) {
      const response = await request(app!.getHttpServer())
        .post(`/api/v1/dose-occurrences/${context.occurrenceId}/commands`)
        .set("Authorization", context.authorization)
        .send({
          clientAt: "2026-08-17T07:55:00+06:00",
          clientMutationId: `01K2DOSETOOEARLY000000000${index}`,
          command,
          expectedVersion: 1,
          ...(command === "SNOOZE" ? { payload: { snoozeMinutes: 10 } } : {}),
        })
        .expect(409);
      expect(response.body.error.code).toBe("DOSE_NOT_DUE");
    }
  });

  it("repairs overdue occurrences without requiring a read request", async () => {
    const context = await createScheduledOccurrence(app!);
    vi.setSystemTime(new Date("2026-08-17T03:06:00.000Z"));
    await vi.advanceTimersByTimeAsync(61_000);

    const database = app!.get(DatabaseService);
    const occurrence = await database.doseOccurrence.findUniqueOrThrow({
      include: { events: true },
      where: { id: context.occurrenceId },
    });
    expect(occurrence.status).toBe("MISSED");
    expect(occurrence.events).toEqual([
      expect.objectContaining({ eventType: "MISSED" }),
    ]);
  });
});

async function createScheduledOccurrence(app: INestApplication) {
  const challenge = await request(app.getHttpServer())
    .post("/api/v1/auth/otp/requests")
    .send({
      deviceInstallationId: "01K2DOSELIFECYCLEDEVICE001",
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
        deviceName: "Dose lifecycle test phone",
        installationId: "01K2DOSELIFECYCLEDEVICE001",
        platform: "ANDROID",
      },
      otp: "123456",
    })
    .expect(201);
  const authorization = `Bearer ${verified.body.data.accessToken}`;
  const profile = await request(app.getHttpServer())
    .post("/api/v1/patient-profiles")
    .set("Authorization", authorization)
    .send({ displayName: "Dose owner", timezone: "Asia/Dhaka" })
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
      times: ["08:00"],
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
    occurrenceId: occurrences.body.data[0].id as string,
    profileId: profile.body.data.id as string,
    refreshToken: verified.body.data.refreshToken as string,
  };
}
