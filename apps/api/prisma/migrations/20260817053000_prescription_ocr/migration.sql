CREATE TABLE "OcrDraft" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "patientProfileId" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'REVIEW_REQUIRED',
    "documentType" TEXT NOT NULL,
    "language" TEXT NOT NULL,
    "rawText" TEXT NOT NULL,
    "medicinesJson" TEXT NOT NULL,
    "warningsJson" TEXT NOT NULL,
    "provider" TEXT NOT NULL,
    "providerModel" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "OcrDraft_patientProfileId_fkey" FOREIGN KEY ("patientProfileId") REFERENCES "PatientProfile" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX "OcrDraft_patientProfileId_createdAt_idx" ON "OcrDraft"("patientProfileId", "createdAt");
