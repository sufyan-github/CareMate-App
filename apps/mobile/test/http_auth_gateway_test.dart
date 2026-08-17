import 'package:caremate/features/auth/data/http_auth_gateway.dart';
import 'package:caremate/features/auth/domain/auth_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('keeps the user identity when a refresh token rotates', () async {
    final gateway = HttpAuthGateway(
      baseUrl: 'http://127.0.0.1:3000/api/v1',
      client: MockClient(
        (_) async => http.Response(
          '{"data":{"accessToken":"access-2","refreshToken":"refresh-2","user":{"id":"user-1"}}}',
          201,
        ),
      ),
    );

    final session = await gateway.refresh('refresh-1');

    expect(session.userId, 'user-1');
  });

  test(
    'reports an unreachable CareMate API instead of blaming internet',
    () async {
      final gateway = HttpAuthGateway(
        baseUrl: 'http://127.0.0.1:3000/api/v1',
        client: MockClient((_) async => throw http.ClientException('refused')),
      );

      await expectLater(
        gateway.requestOtp(
          deviceInstallationId: '01K2DEVICEINSTALLATION000001',
          locale: 'en-BD',
          phoneNumber: '01700123456',
        ),
        throwsA(
          isA<AuthFailure>().having(
            (failure) => failure.message,
            'message',
            'Could not reach the CareMate server. Make sure the API is running and try again.',
          ),
        ),
      );
    },
  );
}
