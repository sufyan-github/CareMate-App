CREATE UNIQUE INDEX "MedicationSchedule_one_open_schedule_per_medication_key"
ON "MedicationSchedule"("medicationId")
WHERE "status" IN ('ACTIVE', 'PAUSED');
