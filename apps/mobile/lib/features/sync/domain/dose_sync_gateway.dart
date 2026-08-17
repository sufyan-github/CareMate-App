import 'package:caremate/features/auth/domain/auth_models.dart';
import 'package:caremate/features/sync/domain/dose_sync_models.dart';

abstract interface class DoseSyncGateway {
  Future<List<DoseSyncResult>> push(
    String accessToken,
    List<DoseSyncMutation> mutations,
  );

  Future<void> registerInstallation({
    required String accessToken,
    required String appVersion,
    required String deviceName,
    required String installationId,
    required String locale,
    required String platform,
    String? pushToken,
  });
}

class UnavailableDoseSyncGateway implements DoseSyncGateway {
  const UnavailableDoseSyncGateway();

  @override
  Future<List<DoseSyncResult>> push(
    String accessToken,
    List<DoseSyncMutation> mutations,
  ) => throw const AuthFailure(
    'NETWORK_UNAVAILABLE',
    'Changes are safe on this phone and waiting to sync.',
  );

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
