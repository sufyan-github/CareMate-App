ALTER TABLE "PatientProfile" ADD COLUMN "missedDoseGraceMinutes" INTEGER NOT NULL DEFAULT 45;

CREATE TABLE "CaregiverAlert" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "patientProfileId" TEXT NOT NULL,
    "doseOccurrenceId" TEXT NOT NULL,
    "invitationId" TEXT NOT NULL,
    "caregiverUserId" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'ACTIVE',
    "availableAt" DATETIME NOT NULL,
    "generatedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deliveredAt" DATETIME,
    "acknowledgedAt" DATETIME,
    "resolvedAt" DATETIME,
    "resolvedMinutesLate" INTEGER,
    CONSTRAINT "CaregiverAlert_patientProfileId_fkey" FOREIGN KEY ("patientProfileId") REFERENCES "PatientProfile" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "CaregiverAlert_doseOccurrenceId_fkey" FOREIGN KEY ("doseOccurrenceId") REFERENCES "DoseOccurrence" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "CaregiverAlert_invitationId_fkey" FOREIGN KEY ("invitationId") REFERENCES "CareInvitation" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "CaregiverAlert_caregiverUserId_fkey" FOREIGN KEY ("caregiverUserId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE "CaregiverAlertEvent" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "alertId" TEXT NOT NULL,
    "eventType" TEXT NOT NULL,
    "actorUserId" TEXT,
    "metadataJson" TEXT NOT NULL DEFAULT '{}',
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "CaregiverAlertEvent_alertId_fkey" FOREIGN KEY ("alertId") REFERENCES "CaregiverAlert" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "CaregiverAlertEvent_actorUserId_fkey" FOREIGN KEY ("actorUserId") REFERENCES "User" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE UNIQUE INDEX "CaregiverAlert_doseOccurrenceId_invitationId_key" ON "CaregiverAlert"("doseOccurrenceId", "invitationId");
CREATE INDEX "CaregiverAlert_caregiverUserId_availableAt_status_idx" ON "CaregiverAlert"("caregiverUserId", "availableAt", "status");
CREATE INDEX "CaregiverAlert_patientProfileId_generatedAt_idx" ON "CaregiverAlert"("patientProfileId", "generatedAt");
CREATE INDEX "CaregiverAlertEvent_alertId_createdAt_idx" ON "CaregiverAlertEvent"("alertId", "createdAt");
