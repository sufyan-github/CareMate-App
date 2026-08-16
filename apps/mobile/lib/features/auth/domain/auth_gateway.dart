import 'package:caremate/features/auth/domain/auth_models.dart';

abstract interface class AuthGateway {
  Future<AuthChallenge> requestOtp({
    required String deviceInstallationId,
    required String locale,
    required String phoneNumber,
  });

  Future<AuthSession> verifyOtp({
    required String challengeId,
    required AuthDevice device,
    required String otp,
  });

  Future<AuthSession> refresh(String refreshToken);

  Future<void> logout(String accessToken);
}
