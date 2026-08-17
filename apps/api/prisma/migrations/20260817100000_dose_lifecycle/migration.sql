ALTER TABLE "DoseOccurrence" ADD COLUMN "reminderSentAt" DATETIME;
ALTER TABLE "DoseOccurrence" ADD COLUMN "snoozedUntil" DATETIME;
ALTER TABLE "DoseOccurrence" ADD COLUMN "responseDueAt" DATETIME;
ALTER TABLE "DoseOccurrence" ADD COLUMN "snoozeCount" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "DoseOccurrence" ADD COLUMN "missedAt" DATETIME;
ALTER TABLE "DoseOccurrence" ADD COLUMN "confirmedAt" DATETIME;
ALTER TABLE "DoseOccurrence" ADD COLUMN "timingClassification" TEXT;

CREATE TABLE "DoseEvent" (
  "id" TEXT NOT NULL PRIMARY KEY,
  "occurrenceId" TEXT NOT NULL,
  "eventType" TEXT NOT NULL,
  "sequence" INTEGER NOT NULL,
  "actorUserId" TEXT,
  "clientMutationId" TEXT,
  "clientAt" DATETIME,
  "serverAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "metadataJson" TEXT NOT NULL DEFAULT '{}',
  "resultJson" TEXT,
  CONSTRAINT "DoseEvent_occurrenceId_fkey"
    FOREIGN KEY ("occurrenceId") REFERENCES "DoseOccurrence" ("id")
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE UNIQUE INDEX "DoseEvent_clientMutationId_key"
  ON "DoseEvent"("clientMutationId");
CREATE INDEX "DoseEvent_occurrenceId_serverAt_idx"
  ON "DoseEvent"("occurrenceId", "serverAt");
CREATE UNIQUE INDEX "DoseEvent_occurrenceId_sequence_key"
  ON "DoseEvent"("occurrenceId", "sequence");

CREATE TABLE "DoseConfirmation" (
  "id" TEXT NOT NULL PRIMARY KEY,
  "occurrenceId" TEXT NOT NULL,
  "actorUserId" TEXT NOT NULL,
  "authSessionId" TEXT NOT NULL,
  "deviceInstallationId" TEXT NOT NULL,
  "timingClassification" TEXT NOT NULL,
  "confirmedAt" DATETIME NOT NULL,
  "clientAt" DATETIME NOT NULL,
  CONSTRAINT "DoseConfirmation_occurrenceId_fkey"
    FOREIGN KEY ("occurrenceId") REFERENCES "DoseOccurrence" ("id")
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE UNIQUE INDEX "DoseConfirmation_occurrenceId_key"
  ON "DoseConfirmation"("occurrenceId");
