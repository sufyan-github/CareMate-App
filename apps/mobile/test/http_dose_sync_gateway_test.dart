import 'dart:convert';

import 'package:caremate/features/medications/domain/patient_medication_models.dart';
import 'package:caremate/features/sync/data/http_dose_sync_gateway.dart';
import 'package:caremate/features/sync/domain/dose_sync_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'pushes an immutable dose mutation batch and parses authority',
    () async {
      final gateway = HttpDoseSyncGateway(
        baseUrl: 'http://caremate.test/api/v1',
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/v1/sync/mutations:batch');
          expect(request.headers['authorization'], 'Bearer access-1');
          expect(jsonDecode(request.body), {
            'mutations': [
              {
                'baseVersion': 1,
                'clientAt': '2026-08-17T02:05:00.000Z',
                'command': 'SNOOZE',
                'entityId': 'occurrence-1',
                'entityType': 'DOSE_OCCURRENCE',
                'installationId': 'installation-1',
                'mutationId': '01K2LOCALMUTATION0000000001',
                'payload': {'snoozeMinutes': 10},
              },
            ],
          });
          return http.Response(
            jsonEncode({
              'data': {
                'results': [
                  {
                    'authoritative': {
                      'confirmedAt': null,
                      'id': 'occurrence-1',
                      'missedAt': null,
                      'reminderSentAt': '2026-08-17T02:05:00.000Z',
                      'responseDueAt': '2026-08-17T03:15:00.000Z',
                      'snoozeCount': 1,
                      'snoozedUntil': '2026-08-17T02:15:00.000Z',
                      'status': 'SNOOZED',
                      'timingClassification': null,
                      'version': 2,
                    },
                    'mutationId': '01K2LOCALMUTATION0000000001',
                    'status': 'ACCEPTED',
                  },
                ],
              },
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final results = await gateway.push('access-1', [
        DoseSyncMutation(
          action: DoseAction.snooze,
          clientAt: DateTime.parse('2026-08-17T02:05:00.000Z'),
          expectedVersion: 1,
          id: '01K2LOCALMUTATION0000000001',
          installationId: 'installation-1',
          occurrenceId: 'occurrence-1',
          snoozeMinutes: 10,
        ),
      ]);

      expect(results.single.status, SyncMutationStatus.accepted);
      expect(results.single.authoritative?.status, 'SNOOZED');
      expect(results.single.authoritative?.version, 2);
    },
  );

  test(
    'registers only installation metadata through its narrow endpoint',
    () async {
      final gateway = HttpDoseSyncGateway(
        baseUrl: 'http://caremate.test/api/v1',
        client: MockClient((request) async {
          expect(request.method, 'PUT');
          expect(request.url.path, '/api/v1/devices/installation-1');
          expect(jsonDecode(request.body), {
            'appVersion': '1.0.0',
            'deviceName': 'Android phone',
            'locale': 'bn-BD',
            'platform': 'ANDROID',
          });
          return http.Response(
            jsonEncode({
              'data': {'status': 'ACTIVE'},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      await gateway.registerInstallation(
        accessToken: 'access-1',
        appVersion: '1.0.0',
        deviceName: 'Android phone',
        installationId: 'installation-1',
        locale: 'bn-BD',
        platform: 'ANDROID',
      );
    },
  );
}
