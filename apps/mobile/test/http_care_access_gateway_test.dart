import 'dart:convert';

import 'package:caremate/features/care/data/http_care_access_gateway.dart';
import 'package:caremate/features/care/domain/care_access_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'creates an authenticated caregiver invitation with permissions',
    () async {
      final gateway = HttpCareAccessGateway(
        baseUrl: 'http://caremate.test/api/v1',
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(
            request.url.path,
            '/api/v1/patient-profiles/profile-1/care-invitations',
          );
          expect(request.headers['authorization'], 'Bearer access-1');
          expect(jsonDecode(request.body), {
            'phoneNumber': '01800123456',
            'permissions': {
              'canReceiveMissedDoseAlerts': true,
              'canViewDoseOutcomes': false,
              'canViewMedicationPlan': true,
            },
          });
          return http.Response(
            jsonEncode({
              'data': {
                'deliveryStatus': 'IN_APP_PENDING',
                'id': 'care-1',
                'inviteePhoneMasked': '••••••3456',
                'patientDisplayName': 'Parent',
                'permissions': {
                  'canReceiveMissedDoseAlerts': true,
                  'canViewMedicationPlan': true,
                },
                'status': 'PENDING',
              },
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final invitation = await gateway.createInvitation(
        accessToken: 'access-1',
        phoneNumber: '01800123456',
        profileId: 'profile-1',
        permissions: const CarePermissions(
          canReceiveMissedDoseAlerts: true,
          canViewMedicationPlan: true,
        ),
      );

      expect(invitation.status, 'PENDING');
      expect(invitation.inviteePhoneMasked, '••••••3456');
    },
  );

  test('lists and updates caregiver alerts and profile alert timing', () async {
    final requests = <http.Request>[];
    final gateway = HttpCareAccessGateway(
      baseUrl: 'http://caremate.test/api/v1',
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.path == '/api/v1/caregiver-alerts') {
          expect(request.url.queryParameters['profileId'], 'profile-1');
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'acknowledgedAt': null,
                  'callPhoneE164': '+8801700123456',
                  'deliveredAt': '2026-08-18T12:00:00.000Z',
                  'generatedAt': '2026-08-18T11:59:58.000Z',
                  'id': 'alert-1',
                  'medicationName': null,
                  'patientDisplayName': 'Parent',
                  'plannedAt': '2026-08-18T11:14:00.000Z',
                  'resolvedAt': null,
                  'resolvedMinutesLate': null,
                  'status': 'ACTIVE',
                },
              ],
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/acknowledge')) {
          return http.Response(jsonEncode({'data': {}}), 200);
        }
        if (request.url.path == '/api/v1/patient-profiles/profile-1' &&
            request.method == 'PATCH') {
          expect(jsonDecode(request.body), {
            'expectedVersion': 2,
            'missedDoseGraceMinutes': 30,
          });
          return http.Response(
            jsonEncode({
              'data': {'version': 3},
            }),
            200,
          );
        }
        expect(
          request.url.path,
          '/api/v1/patient-profiles/profile-1/dose-occurrences/simulate-miss',
        );
        expect(jsonDecode(request.body), {'minutesLate': 46});
        return http.Response(jsonEncode({'data': {}}), 201);
      }),
    );

    final alerts = await gateway.listAlerts(
      accessToken: 'access-1',
      profileId: 'profile-1',
    );
    expect(alerts.single.medicationName, isNull);
    expect(alerts.single.status, 'ACTIVE');
    await gateway.acknowledgeAlert(accessToken: 'access-1', alertId: 'alert-1');
    expect(
      await gateway.updateMissedDoseGrace(
        accessToken: 'access-1',
        expectedVersion: 2,
        minutes: 30,
        profileId: 'profile-1',
      ),
      3,
    );
    await gateway.simulateMiss(
      accessToken: 'access-1',
      minutesLate: 46,
      profileId: 'profile-1',
    );
    expect(requests, hasLength(4));
    expect(
      requests.every(
        (request) => request.headers['authorization'] == 'Bearer access-1',
      ),
      isTrue,
    );
  });
}
