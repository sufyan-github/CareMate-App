import 'package:caremate/features/auth/domain/auth_models.dart';
import 'package:caremate/features/medications/domain/patient_medication_gateway.dart';
import 'package:caremate/features/medications/domain/patient_medication_models.dart';
import 'package:flutter/foundation.dart';

enum PatientMedicationStatus { loading, needsProfile, ready, error }

class PatientMedicationCoordinator extends ChangeNotifier {
  PatientMedicationCoordinator({
    required this.accessToken,
    required this.gateway,
  });

  final String accessToken;
  final PatientMedicationGateway gateway;

  PatientMedicationStatus status = PatientMedicationStatus.loading;
  PatientProfile? profile;
  List<MedicationSummary> medications = const [];
  String? errorMessage;
  bool isSaving = false;

  Future<void> initialize() async {
    try {
      final profiles = await gateway.listProfiles(accessToken);
      if (profiles.isEmpty) {
        status = PatientMedicationStatus.needsProfile;
      } else {
        profile = profiles.first;
        await _loadMedications();
        status = PatientMedicationStatus.ready;
      }
    } on AuthFailure catch (failure) {
      errorMessage = failure.message;
      status = PatientMedicationStatus.error;
    }
    notifyListeners();
  }

  Future<bool> createProfile(String displayName) async {
    return _save(() async {
      profile = await gateway.createProfile(
        accessToken: accessToken,
        displayName: displayName,
        timezone: 'Asia/Dhaka',
      );
      medications = const [];
      status = PatientMedicationStatus.ready;
    });
  }

  Future<bool> createMedication(MedicationDraft draft) async {
    final activeProfile = profile;
    if (activeProfile == null) return false;
    return _save(() async {
      final created = await gateway.createMedication(
        accessToken: accessToken,
        draft: draft,
        profileId: activeProfile.id,
      );
      medications = [created, ...medications];
    });
  }

  Future<void> _loadMedications() async {
    medications = await gateway.listMedications(
      accessToken: accessToken,
      profileId: profile!.id,
    );
  }

  Future<bool> _save(Future<void> Function() operation) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      await operation();
      return true;
    } on AuthFailure catch (failure) {
      errorMessage = failure.message;
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
