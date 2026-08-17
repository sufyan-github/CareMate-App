import 'dart:convert';

import 'package:caremate/features/auth/domain/auth_gateway.dart';
import 'package:caremate/features/auth/domain/auth_models.dart';
import 'package:http/http.dart' as http;

class HttpAuthGateway implements AuthGateway {
  HttpAuthGateway({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  @override
  Future<AuthChallenge> requestOtp({
    required String deviceInstallationId,
    required String locale,
    required String phoneNumber,
  }) async {
    final body = await _post('/auth/otp/requests', {
      'deviceInstallationId': deviceInstallationId,
      'locale': locale,
      'phoneNumber': phoneNumber,
      'purpose': 'LOGIN',
    });
    final data = body['data'] as Map<String, dynamic>;
    final meta = body['meta'] as Map<String, dynamic>? ?? const {};
    return AuthChallenge(
      challengeId: data['challengeId'] as String,
      deliveryHint: data['deliveryHint'] as String,
      expiresInSeconds: data['expiresInSeconds'] as int,
      isDevelopment: meta['deliveryMode'] == 'DEVELOPMENT',
      resendAfterSeconds: data['resendAfterSeconds'] as int,
    );
  }

  @override
  Future<AuthSession> verifyOtp({
    required String challengeId,
    required AuthDevice device,
    required String otp,
  }) async {
    final body = await _post('/auth/otp/verifications', {
      'challengeId': challengeId,
      'device': {
        'appVersion': device.appVersion,
        'deviceName': device.deviceName,
        'installationId': device.installationId,
        'platform': device.platform,
      },
      'otp': otp,
    });
    final data = body['data'] as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>;
    return AuthSession(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      userId: user['id'] as String,
    );
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    final body = await _post('/auth/token/refresh', {
      'refreshToken': refreshToken,
    });
    final data = body['data'] as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>;
    return AuthSession(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      userId: user['id'] as String,
    );
  }

  @override
  Future<void> logout(String accessToken) async {
    try {
      await _client
          .post(
            Uri.parse('$baseUrl/auth/logout'),
            headers: {'authorization': 'Bearer $accessToken'},
          )
          .timeout(const Duration(seconds: 15));
    } on Exception {
      // Local credentials are still cleared. Server sessions expire and refresh
      // rotation prevents a stale client from silently restoring this session.
    }
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> payload,
  ) async {
    http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$baseUrl$path'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));
    } on Exception {
      throw const AuthFailure(
        'NETWORK_UNAVAILABLE',
        'Could not reach the CareMate server. Make sure the API is running and try again.',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = decoded['error'] as Map<String, dynamic>? ?? const {};
      throw AuthFailure(
        error['code'] as String? ?? 'AUTH_FAILED',
        error['message'] as String? ?? 'Something went wrong. Try again.',
      );
    }
    return decoded;
  }
}
