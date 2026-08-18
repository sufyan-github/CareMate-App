import 'package:caremate/features/auth/data/http_auth_gateway.dart';
import 'package:caremate/features/auth/data/device_locale.dart';
import 'package:caremate/features/auth/data/file_refresh_session_lock.dart';
import 'package:caremate/features/auth/data/secure_session_store.dart';
import 'package:caremate/features/auth/domain/auth_models.dart';
import 'package:caremate/features/care/data/flutter_caregiver_alert_notifier.dart';
import 'package:caremate/features/care/data/http_care_access_gateway.dart';
import 'package:caremate/features/medications/data/http_patient_medication_gateway.dart';
import 'package:caremate/features/sync/application/dose_sync_engine.dart';
import 'package:caremate/features/sync/data/drift_dose_mutation_store.dart';
import 'package:caremate/features/sync/data/encrypted_local_database_factory.dart';
import 'package:caremate/features/sync/data/http_dose_sync_gateway.dart';
import 'package:caremate/features/sync/data/workmanager_sync_scheduler.dart';
import 'package:workmanager/workmanager.dart';

const _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000/api/v1',
);

@pragma('vm:entry-point')
void careMateBackgroundSyncDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != careMateDoseSyncTask) return true;
    return runCareMateBackgroundSync();
  });
}

Future<bool> runCareMateBackgroundSync() async {
  final sessionStore = SecureSessionStore();
  try {
    final session = await const FileRefreshSessionLock().synchronized(() async {
      final refreshToken = await sessionStore.readRefreshToken();
      if (refreshToken == null) return null;
      final refreshed = await HttpAuthGateway(
        baseUrl: _apiBaseUrl,
      ).refresh(refreshToken);
      await sessionStore.writeSession(refreshed);
      return refreshed;
    });
    if (session == null) return true;
    final database = await EncryptedLocalDatabaseFactory().open();
    try {
      final store = DriftDoseMutationStore(database);
      final gateway = HttpDoseSyncGateway(baseUrl: _apiBaseUrl);
      await store.bindAccount(session.userId);
      await DoseSyncEngine(
        gateway: gateway,
        store: store,
      ).syncPending(session.accessToken);
      await gateway.registerInstallation(
        accessToken: session.accessToken,
        appVersion: '1.0.0',
        deviceName: 'Android phone',
        installationId: await sessionStore.installationId(),
        locale: careMateDeviceLocale(),
        platform: 'ANDROID',
      );
      try {
        await _pollCaregiverAlerts(session.accessToken);
      } on Object {
        // Dose sync succeeded; caregiver polling can retry on the next run.
      }
    } finally {
      await database.close();
    }
    return true;
  } on AuthFailure catch (failure) {
    if (failure.code == 'NETWORK_UNAVAILABLE') return false;
    if (failure.code.contains('REFRESH') || failure.code.contains('SESSION')) {
      await sessionStore.clear();
    }
    return true;
  } on Exception {
    return false;
  }
}

Future<void> _pollCaregiverAlerts(String accessToken) async {
  final profiles = await HttpPatientMedicationGateway(
    baseUrl: _apiBaseUrl,
  ).listProfiles(accessToken);
  final gateway = HttpCareAccessGateway(baseUrl: _apiBaseUrl);
  final notifier = FlutterCaregiverAlertNotifier();
  final now = DateTime.now();
  for (final profile in profiles.where(
    (profile) => profile.canReceiveMissedDoseAlerts,
  )) {
    final alerts = await gateway.listAlerts(
      accessToken: accessToken,
      profileId: profile.id,
    );
    for (final alert in alerts) {
      final deliveredAt = alert.deliveredAt;
      if (alert.status == 'ACTIVE' &&
          deliveredAt != null &&
          now.difference(deliveredAt).abs() <= const Duration(minutes: 16)) {
        await notifier.show(alert);
      }
    }
  }
}
