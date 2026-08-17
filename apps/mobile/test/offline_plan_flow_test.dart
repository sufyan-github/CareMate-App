import 'package:caremate/features/auth/domain/auth_models.dart';
import 'package:caremate/features/medications/application/patient_medication_coordinator.dart';
import 'package:caremate/features/medications/domain/patient_medication_models.dart';
import 'package:caremate/features/reminders/domain/reminder_scheduler.dart';
import 'package:caremate/features/sync/application/dose_sync_coordinator.dart';
import 'package:caremate/features/sync/data/caremate_local_database.dart';
import 'package:caremate/features/sync/data/drift_dose_mutation_store.dart';
import 'package:caremate/features/sync/domain/background_sync_scheduler.dart';
import 'package:caremate/features/sync/domain/dose_sync_gateway.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/auth_test_support.dart';

void main() {
  test(
    'cold-starts from the encrypted plan cache while the API is offline',
    () async {
      final database = CareMateLocalDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final store = DriftDoseMutationStore(database);
      const profile = PatientProfile(
        displayName: 'Abu Sufyan',
        id: 'profile-1',
        timezone: 'Asia/Dhaka',
        version: 1,
      );
      const medicine = MedicationSummary(
        displayName: 'Napa',
        form: 'TABLET',
        id: 'medication-1',
        quantityLabel: '1 tablet',
        status: 'ACTIVE',
        strengthLabel: '500 mg',
      );
      final now = DateTime.now();
      final localDate =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final occurrence = DoseOccurrenceSummary(
        id: 'occurrence-1',
        medicationName: medicine.displayName,
        plannedAt: now.subtract(const Duration(minutes: 1)),
        plannedLocalDateTime: '${localDate}T08:00',
        quantityLabel: medicine.quantityLabel,
        status: 'SCHEDULED',
        version: 1,
      );
      await store.cacheProfiles([profile]);
      await store.cacheMedications(profile.id, [medicine]);
      await store.cacheServerOccurrences(profile.id, [occurrence]);
      final doseSync = DoseSyncCoordinator(
        accessToken: () async => 'access-1',
        backgroundScheduler: const NoopBackgroundSyncScheduler(),
        gateway: const UnavailableDoseSyncGateway(),
        installationId: () async => 'installation-1',
        refreshAccessToken: () async => 'access-2',
        store: store,
      );
      final coordinator = PatientMedicationCoordinator(
        accessToken: 'access-1',
        doseSync: doseSync,
        gateway: _OfflinePatientGateway(),
        reminderScheduler: const UnsupportedReminderScheduler(),
      );
      addTearDown(coordinator.dispose);

      await coordinator.initialize();

      expect(coordinator.status, PatientMedicationStatus.ready);
      expect(coordinator.usingOfflineCache, isTrue);
      expect(coordinator.profile?.displayName, profile.displayName);
      expect(coordinator.medications.single.displayName, medicine.displayName);
      expect(coordinator.doseOccurrences.single.id, occurrence.id);
    },
  );

  test('shows a valid empty cached plan while the API is offline', () async {
    final database = CareMateLocalDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final store = DriftDoseMutationStore(database);
    await store.cacheProfiles(const [
      PatientProfile(
        displayName: 'Abu Sufyan',
        id: 'profile-1',
        timezone: 'Asia/Dhaka',
        version: 1,
      ),
    ]);
    final coordinator = PatientMedicationCoordinator(
      accessToken: 'cached-access',
      doseSync: DoseSyncCoordinator(
        accessToken: () async => 'cached-access',
        backgroundScheduler: const NoopBackgroundSyncScheduler(),
        gateway: const UnavailableDoseSyncGateway(),
        installationId: () async => 'installation-1',
        refreshAccessToken: () async => 'access-2',
        store: store,
      ),
      gateway: _OfflinePatientGateway(),
      reminderScheduler: const UnsupportedReminderScheduler(),
    );
    addTearDown(coordinator.dispose);

    await coordinator.initialize();

    expect(coordinator.status, PatientMedicationStatus.ready);
    expect(coordinator.usingOfflineCache, isTrue);
    expect(coordinator.medications, isEmpty);
    expect(coordinator.doseOccurrences, isEmpty);
  });
}

class _OfflinePatientGateway extends InMemoryPatientMedicationGateway {
  @override
  Future<List<PatientProfile>> listProfiles(String accessToken) =>
      throw const AuthFailure('NETWORK_UNAVAILABLE', 'Offline');

  @override
  Future<List<MedicationSummary>> listMedications({
    required String accessToken,
    required String profileId,
  }) => throw const AuthFailure('NETWORK_UNAVAILABLE', 'Offline');

  @override
  Future<List<DoseOccurrenceSummary>> listDoseOccurrences({
    required String accessToken,
    required DateTime from,
    required String profileId,
    required DateTime to,
  }) => throw const AuthFailure('NETWORK_UNAVAILABLE', 'Offline');
}
