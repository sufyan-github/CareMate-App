import { HttpStatus, Injectable } from "@nestjs/common";
import { ulid } from "ulid";

import { AuthCryptoService } from "../auth/auth-crypto.service.js";
import { AuthError } from "../auth/auth-error.js";
import { DatabaseService } from "../database/database.service.js";

const quietHoursStartMinute = 22 * 60;
const quietHoursEndMinute = 7 * 60;

@Injectable()
export class CaregiverAlertsService {
  constructor(
    private readonly crypto: AuthCryptoService,
    private readonly database: DatabaseService,
  ) {}

  async fanOutForOccurrence(occurrenceId: string): Promise<void> {
    const occurrence = await this.database.doseOccurrence.findUnique({
      include: { medication: true, patientProfile: true },
      where: { id: occurrenceId },
    });
    if (
      !occurrence ||
      !occurrence.missedAt ||
      !["MISSED", "CONFIRMED"].includes(occurrence.status)
    ) {
      return;
    }
    const invitations = await this.database.careInvitation.findMany({
      where: {
        acceptedByUserId: { not: null },
        patientProfileId: occurrence.patientProfileId,
        status: "ACCEPTED",
      },
    });
    const availableAt = this.deliveryTime(
      occurrence.missedAt,
      occurrence.patientProfile.timezone,
    );
    for (const invitation of invitations) {
      if (
        !invitation.acceptedByUserId ||
        !this.permissions(invitation.permissionsJson).canReceiveMissedDoseAlerts
      ) {
        continue;
      }
      const existing = await this.database.caregiverAlert.findUnique({
        where: {
          doseOccurrenceId_invitationId: {
            doseOccurrenceId: occurrence.id,
            invitationId: invitation.id,
          },
        },
      });
      if (existing) continue;
      await this.database.$transaction(async (transaction) => {
        const alert = await transaction.caregiverAlert.create({
          data: {
            availableAt,
            caregiverUserId: invitation.acceptedByUserId!,
            doseOccurrenceId: occurrence.id,
            id: ulid(),
            invitationId: invitation.id,
            patientProfileId: occurrence.patientProfileId,
            status: availableAt > new Date() ? "QUEUED" : "ACTIVE",
          },
        });
        await transaction.caregiverAlertEvent.create({
          data: {
            alertId: alert.id,
            eventType: "GENERATED",
            id: ulid(),
            metadataJson: JSON.stringify({
              availableAt: availableAt.toISOString(),
              reason: "NO_OUTCOME_RECORDED_BY_DEADLINE",
            }),
          },
        });
      });
    }
  }

  async resolveForOccurrence(
    occurrenceId: string,
    confirmedAt: Date,
  ): Promise<void> {
    const occurrence = await this.database.doseOccurrence.findUnique({
      select: { plannedAt: true },
      where: { id: occurrenceId },
    });
    if (!occurrence) return;
    const minutesLate = Math.max(
      0,
      Math.round(
        (confirmedAt.getTime() - occurrence.plannedAt.getTime()) / 60_000,
      ),
    );
    const alerts = await this.database.caregiverAlert.findMany({
      where: {
        doseOccurrenceId: occurrenceId,
        status: { in: ["ACTIVE", "ACKNOWLEDGED", "QUEUED"] },
      },
    });
    for (const alert of alerts) {
      await this.database.$transaction(async (transaction) => {
        const updated = await transaction.caregiverAlert.updateMany({
          data: {
            resolvedAt: confirmedAt,
            resolvedMinutesLate: minutesLate,
            status: "RESOLVED",
          },
          where: { id: alert.id, status: alert.status },
        });
        if (updated.count !== 1) return;
        await transaction.caregiverAlertEvent.create({
          data: {
            alertId: alert.id,
            eventType: "RESOLVED",
            id: ulid(),
            metadataJson: JSON.stringify({ minutesLate }),
          },
        });
      });
    }
  }

  async list(userId: string, patientProfileId: string) {
    const invitation = await this.authorizedInvitation(
      userId,
      patientProfileId,
    );
    await this.markAvailableAsDelivered(
      userId,
      patientProfileId,
      invitation.id,
    );
    const alerts = await this.database.caregiverAlert.findMany({
      include: {
        doseOccurrence: { include: { medication: true } },
        patientProfile: { include: { owner: true } },
      },
      orderBy: { generatedAt: "desc" },
      where: {
        availableAt: { lte: new Date() },
        caregiverUserId: userId,
        invitationId: invitation.id,
        patientProfileId,
      },
    });
    const canViewPlan = this.permissions(
      invitation.permissionsJson,
    ).canViewMedicationPlan;
    return this.response(
      alerts.map((alert) => ({
        acknowledgedAt: alert.acknowledgedAt?.toISOString() ?? null,
        callPhoneE164: this.crypto.decryptPhone(
          alert.patientProfile.owner.phoneE164Encrypted,
        ),
        deliveredAt: alert.deliveredAt?.toISOString() ?? null,
        generatedAt: alert.generatedAt.toISOString(),
        id: alert.id,
        medicationName: canViewPlan
          ? alert.doseOccurrence.medication.displayName
          : null,
        patientDisplayName: alert.patientProfile.displayName,
        plannedAt: alert.doseOccurrence.plannedAt.toISOString(),
        resolvedAt: alert.resolvedAt?.toISOString() ?? null,
        resolvedMinutesLate: alert.resolvedMinutesLate,
        status: alert.status === "QUEUED" ? "ACTIVE" : alert.status,
      })),
    );
  }

  async acknowledge(userId: string, alertId: string) {
    const alert = await this.database.caregiverAlert.findFirst({
      include: { invitation: true },
      where: { caregiverUserId: userId, id: alertId },
    });
    if (
      !alert ||
      alert.invitation.status !== "ACCEPTED" ||
      !this.permissions(alert.invitation.permissionsJson)
        .canReceiveMissedDoseAlerts
    ) {
      this.notFound();
    }
    if (alert.status === "RESOLVED" || alert.status === "ACKNOWLEDGED") {
      return this.response({
        acknowledgedAt: alert.acknowledgedAt?.toISOString() ?? null,
        id: alert.id,
        status: alert.status,
      });
    }
    if (alert.availableAt > new Date()) this.notFound();
    const acknowledgedAt = new Date();
    await this.database.$transaction(async (transaction) => {
      const updated = await transaction.caregiverAlert.updateMany({
        data: { acknowledgedAt, status: "ACKNOWLEDGED" },
        where: { id: alertId, status: { in: ["ACTIVE", "QUEUED"] } },
      });
      if (updated.count !== 1) return;
      await transaction.caregiverAlertEvent.create({
        data: {
          actorUserId: userId,
          alertId,
          eventType: "ACKNOWLEDGED",
          id: ulid(),
        },
      });
    });
    return this.response({
      acknowledgedAt: acknowledgedAt.toISOString(),
      id: alertId,
      status: "ACKNOWLEDGED",
    });
  }

  async audit(userId: string, alertId: string) {
    const alert = await this.database.caregiverAlert.findFirst({
      include: { patientProfile: true },
      where: { id: alertId },
    });
    if (!alert) this.notFound();
    const isOwner = alert.patientProfile.ownerUserId === userId;
    if (!isOwner) {
      const invitation = await this.database.careInvitation.findFirst({
        where: {
          acceptedByUserId: userId,
          id: alert.invitationId,
          status: "ACCEPTED",
        },
      });
      if (!invitation) this.notFound();
    }
    const events = await this.database.caregiverAlertEvent.findMany({
      orderBy: { createdAt: "asc" },
      where: { alertId },
    });
    return this.response(
      events.map((event) => ({
        createdAt: event.createdAt.toISOString(),
        eventType: event.eventType,
        id: event.id,
        metadata: JSON.parse(event.metadataJson) as unknown,
      })),
    );
  }

  private async markAvailableAsDelivered(
    userId: string,
    patientProfileId: string,
    invitationId: string,
  ) {
    const now = new Date();
    const alerts = await this.database.caregiverAlert.findMany({
      where: {
        availableAt: { lte: now },
        caregiverUserId: userId,
        deliveredAt: null,
        invitationId,
        patientProfileId,
        status: { in: ["ACTIVE", "QUEUED"] },
      },
    });
    for (const alert of alerts) {
      await this.database.$transaction(async (transaction) => {
        const delivered = await transaction.caregiverAlert.updateMany({
          data: {
            deliveredAt: now,
            status: alert.status === "QUEUED" ? "ACTIVE" : alert.status,
          },
          where: { deliveredAt: null, id: alert.id },
        });
        if (delivered.count !== 1) return;
        await transaction.caregiverAlertEvent.create({
          data: {
            alertId: alert.id,
            eventType: "DELIVERED_IN_APP",
            id: ulid(),
          },
        });
      });
    }
  }

  private async authorizedInvitation(userId: string, patientProfileId: string) {
    const invitation = await this.database.careInvitation.findFirst({
      where: {
        acceptedByUserId: userId,
        patientProfileId,
        status: "ACCEPTED",
      },
    });
    if (
      !invitation ||
      !this.permissions(invitation.permissionsJson).canReceiveMissedDoseAlerts
    ) {
      this.notFound();
    }
    return invitation;
  }

  private permissions(value: string): {
    canReceiveMissedDoseAlerts: boolean;
    canViewMedicationPlan: boolean;
  } {
    try {
      const parsed = JSON.parse(value) as Record<string, unknown>;
      return {
        canReceiveMissedDoseAlerts: parsed.canReceiveMissedDoseAlerts === true,
        canViewMedicationPlan: parsed.canViewMedicationPlan === true,
      };
    } catch {
      return {
        canReceiveMissedDoseAlerts: false,
        canViewMedicationPlan: false,
      };
    }
  }

  private deliveryTime(value: Date, timezone: string): Date {
    const parts = new Intl.DateTimeFormat("en-US", {
      hour: "2-digit",
      hourCycle: "h23",
      minute: "2-digit",
      timeZone: timezone,
    }).formatToParts(value);
    const hour = Number(parts.find((part) => part.type === "hour")?.value);
    const minute = Number(parts.find((part) => part.type === "minute")?.value);
    const localMinute = hour * 60 + minute;
    if (localMinute >= quietHoursStartMinute) {
      return new Date(
        value.getTime() +
          (24 * 60 - localMinute + quietHoursEndMinute) * 60_000,
      );
    }
    if (localMinute < quietHoursEndMinute) {
      return new Date(
        value.getTime() + (quietHoursEndMinute - localMinute) * 60_000,
      );
    }
    return value;
  }

  private notFound(): never {
    throw new AuthError(
      HttpStatus.NOT_FOUND,
      "RESOURCE_NOT_FOUND",
      "The requested caregiver alert was not found.",
    );
  }

  private response(data: unknown) {
    return { data, meta: { requestId: `req_${ulid()}` } };
  }
}
