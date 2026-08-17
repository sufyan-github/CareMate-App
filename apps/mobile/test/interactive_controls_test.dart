import 'package:caremate/app/caremate_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/auth_test_support.dart';

Future<void> _pumpSignedInApp(WidgetTester tester) async {
  await tester.pumpWidget(
    CareMateApp(
      accountSettingsGateway: accountSettingsGateway(),
      authCoordinator: authenticatedCoordinator(),
      careAccessGateway: emptyCareAccessGateway(),
      insightsGateway: insightsGateway(),
      patientMedicationGateway: existingPatientGateway(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _showTodayQuickActions(WidgetTester tester) async {
  await tester.drag(find.byType(CustomScrollView), const Offset(0, -360));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Today Add medicine opens the medication form', (tester) async {
    await _pumpSignedInApp(tester);

    await _tapVisible(
      tester,
      find.widgetWithText(FilledButton, 'Add medicine'),
    );

    expect(find.byKey(const Key('medication-name-input')), findsOneWidget);
  });

  testWidgets('Today Scan prescription opens prescription intake', (
    tester,
  ) async {
    await _pumpSignedInApp(tester);

    await _showTodayQuickActions(tester);
    await _tapVisible(tester, find.text('Scan prescription'));

    expect(find.text('Prescription scan'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
  });

  testWidgets('manual OCR fallback requires review before medication save', (
    tester,
  ) async {
    final gateway = existingPatientGateway();
    await tester.pumpWidget(
      CareMateApp(
        authCoordinator: authenticatedCoordinator(),
        patientMedicationGateway: gateway,
      ),
    );
    await tester.pumpAndSettle();

    await _showTodayQuickActions(tester);
    await _tapVisible(tester, find.text('Scan prescription'));
    await tester.tap(find.text('Enter prescription text manually'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('ocr-medicine-name-input')),
      'Napa',
    );
    await tester.enterText(
      find.byKey(const Key('ocr-source-text-input')),
      'Napa 500 mg - one tablet after food',
    );
    await tester.drag(find.byType(ListView), const Offset(0, -280));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.byKey(const Key('review-ocr-draft-button')));

    expect(find.text('Napa'), findsOneWidget);
    expect(find.textContaining('unverified OCR draft'), findsOneWidget);
    await _tapVisible(tester, find.byKey(const Key('save-medication-button')));

    expect(gateway.medications, hasLength(1));
    expect(
      gateway.lastCreatedDraft?.sourceText,
      'Napa 500 mg - one tablet after food',
    );
  });

  testWidgets('Today Add caregiver opens caregiver invitation', (tester) async {
    final careGateway = emptyCareAccessGateway();
    await tester.pumpWidget(
      CareMateApp(
        authCoordinator: authenticatedCoordinator(),
        careAccessGateway: careGateway,
        patientMedicationGateway: existingPatientGateway(),
      ),
    );
    await tester.pumpAndSettle();

    await _showTodayQuickActions(tester);
    await _tapVisible(tester, find.text('Add caregiver'));

    expect(find.text('Invite caregiver'), findsOneWidget);
    expect(find.byKey(const Key('caregiver-phone-input')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('caregiver-phone-input')),
      '01800123456',
    );
    await _tapVisible(
      tester,
      find.byKey(const Key('send-caregiver-invitation-button')),
    );
    expect(careGateway.invitations, isEmpty);
    expect(find.text('Create this invitation?'), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('confirm-caregiver-invitation-button')),
    );
    await tester.pumpAndSettle();

    expect(careGateway.invitations, hasLength(1));
    expect(find.textContaining('Invitation created'), findsOneWidget);

    await tester.tap(find.text('Care'));
    await tester.pumpAndSettle();
    expect(find.text('••••••3456'), findsOneWidget);
    expect(find.text('Waiting for acceptance'), findsOneWidget);
    await tester.tap(find.text('Revoke'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-revoke-caregiver-button')));
    await tester.pumpAndSettle();
    expect(careGateway.invitations.single.status, 'REVOKED');
    expect(find.text('No caregivers connected'), findsOneWidget);
  });

  testWidgets('notifications action opens notification centre', (tester) async {
    await _pumpSignedInApp(tester);

    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsWidgets);
    expect(find.text('Upcoming reminders'), findsOneWidget);
    expect(
      find.text(
        'No unresolved dose reminders are scheduled in the next 14 days.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Care and Insights destinations contain operational actions', (
    tester,
  ) async {
    await _pumpSignedInApp(tester);

    await tester.tap(find.text('Care'));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(FilledButton, 'Invite caregiver'),
      findsOneWidget,
    );

    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();
    expect(find.text('Medication overview'), findsOneWidget);
    expect(find.text('App-based adherence indicator'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Low stock'),
      find.byKey(const Key('insights-scroll-view')),
      const Offset(0, -300),
    );
    expect(find.text('Low stock'), findsOneWidget);
  });

  testWidgets('records opening stock from the Insights inventory ledger', (
    tester,
  ) async {
    final gateway = insightsGateway();
    await tester.pumpWidget(
      CareMateApp(
        accountSettingsGateway: accountSettingsGateway(),
        authCoordinator: authenticatedCoordinator(),
        careAccessGateway: emptyCareAccessGateway(),
        insightsGateway: gateway,
        patientMedicationGateway: existingPatientGateway(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Set opening stock'),
      find.byKey(const Key('insights-scroll-view')),
      const Offset(0, -300),
    );
    await _tapVisible(tester, find.text('Set opening stock'));
    await tester.enterText(find.byKey(const Key('stock-quantity-input')), '5');
    await tester.tap(find.byKey(const Key('save-stock-adjustment-button')));
    await tester.pumpAndSettle();

    expect(gateway.position.estimatedQuantity, 7);
    expect(find.text('7 TABLET'), findsOneWidget);
    expect(find.text('Estimated stock updated.'), findsOneWidget);
  });

  testWidgets('More settings rows open their detail pages', (tester) async {
    await _pumpSignedInApp(tester);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    expect(find.text('Language and display'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Devices and sessions'));
    await tester.pumpAndSettle();
    expect(find.text('Signed-in devices'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Privacy and security'));
    await tester.pumpAndSettle();
    expect(find.text('Your privacy controls'), findsOneWidget);
  });
}
