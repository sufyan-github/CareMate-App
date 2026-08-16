import 'dart:convert';

import 'package:caremate/features/care/domain/care_access_gateway.dart';
import 'package:http/http.dart' as http;

class HttpCareAccessGateway implements CareAccessGateway {
  HttpCareAccessGateway({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  @override
  Future<List<CareInvitation>> listForProfile({
    required String accessToken,
    required String profileId,
  }) async => _list(
    await _request(
      'GET',
      '/patient-profiles/$profileId/care-invitations',
      accessToken,
    ),
  );

  @override
  Future<CareInvitation> createInvitation({
    required String accessToken,
    required String phoneNumber,
    required String profileId,
    required CarePermissions permissions,
  }) async => _single(
    await _request(
      'POST',
      '/patient-profiles/$profileId/care-invitations',
      accessToken,
      {'phoneNumber': phoneNumber, 'permissions': permissions.toJson()},
    ),
  );

  @override
  Future<CareInvitation> revoke({
    required String accessToken,
    required String invitationId,
  }) async => _single(
    await _request(
      'PATCH',
      '/care-invitations/$invitationId/revoke',
      accessToken,
    ),
  );

  @override
  Future<List<CareInvitation>> listIncoming({
    required String accessToken,
  }) async =>
      _list(await _request('GET', '/care-invitations/incoming', accessToken));

  @override
  Future<CareInvitation> accept({
    required String accessToken,
    required String invitationId,
  }) async => _single(
    await _request(
      'PATCH',
      '/care-invitations/$invitationId/accept',
      accessToken,
    ),
  );

  @override
  Future<CareInvitation> decline({
    required String accessToken,
    required String invitationId,
  }) async => _single(
    await _request(
      'PATCH',
      '/care-invitations/$invitationId/decline',
      accessToken,
    ),
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
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = body['error'] as Map<String, dynamic>? ?? const {};
        throw CareAccessFailure(
          _errorMessage(error['message'] ?? body['message']) ??
              'Could not update caregiver access. Try again.',
        );
      }
      return body;
    } on CareAccessFailure {
      rethrow;
    } on Exception {
      throw const CareAccessFailure(
        'Could not reach the CareMate server. Make sure the API is running and try again.',
      );
    }
  }

  CareInvitation _single(Map<String, dynamic> body) =>
      CareInvitation.fromJson(body['data'] as Map<String, dynamic>);

  List<CareInvitation> _list(Map<String, dynamic> body) =>
      (body['data'] as List<dynamic>)
          .map((item) => CareInvitation.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);

  String? _errorMessage(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value;
    if (value is List<dynamic>) {
      final messages = value.map((item) => item.toString()).join(' ');
      return messages.trim().isEmpty ? null : messages;
    }
    return null;
  }
}
