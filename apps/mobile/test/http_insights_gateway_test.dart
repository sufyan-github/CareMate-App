import 'dart:convert';

import 'package:caremate/features/insights/data/http_insights_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'loads authenticated inventory and transparent indicator data',
    () async {
      final gateway = HttpInsightsGateway(
        baseUrl: 'http://caremate.test/api/v1',
        client: MockClient((request) async {
          expect(request.headers['authorization'], 'Bearer access-1');
          if (request.url.path.endsWith('/inventory')) {
            return http.Response(
              jsonEncode({
                'data': [_positionJson()],
              }),
              200,
            );
          }
          expect(
            request.url.path,
            '/api/v1/patient-profiles/profile-1/indicators',
          );
          expect(request.url.queryParameters, {
            'from': '2026-08-11',
            'to': '2026-08-17',
          });
          return http.Response(
            jsonEncode({
              'data': {
                'counts': {
                  'cancelledExcluded': 0,
                  'futureExcluded': 1,
                  'lateConfirmed': 1,
                  'missed': 1,
                  'onTimeConfirmed': 3,
                  'skipped': 1,
                  'unresolved': 1,
                },
                'denominator': 6,
                'disclaimer': 'Not a clinical measure.',
                'numerator': 4,
                'percentage': 66.7,
                'period': {
                  'from': '2026-08-11',
                  'timezone': 'Asia/Dhaka',
                  'to': '2026-08-17',
                },
              },
            }),
            200,
          );
        }),
      );

      final inventory = await gateway.listInventory(
        accessToken: 'access-1',
        profileId: 'profile-1',
      );
      final indicator = await gateway.getIndicator(
        accessToken: 'access-1',
        from: DateTime(2026, 8, 11),
        profileId: 'profile-1',
        to: DateTime(2026, 8, 17),
      );

      expect(inventory.single.medicationName, 'Napa');
      expect(inventory.single.estimatedQuantity, 2);
      expect(inventory.single.isLowStock, isTrue);
      expect(indicator.percentage, 66.7);
      expect(indicator.counts.onTimeConfirmed, 3);
    },
  );

  test('posts a unit-bound idempotent stock adjustment', () async {
    final gateway = HttpInsightsGateway(
      baseUrl: 'http://caremate.test/api/v1',
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/inventory/inventory-1/adjustments');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body, containsPair('delta', 10.0));
        expect(body, containsPair('quantityUnit', 'TABLET'));
        expect(body, containsPair('reason', 'RESTOCK'));
        expect(body['idempotencyKey'], isA<String>());
        expect((body['idempotencyKey'] as String).length, greaterThan(20));
        return http.Response(
          jsonEncode({'data': _positionJson(quantity: 12)}),
          201,
        );
      }),
    );

    final updated = await gateway.createStockAdjustment(
      accessToken: 'access-1',
      delta: 10,
      positionId: 'inventory-1',
      quantityUnit: 'TABLET',
      reason: 'RESTOCK',
    );

    expect(updated.estimatedQuantity, 12);
  });
}

Map<String, dynamic> _positionJson({double quantity = 2}) => {
  'adjustments': <Map<String, dynamic>>[],
  'estimatedDaysRemaining': 2,
  'estimatedQuantity': quantity,
  'id': 'inventory-1',
  'isLowStock': quantity <= 5,
  'lowStockThreshold': 5,
  'medicationId': 'medication-1',
  'medicationName': 'Napa',
  'patientProfileId': 'profile-1',
  'projectedRunOutAt': '2026-08-19T02:00:00.000Z',
  'quantityUnit': 'TABLET',
  'version': 1,
};
