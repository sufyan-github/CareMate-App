CREATE TABLE "MedicationSchedule" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "medicationId" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'ACTIVE',
    "timezone" TEXT NOT NULL,
    "startDate" TEXT NOT NULL,
    "endDate" TEXT,
    "timesJson" TEXT NOT NULL,
    "recurrence" TEXT NOT NULL DEFAULT 'DAILY',
    "timezonePolicy" TEXT NOT NULL DEFAULT 'LOCAL_TIME_ANCHORED',
    "revision" INTEGER NOT NULL DEFAULT 1,
    "version" INTEGER NOT NULL DEFAULT 1,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "MedicationSchedule_medicationId_fkey" FOREIGN KEY ("medicationId") REFERENCES "Medication" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX "MedicationSchedule_medicationId_status_idx" ON "MedicationSchedule"("medicationId", "status");

CREATE TABLE "DoseOccurrence" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "scheduleId" TEXT NOT NULL,
    "medicationId" TEXT NOT NULL,
    "patientProfileId" TEXT NOT NULL,
    "ruleRevision" INTEGER NOT NULL,
    "plannedLocalDateTime" TEXT NOT NULL,
    "plannedAt" DATETIME NOT NULL,
    "timezone" TEXT NOT NULL,
    "quantityValue" REAL NOT NULL,
    "quantityUnit" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'SCHEDULED',
    "version" INTEGER NOT NULL DEFAULT 1,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "DoseOccurrence_scheduleId_fkey" FOREIGN KEY ("scheduleId") REFERENCES "MedicationSchedule" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "DoseOccurrence_medicationId_fkey" FOREIGN KEY ("medicationId") REFERENCES "Medication" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "DoseOccurrence_patientProfileId_fkey" FOREIGN KEY ("patientProfileId") REFERENCES "PatientProfile" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX "DoseOccurrence_scheduleId_plannedLocalDateTime_ruleRevision_key" ON "DoseOccurrence"("scheduleId", "plannedLocalDateTime", "ruleRevision");
CREATE INDEX "DoseOccurrence_patientProfileId_plannedAt_idx" ON "DoseOccurrence"("patientProfileId", "plannedAt");
CREATE INDEX "DoseOccurrence_scheduleId_status_idx" ON "DoseOccurrence"("scheduleId", "status");
