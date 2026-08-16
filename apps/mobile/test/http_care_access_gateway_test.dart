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
}
