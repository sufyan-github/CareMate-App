import 'dart:async';

import 'package:caremate/features/auth/domain/auth_models.dart';
import 'package:caremate/features/medications/domain/patient_medication_gateway.dart';
import 'package:caremate/features/medications/domain/patient_medication_models.dart';
import 'package:caremate/features/reminders/domain/reminder_scheduler.dart';
import 'package:caremate/features/sync/application/dose_sync_coordinator.dart';
import 'package:flutter/foundation.dart';

enum PatientMedicationStatus { loading, needsProfile, ready, error }

class PatientMedicationCoordinator extends ChangeNotifier {
  PatientMedicationCoordinator({
    required this.accessToken,
    Future<String> Function()? accessTokenProvider,
    required this.doseSync,
    required this.gateway,
    required this.reminderScheduler,
  }) : _accessTokenProvider = accessTokenProvider ?? (() async => accessToken);

  String accessToken;
  final Future<String> Function() _accessTokenProvider;
  final DoseSyncCoordinator doseSync;
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
  int pendingSyncCount = 0;
  bool usingOfflineCache = false;
  String? syncMessage;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> initialize({String? userId}) async {
    try {
      if (userId != null) await doseSync.bindAccount(userId);
      List<PatientProfile> profiles;
      try {
        profiles = await gateway.listProfiles(await _token());
        await doseSync.cacheProfiles(profiles);
        usingOfflineCache = false;
      } on AuthFailure catch (failure) {
        if (failure.code != 'NETWORK_UNAVAILABLE') rethrow;
        profiles = await doseSync.cachedProfiles();
        usingOfflineCache = true;
      }
      if (profiles.isEmpty) {
        if (usingOfflineCache) {
          throw const AuthFailure(
            'OFFLINE_CACHE_EMPTY',
            'CareMate is offline and this phone has no saved profile yet.',
          );
        }
        status = PatientMedicationStatus.needsProfile;
      } else {
        profile = profiles.first;
        if (profile!.canViewMedicationPlan) {
          await _loadMedications();
        } else {
          medications = const [];
          doseOccurrences = const [];
          reminderOccurrences = const [];
        }
        status = PatientMedicationStatus.ready;
        notifyListeners();
        if (profile!.canViewMedicationPlan) {
          unawaited(_initializeReminders());
        }
      }
    } on AuthFailure catch (failure) {
      errorMessage = failure.message;
      status = PatientMedicationStatus.error;
    } on Object {
      errorMessage =
          'CareMate could not open its secure offline storage. Restart the app and try again.';
      status = PatientMedicationStatus.error;
    }
    notifyListeners();
  }

  Future<bool> createProfile(String displayName) async {
    return _save(() async {
      profile = await gateway.createProfile(
        accessToken: await _token(),
        displayName: displayName,
        timezone: 'Asia/Dhaka',
      );
      await doseSync.cacheProfiles([profile!]);
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
        accessToken: await _token(),
        draft: draft,
        profileId: activeProfile.id,
      );
      medications = [created, ...medications];
      await doseSync.cacheMedications(activeProfile.id, medications);
    });
  }

  Future<MedicationSchedulePlan?> previewSchedule(
    String medicationId,
    MedicationScheduleDraft draft,
  ) async {
    return _scheduleOperation(
      () async => gateway.createSchedule(
        accessToken: await _token(),
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
      () async => gateway.createSchedule(
        accessToken: await _token(),
        activation: 'ACTIVATE',
        draft: draft,
        medicationId: medicationId,
      ),
    );
    if (plan != null) {
      if (plan.schedule case final schedule?) {
        _replaceSchedule(medicationId, schedule);
      }
      await doseSync.cacheMedications(profile!.id, medications);
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
      () async => gateway.updateSchedule(
        accessToken: await _token(),
        draft: draft,
        schedule: schedule,
      ),
    );
    if (updated != null) {
      _replaceSchedule(medicationId, updated);
      await doseSync.cacheMedications(profile!.id, medications);
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
      () async => gateway.commandSchedule(
        accessToken: await _token(),
        action: action,
        schedule: schedule,
      ),
    );
    if (updated != null) {
      _replaceSchedule(
        medicationId,
        updated.status == 'ENDED' ? null : updated,
      );
      await doseSync.cacheMedications(profile!.id, medications);
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
    var accepted = false;
    final saved = await _save(() async {
      final updated = await doseSync.record(
        occurrence,
        action,
        reason: reason,
        snoozeMinutes: snoozeMinutes,
      );
      doseOccurrences = doseOccurrences
          .map((item) => item.id == updated.id ? updated : item)
          .toList(growable: false);
      reminderOccurrences = reminderOccurrences
          .map((item) => item.id == updated.id ? updated : item)
          .toList(growable: false);
      pendingSyncCount = await doseSync.pendingCount();
      accepted = updated.syncConflictCode == null;
      syncMessage = updated.pendingSync
          ? 'Saved on this phone. Waiting to sync.'
          : accepted
          ? 'Synced with CareMate.'
          : 'CareMate kept the latest server state. Review this dose before trying again.';
      await _reconcileReminders();
    });
    return saved && accepted;
  }

  Future<void> syncNow() async {
    if (isSaving) return;
    isSaving = true;
    syncMessage = null;
    notifyListeners();
    try {
      final resolved = await doseSync.syncNow();
      await _loadDoseOccurrences();
      syncMessage = resolved == 0
          ? 'Everything is already synced.'
          : 'Synced $resolved saved change${resolved == 1 ? '' : 's'}.';
      errorMessage = null;
    } on AuthFailure catch (failure) {
      syncMessage = failure.message;
    } finally {
      isSaving = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<String> accessTokenForRequest() => _token();

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
    if (profile?.canViewMedicationPlan != true) return;
    try {
      try {
        await doseSync.syncNow();
      } on AuthFailure {
        // Cached data remains authoritative for the immediate offline UX.
      }
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
    try {
      medications = await gateway.listMedications(
        accessToken: await _token(),
        profileId: profile!.id,
      );
      await doseSync.cacheMedications(profile!.id, medications);
    } on AuthFailure catch (failure) {
      if (failure.code != 'NETWORK_UNAVAILABLE') rethrow;
      medications = await doseSync.cachedMedications(profile!.id);
      usingOfflineCache = true;
    }
    await _loadDoseOccurrences();
  }

  Future<void> _loadDoseOccurrences() async {
    final activeProfile = profile;
    if (activeProfile == null) return;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 13));
    try {
      final serverOccurrences = await gateway.listDoseOccurrences(
        accessToken: await _token(),
        from: start,
        profileId: activeProfile.id,
        to: end,
      );
      await doseSync.cache(activeProfile.id, serverOccurrences);
      usingOfflineCache = false;
    } on AuthFailure catch (failure) {
      if (failure.code != 'NETWORK_UNAVAILABLE') rethrow;
      usingOfflineCache = true;
    }
    reminderOccurrences = await doseSync.cached(
      activeProfile.id,
      from: start,
      to: end,
    );
    doseOccurrences = reminderOccurrences
        .where(
          (occurrence) =>
              occurrence.plannedLocalDateTime.substring(0, 10) ==
              _localDate(start),
        )
        .toList(growable: false);
    pendingSyncCount = await doseSync.pendingCount();
  }

  String _localDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  Future<String> _token() async {
    accessToken = await _accessTokenProvider();
    return accessToken;
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
