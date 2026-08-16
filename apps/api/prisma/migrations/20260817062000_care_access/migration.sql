CREATE TABLE "CareInvitation" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "patientProfileId" TEXT NOT NULL,
    "inviterUserId" TEXT NOT NULL,
    "inviteePhoneEncrypted" TEXT NOT NULL,
    "inviteePhoneHash" TEXT NOT NULL,
    "permissionsJson" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'PENDING',
    "deliveryStatus" TEXT NOT NULL DEFAULT 'IN_APP_PENDING',
    "acceptedByUserId" TEXT,
    "expiresAt" DATETIME NOT NULL,
    "acceptedAt" DATETIME,
    "declinedAt" DATETIME,
    "revokedAt" DATETIME,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "CareInvitation_patientProfileId_fkey" FOREIGN KEY ("patientProfileId") REFERENCES "PatientProfile" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "CareInvitation_inviterUserId_fkey" FOREIGN KEY ("inviterUserId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "CareInvitation_acceptedByUserId_fkey" FOREIGN KEY ("acceptedByUserId") REFERENCES "User" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE TABLE "CareAccessAudit" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "invitationId" TEXT NOT NULL,
    "actorUserId" TEXT NOT NULL,
    "action" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "CareAccessAudit_invitationId_fkey" FOREIGN KEY ("invitationId") REFERENCES "CareInvitation" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "CareAccessAudit_actorUserId_fkey" FOREIGN KEY ("actorUserId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE INDEX "CareInvitation_patientProfileId_status_idx" ON "CareInvitation"("patientProfileId", "status");
CREATE INDEX "CareInvitation_inviteePhoneHash_status_expiresAt_idx" ON "CareInvitation"("inviteePhoneHash", "status", "expiresAt");
CREATE INDEX "CareAccessAudit_invitationId_createdAt_idx" ON "CareAccessAudit"("invitationId", "createdAt");
CREATE INDEX "CareAccessAudit_actorUserId_createdAt_idx" ON "CareAccessAudit"("actorUserId", "createdAt");
