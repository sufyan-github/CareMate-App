import 'package:caremate/features/auth/domain/auth_models.dart';
import 'package:caremate/features/auth/data/device_locale.dart';
import 'package:caremate/features/medications/domain/patient_medication_models.dart';
import 'package:caremate/features/sync/application/dose_sync_engine.dart';
import 'package:caremate/features/sync/domain/background_sync_scheduler.dart';
import 'package:caremate/features/sync/domain/dose_sync_gateway.dart';
import 'package:caremate/features/sync/domain/dose_sync_models.dart';
import 'package:uuid/uuid.dart';

class DoseSyncCoordinator {
  DoseSyncCoordinator({
    required this.accessToken,
    required this.backgroundScheduler,
    required this.gateway,
    required this.installationId,
    required this.refreshAccessToken,
    required this.store,
    Uuid? uuid,
  }) : _engine = DoseSyncEngine(gateway: gateway, store: store),
       _uuid = uuid ?? const Uuid();

  final Future<String> Function() accessToken;
  final BackgroundSyncScheduler backgroundScheduler;
  final DoseSyncGateway gateway;
  final Future<String> Function() installationId;
  final Future<String> Function() refreshAccessToken;
  final DoseMutationStore store;
  final DoseSyncEngine _engine;
  final Uuid _uuid;

  Future<void> bindAccount(String userId) => store.bindAccount(userId);

  Future<void> cache(
    String profileId,
    List<DoseOccurrenceSummary> occurrences,
  ) => store.cacheServerOccurrences(profileId, occurrences);

  Future<void> cacheMedications(
    String profileId,
    List<MedicationSummary> medications,
  ) => store.cacheMedications(profileId, medications);

  Future<void> cacheProfiles(List<PatientProfile> profiles) =>
      store.cacheProfiles(profiles);

  Future<List<DoseOccurrenceSummary>> cached(
    String profileId, {
    required DateTime from,
    required DateTime to,
  }) => store.listCached(profileId, from: from, to: to);

  Future<List<MedicationSummary>> cachedMedications(String profileId) =>
      store.listCachedMedications(profileId);

  Future<List<PatientProfile>> cachedProfiles() => store.listCachedProfiles();

  Future<int> pendingCount() => store.pendingCount();

  Future<DoseOccurrenceSummary> record(
    DoseOccurrenceSummary occurrence,
    DoseAction action, {
    String? reason,
    int? snoozeMinutes,
  }) async {
    if (occurrence.pendingSync) {
      throw const AuthFailure(
        'DOSE_SYNC_PENDING',
        'This dose already has a change waiting to sync.',
      );
    }
    final now = DateTime.now().toUtc();
    final mutation = DoseSyncMutation(
      action: action,
      clientAt: now,
      expectedVersion: occurrence.version,
      id: _uuid.v7(),
      installationId: await installationId(),
      occurrenceId: occurrence.id,
      reason: reason,
      snoozeMinutes: snoozeMinutes,
    );
    await store.enqueue(
      mutation,
      _optimistic(occurrence, action, now: now, snoozeMinutes: snoozeMinutes),
    );
    try {
      await backgroundScheduler.schedule();
    } on Object {
      // The local mutation remains durable and manual/foreground sync still works.
    }
    try {
      await _syncPending();
    } on AuthFailure {
      // The mutation is already durable. WorkManager or manual sync retries it.
    }
    return await store.getOccurrence(occurrence.id) ?? occurrence;
  }

  Future<int> syncNow() => _syncPending();

  Future<void> registerInstallation({required String installationId}) =>
      _withToken(
        (token) => gateway.registerInstallation(
          accessToken: token,
          appVersion: '1.0.0',
          deviceName: 'Android phone',
          installationId: installationId,
          locale: careMateDeviceLocale(),
          platform: 'ANDROID',
        ),
      );

  Future<int> _syncPending() =>
      _withToken((token) => _engine.syncPending(token));

  Future<T> _withToken<T>(Future<T> Function(String token) operation) async {
    try {
      return await operation(await accessToken());
    } on AuthFailure catch (failure) {
      if (!_requiresRefresh(failure.code)) rethrow;
      return operation(await refreshAccessToken());
    }
  }

  bool _requiresRefresh(String code) =>
      code.contains('ACCESS') ||
      code.contains('SESSION') ||
      code.contains('TOKEN');

  DoseOccurrenceSummary _optimistic(
    DoseOccurrenceSummary occurrence,
    DoseAction action, {
    required DateTime now,
    int? snoozeMinutes,
  }) => DoseOccurrenceSummary(
    confirmedAt: action == DoseAction.confirm ? now : occurrence.confirmedAt,
    id: occurrence.id,
    medicationName: occurrence.medicationName,
    missedAt: occurrence.missedAt,
    pendingSync: true,
    plannedAt: occurrence.plannedAt,
    plannedLocalDateTime: occurrence.plannedLocalDateTime,
    quantityLabel: occurrence.quantityLabel,
    reminderSentAt: occurrence.reminderSentAt,
    responseDueAt: occurrence.responseDueAt,
    ruleRevision: occurrence.ruleRevision,
    snoozeCount: action == DoseAction.snooze
        ? occurrence.snoozeCount + 1
        : occurrence.snoozeCount,
    snoozedUntil: action == DoseAction.snooze
        ? now.add(Duration(minutes: snoozeMinutes ?? 10))
        : null,
    status: switch (action) {
      DoseAction.confirm => 'CONFIRMED',
      DoseAction.snooze => 'SNOOZED',
      DoseAction.skip => 'SKIPPED',
    },
    timingClassification: action == DoseAction.confirm
        ? (occurrence.status == 'MISSED' ? 'LATE' : 'ON_TIME')
        : occurrence.timingClassification,
    version: occurrence.version,
  );
}
