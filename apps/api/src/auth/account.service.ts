import { HttpStatus, Injectable } from "@nestjs/common";
import { ulid } from "ulid";

import { DatabaseService } from "../database/database.service.js";
import type {
  RequestAccountDeletionDto,
  UpdateAccountPreferencesDto,
} from "./account.dto.js";
import { AuthError } from "./auth-error.js";

@Injectable()
export class AccountService {
  constructor(private readonly database: DatabaseService) {}

  async getPreferences(userId: string) {
    const user = await this.user(userId);
    return this.response({
      allowAnalytics: user.allowAnalytics,
      locale: user.locale,
      showMedicineOnLockScreen: user.showMedicineOnLockScreen,
      simpleMode: user.simpleMode,
      voicePromptsEnabled: user.voicePromptsEnabled,
    });
  }

  async updatePreferences(userId: string, input: UpdateAccountPreferencesDto) {
    if (Object.keys(input).length === 0) {
      throw new AuthError(
        HttpStatus.BAD_REQUEST,
        "PREFERENCE_REQUIRED",
        "Choose a preference to update.",
      );
    }
    await this.database.user.update({ data: input, where: { id: userId } });
    return this.getPreferences(userId);
  }

  async requestDeletion(userId: string, _input: RequestAccountDeletionDto) {
    const user = await this.user(userId);
    if (user.deletionRequestedAt) {
      return this.response({
        requestedAt: user.deletionRequestedAt.toISOString(),
        status: "DELETION_PENDING",
      });
    }
    const now = new Date();
    const activeInvitations = await this.database.careInvitation.findMany({
      where: {
        OR: [{ inviterUserId: userId }, { acceptedByUserId: userId }],
        status: { in: ["PENDING", "ACCEPTED"] },
      },
    });
    await this.database.$transaction(async (transaction) => {
      for (const invitation of activeInvitations) {
        await transaction.careInvitation.update({
          data: { revokedAt: now, status: "REVOKED" },
          where: { id: invitation.id },
        });
        await transaction.careAccessAudit.create({
          data: {
            action: "ACCOUNT_DELETION_REVOKED_ACCESS",
            actorUserId: userId,
            id: ulid(),
            invitationId: invitation.id,
          },
        });
      }
      const sessions = await transaction.authSession.findMany({
        select: { id: true },
        where: { userId },
      });
      const sessionIds = sessions.map((session) => session.id);
      await transaction.refreshCredential.updateMany({
        data: { revokedAt: now },
        where: { revokedAt: null, sessionId: { in: sessionIds } },
      });
      await transaction.authSession.updateMany({
        data: { revokedAt: now },
        where: { revokedAt: null, userId },
      });
      await transaction.user.update({
        data: {
          deletedAt: now,
          deletionRequestedAt: now,
          status: "DELETION_PENDING",
          tokenVersion: { increment: 1 },
        },
        where: { id: userId },
      });
    });
    return this.response({
      requestedAt: now.toISOString(),
      status: "DELETION_PENDING",
    });
  }

  private async user(userId: string) {
    const user = await this.database.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new AuthError(
        HttpStatus.NOT_FOUND,
        "RESOURCE_NOT_FOUND",
        "The account was not found.",
      );
    }
    return user;
  }

  private response(data: unknown) {
    return { data, meta: { requestId: `req_${ulid()}` } };
  }
}
