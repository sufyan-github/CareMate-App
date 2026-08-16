import 'package:caremate/app/caremate_app.dart';
import 'package:caremate/features/auth/application/auth_coordinator.dart';
import 'package:caremate/features/auth/domain/auth_gateway.dart';
import 'package:caremate/features/auth/domain/auth_models.dart';
import 'package:caremate/features/auth/domain/session_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/auth_test_support.dart';

void main() {
  testWidgets('requests and verifies a development login code', (tester) async {
    final store = _MemorySessionStore();
    final coordinator = AuthCoordinator(
      gateway: _FakeAuthGateway(),
      sessionStore: store,
    );

    await tester.pumpWidget(
      CareMateApp(
        authCoordinator: coordinator,
        patientMedicationGateway: existingPatientGateway(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your medicines, right on time'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('phone-input')), '01700123456');
    await tester.tap(find.text('Send verification code'));
    await tester.pumpAndSettle();

    expect(find.text('Check your messages'), findsOneWidget);
    expect(find.text('Development mode: use code 123456'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('otp-input')), '123456');
    await tester.tap(find.text('Verify and continue'));
    await tester.pumpAndSettle();

    expect(find.text('CareMate'), findsOneWidget);
    expect(find.text('Today'), findsWidgets);
    expect(store.refreshToken, 'refresh-2');

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out of this device'));
    await tester.pumpAndSettle();
    expect(find.text('Your medicines, right on time'), findsOneWidget);
    expect(store.refreshToken, isNull);
  });
}

class _FakeAuthGateway implements AuthGateway {
  @override
  Future<AuthChallenge> requestOtp({
    required String deviceInstallationId,
    required String locale,
    required String phoneNumber,
  }) async {
    return AuthChallenge(
      challengeId: '01K2CHALLENGE00000000000001',
      deliveryHint: '••••••3456',
      expiresInSeconds: 300,
      isDevelopment: true,
      resendAfterSeconds: 0,
    );
  }

  @override
  Future<AuthSession> verifyOtp({
    required String challengeId,
    required AuthDevice device,
    required String otp,
  }) async {
    return const AuthSession(
      accessToken: 'access-1',
      refreshToken: 'refresh-2',
      userId: '01K2USER000000000000000001',
    );
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    throw const AuthFailure('SESSION_REVOKED', 'No session');
  }

  @override
  Future<void> logout(String accessToken) async {}
}

class _MemorySessionStore implements SessionStore {
  String? refreshToken;

  @override
  Future<void> clear() async => refreshToken = null;

  @override
  Future<String> installationId() async => '01K2DEVICE0000000000000001';

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> writeRefreshToken(String token) async => refreshToken = token;
}
