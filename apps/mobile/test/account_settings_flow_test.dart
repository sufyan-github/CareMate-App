import 'package:caremate/app/caremate_app.dart';
import 'package:caremate/app/preferences/caremate_preferences.dart';
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
        preferencesController: CareMatePreferencesController(
          store: _MemoryPreferenceStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-settings-tile')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('বাংলা'));
    await tester.pumpAndSettle();
    expect(settings.preferences.locale, 'bn-BD');
    expect(find.text('ভাষা ও প্রদর্শন'), findsOneWidget);
    await tester.tap(find.byKey(const Key('large-text-setting')));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('সেটিংস ও সহায়তা'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('devices-settings-tile')));
    await tester.tap(find.byKey(const Key('devices-settings-tile')));
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
    await tester.ensureVisible(find.byKey(const Key('privacy-settings-tile')));
    await tester.tap(find.byKey(const Key('privacy-settings-tile')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share optional usage analytics'));
    await tester.pumpAndSettle();
    expect(settings.preferences.allowAnalytics, isTrue);

    await tester.scrollUntilVisible(
      find.byKey(const Key('request-account-deletion-button')),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    tester
        .widget<OutlinedButton>(
          find.byKey(const Key('request-account-deletion-button')),
        )
        .onPressed!();
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
    expect(find.text('সঠিক সময়ে আপনার ওষুধ'), findsOneWidget);
  });
}

class _MemoryPreferenceStore implements CareMatePreferenceStore {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}
