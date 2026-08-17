import 'dart:math';

import 'package:caremate/features/auth/domain/auth_models.dart';
import 'package:caremate/features/auth/domain/session_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureSessionStore implements SessionStore {
  SecureSessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _installationKey = 'caremate.installation-id';
  static const _accessTokenKey = 'caremate.access-token';
  static const _refreshTokenKey = 'caremate.refresh-token';
  static const _userIdKey = 'caremate.user-id';
  static const _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

  final FlutterSecureStorage _storage;

  @override
  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _refreshTokenKey);
  }

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
  Future<AuthSession?> readSession() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    final userId = await _storage.read(key: _userIdKey);
    if (accessToken == null || refreshToken == null || userId == null) {
      return null;
    }
    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
    );
  }

  @override
  Future<void> writeSession(AuthSession session) async {
    await _storage.write(key: _accessTokenKey, value: session.accessToken);
    await _storage.write(key: _userIdKey, value: session.userId);
    await _storage.write(key: _refreshTokenKey, value: session.refreshToken);
  }
}
