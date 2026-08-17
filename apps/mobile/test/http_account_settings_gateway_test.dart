import 'dart:convert';

import 'package:caremate/features/more/data/http_account_settings_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('updates authenticated account preferences', () async {
    final gateway = HttpAccountSettingsGateway(
      baseUrl: 'http://caremate.test/api/v1',
      client: MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/api/v1/me/preferences');
        expect(request.headers['authorization'], 'Bearer access-1');
        expect(jsonDecode(request.body), {
          'allowAnalytics': true,
          'locale': 'bn-BD',
        });
        return http.Response(
          jsonEncode({
            'data': {
              'allowAnalytics': true,
              'locale': 'bn-BD',
              'showMedicineOnLockScreen': false,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final preferences = await gateway.updatePreferences(
      accessToken: 'access-1',
      allowAnalytics: true,
      locale: 'bn-BD',
    );

    expect(preferences.locale, 'bn-BD');
    expect(preferences.allowAnalytics, isTrue);
  });
}
