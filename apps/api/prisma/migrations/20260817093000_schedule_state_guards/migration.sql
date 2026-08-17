CREATE TRIGGER "MedicationSchedule_status_insert_guard"
BEFORE INSERT ON "MedicationSchedule"
WHEN NEW."status" NOT IN ('ACTIVE', 'PAUSED', 'ENDED')
BEGIN
  SELECT RAISE(ABORT, 'invalid medication schedule status');
END;

CREATE TRIGGER "MedicationSchedule_status_update_guard"
BEFORE UPDATE OF "status" ON "MedicationSchedule"
WHEN NEW."status" NOT IN ('ACTIVE', 'PAUSED', 'ENDED')
BEGIN
  SELECT RAISE(ABORT, 'invalid medication schedule status');
END;

CREATE TRIGGER "DoseOccurrence_status_insert_guard"
BEFORE INSERT ON "DoseOccurrence"
WHEN NEW."status" NOT IN ('SCHEDULED', 'REMINDER_SENT', 'SNOOZED', 'CONFIRMED', 'SKIPPED', 'MISSED', 'CANCELLED')
BEGIN
  SELECT RAISE(ABORT, 'invalid dose occurrence status');
END;

CREATE TRIGGER "DoseOccurrence_status_update_guard"
BEFORE UPDATE OF "status" ON "DoseOccurrence"
WHEN NEW."status" NOT IN ('SCHEDULED', 'REMINDER_SENT', 'SNOOZED', 'CONFIRMED', 'SKIPPED', 'MISSED', 'CANCELLED')
BEGIN
  SELECT RAISE(ABORT, 'invalid dose occurrence status');
END;

CREATE TRIGGER "MedicationSchedule_preserve_occurrence_history"
BEFORE DELETE ON "MedicationSchedule"
WHEN EXISTS (SELECT 1 FROM "DoseOccurrence" WHERE "scheduleId" = OLD."id")
BEGIN
  SELECT RAISE(ABORT, 'medication schedule history must be retained');
END;

CREATE TRIGGER "Medication_preserve_occurrence_history"
BEFORE DELETE ON "Medication"
WHEN EXISTS (SELECT 1 FROM "DoseOccurrence" WHERE "medicationId" = OLD."id")
BEGIN
  SELECT RAISE(ABORT, 'medication occurrence history must be retained');
END;

CREATE TRIGGER "PatientProfile_preserve_occurrence_history"
BEFORE DELETE ON "PatientProfile"
WHEN EXISTS (SELECT 1 FROM "DoseOccurrence" WHERE "patientProfileId" = OLD."id")
BEGIN
  SELECT RAISE(ABORT, 'patient occurrence history must be retained');
END;
