import 'package:caremate/features/medications/domain/patient_medication_models.dart';

enum SyncMutationStatus {
  pending,
  syncing,
  accepted,
  alreadyApplied,
  conflict,
  rejected,
  retryLater,
}

class DoseSyncMutation {
  const DoseSyncMutation({
    required this.action,
    required this.clientAt,
    required this.expectedVersion,
    required this.id,
    required this.installationId,
    required this.occurrenceId,
    this.reason,
    this.snoozeMinutes,
  });

  final DoseAction action;
  final DateTime clientAt;
  final int expectedVersion;
  final String id;
  final String installationId;
  final String occurrenceId;
  final String? reason;
  final int? snoozeMinutes;
}

class DoseSyncResult {
  const DoseSyncResult({
    this.authoritative,
    this.errorCode,
    this.errorMessage,
    required this.mutationId,
    required this.status,
  });

  final AuthoritativeDoseState? authoritative;
  final String? errorCode;
  final String? errorMessage;
  final String mutationId;
  final SyncMutationStatus status;
}

class AuthoritativeDoseState {
  const AuthoritativeDoseState({
    this.confirmedAt,
    required this.id,
    this.missedAt,
    this.reminderSentAt,
    this.responseDueAt,
    required this.snoozeCount,
    this.snoozedUntil,
    required this.status,
    this.timingClassification,
    required this.version,
  });

  final DateTime? confirmedAt;
  final String id;
  final DateTime? missedAt;
  final DateTime? reminderSentAt;
  final DateTime? responseDueAt;
  final int snoozeCount;
  final DateTime? snoozedUntil;
  final String status;
  final String? timingClassification;
  final int version;
}

abstract interface class DoseMutationStore {
  Future<void> applyResult(DoseSyncResult result);

  Future<void> bindAccount(String userId);

  Future<void> clearAll();

  Future<void> cacheServerOccurrences(
    String profileId,
    List<DoseOccurrenceSummary> occurrences,
  );

  Future<void> cacheMedications(
    String profileId,
    List<MedicationSummary> medications,
  );

  Future<void> cacheProfiles(List<PatientProfile> profiles);

  Future<void> enqueue(
    DoseSyncMutation mutation,
    DoseOccurrenceSummary optimistic,
  );

  Future<DoseOccurrenceSummary?> getOccurrence(String occurrenceId);

  Future<List<DoseOccurrenceSummary>> listCached(
    String profileId, {
    required DateTime from,
    required DateTime to,
  });

  Future<List<MedicationSummary>> listCachedMedications(String profileId);

  Future<List<PatientProfile>> listCachedProfiles();

  Future<List<DoseSyncMutation>> pending({int limit = 50});

  Future<int> pendingCount();
}

class LazyDoseMutationStore implements DoseMutationStore {
  LazyDoseMutationStore(Future<DoseMutationStore> Function() open)
    : _store = open();

  final Future<DoseMutationStore> _store;

  @override
  Future<void> applyResult(DoseSyncResult result) async =>
      (await _store).applyResult(result);

  @override
  Future<void> bindAccount(String userId) async =>
      (await _store).bindAccount(userId);

  @override
  Future<void> clearAll() async => (await _store).clearAll();

  @override
  Future<void> cacheServerOccurrences(
    String profileId,
    List<DoseOccurrenceSummary> occurrences,
  ) async => (await _store).cacheServerOccurrences(profileId, occurrences);

  @override
  Future<void> cacheMedications(
    String profileId,
    List<MedicationSummary> medications,
  ) async => (await _store).cacheMedications(profileId, medications);

  @override
  Future<void> cacheProfiles(List<PatientProfile> profiles) async =>
      (await _store).cacheProfiles(profiles);

  @override
  Future<void> enqueue(
    DoseSyncMutation mutation,
    DoseOccurrenceSummary optimistic,
  ) async => (await _store).enqueue(mutation, optimistic);

  @override
  Future<DoseOccurrenceSummary?> getOccurrence(String occurrenceId) async =>
      (await _store).getOccurrence(occurrenceId);

  @override
  Future<List<DoseOccurrenceSummary>> listCached(
    String profileId, {
    required DateTime from,
    required DateTime to,
  }) async => (await _store).listCached(profileId, from: from, to: to);

  @override
  Future<List<MedicationSummary>> listCachedMedications(
    String profileId,
  ) async => (await _store).listCachedMedications(profileId);

  @override
  Future<List<PatientProfile>> listCachedProfiles() async =>
      (await _store).listCachedProfiles();

  @override
  Future<List<DoseSyncMutation>> pending({int limit = 50}) async =>
      (await _store).pending(limit: limit);

  @override
  Future<int> pendingCount() async => (await _store).pendingCount();
}
