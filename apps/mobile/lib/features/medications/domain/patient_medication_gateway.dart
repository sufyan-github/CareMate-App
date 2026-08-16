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
}
