import 'dart:convert';

import 'package:caremate/features/more/domain/account_settings_gateway.dart';
import 'package:http/http.dart' as http;

class HttpAccountSettingsGateway implements AccountSettingsGateway {
  HttpAccountSettingsGateway({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  @override
  Future<AccountPreferences> getPreferences(String accessToken) async =>
      _preferences(await _request('GET', '/me/preferences', accessToken));

  @override
  Future<AccountPreferences> updatePreferences({
    required String accessToken,
    bool? allowAnalytics,
    String? locale,
    bool? showMedicineOnLockScreen,
    bool? simpleMode,
    bool? voicePromptsEnabled,
  }) async {
    final payload = <String, dynamic>{};
    if (allowAnalytics != null) payload['allowAnalytics'] = allowAnalytics;
    if (locale != null) payload['locale'] = locale;
    if (showMedicineOnLockScreen != null) {
      payload['showMedicineOnLockScreen'] = showMedicineOnLockScreen;
    }
    if (simpleMode != null) payload['simpleMode'] = simpleMode;
    if (voicePromptsEnabled != null) {
      payload['voicePromptsEnabled'] = voicePromptsEnabled;
    }
    return _preferences(
      await _request('PATCH', '/me/preferences', accessToken, payload),
    );
  }

  @override
  Future<List<DeviceSession>> listSessions(String accessToken) async {
    final body = await _request('GET', '/me/sessions', accessToken);
    return (body['data'] as List<dynamic>)
        .map((item) => DeviceSession.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<void> revokeSession({
    required String accessToken,
    required String sessionId,
  }) async => _request('DELETE', '/me/sessions/$sessionId', accessToken);

  @override
  Future<void> logoutAll(String accessToken) async =>
      _request('POST', '/auth/logout-all', accessToken);

  @override
  Future<void> requestAccountDeletion(String accessToken) async => _request(
    'POST',
    '/me/deletion-requests',
    accessToken,
    {'confirmation': 'DELETE'},
  );

  Future<Map<String, dynamic>> _request(
    String method,
    String path,
    String accessToken, [
    Map<String, dynamic>? payload,
  ]) async {
    try {
      final request = http.Request(method, Uri.parse('$baseUrl$path'))
        ..headers.addAll({
          'authorization': 'Bearer $accessToken',
          'content-type': 'application/json',
        });
      if (payload != null) request.body = jsonEncode(payload);
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 204) return const {};
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = body['error'] as Map<String, dynamic>? ?? const {};
        throw AccountSettingsFailure(
          _errorMessage(error['message'] ?? body['message']) ??
              'Could not update account settings. Try again.',
        );
      }
      return body;
    } on AccountSettingsFailure {
      rethrow;
    } on Exception {
      throw const AccountSettingsFailure(
        'Could not reach the CareMate server. Make sure the API is running and try again.',
      );
    }
  }

  AccountPreferences _preferences(Map<String, dynamic> body) =>
      AccountPreferences.fromJson(body['data'] as Map<String, dynamic>);

  String? _errorMessage(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value;
    if (value is List<dynamic>) {
      final messages = value.map((item) => item.toString()).join(' ');
      return messages.trim().isEmpty ? null : messages;
    }
    return null;
  }
}
