ALTER TABLE "MedicationSchedule" ADD COLUMN "daysOfWeekJson" TEXT NOT NULL DEFAULT '[]';
ALTER TABLE "MedicationSchedule" ADD COLUMN "excludedDatesJson" TEXT NOT NULL DEFAULT '[]';
ALTER TABLE "MedicationSchedule" ADD COLUMN "generationHorizonDays" INTEGER NOT NULL DEFAULT 30;
ALTER TABLE "MedicationSchedule" ADD COLUMN "generatedThroughDate" TEXT NOT NULL DEFAULT '';
UPDATE "MedicationSchedule"
SET "generatedThroughDate" = COALESCE("endDate", date("startDate", '+29 days'))
WHERE "generatedThroughDate" = '';
