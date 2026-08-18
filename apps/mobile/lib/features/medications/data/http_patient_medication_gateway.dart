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

  @override
  Future<MedicationSchedulePlan> createSchedule({
    required String accessToken,
    required String activation,
    required MedicationScheduleDraft draft,
    required String medicationId,
  }) async {
    final body = await _request(
      'POST',
      '/medications/$medicationId/schedules',
      accessToken,
      {
        'activation': activation,
        'daysOfWeek': draft.daysOfWeek,
        if (draft.endDate case final endDate?) 'endDate': _localDate(endDate),
        'excludedDates': draft.excludedDates.map(_localDate).toList(),
        'openEnded': draft.endDate == null,
        'recurrence': draft.recurrence,
        'startDate': _localDate(draft.startDate),
        'times': draft.times,
        'timezone': draft.timezone,
      },
    );
    final data = body['data'] as Map<String, dynamic>;
    final scheduleData = data['schedule'] as Map<String, dynamic>?;
    return MedicationSchedulePlan(
      occurrences: (data['occurrences'] as List<dynamic>)
          .map(
            (item) => ScheduleOccurrencePreview(
              plannedAt: DateTime.parse(
                (item as Map<String, dynamic>)['plannedAt'] as String,
              ),
              plannedLocalDateTime: item['plannedLocalDateTime'] as String,
            ),
          )
          .toList(growable: false),
      quantityRequired: (data['quantityRequired'] as num).toDouble(),
      quantityUnit: data['quantityUnit'] as String,
      schedule: scheduleData == null ? null : _schedule(scheduleData),
    );
  }

  @override
  Future<List<DoseOccurrenceSummary>> listDoseOccurrences({
    required String accessToken,
    required DateTime from,
    required String profileId,
    required DateTime to,
  }) async {
    final uri =
        '/patient-profiles/$profileId/dose-occurrences?from=${_localDate(from)}&to=${_localDate(to)}';
    final body = await _request('GET', uri, accessToken);
    return (body['data'] as List<dynamic>)
        .map((item) {
          final data = item as Map<String, dynamic>;
          final medication = data['medication'] as Map<String, dynamic>;
          return DoseOccurrenceSummary(
            confirmedAt: _optionalDate(data['confirmedAt']),
            id: data['id'] as String,
            medicationName: medication['displayName'] as String,
            missedAt: _optionalDate(data['missedAt']),
            plannedAt: DateTime.parse(data['plannedAt'] as String),
            plannedLocalDateTime: data['plannedLocalDateTime'] as String,
            quantityLabel:
                '${data['quantityValue']} ${data['quantityUnit'].toString().toLowerCase()}',
            reminderSentAt: _optionalDate(data['reminderSentAt']),
            responseDueAt: _optionalDate(data['responseDueAt']),
            ruleRevision: data['ruleRevision'] as int? ?? 1,
            snoozeCount: data['snoozeCount'] as int? ?? 0,
            snoozedUntil: _optionalDate(data['snoozedUntil']),
            status: data['status'] as String? ?? 'NOT_SHARED',
            timingClassification: data['timingClassification'] as String?,
            version: data['version'] as int,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<DoseOccurrenceSummary> commandDose({
    required String accessToken,
    required DoseCommand command,
  }) async {
    final payload = <String, dynamic>{
      if (command.reason != null) 'reason': command.reason,
      if (command.snoozeMinutes != null) 'snoozeMinutes': command.snoozeMinutes,
    };
    final body = await _request(
      'POST',
      '/dose-occurrences/${command.occurrence.id}/commands',
      accessToken,
      {
        'clientAt': command.clientAt.toUtc().toIso8601String(),
        'clientMutationId': command.clientMutationId,
        'command': command.action.name.toUpperCase(),
        'expectedVersion': command.occurrence.version,
        if (payload.isNotEmpty) 'payload': payload,
      },
    );
    final data = body['data'] as Map<String, dynamic>;
    return DoseOccurrenceSummary(
      confirmedAt: _optionalDate(data['confirmedAt']),
      id: command.occurrence.id,
      medicationName: command.occurrence.medicationName,
      missedAt: _optionalDate(data['missedAt']),
      plannedAt: command.occurrence.plannedAt,
      plannedLocalDateTime: command.occurrence.plannedLocalDateTime,
      quantityLabel: command.occurrence.quantityLabel,
      reminderSentAt: _optionalDate(data['reminderSentAt']),
      responseDueAt: _optionalDate(data['responseDueAt']),
      ruleRevision: command.occurrence.ruleRevision,
      snoozeCount: data['snoozeCount'] as int? ?? 0,
      snoozedUntil: _optionalDate(data['snoozedUntil']),
      status: data['status'] as String,
      timingClassification: data['timingClassification'] as String?,
      version: data['version'] as int,
    );
  }

  @override
  Future<MedicationScheduleSummary> updateSchedule({
    required String accessToken,
    required MedicationScheduleDraft draft,
    required MedicationScheduleSummary schedule,
  }) async {
    final body =
        await _request('PATCH', '/schedules/${schedule.id}', accessToken, {
          'daysOfWeek': draft.daysOfWeek,
          if (draft.endDate case final endDate?) 'endDate': _localDate(endDate),
          'excludedDates': draft.excludedDates.map(_localDate).toList(),
          'expectedVersion': schedule.version,
          'openEnded': draft.endDate == null,
          'recurrence': draft.recurrence,
          'startDate': _localDate(draft.startDate),
          'times': draft.times,
        });
    return _schedule(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<MedicationScheduleSummary> commandSchedule({
    required String accessToken,
    required ScheduleAction action,
    required MedicationScheduleSummary schedule,
  }) async {
    final body = await _request(
      'POST',
      '/schedules/${schedule.id}/${action.name}',
      accessToken,
      {'expectedVersion': schedule.version},
    );
    return _schedule(body['data'] as Map<String, dynamic>);
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
    canReceiveMissedDoseAlerts:
        (data['permissions']
                as Map<String, dynamic>?)?['canReceiveMissedDoseAlerts']
            as bool? ??
        false,
    canViewMedicationPlan:
        (data['permissions'] as Map<String, dynamic>?)?['canViewMedicationPlan']
            as bool? ??
        true,
    displayName: data['displayName'] as String,
    id: data['id'] as String,
    missedDoseGraceMinutes: data['missedDoseGraceMinutes'] as int? ?? 45,
    timezone: data['timezone'] as String,
    version: data['version'] as int,
  );

  MedicationSummary _medication(Map<String, dynamic> data) {
    final instruction = data['instructions'] as Map<String, dynamic>;
    final strength = data['strengthValue'];
    return MedicationSummary(
      activeSchedule: data['activeSchedule'] == null
          ? null
          : _schedule(data['activeSchedule'] as Map<String, dynamic>),
      displayName: data['displayName'] as String,
      form: data['form'] as String,
      id: data['id'] as String,
      mealRelation: instruction['mealRelation'] as String? ?? 'UNSPECIFIED',
      quantityLabel:
          '${instruction['quantityValue']} ${instruction['quantityUnit'].toString().toLowerCase()}',
      status: data['status'] as String,
      strengthLabel: strength == null
          ? 'Strength not specified'
          : '$strength ${data['strengthUnit'] ?? ''}'.trim(),
    );
  }

  MedicationScheduleSummary _schedule(Map<String, dynamic> data) =>
      MedicationScheduleSummary(
        daysOfWeek: (data['daysOfWeek'] as List<dynamic>? ?? const [])
            .cast<int>(),
        endDate: data['endDate'] == null
            ? null
            : DateTime.parse(data['endDate'] as String),
        excludedDates: (data['excludedDates'] as List<dynamic>? ?? const [])
            .cast<String>()
            .map(DateTime.parse)
            .toList(growable: false),
        id: data['id'] as String,
        revision: data['revision'] as int,
        recurrence: data['recurrence'] as String? ?? 'DAILY',
        startDate: DateTime.parse(data['startDate'] as String),
        status: data['status'] as String,
        times: (data['times'] as List<dynamic>).cast<String>(),
        timezone: data['timezone'] as String,
        version: data['version'] as int,
      );

  String _localDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  DateTime? _optionalDate(Object? value) =>
      value is String ? DateTime.parse(value) : null;
}
