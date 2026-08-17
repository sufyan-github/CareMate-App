import 'package:caremate/features/medications/domain/patient_medication_models.dart';
import 'package:caremate/features/sync/data/caremate_local_database.dart';
import 'package:caremate/features/sync/data/drift_dose_mutation_store.dart';
import 'package:caremate/features/sync/domain/dose_sync_models.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CareMateLocalDatabase database;
  late DriftDoseMutationStore store;

  setUp(() {
    database = CareMateLocalDatabase(NativeDatabase.memory());
    store = DriftDoseMutationStore(database);
  });

  tearDown(() => database.close());

  test(
    'persists optimistic state and its immutable mutation atomically',
    () async {
      final occurrence = _occurrence();
      await store.cacheServerOccurrences('profile-1', [occurrence]);
      final mutation = DoseSyncMutation(
        action: DoseAction.confirm,
        clientAt: _clientAt,
        expectedVersion: 1,
        id: '01K2LOCALCONFIRM00000000001',
        installationId: 'installation-1',
        occurrenceId: 'occurrence-1',
      );

      await store.enqueue(
        mutation,
        _occurrence(
          confirmedAt: _clientAt,
          pendingSync: true,
          status: 'CONFIRMED',
        ),
      );

      expect(await store.pending(), [
        isA<DoseSyncMutation>()
            .having((item) => item.id, 'id', mutation.id)
            .having((item) => item.action, 'action', DoseAction.confirm),
      ]);
      final cached = await store.listCached(
        'profile-1',
        from: DateTime(2026, 8, 17),
        to: DateTime(2026, 8, 17),
      );
      expect(cached.single.status, 'CONFIRMED');
      expect(cached.single.pendingSync, isTrue);
      expect(await store.pendingCount(), 1);
    },
  );

  test(
    'replaces pending state only with an authoritative sync result',
    () async {
      final occurrence = _occurrence();
      await store.cacheServerOccurrences('profile-1', [occurrence]);
      final mutation = DoseSyncMutation(
        action: DoseAction.confirm,
        clientAt: _clientAt,
        expectedVersion: 1,
        id: '01K2LOCALCONFIRM00000000001',
        installationId: 'installation-1',
        occurrenceId: 'occurrence-1',
      );
      await store.enqueue(
        mutation,
        _occurrence(
          confirmedAt: _clientAt,
          pendingSync: true,
          status: 'CONFIRMED',
        ),
      );

      await store.applyResult(
        DoseSyncResult(
          authoritative: AuthoritativeDoseState(
            confirmedAt: _clientAt.add(const Duration(seconds: 2)),
            id: 'occurrence-1',
            snoozeCount: 0,
            status: 'CONFIRMED',
            version: 2,
          ),
          mutationId: mutation.id,
          status: SyncMutationStatus.accepted,
        ),
      );

      expect(await store.pendingCount(), 0);
      final cached = await store.listCached(
        'profile-1',
        from: DateTime(2026, 8, 17),
        to: DateTime(2026, 8, 17),
      );
      expect(cached.single.version, 2);
      expect(cached.single.pendingSync, isFalse);
      expect(cached.single.syncConflictCode, isNull);
    },
  );

  test('restores the last server state when a mutation is rejected', () async {
    final occurrence = _occurrence();
    await store.cacheServerOccurrences('profile-1', [occurrence]);
    const mutationId = '01K2LOCALREJECTED0000000001';
    await store.enqueue(
      DoseSyncMutation(
        action: DoseAction.confirm,
        clientAt: _clientAt,
        expectedVersion: 1,
        id: mutationId,
        installationId: 'installation-1',
        occurrenceId: occurrence.id,
      ),
      _occurrence(
        confirmedAt: _clientAt,
        pendingSync: true,
        status: 'CONFIRMED',
      ),
    );

    await store.applyResult(
      const DoseSyncResult(
        errorCode: 'DOSE_NOT_DUE',
        errorMessage: 'This dose is not due yet.',
        mutationId: mutationId,
        status: SyncMutationStatus.rejected,
      ),
    );

    final restored = await store.getOccurrence(occurrence.id);
    expect(restored?.status, 'SCHEDULED');
    expect(restored?.pendingSync, isFalse);
    expect(restored?.syncConflictCode, 'DOSE_NOT_DUE');
  });

  test('keeps a retry-later mutation pending with bounded backoff', () async {
    final occurrence = _occurrence();
    await store.cacheServerOccurrences('profile-1', [occurrence]);
    const mutationId = '01K2LOCALRETRY000000000001';
    await store.enqueue(
      DoseSyncMutation(
        action: DoseAction.confirm,
        clientAt: _clientAt,
        expectedVersion: 1,
        id: mutationId,
        installationId: 'installation-1',
        occurrenceId: occurrence.id,
      ),
      _occurrence(
        confirmedAt: _clientAt,
        pendingSync: true,
        status: 'CONFIRMED',
      ),
    );

    await store.applyResult(
      const DoseSyncResult(
        errorCode: 'SYNC_TEMPORARY_FAILURE',
        errorMessage: 'Try later.',
        mutationId: mutationId,
        status: SyncMutationStatus.retryLater,
      ),
    );

    expect(await store.pendingCount(), 1);
    expect((await store.getOccurrence(occurrence.id))?.pendingSync, isTrue);
  });

  test(
    'keeps the confirmed profile and medication plan for cold-start use',
    () async {
      const profile = PatientProfile(
        displayName: 'Abu Sufyan',
        id: 'profile-1',
        timezone: 'Asia/Dhaka',
        version: 1,
      );
      final schedule = MedicationScheduleSummary(
        endDate: DateTime(2026, 8, 20),
        id: 'schedule-1',
        revision: 2,
        startDate: DateTime(2026, 8, 17),
        status: 'ACTIVE',
        times: const ['08:00'],
        timezone: 'Asia/Dhaka',
        version: 3,
      );
      await store.cacheProfiles([profile]);
      await store.cacheMedications('profile-1', [
        MedicationSummary(
          activeSchedule: schedule,
          displayName: 'Napa',
          form: 'TABLET',
          id: 'medication-1',
          quantityLabel: '1 tablet',
          status: 'ACTIVE',
          strengthLabel: '500 mg',
        ),
      ]);

      expect(await store.listCachedProfiles(), [
        isA<PatientProfile>().having((item) => item.id, 'id', profile.id),
      ]);
      final medications = await store.listCachedMedications(profile.id);
      expect(medications.single.displayName, 'Napa');
      expect(medications.single.activeSchedule?.revision, 2);
      expect(medications.single.activeSchedule?.times, ['08:00']);
    },
  );

  test('purges another user cache before any offline read', () async {
    const firstProfile = PatientProfile(
      displayName: 'First user',
      id: 'profile-1',
      timezone: 'Asia/Dhaka',
      version: 1,
    );
    await store.bindAccount('user-1');
    await store.cacheProfiles([firstProfile]);
    await store.cacheServerOccurrences('profile-1', [_occurrence()]);

    await store.bindAccount('user-1');
    expect(await store.listCachedProfiles(), hasLength(1));

    await store.bindAccount('user-2');
    expect(await store.listCachedProfiles(), isEmpty);
    expect(
      await store.listCached(
        'profile-1',
        from: DateTime(2026, 8, 17),
        to: DateTime(2026, 8, 17),
      ),
      isEmpty,
    );
  });

  test(
    'removes stale server occurrences while preserving the current window',
    () async {
      await store.cacheServerOccurrences('profile-1', [
        _occurrence(),
        DoseOccurrenceSummary(
          id: 'occurrence-stale',
          medicationName: 'Napa',
          plannedAt: DateTime.utc(2026, 8, 17, 8),
          plannedLocalDateTime: '2026-08-17T14:00',
          quantityLabel: '1 tablet',
          status: 'SCHEDULED',
          version: 1,
        ),
      ]);

      await store.cacheServerOccurrences('profile-1', [_occurrence()]);

      final cached = await store.listCached(
        'profile-1',
        from: DateTime(2026, 8, 17),
        to: DateTime(2026, 8, 17),
      );
      expect(cached.map((item) => item.id), ['occurrence-1']);
    },
  );

  test('revoking a shared profile preserves an owner mutation', () async {
    await store.bindAccount('user-1');
    await store.cacheProfiles(const [
      PatientProfile(
        displayName: 'Owner',
        id: 'profile-1',
        timezone: 'Asia/Dhaka',
        version: 1,
      ),
      PatientProfile(
        accessRole: 'CAREGIVER',
        canManage: false,
        displayName: 'Shared profile',
        id: 'profile-shared',
        timezone: 'Asia/Dhaka',
        version: 1,
      ),
    ]);
    await store.cacheServerOccurrences('profile-1', [_occurrence()]);
    await store.enqueue(
      DoseSyncMutation(
        action: DoseAction.confirm,
        clientAt: _clientAt,
        expectedVersion: 1,
        id: '01K2OWNERPENDING00000000001',
        installationId: 'installation-1',
        occurrenceId: 'occurrence-1',
      ),
      _occurrence(
        confirmedAt: _clientAt,
        pendingSync: true,
        status: 'CONFIRMED',
      ),
    );

    await store.cacheProfiles(const [
      PatientProfile(
        displayName: 'Owner',
        id: 'profile-1',
        timezone: 'Asia/Dhaka',
        version: 1,
      ),
    ]);

    expect(await store.pendingCount(), 1);
    expect((await store.listCachedProfiles()).map((item) => item.id), [
      'profile-1',
    ]);
  });
}

final _clientAt = DateTime.utc(2026, 8, 17, 2, 5);

DoseOccurrenceSummary _occurrence({
  DateTime? confirmedAt,
  bool pendingSync = false,
  String status = 'SCHEDULED',
  int version = 1,
}) => DoseOccurrenceSummary(
  confirmedAt: confirmedAt,
  id: 'occurrence-1',
  medicationName: 'Napa',
  pendingSync: pendingSync,
  plannedAt: DateTime.utc(2026, 8, 17, 2),
  plannedLocalDateTime: '2026-08-17T08:00',
  quantityLabel: '1 tablet',
  status: status,
  version: version,
);
