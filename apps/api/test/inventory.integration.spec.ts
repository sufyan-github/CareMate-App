import type { INestApplication } from "@nestjs/common";
import { Test } from "@nestjs/testing";
import request from "supertest";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { AppModule } from "../src/app.module.js";
import { configureApp } from "../src/configure-app.js";
import { DatabaseService } from "../src/database/database.service.js";

describe("inventory ledger", () => {
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

  it("creates an idempotent unit-bound stock ledger and forecast", async () => {
    const context = await createInventoryContext(app!);
    const initial = await request(app!.getHttpServer())
      .get(`/api/v1/patient-profiles/${context.profileId}/inventory`)
      .set("Authorization", context.authorization)
      .expect(200);
    expect(initial.body.data).toEqual([
      expect.objectContaining({
        estimatedQuantity: 0,
        isLowStock: true,
        medicationName: "Napa",
        quantityUnit: "TABLET",
      }),
    ]);
    const positionId = initial.body.data[0].id as string;
    const adjustment = {
      delta: 2,
      idempotencyKey: "01K2INVENTORYOPENING00000001",
      quantityUnit: "TABLET",
      reason: "OPENING",
    };

    const opened = await request(app!.getHttpServer())
      .post(`/api/v1/inventory/${positionId}/adjustments`)
      .set("Authorization", context.authorization)
      .send(adjustment)
      .expect(201);
    expect(opened.body.data).toMatchObject({
      estimatedDaysRemaining: 2,
      estimatedQuantity: 2,
      projectedRunOutAt: "2026-08-19T02:00:00.000Z",
    });

    const retried = await request(app!.getHttpServer())
      .post(`/api/v1/inventory/${positionId}/adjustments`)
      .set("Authorization", context.authorization)
      .send(adjustment)
      .expect(201);
    expect(retried.body.meta.alreadyApplied).toBe(true);
    expect(retried.body.data.estimatedQuantity).toBe(2);
    expect(retried.body.data.adjustments).toHaveLength(1);
  });

  it("consumes inventory exactly once when a confirmation is retried", async () => {
    const context = await createInventoryContext(app!);
    const inventory = await request(app!.getHttpServer())
      .get(`/api/v1/patient-profiles/${context.profileId}/inventory`)
      .set("Authorization", context.authorization)
      .expect(200);
    const positionId = inventory.body.data[0].id as string;
    await request(app!.getHttpServer())
      .post(`/api/v1/inventory/${positionId}/adjustments`)
      .set("Authorization", context.authorization)
      .send({
        delta: 3,
        idempotencyKey: "01K2INVENTORYRESTOCK00000001",
        quantityUnit: "TABLET",
        reason: "RESTOCK",
      })
      .expect(201);
    const command = {
      clientAt: "2026-08-17T08:05:00+06:00",
      clientMutationId: "01K2INVENTORYCONFIRM0000001",
      command: "CONFIRM",
      expectedVersion: 1,
    };
    await request(app!.getHttpServer())
      .post(`/api/v1/dose-occurrences/${context.occurrenceId}/commands`)
      .set("Authorization", context.authorization)
      .send(command)
      .expect(201);
    await request(app!.getHttpServer())
      .post(`/api/v1/dose-occurrences/${context.occurrenceId}/commands`)
      .set("Authorization", context.authorization)
      .send(command)
      .expect(201);

    const afterConfirmation = await request(app!.getHttpServer())
      .get(`/api/v1/patient-profiles/${context.profileId}/inventory`)
      .set("Authorization", context.authorization)
      .expect(200);
    expect(afterConfirmation.body.data[0]).toMatchObject({
      estimatedQuantity: 2,
      projectedRunOutAt: "2026-08-19T02:00:00.000Z",
    });
    expect(afterConfirmation.body.data[0].adjustments).toEqual([
      expect.objectContaining({
        delta: -1,
        occurrenceId: context.occurrenceId,
        reason: "CONFIRMED_CONSUMPTION",
      }),
      expect.objectContaining({ delta: 3, reason: "RESTOCK" }),
    ]);
    expect(
      await app!.get(DatabaseService).stockAdjustment.count({
        where: { occurrenceId: context.occurrenceId },
      }),
    ).toBe(1);
  });

  it("rejects incompatible units and stale threshold updates", async () => {
    const context = await createInventoryContext(app!);
    const inventory = await request(app!.getHttpServer())
      .get(`/api/v1/patient-profiles/${context.profileId}/inventory`)
      .set("Authorization", context.authorization)
      .expect(200);
    const positionId = inventory.body.data[0].id as string;
    const mismatch = await request(app!.getHttpServer())
      .post(`/api/v1/inventory/${positionId}/adjustments`)
      .set("Authorization", context.authorization)
      .send({
        delta: 100,
        idempotencyKey: "01K2INVENTORYWRONGUNIT000001",
        quantityUnit: "ML",
        reason: "RESTOCK",
      })
      .expect(409);
    expect(mismatch.body.error.code).toBe("INVENTORY_UNIT_MISMATCH");

    const updated = await request(app!.getHttpServer())
      .patch(`/api/v1/inventory/${positionId}`)
      .set("Authorization", context.authorization)
      .send({ expectedVersion: 1, lowStockThreshold: 2 })
      .expect(200);
    expect(updated.body.data).toMatchObject({
      lowStockThreshold: 2,
      version: 2,
    });
    const stale = await request(app!.getHttpServer())
      .patch(`/api/v1/inventory/${positionId}`)
      .set("Authorization", context.authorization)
      .send({ expectedVersion: 1, lowStockThreshold: 1 })
      .expect(409);
    expect(stale.body.error.code).toBe("INVENTORY_VERSION_CONFLICT");
  });
});

async function createInventoryContext(app: INestApplication) {
  const challenge = await request(app.getHttpServer())
    .post("/api/v1/auth/otp/requests")
    .send({
      deviceInstallationId: "01K2INVENTORYDEVICE00000001",
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
        deviceName: "Inventory test phone",
        installationId: "01K2INVENTORYDEVICE00000001",
        platform: "ANDROID",
      },
      otp: "123456",
    })
    .expect(201);
  const authorization = `Bearer ${verified.body.data.accessToken}`;
  const profile = await request(app.getHttpServer())
    .post("/api/v1/patient-profiles")
    .set("Authorization", authorization)
    .send({ displayName: "Inventory owner", timezone: "Asia/Dhaka" })
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
      endDate: "2026-08-19",
      startDate: "2026-08-17",
      times: ["08:00"],
      timezone: "Asia/Dhaka",
    })
    .expect(201);
  const occurrences = await request(app.getHttpServer())
    .get(`/api/v1/patient-profiles/${profile.body.data.id}/dose-occurrences`)
    .set("Authorization", authorization)
    .query({ from: "2026-08-17", to: "2026-08-19" })
    .expect(200);
  return {
    authorization,
    occurrenceId: occurrences.body.data[0].id as string,
    profileId: profile.body.data.id as string,
  };
}
