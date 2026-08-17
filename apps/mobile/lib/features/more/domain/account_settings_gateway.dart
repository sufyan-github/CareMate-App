class AccountPreferences {
  const AccountPreferences({
    required this.allowAnalytics,
    required this.locale,
    required this.showMedicineOnLockScreen,
  });

  final bool allowAnalytics;
  final String locale;
  final bool showMedicineOnLockScreen;

  factory AccountPreferences.fromJson(Map<String, dynamic> json) =>
      AccountPreferences(
        allowAnalytics: json['allowAnalytics'] as bool? ?? false,
        locale: json['locale'] as String? ?? 'en-BD',
        showMedicineOnLockScreen:
            json['showMedicineOnLockScreen'] as bool? ?? false,
      );
}

class DeviceSession {
  const DeviceSession({
    required this.appVersion,
    required this.current,
    required this.deviceName,
    required this.id,
    required this.lastSeenAt,
    required this.platform,
    required this.status,
  });

  final String appVersion;
  final bool current;
  final String deviceName;
  final String id;
  final DateTime lastSeenAt;
  final String platform;
  final String status;

  factory DeviceSession.fromJson(Map<String, dynamic> json) => DeviceSession(
    appVersion: json['appVersion'] as String? ?? '',
    current: json['current'] as bool? ?? false,
    deviceName: json['deviceName'] as String? ?? 'Android device',
    id: json['id'] as String,
    lastSeenAt: DateTime.parse(json['lastSeenAt'] as String),
    platform: json['platform'] as String? ?? 'ANDROID',
    status: json['status'] as String? ?? 'ACTIVE',
  );
}

class AccountSettingsFailure implements Exception {
  const AccountSettingsFailure(this.message);

  final String message;
}

abstract class AccountSettingsGateway {
  Future<AccountPreferences> getPreferences(String accessToken);

  Future<AccountPreferences> updatePreferences({
    required String accessToken,
    bool? allowAnalytics,
    String? locale,
    bool? showMedicineOnLockScreen,
  });

  Future<List<DeviceSession>> listSessions(String accessToken);

  Future<void> revokeSession({
    required String accessToken,
    required String sessionId,
  });

  Future<void> logoutAll(String accessToken);

  Future<void> requestAccountDeletion(String accessToken);
}
