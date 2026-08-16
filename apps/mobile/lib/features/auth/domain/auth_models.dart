class AuthChallenge {
  const AuthChallenge({
    required this.challengeId,
    required this.deliveryHint,
    required this.expiresInSeconds,
    required this.isDevelopment,
    required this.resendAfterSeconds,
  });

  final String challengeId;
  final String deliveryHint;
  final int expiresInSeconds;
  final bool isDevelopment;
  final int resendAfterSeconds;
}

class AuthDevice {
  const AuthDevice({
    required this.appVersion,
    required this.deviceName,
    required this.installationId,
    this.platform = 'ANDROID',
  });

  final String appVersion;
  final String deviceName;
  final String installationId;
  final String platform;
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
  });

  final String accessToken;
  final String refreshToken;
  final String userId;
}

class AuthFailure implements Exception {
  const AuthFailure(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}
