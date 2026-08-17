import 'dart:convert';

import 'package:caremate/features/auth/domain/auth_models.dart';
import 'package:caremate/features/sync/domain/dose_sync_gateway.dart';
import 'package:caremate/features/sync/domain/dose_sync_models.dart';
import 'package:http/http.dart' as http;

class HttpDoseSyncGateway implements DoseSyncGateway {
  HttpDoseSyncGateway({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  @override
  Future<List<DoseSyncResult>> push(
    String accessToken,
    List<DoseSyncMutation> mutations,
  ) async {
    final body = await _request('POST', '/sync/mutations:batch', accessToken, {
      'mutations': mutations
          .map(
            (mutation) => {
              'baseVersion': mutation.expectedVersion,
              'clientAt': mutation.clientAt.toUtc().toIso8601String(),
              'command': mutation.action.name.toUpperCase(),
              'entityId': mutation.occurrenceId,
              'entityType': 'DOSE_OCCURRENCE',
              'installationId': mutation.installationId,
              'mutationId': mutation.id,
              if (mutation.reason != null || mutation.snoozeMinutes != null)
                'payload': {
                  if (mutation.reason != null) 'reason': mutation.reason,
                  if (mutation.snoozeMinutes != null)
                    'snoozeMinutes': mutation.snoozeMinutes,
                },
            },
          )
          .toList(growable: false),
    });
    final data = body['data'] as Map<String, dynamic>;
    return (data['results'] as List<dynamic>)
        .map((item) => _result(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<void> registerInstallation({
    required String accessToken,
    required String appVersion,
    required String deviceName,
    required String installationId,
    required String locale,
    required String platform,
    String? pushToken,
  }) async {
    await _request('PUT', '/devices/$installationId', accessToken, {
      'appVersion': appVersion,
      'deviceName': deviceName,
      'locale': locale,
      'platform': platform,
      'pushToken': ?pushToken,
    });
  }

  DoseSyncResult _result(Map<String, dynamic> data) {
    final authoritative = data['authoritative'] as Map<String, dynamic>?;
    final error = data['error'] as Map<String, dynamic>?;
    return DoseSyncResult(
      authoritative: authoritative == null
          ? null
          : AuthoritativeDoseState(
              confirmedAt: _optionalDate(authoritative['confirmedAt']),
              id: authoritative['id'] as String,
              missedAt: _optionalDate(authoritative['missedAt']),
              reminderSentAt: _optionalDate(authoritative['reminderSentAt']),
              responseDueAt: _optionalDate(authoritative['responseDueAt']),
              snoozeCount: authoritative['snoozeCount'] as int? ?? 0,
              snoozedUntil: _optionalDate(authoritative['snoozedUntil']),
              status: authoritative['status'] as String,
              timingClassification:
                  authoritative['timingClassification'] as String?,
              version: authoritative['version'] as int,
            ),
      errorCode: error?['code'] as String?,
      errorMessage: error?['message'] as String?,
      mutationId: data['mutationId'] as String,
      status: switch (data['status'] as String) {
        'ACCEPTED' => SyncMutationStatus.accepted,
        'ALREADY_APPLIED' => SyncMutationStatus.alreadyApplied,
        'CONFLICT' => SyncMutationStatus.conflict,
        'REJECTED' => SyncMutationStatus.rejected,
        'RETRY_LATER' => SyncMutationStatus.retryLater,
        final status => throw FormatException('Unknown sync status: $status'),
      },
    );
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path,
    String accessToken,
    Map<String, dynamic> payload,
  ) async {
    try {
      final request = http.Request(method, Uri.parse('$baseUrl$path'))
        ..headers.addAll({
          'authorization': 'Bearer $accessToken',
          'content-type': 'application/json',
        })
        ..body = jsonEncode(payload);
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamed);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = body['error'] as Map<String, dynamic>? ?? const {};
        throw AuthFailure(
          error['code'] as String? ?? 'SYNC_REQUEST_FAILED',
          error['message'] as String? ?? 'Could not sync CareMate changes.',
        );
      }
      return body;
    } on AuthFailure {
      rethrow;
    } on Exception {
      throw const AuthFailure(
        'NETWORK_UNAVAILABLE',
        'Changes are safe on this phone and will sync when CareMate can reach the server.',
      );
    }
  }

  DateTime? _optionalDate(Object? value) =>
      value is String ? DateTime.parse(value) : null;
}
