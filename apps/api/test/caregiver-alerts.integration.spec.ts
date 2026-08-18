import type { INestApplication } from "@nestjs/common";
import { Test } from "@nestjs/testing";
import request from "supertest";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { AppModule } from "../src/app.module.js";
import { configureApp } from "../src/configure-app.js";
import { DatabaseService } from "../src/database/database.service.js";

describe("caregiver missed-dose alerts", () => {
  let app: INestApplication | undefined;
  let database: DatabaseService;

  beforeEach(async () => {
    vi.useFakeTimers({ shouldAdvanceTime: true });
    vi.setSystemTime(new Date("2026-08-18T12:00:00.000Z"));
    process.env.NODE_ENV = "test";
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
    database = app.get(DatabaseService);
  });

  afterEach(async () => {
    await app?.close();
    vi.useRealTimers();
  });

  async function signIn(phoneNumber: string, installationId: string) {
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
          deviceName: "Caregiver alert test phone",
          installationId,
          platform: "ANDROID",
        },
        otp: "123456",
      })
      .expect(201);
    return `Bearer ${verified.body.data.accessToken}`;
  }

  async function createContext(canViewMedicationPlan = true) {
    const ownerAuthorization = await signIn(
      "01700123456",
      "01K2ALERTOWNER00000000001",
    );
    const caregiverAuthorization = await signIn(
      "01800123456",
      "01K2ALERTCARE000000000001",
    );
    const profile = await request(app!.getHttpServer())
      .post("/api/v1/patient-profiles")
      .set("Authorization", ownerAuthorization)
      .send({ displayName: "Parent", timezone: "Asia/Dhaka" })
      .expect(201);
    const invitation = await request(app!.getHttpServer())
      .post(`/api/v1/patient-profiles/${profile.body.data.id}/care-invitations`)
      .set("Authorization", ownerAuthorization)
      .send({
        phoneNumber: "01800123456",
        permissions: {
          canReceiveMissedDoseAlerts: true,
          canViewMedicationPlan,
        },
      })
      .expect(201);
    await request(app!.getHttpServer())
      .patch(`/api/v1/care-invitations/${invitation.body.data.id}/accept`)
      .set("Authorization", caregiverAuthorization)
      .expect(200);
    const medication = await request(app!.getHttpServer())
      .post(`/api/v1/patient-profiles/${profile.body.data.id}/medications`)
      .set("Authorization", ownerAuthorization)
      .send({
        displayName: "Napa",
        form: "TABLET",
        instructions: {
          mealRelation: "AFTER",
          quantityUnit: "TABLET",
          quantityValue: 1,
          route: "ORAL",
        },
        strengthUnit: "mg",
        strengthValue: 500,
      })
      .expect(201);
    await request(app!.getHttpServer())
      .post(`/api/v1/medications/${medication.body.data.id}/schedules`)
      .set("Authorization", ownerAuthorization)
      .send({
        activation: "ACTIVATE",
        openEnded: true,
        startDate: "2026-08-18",
        times: ["19:00", "20:00"],
        timezone: "Asia/Dhaka",
      })
      .expect(201);
    return {
      caregiverAuthorization,
      invitationId: invitation.body.data.id as string,
      ownerAuthorization,
      profileId: profile.body.data.id as string,
    };
  }

  async function simulateMiss(context: {
    ownerAuthorization: string;
    profileId: string;
  }) {
    return request(app!.getHttpServer())
      .post(
        `/api/v1/patient-profiles/${context.profileId}/dose-occurrences/simulate-miss`,
      )
      .set("Authorization", context.ownerAuthorization)
      .send({ minutesLate: 46 })
      .expect(201);
  }

  it("fans out, delivers, acknowledges, and resolves a late-confirmed alert", async () => {
    const context = await createContext();
    const missed = await simulateMiss(context);

    const delivered = await request(app!.getHttpServer())
      .get("/api/v1/caregiver-alerts")
      .query({ profileId: context.profileId })
      .set("Authorization", context.caregiverAuthorization)
      .expect(200);
    expect(delivered.body.data).toEqual([
      expect.objectContaining({
        medicationName: "Napa",
        patientDisplayName: "Parent",
        status: "ACTIVE",
      }),
    ]);
    expect(delivered.body.data[0].deliveredAt).not.toBeNull();
    const alertId = delivered.body.data[0].id as string;

    await request(app!.getHttpServer())
      .patch(`/api/v1/caregiver-alerts/${alertId}/acknowledge`)
      .set("Authorization", context.caregiverAuthorization)
      .expect(200)
      .expect(({ body }) => expect(body.data.status).toBe("ACKNOWLEDGED"));

    await request(app!.getHttpServer())
      .post(`/api/v1/dose-occurrences/${missed.body.data.id}/commands`)
      .set("Authorization", context.ownerAuthorization)
      .send({
        clientAt: "2026-08-18T18:00:00+06:00",
        clientMutationId: "01K2ALERTLATECONFIRM000001",
        command: "CONFIRM",
        expectedVersion: missed.body.data.version,
      })
      .expect(201);

    const resolved = await request(app!.getHttpServer())
      .get("/api/v1/caregiver-alerts")
      .query({ profileId: context.profileId })
      .set("Authorization", context.caregiverAuthorization)
      .expect(200);
    expect(resolved.body.data[0]).toMatchObject({
      resolvedMinutesLate: 46,
      status: "RESOLVED",
    });

    const audit = await request(app!.getHttpServer())
      .get(`/api/v1/caregiver-alerts/${alertId}/audit`)
      .set("Authorization", context.caregiverAuthorization)
      .expect(200);
    expect(
      audit.body.data.map((event: { eventType: string }) => event.eventType),
    ).toEqual(["GENERATED", "DELIVERED_IN_APP", "ACKNOWLEDGED", "RESOLVED"]);
  });

  it("redacts medicine details and stops access and fan-out after revocation", async () => {
    const context = await createContext(false);
    const sharedProfiles = await request(app!.getHttpServer())
      .get("/api/v1/patient-profiles")
      .set("Authorization", context.caregiverAuthorization)
      .expect(200);
    expect(sharedProfiles.body.data[0]).toMatchObject({
      canManage: false,
      displayName: "Parent",
      permissions: {
        canReceiveMissedDoseAlerts: true,
        canViewMedicationPlan: false,
      },
    });
    await request(app!.getHttpServer())
      .get(`/api/v1/patient-profiles/${context.profileId}/medications`)
      .set("Authorization", context.caregiverAuthorization)
      .expect(404);

    await simulateMiss(context);
    const privateAlert = await request(app!.getHttpServer())
      .get("/api/v1/caregiver-alerts")
      .query({ profileId: context.profileId })
      .set("Authorization", context.caregiverAuthorization)
      .expect(200);
    expect(privateAlert.body.data[0]).toMatchObject({
      medicationName: null,
      status: "ACTIVE",
    });

    await request(app!.getHttpServer())
      .patch(`/api/v1/care-invitations/${context.invitationId}/revoke`)
      .set("Authorization", context.ownerAuthorization)
      .expect(200);
    await request(app!.getHttpServer())
      .get("/api/v1/caregiver-alerts")
      .query({ profileId: context.profileId })
      .set("Authorization", context.caregiverAuthorization)
      .expect(404);

    await simulateMiss(context);
    expect(await database.caregiverAlert.count()).toBe(1);
  });
});
