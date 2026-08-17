import 'dart:async';

import 'package:caremate/features/auth/domain/auth_models.dart';
import 'package:caremate/features/medications/domain/patient_medication_gateway.dart';
import 'package:caremate/features/medications/domain/patient_medication_models.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:caremate/features/reminders/domain/reminder_scheduler.dart';

enum PatientMedicationStatus { loading, needsProfile, ready, error }

class PatientMedicationCoordinator extends ChangeNotifier {
  PatientMedicationCoordinator({
    required this.accessToken,
    required this.gateway,
    required this.reminderScheduler,
  });

  final String accessToken;
  final PatientMedicationGateway gateway;
  final ReminderScheduler reminderScheduler;

  PatientMedicationStatus status = PatientMedicationStatus.loading;
  PatientProfile? profile;
  List<MedicationSummary> medications = const [];
  List<DoseOccurrenceSummary> doseOccurrences = const [];
  List<DoseOccurrenceSummary> reminderOccurrences = const [];
  String? errorMessage;
  bool isSaving = false;
  ReminderReadiness? reminderReadiness;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> initialize() async {
    try {
      final profiles = await gateway.listProfiles(accessToken);
      if (profiles.isEmpty) {
        status = PatientMedicationStatus.needsProfile;
      } else {
        profile = profiles.first;
        await _loadMedications();
        status = PatientMedicationStatus.ready;
        notifyListeners();
        unawaited(_initializeReminders());
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
      unawaited(_initializeReminders());
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
      await _reconcileReminders();
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
      await _reconcileReminders();
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
      await _reconcileReminders();
      notifyListeners();
    }
    return updated;
  }

  Future<bool> commandDose(
    DoseOccurrenceSummary occurrence,
    DoseAction action, {
    String? reason,
    int? snoozeMinutes,
  }) async {
    return _save(() async {
      final updated = await gateway.commandDose(
        accessToken: accessToken,
        command: DoseCommand(
          action: action,
          clientAt: DateTime.now(),
          clientMutationId: const Uuid().v7(),
          occurrence: occurrence,
          reason: reason,
          snoozeMinutes: snoozeMinutes,
        ),
      );
      doseOccurrences = doseOccurrences
          .map((item) => item.id == updated.id ? updated : item)
          .toList(growable: false);
      reminderOccurrences = reminderOccurrences
          .map((item) => item.id == updated.id ? updated : item)
          .toList(growable: false);
      await _reconcileReminders();
    });
  }

  Future<void> requestReminderPermissions() async {
    try {
      reminderReadiness = await reminderScheduler.checkReadiness(request: true);
      await _reconcileReminders();
    } on Object {
      reminderReadiness = const ReminderReadiness(
        exactAlarmsAllowed: false,
        notificationsAllowed: false,
        supported: false,
      );
    }
    notifyListeners();
  }

  Future<void> openReminderSettings() async {
    try {
      await reminderScheduler.openNotificationSettings();
    } on Object {
      errorMessage = 'Could not open Android notification settings.';
      notifyListeners();
    }
  }

  Future<void> refreshAfterAppResume() async {
    if (status != PatientMedicationStatus.ready || _disposed) return;
    try {
      await _loadDoseOccurrences();
      reminderReadiness = await reminderScheduler.checkReadiness();
      await _reconcileReminders();
    } on AuthFailure catch (failure) {
      errorMessage = failure.message;
    } on Object {
      reminderReadiness = const ReminderReadiness(
        exactAlarmsAllowed: false,
        notificationsAllowed: false,
        supported: false,
      );
    }
    if (!_disposed) notifyListeners();
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
    reminderOccurrences = await gateway.listDoseOccurrences(
      accessToken: accessToken,
      from: start,
      profileId: activeProfile.id,
      to: start.add(const Duration(days: 13)),
    );
  }

  Future<void> _initializeReminders() async {
    try {
      await reminderScheduler.initialize(_handleReminderAction);
      reminderReadiness = await reminderScheduler.checkReadiness();
      await _reconcileReminders();
    } on Object {
      reminderReadiness = const ReminderReadiness(
        exactAlarmsAllowed: false,
        notificationsAllowed: false,
        supported: false,
      );
    } finally {
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> _handleReminderAction(
    String occurrenceId,
    DoseAction action,
  ) async {
    final occurrence = doseOccurrences
        .followedBy(reminderOccurrences)
        .where((item) => item.id == occurrenceId)
        .firstOrNull;
    if (occurrence == null) return;
    await commandDose(
      occurrence,
      action,
      snoozeMinutes: action == DoseAction.snooze ? 10 : null,
    );
  }

  Future<void> _reconcileReminders() async {
    if (reminderReadiness?.notificationsAllowed != true) return;
    try {
      await reminderScheduler.reconcile(reminderOccurrences);
    } on Object {
      reminderReadiness = ReminderReadiness(
        exactAlarmsAllowed: reminderReadiness?.exactAlarmsAllowed ?? false,
        notificationsAllowed: false,
        supported: reminderReadiness?.supported ?? false,
      );
    }
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
