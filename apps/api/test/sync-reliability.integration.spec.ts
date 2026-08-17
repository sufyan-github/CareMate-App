import type { INestApplication } from "@nestjs/common";
import { Test } from "@nestjs/testing";
import request from "supertest";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { AppModule } from "../src/app.module.js";
import { configureApp } from "../src/configure-app.js";
import { DatabaseService } from "../src/database/database.service.js";

describe("sync reliability", () => {
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

  it("accepts an offline mutation exactly once and resolves a stale conflict", async () => {
    const context = await createScheduledOccurrence(app!);
    const confirmation = {
      baseVersion: 1,
      clientAt: "2026-08-17T08:05:00+06:00",
      command: "CONFIRM",
      entityId: context.occurrenceId,
      entityType: "DOSE_OCCURRENCE",
      installationId: context.installationId,
      mutationId: "01K2SYNCCONFIRM000000000001",
    };

    const first = await request(app!.getHttpServer())
      .post("/api/v1/sync/mutations:batch")
      .set("Authorization", context.authorization)
      .send({ mutations: [confirmation] })
      .expect(201);
    expect(first.body.data.results).toEqual([
      expect.objectContaining({
        authoritative: expect.objectContaining({
          id: context.occurrenceId,
          status: "CONFIRMED",
          version: 2,
        }),
        mutationId: confirmation.mutationId,
        status: "ACCEPTED",
      }),
    ]);

    const replay = await request(app!.getHttpServer())
      .post("/api/v1/sync/mutations:batch")
      .set("Authorization", context.authorization)
      .send({ mutations: [confirmation] })
      .expect(201);
    expect(replay.body.data.results).toEqual([
      expect.objectContaining({
        authoritative: first.body.data.results[0].authoritative,
        mutationId: confirmation.mutationId,
        status: "ALREADY_APPLIED",
      }),
    ]);

    const conflict = await request(app!.getHttpServer())
      .post("/api/v1/sync/mutations:batch")
      .set("Authorization", context.authorization)
      .send({
        mutations: [
          {
            ...confirmation,
            command: "SKIP",
            mutationId: "01K2SYNCCONFLICT0000000001",
          },
        ],
      })
      .expect(201);
    expect(conflict.body.data.results).toEqual([
      expect.objectContaining({
        authoritative: expect.objectContaining({
          status: "CONFIRMED",
          version: 2,
        }),
        error: expect.objectContaining({ code: "DOSE_VERSION_CONFLICT" }),
        status: "CONFLICT",
      }),
    ]);
  });

  it("registers the authenticated installation without accepting another session installation", async () => {
    const context = await createScheduledOccurrence(app!);

    const registered = await request(app!.getHttpServer())
      .put(`/api/v1/devices/${context.installationId}`)
      .set("Authorization", context.authorization)
      .send({
        appVersion: "1.0.0",
        deviceName: "Motorola test phone",
        locale: "bn-BD",
        platform: "ANDROID",
        pushToken: "test-fcm-token-1234567890",
      })
      .expect(200);
    expect(registered.body.data).toMatchObject({
      appVersion: "1.0.0",
      installationId: context.installationId,
      locale: "bn-BD",
      platform: "ANDROID",
      status: "ACTIVE",
    });
    const encryptedRegistration = await app!
      .get(DatabaseService)
      .deviceInstallation.findUnique({
        where: {
          userId_installationId: {
            installationId: context.installationId,
            userId: context.userId,
          },
        },
      });
    expect(encryptedRegistration?.pushTokenEncrypted).not.toContain(
      "test-fcm-token-1234567890",
    );
    expect(encryptedRegistration?.pushTokenLookupHash).toHaveLength(64);
    expect(encryptedRegistration?.pushStatus).toBe("ACTIVE");

    await request(app!.getHttpServer())
      .delete(`/api/v1/devices/${context.installationId}/push-token`)
      .set("Authorization", context.authorization)
      .expect(204);

    await request(app!.getHttpServer())
      .put("/api/v1/devices/01K2OTHERINSTALLATION000001")
      .set("Authorization", context.authorization)
      .send({
        appVersion: "1.0.0",
        deviceName: "Unknown phone",
        locale: "bn-BD",
        platform: "ANDROID",
      })
      .expect(403);

    await request(app!.getHttpServer())
      .put(`/api/v1/devices/${context.installationId}`)
      .set("Authorization", context.authorization)
      .send({
        appVersion: "1.0.0",
        deviceName: "Motorola test phone",
        locale: "bn-BD",
        platform: "ANDROID",
        pushToken: "replacement-fcm-token-123456",
      })
      .expect(200);
    await request(app!.getHttpServer())
      .post("/api/v1/auth/logout")
      .set("Authorization", context.authorization)
      .expect(204);
    const installation = await app!
      .get(DatabaseService)
      .deviceInstallation.findUnique({
        where: {
          userId_installationId: {
            installationId: context.installationId,
            userId: context.userId,
          },
        },
      });
    expect(installation?.pushTokenEncrypted).toBeNull();
    expect(installation?.pushTokenLookupHash).toBeNull();
    expect(installation?.pushStatus).toBe("UNREGISTERED");
  });

  it("labels concurrent replays atomically and creates one outcome event", async () => {
    const context = await createScheduledOccurrence(app!);
    const mutation = {
      baseVersion: 1,
      clientAt: "2026-08-17T08:05:00+06:00",
      command: "CONFIRM",
      entityId: context.occurrenceId,
      entityType: "DOSE_OCCURRENCE",
      installationId: context.installationId,
      mutationId: "01K2SYNCCONCURRENT00000001",
    };

    const responses = await Promise.all([
      request(app!.getHttpServer())
        .post("/api/v1/sync/mutations:batch")
        .set("Authorization", context.authorization)
        .send({ mutations: [mutation] }),
      request(app!.getHttpServer())
        .post("/api/v1/sync/mutations:batch")
        .set("Authorization", context.authorization)
        .send({ mutations: [mutation] }),
    ]);

    expect(responses.map((response) => response.status)).toEqual([201, 201]);
    expect(
      responses
        .map((response) => response.body.data.results[0].status as string)
        .sort(),
    ).toEqual(["ACCEPTED", "ALREADY_APPLIED"]);
    expect(
      await app!.get(DatabaseService).doseEvent.count({
        where: { clientMutationId: mutation.mutationId },
      }),
    ).toBe(1);
  });
});

async function createScheduledOccurrence(app: INestApplication) {
  const installationId = "01K2SYNCDEVICE000000000001";
  const challenge = await request(app.getHttpServer())
    .post("/api/v1/auth/otp/requests")
    .send({
      deviceInstallationId: installationId,
      locale: "en-BD",
      phoneNumber: "01700112244",
      purpose: "LOGIN",
    })
    .expect(201);
  const verified = await request(app.getHttpServer())
    .post("/api/v1/auth/otp/verifications")
    .send({
      challengeId: challenge.body.data.challengeId,
      device: {
        appVersion: "1.0.0",
        deviceName: "Sync test phone",
        installationId,
        platform: "ANDROID",
      },
      otp: "123456",
    })
    .expect(201);
  const authorization = `Bearer ${verified.body.data.accessToken}`;
  const profile = await request(app.getHttpServer())
    .post("/api/v1/patient-profiles")
    .set("Authorization", authorization)
    .send({ displayName: "Sync owner", timezone: "Asia/Dhaka" })
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
    installationId,
    occurrenceId: occurrences.body.data[0].id as string,
    userId: verified.body.data.user.id as string,
  };
}
