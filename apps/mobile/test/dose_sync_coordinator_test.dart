import 'package:caremate/features/auth/domain/auth_models.dart';
import 'package:caremate/features/medications/domain/patient_medication_models.dart';
import 'package:caremate/features/sync/application/dose_sync_coordinator.dart';
import 'package:caremate/features/sync/data/caremate_local_database.dart';
import 'package:caremate/features/sync/data/drift_dose_mutation_store.dart';
import 'package:caremate/features/sync/domain/background_sync_scheduler.dart';
import 'package:caremate/features/sync/domain/dose_sync_gateway.dart';
import 'package:caremate/features/sync/domain/dose_sync_models.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'records offline first and later resolves exactly one mutation',
    () async {
      final database = CareMateLocalDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final store = DriftDoseMutationStore(database);
      final gateway = _FakeDoseSyncGateway()..offline = true;
      final scheduler = _FakeBackgroundScheduler();
      final coordinator = DoseSyncCoordinator(
        accessToken: () async => 'access-1',
        backgroundScheduler: scheduler,
        gateway: gateway,
        installationId: () async => 'installation-1',
        refreshAccessToken: () async => 'access-2',
        store: store,
      );
      final occurrence = DoseOccurrenceSummary(
        id: 'occurrence-1',
        medicationName: 'Napa',
        plannedAt: DateTime.now().subtract(const Duration(minutes: 1)),
        plannedLocalDateTime: '2026-08-17T08:00',
        quantityLabel: '1 tablet',
        status: 'SCHEDULED',
        version: 1,
      );
      await coordinator.cache('profile-1', [occurrence]);

      final local = await coordinator.record(occurrence, DoseAction.confirm);

      expect(local.status, 'CONFIRMED');
      expect(local.pendingSync, isTrue);
      expect(await coordinator.pendingCount(), 1);
      expect(scheduler.scheduled, 1);

      gateway.offline = false;
      expect(await coordinator.syncNow(), 1);
      final resolved = await coordinator.cached(
        'profile-1',
        from: DateTime(2026, 8, 17),
        to: DateTime(2026, 8, 17),
      );
      expect(resolved.single.status, 'CONFIRMED');
      expect(resolved.single.pendingSync, isFalse);
      expect(resolved.single.version, 2);
      expect(gateway.acceptedMutationIds.toSet(), hasLength(1));
    },
  );

  test('refreshes an expired foreground token and retries once', () async {
    final database = CareMateLocalDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final store = DriftDoseMutationStore(database);
    final gateway = _FakeDoseSyncGateway()..requiredAccessToken = 'access-2';
    var refreshCount = 0;
    final coordinator = DoseSyncCoordinator(
      accessToken: () async => 'access-1',
      backgroundScheduler: _FakeBackgroundScheduler(),
      gateway: gateway,
      installationId: () async => 'installation-1',
      refreshAccessToken: () async {
        refreshCount += 1;
        return 'access-2';
      },
      store: store,
    );
    final occurrence = DoseOccurrenceSummary(
      id: 'occurrence-1',
      medicationName: 'Napa',
      plannedAt: DateTime.now().subtract(const Duration(minutes: 1)),
      plannedLocalDateTime: '2026-08-17T08:00',
      quantityLabel: '1 tablet',
      status: 'SCHEDULED',
      version: 1,
    );
    await coordinator.cache('profile-1', [occurrence]);

    final resolved = await coordinator.record(occurrence, DoseAction.confirm);

    expect(refreshCount, 1);
    expect(resolved.pendingSync, isFalse);
    expect(resolved.version, 2);
  });
}

class _FakeBackgroundScheduler implements BackgroundSyncScheduler {
  int scheduled = 0;

  @override
  Future<void> schedule() async => scheduled += 1;
}

class _FakeDoseSyncGateway implements DoseSyncGateway {
  bool offline = false;
  String? requiredAccessToken;
  final List<String> acceptedMutationIds = [];

  @override
  Future<List<DoseSyncResult>> push(
    String accessToken,
    List<DoseSyncMutation> mutations,
  ) async {
    if (offline) {
      throw const AuthFailure('NETWORK_UNAVAILABLE', 'Offline');
    }
    if (requiredAccessToken != null && accessToken != requiredAccessToken) {
      throw const AuthFailure('SESSION_REVOKED', 'Refresh required');
    }
    return mutations
        .map((mutation) {
          acceptedMutationIds.add(mutation.id);
          return DoseSyncResult(
            authoritative: AuthoritativeDoseState(
              confirmedAt: mutation.clientAt,
              id: mutation.occurrenceId,
              snoozeCount: 0,
              status: 'CONFIRMED',
              version: mutation.expectedVersion + 1,
            ),
            mutationId: mutation.id,
            status: SyncMutationStatus.accepted,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<void> registerInstallation({
    required String accessToken,
    required String appVersion,
    required String deviceName,
    required String installationId,
    required String locale,
    required String platform,
    String? pushToken,
  }) async {}
}
