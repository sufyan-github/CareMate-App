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
  List<DoseOccurrenceSummary> doseOccurrences = const [];
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

  Future<MedicationSchedulePlan?> previewSchedule(
    String medicationId,
    MedicationScheduleDraft draft,
  ) async {
    return _scheduleOperation(
      () => gateway.createSchedule(
        accessToken: accessToken,
        activation: 'PREVIEW',
        draft: draft,
        medicationId: medicationId,
      ),
    );
  }

  Future<MedicationSchedulePlan?> activateSchedule(
    String medicationId,
    MedicationScheduleDraft draft,
  ) async {
    final plan = await _scheduleOperation(
      () => gateway.createSchedule(
        accessToken: accessToken,
        activation: 'ACTIVATE',
        draft: draft,
        medicationId: medicationId,
      ),
    );
    if (plan != null) {
      if (plan.schedule case final schedule?) {
        _replaceSchedule(medicationId, schedule);
      }
      await _loadDoseOccurrences();
      notifyListeners();
    }
    return plan;
  }

  Future<MedicationScheduleSummary?> updateSchedule(
    String medicationId,
    MedicationScheduleSummary schedule,
    MedicationScheduleDraft draft,
  ) async {
    final updated = await _scheduleOperation(
      () => gateway.updateSchedule(
        accessToken: accessToken,
        draft: draft,
        schedule: schedule,
      ),
    );
    if (updated != null) {
      _replaceSchedule(medicationId, updated);
      await _loadDoseOccurrences();
      notifyListeners();
    }
    return updated;
  }

  Future<MedicationScheduleSummary?> commandSchedule(
    String medicationId,
    MedicationScheduleSummary schedule,
    ScheduleAction action,
  ) async {
    final updated = await _scheduleOperation(
      () => gateway.commandSchedule(
        accessToken: accessToken,
        action: action,
        schedule: schedule,
      ),
    );
    if (updated != null) {
      _replaceSchedule(
        medicationId,
        updated.status == 'ENDED' ? null : updated,
      );
      await _loadDoseOccurrences();
      notifyListeners();
    }
    return updated;
  }

  Future<void> _loadMedications() async {
    medications = await gateway.listMedications(
      accessToken: accessToken,
      profileId: profile!.id,
    );
    await _loadDoseOccurrences();
  }

  Future<void> _loadDoseOccurrences() async {
    final activeProfile = profile;
    if (activeProfile == null) return;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    doseOccurrences = await gateway.listDoseOccurrences(
      accessToken: accessToken,
      from: start,
      profileId: activeProfile.id,
      to: start,
    );
  }

  Future<T?> _scheduleOperation<T>(Future<T> Function() operation) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      return await operation();
    } on AuthFailure catch (failure) {
      errorMessage = failure.message;
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  void _replaceSchedule(
    String medicationId,
    MedicationScheduleSummary? schedule,
  ) {
    medications = medications
        .map(
          (medication) => medication.id == medicationId
              ? MedicationSummary(
                  activeSchedule: schedule,
                  displayName: medication.displayName,
                  form: medication.form,
                  id: medication.id,
                  quantityLabel: medication.quantityLabel,
                  status: medication.status,
                  strengthLabel: medication.strengthLabel,
                )
              : medication,
        )
        .toList(growable: false);
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
