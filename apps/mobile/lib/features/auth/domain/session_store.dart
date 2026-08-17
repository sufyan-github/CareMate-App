import 'package:caremate/features/auth/domain/auth_models.dart';

abstract interface class SessionStore {
  Future<String> installationId();
  Future<String?> readRefreshToken();
  Future<AuthSession?> readSession();
  Future<void> writeSession(AuthSession session);
  Future<void> clear();
}
