import { HttpStatus, Injectable } from "@nestjs/common";
import { ulid } from "ulid";

import { AuthCryptoService } from "../auth/auth-crypto.service.js";
import { AuthError } from "../auth/auth-error.js";
import {
  maskPhoneNumber,
  normalizeBangladeshPhoneNumber,
} from "../auth/phone-number.js";
import { DatabaseService } from "../database/database.service.js";
import type { CreateCareInvitationDto } from "./care-access.dto.js";

const invitationLifetimeMs = 7 * 24 * 60 * 60 * 1000;

@Injectable()
export class CareAccessService {
  constructor(
    private readonly crypto: AuthCryptoService,
    private readonly database: DatabaseService,
  ) {}

  async createInvitation(
    userId: string,
    patientProfileId: string,
    input: CreateCareInvitationDto,
  ) {
    const profile = await this.ownedProfile(userId, patientProfileId);
    if (
      !input.permissions.canViewMedicationPlan &&
      !input.permissions.canReceiveMissedDoseAlerts &&
      !input.permissions.canViewDoseOutcomes
    ) {
      throw new AuthError(
        HttpStatus.BAD_REQUEST,
        "CARE_PERMISSION_REQUIRED",
        "Choose at least one caregiver permission.",
      );
    }
    if (
      input.permissions.canViewDoseOutcomes &&
      !input.permissions.canViewMedicationPlan
    ) {
      throw new AuthError(
        HttpStatus.BAD_REQUEST,
        "CARE_PERMISSION_DEPENDENCY_INVALID",
        "Medication plan access is required before sharing dose outcomes.",
      );
    }
    const phone = normalizeBangladeshPhoneNumber(input.phoneNumber);
    const phoneHash = this.crypto.phoneLookupHash(phone);
    const owner = await this.database.user.findUnique({
      where: { id: userId },
    });
    if (owner?.phoneLookupHash === phoneHash) {
      throw new AuthError(
        HttpStatus.BAD_REQUEST,
        "CARE_SELF_INVITE_NOT_ALLOWED",
        "Invite a different mobile number as caregiver.",
      );
    }
    const now = new Date();
    const existing = await this.database.careInvitation.findFirst({
      where: {
        inviteePhoneHash: phoneHash,
        patientProfileId,
        OR: [
          { status: "ACCEPTED" },
          { expiresAt: { gt: now }, status: "PENDING" },
        ],
      },
    });
    if (existing) {
      throw new AuthError(
        HttpStatus.CONFLICT,
        "CARE_INVITATION_EXISTS",
        "This caregiver already has an active or pending invitation.",
      );
    }

    const invitation = await this.database.$transaction(async (transaction) => {
      const created = await transaction.careInvitation.create({
        data: {
          expiresAt: new Date(now.getTime() + invitationLifetimeMs),
          id: ulid(),
          inviteePhoneEncrypted: this.crypto.encryptPhone(phone),
          inviteePhoneHash: phoneHash,
          inviterUserId: userId,
          patientProfileId,
          permissionsJson: JSON.stringify(input.permissions),
        },
      });
      await transaction.careAccessAudit.create({
        data: {
          action: "INVITATION_CREATED",
          actorUserId: userId,
          id: ulid(),
          invitationId: created.id,
        },
      });
      return created;
    });
    return this.response(this.invitationView(invitation, profile.displayName));
  }

  async listForProfile(userId: string, patientProfileId: string) {
    const profile = await this.ownedProfile(userId, patientProfileId);
    await this.expirePendingInvitations();
    const invitations = await this.database.careInvitation.findMany({
      orderBy: { createdAt: "desc" },
      where: { patientProfileId },
    });
    return this.response(
      invitations.map((item) => this.invitationView(item, profile.displayName)),
    );
  }

  async listIncoming(userId: string) {
    const user = await this.database.user.findUnique({ where: { id: userId } });
    if (!user) this.notFound();
    await this.expirePendingInvitations();
    const invitations = await this.database.careInvitation.findMany({
      include: { patientProfile: true },
      orderBy: { createdAt: "desc" },
      where: { inviteePhoneHash: user.phoneLookupHash, status: "PENDING" },
    });
    return this.response(
      invitations.map((item) =>
        this.invitationView(item, item.patientProfile.displayName),
      ),
    );
  }

  async accept(userId: string, invitationId: string) {
    const invitation = await this.incomingInvitation(userId, invitationId);
    if (
      invitation.status === "ACCEPTED" &&
      invitation.acceptedByUserId === userId
    ) {
      return this.response(
        this.invitationView(invitation, invitation.patientProfile.displayName),
      );
    }
    if (invitation.status !== "PENDING" || invitation.expiresAt <= new Date()) {
      throw new AuthError(
        HttpStatus.GONE,
        "CARE_INVITATION_EXPIRED",
        "This caregiver invitation is no longer available.",
      );
    }
    const accepted = await this.database.$transaction(async (transaction) => {
      const result = await transaction.careInvitation.updateMany({
        data: {
          acceptedAt: new Date(),
          acceptedByUserId: userId,
          status: "ACCEPTED",
        },
        where: { id: invitationId, status: "PENDING" },
      });
      if (result.count !== 1) this.conflict();
      await transaction.careAccessAudit.create({
        data: {
          action: "INVITATION_ACCEPTED",
          actorUserId: userId,
          id: ulid(),
          invitationId,
        },
      });
      return transaction.careInvitation.findUniqueOrThrow({
        include: { patientProfile: true },
        where: { id: invitationId },
      });
    });
    return this.response(
      this.invitationView(accepted, accepted.patientProfile.displayName),
    );
  }

  async decline(userId: string, invitationId: string) {
    const invitation = await this.incomingInvitation(userId, invitationId);
    if (invitation.status !== "PENDING") this.conflict();
    const declined = await this.database.$transaction(async (transaction) => {
      const result = await transaction.careInvitation.updateMany({
        data: { declinedAt: new Date(), status: "DECLINED" },
        where: { id: invitationId, status: "PENDING" },
      });
      if (result.count !== 1) this.conflict();
      await transaction.careAccessAudit.create({
        data: {
          action: "INVITATION_DECLINED",
          actorUserId: userId,
          id: ulid(),
          invitationId,
        },
      });
      return transaction.careInvitation.findUniqueOrThrow({
        where: { id: invitationId },
      });
    });
    return this.response(
      this.invitationView(declined, invitation.patientProfile.displayName),
    );
  }

  async revoke(userId: string, invitationId: string) {
    const invitation = await this.database.careInvitation.findFirst({
      include: { patientProfile: true },
      where: { id: invitationId, patientProfile: { ownerUserId: userId } },
    });
    if (!invitation) this.notFound();
    if (!["PENDING", "ACCEPTED"].includes(invitation.status)) this.conflict();
    const revoked = await this.database.$transaction(async (transaction) => {
      const result = await transaction.careInvitation.updateMany({
        data: { revokedAt: new Date(), status: "REVOKED" },
        where: { id: invitationId, status: invitation.status },
      });
      if (result.count !== 1) this.conflict();
      await transaction.careAccessAudit.create({
        data: {
          action: "ACCESS_REVOKED",
          actorUserId: userId,
          id: ulid(),
          invitationId,
        },
      });
      return transaction.careInvitation.findUniqueOrThrow({
        where: { id: invitationId },
      });
    });
    return this.response(
      this.invitationView(revoked, invitation.patientProfile.displayName),
    );
  }

  async audit(userId: string, invitationId: string) {
    const invitation = await this.database.careInvitation.findFirst({
      where: { id: invitationId, patientProfile: { ownerUserId: userId } },
    });
    if (!invitation) this.notFound();
    const events = await this.database.careAccessAudit.findMany({
      orderBy: { createdAt: "desc" },
      where: { invitationId },
    });
    return this.response(
      events.map((event) => ({
        action: event.action,
        createdAt: event.createdAt.toISOString(),
        id: event.id,
      })),
    );
  }

  private async incomingInvitation(userId: string, invitationId: string) {
    const user = await this.database.user.findUnique({ where: { id: userId } });
    if (!user) this.notFound();
    const invitation = await this.database.careInvitation.findFirst({
      include: { patientProfile: true },
      where: { id: invitationId, inviteePhoneHash: user.phoneLookupHash },
    });
    return invitation ?? this.notFound();
  }

  private async ownedProfile(userId: string, profileId: string) {
    const profile = await this.database.patientProfile.findFirst({
      where: { id: profileId, ownerUserId: userId },
    });
    return profile ?? this.notFound();
  }

  private expirePendingInvitations() {
    return this.database.careInvitation.updateMany({
      data: { status: "EXPIRED" },
      where: { expiresAt: { lte: new Date() }, status: "PENDING" },
    });
  }

  private invitationView(
    invitation: {
      acceptedAt: Date | null;
      createdAt: Date;
      deliveryStatus: string;
      expiresAt: Date;
      id: string;
      inviteePhoneEncrypted: string;
      permissionsJson: string;
      status: string;
      updatedAt: Date;
    },
    patientDisplayName: string,
  ) {
    return {
      acceptedAt: invitation.acceptedAt?.toISOString() ?? null,
      createdAt: invitation.createdAt.toISOString(),
      deliveryStatus: invitation.deliveryStatus,
      expiresAt: invitation.expiresAt.toISOString(),
      id: invitation.id,
      inviteePhoneMasked: maskPhoneNumber(
        this.crypto.decryptPhone(invitation.inviteePhoneEncrypted),
      ),
      patientDisplayName,
      permissions: JSON.parse(invitation.permissionsJson) as unknown,
      status: invitation.status,
      updatedAt: invitation.updatedAt.toISOString(),
    };
  }

  private notFound(): never {
    throw new AuthError(
      HttpStatus.NOT_FOUND,
      "RESOURCE_NOT_FOUND",
      "The requested caregiver invitation was not found.",
    );
  }

  private conflict(): never {
    throw new AuthError(
      HttpStatus.CONFLICT,
      "CARE_INVITATION_CHANGED",
      "This caregiver invitation has already changed. Refresh and try again.",
    );
  }

  private response(data: unknown) {
    return { data, meta: { requestId: `req_${ulid()}` } };
  }
}
