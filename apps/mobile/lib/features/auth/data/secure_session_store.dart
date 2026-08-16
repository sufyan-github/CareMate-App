import 'dart:math';

import 'package:caremate/features/auth/domain/session_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureSessionStore implements SessionStore {
  SecureSessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _installationKey = 'caremate.installation-id';
  static const _refreshTokenKey = 'caremate.refresh-token';
  static const _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

  final FlutterSecureStorage _storage;

  @override
  Future<void> clear() => _storage.delete(key: _refreshTokenKey);

  @override
  Future<String> installationId() async {
    final existing = await _storage.read(key: _installationKey);
    if (existing != null) return existing;

    final random = Random.secure();
    final generated = List.generate(
      26,
      (_) => _alphabet[random.nextInt(_alphabet.length)],
    ).join();
    await _storage.write(key: _installationKey, value: generated);
    return generated;
  }

  @override
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  @override
  Future<void> writeRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);
}
