import 'package:caremate/features/medications/domain/patient_medication_models.dart';

abstract interface class PatientMedicationGateway {
  Future<List<PatientProfile>> listProfiles(String accessToken);
  Future<PatientProfile> createProfile({
    required String accessToken,
    required String displayName,
    required String timezone,
  });
  Future<List<MedicationSummary>> listMedications({
    required String accessToken,
    required String profileId,
  });
  Future<MedicationSummary> createMedication({
    required String accessToken,
    required MedicationDraft draft,
    required String profileId,
  });
  Future<MedicationSchedulePlan> createSchedule({
    required String accessToken,
    required String activation,
    required MedicationScheduleDraft draft,
    required String medicationId,
  });
  Future<List<DoseOccurrenceSummary>> listDoseOccurrences({
    required String accessToken,
    required DateTime from,
    required String profileId,
    required DateTime to,
  });
  Future<DoseOccurrenceSummary> commandDose({
    required String accessToken,
    required DoseCommand command,
  });
  Future<MedicationScheduleSummary> updateSchedule({
    required String accessToken,
    required MedicationScheduleDraft draft,
    required MedicationScheduleSummary schedule,
  });
  Future<MedicationScheduleSummary> commandSchedule({
    required String accessToken,
    required ScheduleAction action,
    required MedicationScheduleSummary schedule,
  });
}
