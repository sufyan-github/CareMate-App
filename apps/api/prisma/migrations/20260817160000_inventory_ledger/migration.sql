CREATE TABLE "InventoryPosition" (
  "id" TEXT NOT NULL PRIMARY KEY,
  "patientProfileId" TEXT NOT NULL,
  "medicationId" TEXT NOT NULL,
  "quantityUnit" TEXT NOT NULL,
  "lowStockThreshold" REAL NOT NULL DEFAULT 5,
  "version" INTEGER NOT NULL DEFAULT 1,
  "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "InventoryPosition_patientProfileId_fkey"
    FOREIGN KEY ("patientProfileId") REFERENCES "PatientProfile" ("id")
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "InventoryPosition_medicationId_fkey"
    FOREIGN KEY ("medicationId") REFERENCES "Medication" ("id")
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE UNIQUE INDEX "InventoryPosition_medicationId_key"
  ON "InventoryPosition"("medicationId");
CREATE INDEX "InventoryPosition_patientProfileId_idx"
  ON "InventoryPosition"("patientProfileId");

INSERT INTO "InventoryPosition" (
  "id", "patientProfileId", "medicationId", "quantityUnit"
)
SELECT
  lower(hex(randomblob(16))),
  medication."patientProfileId",
  medication."id",
  instruction."quantityUnit"
FROM "Medication" medication
JOIN "DoseInstruction" instruction
  ON instruction."medicationId" = medication."id";

CREATE TABLE "StockAdjustment" (
  "id" TEXT NOT NULL PRIMARY KEY,
  "inventoryPositionId" TEXT NOT NULL,
  "delta" REAL NOT NULL,
  "reason" TEXT NOT NULL,
  "occurrenceId" TEXT,
  "actorUserId" TEXT,
  "idempotencyKey" TEXT NOT NULL,
  "note" TEXT,
  "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "StockAdjustment_inventoryPositionId_fkey"
    FOREIGN KEY ("inventoryPositionId") REFERENCES "InventoryPosition" ("id")
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT "StockAdjustment_occurrenceId_fkey"
    FOREIGN KEY ("occurrenceId") REFERENCES "DoseOccurrence" ("id")
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT "StockAdjustment_actorUserId_fkey"
    FOREIGN KEY ("actorUserId") REFERENCES "User" ("id")
    ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE UNIQUE INDEX "StockAdjustment_occurrenceId_key"
  ON "StockAdjustment"("occurrenceId");
CREATE UNIQUE INDEX "StockAdjustment_idempotencyKey_key"
  ON "StockAdjustment"("idempotencyKey");
CREATE INDEX "StockAdjustment_inventoryPositionId_createdAt_idx"
  ON "StockAdjustment"("inventoryPositionId", "createdAt");
