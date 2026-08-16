abstract interface class SessionStore {
  Future<String> installationId();
  Future<String?> readRefreshToken();
  Future<void> writeRefreshToken(String token);
  Future<void> clear();
}
