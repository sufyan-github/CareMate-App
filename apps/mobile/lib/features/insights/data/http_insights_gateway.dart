import 'dart:convert';

import 'package:caremate/features/insights/domain/insights_gateway.dart';
import 'package:caremate/features/insights/domain/insights_models.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class HttpInsightsGateway implements InsightsGateway {
  HttpInsightsGateway({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  @override
  Future<List<InventoryPositionSummary>> listInventory({
    required String accessToken,
    required String profileId,
  }) async {
    final body = await _request(
      'GET',
      '/patient-profiles/$profileId/inventory',
      accessToken,
    );
    return (body['data'] as List<dynamic>)
        .map(
          (item) =>
              InventoryPositionSummary.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  @override
  Future<InventoryPositionSummary> createStockAdjustment({
    required String accessToken,
    required double delta,
    required String positionId,
    required String quantityUnit,
    required String reason,
  }) async {
    final body = await _request(
      'POST',
      '/inventory/$positionId/adjustments',
      accessToken,
      {
        'delta': delta,
        'idempotencyKey': const Uuid().v7(),
        'quantityUnit': quantityUnit,
        'reason': reason,
      },
    );
    return InventoryPositionSummary.fromJson(
      body['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<AdherenceIndicator> getIndicator({
    required String accessToken,
    required DateTime from,
    required String profileId,
    required DateTime to,
  }) async {
    final query = Uri(
      queryParameters: {'from': _localDate(from), 'to': _localDate(to)},
    ).query;
    final body = await _request(
      'GET',
      '/patient-profiles/$profileId/indicators?$query',
      accessToken,
    );
    return AdherenceIndicator.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<InventoryPositionSummary> updateLowStockThreshold({
    required String accessToken,
    required int expectedVersion,
    required double lowStockThreshold,
    required String positionId,
  }) async {
    final body = await _request(
      'PATCH',
      '/inventory/$positionId',
      accessToken,
      {
        'expectedVersion': expectedVersion,
        'lowStockThreshold': lowStockThreshold,
      },
    );
    return InventoryPositionSummary.fromJson(
      body['data'] as Map<String, dynamic>,
    );
  }

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
        throw InsightsFailure(
          _errorMessage(error['message'] ?? body['message']) ??
              'Could not load insights. Try again.',
        );
      }
      return body;
    } on InsightsFailure {
      rethrow;
    } on Exception {
      throw const InsightsFailure(
        'Could not reach the CareMate server. Check your connection and try again.',
      );
    }
  }

  String _localDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  String? _errorMessage(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value;
    if (value is List<dynamic>) {
      final messages = value.map((item) => item.toString()).join(' ');
      return messages.trim().isEmpty ? null : messages;
    }
    return null;
  }
}
