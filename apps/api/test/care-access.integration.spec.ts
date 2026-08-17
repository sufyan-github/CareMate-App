import type { INestApplication } from "@nestjs/common";
import { Test } from "@nestjs/testing";
import request from "supertest";
import { afterEach, beforeEach, describe, expect, it } from "vitest";

import { AppModule } from "../src/app.module.js";
import { configureApp } from "../src/configure-app.js";

describe("care access", () => {
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
          deviceName: "Care access test phone",
          installationId,
          platform: "ANDROID",
        },
        otp: "123456",
      })
      .expect(201);
    return `Bearer ${verified.body.data.accessToken}`;
  }

  it("creates, accepts, audits, and revokes consent-based access", async () => {
    const ownerAuthorization = await signIn(
      "01700123456",
      "01K2CAREOWNER000000000001",
    );
    const profile = await request(app!.getHttpServer())
      .post("/api/v1/patient-profiles")
      .set("Authorization", ownerAuthorization)
      .send({ displayName: "Parent", timezone: "Asia/Dhaka" })
      .expect(201);

    const created = await request(app!.getHttpServer())
      .post(`/api/v1/patient-profiles/${profile.body.data.id}/care-invitations`)
      .set("Authorization", ownerAuthorization)
      .send({
        phoneNumber: "01800123456",
        permissions: {
          canReceiveMissedDoseAlerts: true,
          canViewMedicationPlan: true,
        },
      })
      .expect(201);
    expect(created.body.data).toMatchObject({
      deliveryStatus: "IN_APP_PENDING",
      inviteePhoneMasked: "••••••3456",
      patientDisplayName: "Parent",
      status: "PENDING",
    });

    const caregiverAuthorization = await signIn(
      "01800123456",
      "01K2CAREGIVER00000000001",
    );
    const incoming = await request(app!.getHttpServer())
      .get("/api/v1/care-invitations/incoming")
      .set("Authorization", caregiverAuthorization)
      .expect(200);
    expect(incoming.body.data).toHaveLength(1);

    await request(app!.getHttpServer())
      .patch(`/api/v1/care-invitations/${created.body.data.id}/accept`)
      .set("Authorization", caregiverAuthorization)
      .expect(200)
      .expect(({ body }) => expect(body.data.status).toBe("ACCEPTED"));

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
        endDate: "2099-01-01",
        startDate: "2099-01-01",
        times: ["08:00"],
        timezone: "Asia/Dhaka",
      })
      .expect(201);
    const sharedProfiles = await request(app!.getHttpServer())
      .get("/api/v1/patient-profiles")
      .set("Authorization", caregiverAuthorization)
      .expect(200);
    expect(sharedProfiles.body.data[0]).toMatchObject({
      accessRole: "CAREGIVER",
      canManage: false,
      displayName: "Parent",
    });
    const sharedMedicines = await request(app!.getHttpServer())
      .get(`/api/v1/patient-profiles/${profile.body.data.id}/medications`)
      .set("Authorization", caregiverAuthorization)
      .expect(200);
    expect(sharedMedicines.body.data[0].displayName).toBe("Napa");
    const sharedOccurrences = await request(app!.getHttpServer())
      .get(`/api/v1/patient-profiles/${profile.body.data.id}/dose-occurrences`)
      .set("Authorization", caregiverAuthorization)
      .query({ from: "2099-01-01", to: "2099-01-01" })
      .expect(200);
    expect(sharedOccurrences.body.data).toHaveLength(1);
    expect(sharedOccurrences.body.data[0]).not.toHaveProperty("status");
    const outcomeInvitation = await request(app!.getHttpServer())
      .post(`/api/v1/patient-profiles/${profile.body.data.id}/care-invitations`)
      .set("Authorization", ownerAuthorization)
      .send({
        phoneNumber: "01900123456",
        permissions: {
          canReceiveMissedDoseAlerts: false,
          canViewDoseOutcomes: true,
          canViewMedicationPlan: true,
        },
      })
      .expect(201);
    const outcomeCaregiver = await signIn(
      "01900123456",
      "01K2OUTCOMECARE0000000001",
    );
    await request(app!.getHttpServer())
      .patch(
        `/api/v1/care-invitations/${outcomeInvitation.body.data.id}/accept`,
      )
      .set("Authorization", outcomeCaregiver)
      .expect(200);
    const sharedOutcomes = await request(app!.getHttpServer())
      .get(`/api/v1/patient-profiles/${profile.body.data.id}/dose-occurrences`)
      .set("Authorization", outcomeCaregiver)
      .query({ from: "2099-01-01", to: "2099-01-01" })
      .expect(200);
    expect(sharedOutcomes.body.data[0].status).toBe("SCHEDULED");
    const occurrenceId = sharedOutcomes.body.data[0].id as string;
    await request(app!.getHttpServer())
      .get(`/api/v1/dose-occurrences/${occurrenceId}`)
      .set("Authorization", caregiverAuthorization)
      .expect(404);
    const sharedOutcomeDetail = await request(app!.getHttpServer())
      .get(`/api/v1/dose-occurrences/${occurrenceId}`)
      .set("Authorization", outcomeCaregiver)
      .expect(200);
    expect(sharedOutcomeDetail.body.data).toMatchObject({
      events: [],
      id: occurrenceId,
      status: "SCHEDULED",
    });
    await request(app!.getHttpServer())
      .post(`/api/v1/dose-occurrences/${occurrenceId}/commands`)
      .set("Authorization", outcomeCaregiver)
      .send({
        clientAt: "2099-01-01T08:00:00+06:00",
        clientMutationId: "01K2CAREGIVERDOSECOMMAND001",
        command: "CONFIRM",
        expectedVersion: 1,
      })
      .expect(404);
    await request(app!.getHttpServer())
      .post(`/api/v1/patient-profiles/${profile.body.data.id}/medications`)
      .set("Authorization", caregiverAuthorization)
      .send({
        displayName: "Unauthorized change",
        form: "TABLET",
        instructions: {
          mealRelation: "UNSPECIFIED",
          quantityUnit: "TABLET",
          quantityValue: 1,
          route: "ORAL",
        },
      })
      .expect(404);

    const audit = await request(app!.getHttpServer())
      .get(`/api/v1/care-invitations/${created.body.data.id}/audit`)
      .set("Authorization", ownerAuthorization)
      .expect(200);
    expect(
      audit.body.data.map((event: { action: string }) => event.action),
    ).toEqual(["INVITATION_ACCEPTED", "INVITATION_CREATED"]);

    await request(app!.getHttpServer())
      .patch(`/api/v1/care-invitations/${created.body.data.id}/revoke`)
      .set("Authorization", ownerAuthorization)
      .expect(200)
      .expect(({ body }) => expect(body.data.status).toBe("REVOKED"));
    await request(app!.getHttpServer())
      .get(`/api/v1/patient-profiles/${profile.body.data.id}/medications`)
      .set("Authorization", caregiverAuthorization)
      .expect(404);
  });

  it("blocks self-invitation and invitations without permissions", async () => {
    const authorization = await signIn(
      "01700123456",
      "01K2CAREOWNER000000000002",
    );
    const profile = await request(app!.getHttpServer())
      .post("/api/v1/patient-profiles")
      .set("Authorization", authorization)
      .send({ displayName: "Patient", timezone: "Asia/Dhaka" })
      .expect(201);

    const selfInvite = await request(app!.getHttpServer())
      .post(`/api/v1/patient-profiles/${profile.body.data.id}/care-invitations`)
      .set("Authorization", authorization)
      .send({
        phoneNumber: "01700123456",
        permissions: {
          canReceiveMissedDoseAlerts: false,
          canViewMedicationPlan: true,
        },
      })
      .expect(400);
    expect(selfInvite.body.error.code).toBe("CARE_SELF_INVITE_NOT_ALLOWED");

    const noPermissions = await request(app!.getHttpServer())
      .post(`/api/v1/patient-profiles/${profile.body.data.id}/care-invitations`)
      .set("Authorization", authorization)
      .send({
        phoneNumber: "01800123456",
        permissions: {
          canReceiveMissedDoseAlerts: false,
          canViewMedicationPlan: false,
        },
      })
      .expect(400);
    expect(noPermissions.body.error.code).toBe("CARE_PERMISSION_REQUIRED");
  });
});
