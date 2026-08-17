import 'dart:convert';

import 'package:caremate/features/medications/data/http_patient_medication_gateway.dart';
import 'package:caremate/features/medications/domain/patient_medication_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'previews a schedule through the authenticated medication endpoint',
    () async {
      final gateway = HttpPatientMedicationGateway(
        baseUrl: 'http://caremate.test/api/v1',
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/v1/medications/med-1/schedules');
          expect(request.headers['authorization'], 'Bearer access-1');
          expect(jsonDecode(request.body), {
            'activation': 'PREVIEW',
            'daysOfWeek': [],
            'endDate': '2026-08-18',
            'excludedDates': [],
            'openEnded': false,
            'recurrence': 'DAILY',
            'startDate': '2026-08-17',
            'times': ['08:00'],
            'timezone': 'Asia/Dhaka',
          });
          return http.Response(
            jsonEncode({
              'data': {
                'activation': 'PREVIEW',
                'occurrences': [
                  {
                    'plannedAt': '2026-08-17T02:00:00.000Z',
                    'plannedLocalDateTime': '2026-08-17T08:00',
                  },
                  {
                    'plannedAt': '2026-08-18T02:00:00.000Z',
                    'plannedLocalDateTime': '2026-08-18T08:00',
                  },
                ],
                'quantityRequired': 2,
                'quantityUnit': 'TABLET',
              },
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final preview = await gateway.createSchedule(
        accessToken: 'access-1',
        activation: 'PREVIEW',
        draft: MedicationScheduleDraft(
          endDate: DateTime(2026, 8, 18),
          startDate: DateTime(2026, 8, 17),
          times: const ['08:00'],
          timezone: 'Asia/Dhaka',
        ),
        medicationId: 'med-1',
      );

      expect(preview.occurrences, hasLength(2));
      expect(preview.quantityRequired, 2);
      expect(preview.schedule, isNull);
    },
  );

  test(
    'sends a versioned pause command and parses the updated schedule',
    () async {
      final current = MedicationScheduleSummary(
        endDate: DateTime(2026, 8, 18),
        id: 'schedule-1',
        revision: 1,
        startDate: DateTime(2026, 8, 17),
        status: 'ACTIVE',
        times: const ['08:00'],
        timezone: 'Asia/Dhaka',
        version: 2,
      );
      final gateway = HttpPatientMedicationGateway(
        baseUrl: 'http://caremate.test/api/v1',
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/v1/schedules/schedule-1/pause');
          expect(jsonDecode(request.body), {'expectedVersion': 2});
          return http.Response(
            jsonEncode({
              'data': {
                'endDate': '2026-08-18',
                'id': 'schedule-1',
                'revision': 1,
                'startDate': '2026-08-17',
                'status': 'PAUSED',
                'times': ['08:00'],
                'timezone': 'Asia/Dhaka',
                'version': 3,
              },
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final paused = await gateway.commandSchedule(
        accessToken: 'access-1',
        action: ScheduleAction.pause,
        schedule: current,
      );

      expect(paused.status, 'PAUSED');
      expect(paused.version, 3);
    },
  );

  test('records a self-reported dose action with an idempotency key', () async {
    final occurrence = DoseOccurrenceSummary(
      id: 'occurrence-1',
      medicationName: 'Napa',
      plannedAt: DateTime.parse('2026-08-17T02:00:00.000Z'),
      plannedLocalDateTime: '2026-08-17T08:00',
      quantityLabel: '1 tablet',
      status: 'REMINDER_SENT',
      version: 2,
    );
    final gateway = HttpPatientMedicationGateway(
      baseUrl: 'http://caremate.test/api/v1',
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.path,
          '/api/v1/dose-occurrences/occurrence-1/commands',
        );
        expect(jsonDecode(request.body), {
          'clientAt': '2026-08-17T02:05:00.000Z',
          'clientMutationId': 'mutation-12345678901234567890',
          'command': 'SNOOZE',
          'expectedVersion': 2,
          'payload': {'snoozeMinutes': 10},
        });
        return http.Response(
          jsonEncode({
            'data': {
              'confirmedAt': null,
              'id': 'occurrence-1',
              'missedAt': null,
              'reminderSentAt': '2026-08-17T02:00:00.000Z',
              'responseDueAt': '2026-08-17T03:15:00.000Z',
              'snoozeCount': 1,
              'snoozedUntil': '2026-08-17T02:15:00.000Z',
              'status': 'SNOOZED',
              'timingClassification': null,
              'version': 3,
            },
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final updated = await gateway.commandDose(
      accessToken: 'access-1',
      command: DoseCommand(
        action: DoseAction.snooze,
        clientAt: DateTime.parse('2026-08-17T02:05:00.000Z'),
        clientMutationId: 'mutation-12345678901234567890',
        occurrence: occurrence,
        snoozeMinutes: 10,
      ),
    );

    expect(updated.status, 'SNOOZED');
    expect(updated.snoozeCount, 1);
    expect(updated.snoozedUntil, DateTime.parse('2026-08-17T02:15:00.000Z'));
    expect(updated.version, 3);
  });
}
