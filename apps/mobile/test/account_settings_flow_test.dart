import 'package:caremate/app/caremate_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/auth_test_support.dart';

void main() {
  testWidgets('persists language, revokes a device, and requests deletion', (
    tester,
  ) async {
    final settings = accountSettingsGateway();
    await tester.pumpWidget(
      CareMateApp(
        accountSettingsGateway: settings,
        authCoordinator: authenticatedCoordinator(),
        careAccessGateway: emptyCareAccessGateway(),
        patientMedicationGateway: existingPatientGateway(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('বাংলা'));
    await tester.pumpAndSettle();
    expect(settings.preferences.locale, 'bn-BD');

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Devices and sessions'));
    await tester.pumpAndSettle();
    expect(find.text('Other phone'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
    await tester.pumpAndSettle();
    expect(
      settings.sessions
          .firstWhere((session) => session.id == 'other-session')
          .status,
      'REVOKED',
    );
    expect(find.text('Signed out'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Privacy and security'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share optional usage analytics'));
    await tester.pumpAndSettle();
    expect(settings.preferences.allowAnalytics, isTrue);

    await tester.tap(find.byKey(const Key('request-account-deletion-button')));
    await tester.pumpAndSettle();
    final confirm = tester.widget<FilledButton>(
      find.byKey(const Key('confirm-account-deletion-button')),
    );
    expect(confirm.onPressed, isNull);
    await tester.enterText(
      find.byKey(const Key('account-deletion-confirmation-input')),
      'DELETE',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-account-deletion-button')));
    await tester.pumpAndSettle();

    expect(settings.deletionRequested, isTrue);
    expect(find.text('Your medicines, right on time'), findsOneWidget);
  });
}
