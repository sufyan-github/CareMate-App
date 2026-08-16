import 'dart:convert';

import 'package:caremate/features/auth/domain/auth_models.dart';
import 'package:caremate/features/medications/domain/patient_medication_gateway.dart';
import 'package:caremate/features/medications/domain/patient_medication_models.dart';
import 'package:http/http.dart' as http;

class HttpPatientMedicationGateway implements PatientMedicationGateway {
  HttpPatientMedicationGateway({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  @override
  Future<List<PatientProfile>> listProfiles(String accessToken) async {
    final body = await _request('GET', '/patient-profiles', accessToken);
    return (body['data'] as List<dynamic>)
        .map((item) => _profile(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<PatientProfile> createProfile({
    required String accessToken,
    required String displayName,
    required String timezone,
  }) async {
    final body = await _request('POST', '/patient-profiles', accessToken, {
      'displayName': displayName,
      'timezone': timezone,
    });
    return _profile(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<MedicationSummary>> listMedications({
    required String accessToken,
    required String profileId,
  }) async {
    final body = await _request(
      'GET',
      '/patient-profiles/$profileId/medications',
      accessToken,
    );
    return (body['data'] as List<dynamic>)
        .map((item) => _medication(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<MedicationSummary> createMedication({
    required String accessToken,
    required MedicationDraft draft,
    required String profileId,
  }) async {
    final body = await _request(
      'POST',
      '/patient-profiles/$profileId/medications',
      accessToken,
      {
        'displayName': draft.displayName,
        'form': draft.form,
        'instructions': {
          'mealRelation': draft.mealRelation,
          'quantityUnit': draft.quantityUnit,
          'quantityValue': draft.quantityValue,
          'route': draft.route,
          if (draft.sourceText != null) 'sourceText': draft.sourceText,
        },
        if (draft.notes != null) 'notes': draft.notes,
        if (draft.strengthUnit != null) 'strengthUnit': draft.strengthUnit,
        if (draft.strengthValue != null) 'strengthValue': draft.strengthValue,
      },
    );
    return _medication(body['data'] as Map<String, dynamic>);
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
        throw AuthFailure(
          error['code'] as String? ?? 'REQUEST_FAILED',
          error['message'] as String? ?? 'Could not save your changes.',
        );
      }
      return body;
    } on AuthFailure {
      rethrow;
    } on Exception {
      throw const AuthFailure(
        'NETWORK_UNAVAILABLE',
        'Could not reach the CareMate server. Make sure the API is running and try again.',
      );
    }
  }

  PatientProfile _profile(Map<String, dynamic> data) => PatientProfile(
    accessRole: data['accessRole'] as String? ?? 'OWNER',
    canManage: data['canManage'] as bool? ?? true,
    displayName: data['displayName'] as String,
    id: data['id'] as String,
    timezone: data['timezone'] as String,
    version: data['version'] as int,
  );

  MedicationSummary _medication(Map<String, dynamic> data) {
    final instruction = data['instructions'] as Map<String, dynamic>;
    final strength = data['strengthValue'];
    return MedicationSummary(
      displayName: data['displayName'] as String,
      form: data['form'] as String,
      id: data['id'] as String,
      quantityLabel:
          '${instruction['quantityValue']} ${instruction['quantityUnit'].toString().toLowerCase()}',
      status: data['status'] as String,
      strengthLabel: strength == null
          ? 'Strength not specified'
          : '$strength ${data['strengthUnit'] ?? ''}'.trim(),
    );
  }
}
