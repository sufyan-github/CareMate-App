import 'package:caremate/features/auth/application/auth_coordinator.dart';
import 'package:caremate/features/auth/domain/auth_gateway.dart';
import 'package:caremate/features/auth/domain/auth_models.dart';
import 'package:caremate/features/auth/domain/session_store.dart';

AuthCoordinator authenticatedCoordinator() => AuthCoordinator(
  gateway: _RestorableAuthGateway(),
  sessionStore: _ExistingSessionStore(),
);

AuthCoordinator signedOutCoordinator() => AuthCoordinator(
  gateway: _RestorableAuthGateway(),
  sessionStore: _EmptySessionStore(),
);

class _RestorableAuthGateway implements AuthGateway {
  @override
  Future<void> logout(String accessToken) async {}

  @override
  Future<AuthSession> refresh(String refreshToken) async => const AuthSession(
    accessToken: 'restored-access',
    refreshToken: 'rotated-refresh',
    userId: 'test-user',
  );

  @override
  Future<AuthChallenge> requestOtp({
    required String deviceInstallationId,
    required String locale,
    required String phoneNumber,
  }) => throw UnimplementedError();

  @override
  Future<AuthSession> verifyOtp({
    required String challengeId,
    required AuthDevice device,
    required String otp,
  }) => throw UnimplementedError();
}

class _ExistingSessionStore implements SessionStore {
  String? _refreshToken = 'existing-refresh';

  @override
  Future<void> clear() async => _refreshToken = null;

  @override
  Future<String> installationId() async => 'test-installation';

  @override
  Future<String?> readRefreshToken() async => _refreshToken;

  @override
  Future<void> writeRefreshToken(String token) async => _refreshToken = token;
}

class _EmptySessionStore implements SessionStore {
  @override
  Future<void> clear() async {}

  @override
  Future<String> installationId() async => 'test-installation';

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> writeRefreshToken(String token) async {}
}
