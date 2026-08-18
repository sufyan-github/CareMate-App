import 'package:caremate/app/caremate_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/auth_test_support.dart';

void main() {
  testWidgets('shows the CareMate Today experience on launch', (tester) async {
    await tester.pumpWidget(
      CareMateApp(
        authCoordinator: authenticatedCoordinator(),
        patientMedicationGateway: existingPatientGateway(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CareMate'), findsOneWidget);
    expect(find.text("Today's care"), findsOneWidget);
    expect(find.text('No medicine reminders yet'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Add medicine'), findsOneWidget);
    expect(
      find.byKey(const Key('competition-demo-guide-button')),
      findsNothing,
    );
  });

  testWidgets('competition build exposes a safe five-minute presenter guide', (
    tester,
  ) async {
    await tester.pumpWidget(
      CareMateApp(
        authCoordinator: authenticatedCoordinator(),
        competitionDemo: true,
        patientMedicationGateway: existingPatientGateway(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('competition-demo-guide-button')));
    await tester.pumpAndSettle();

    expect(find.text('Five-minute demo guide'), findsOneWidget);
    expect(find.text('Presenter aid â€¢ synthetic data only'), findsOneWidget);
    expect(find.text('1. Review-first prescription'), findsOneWidget);
    expect(find.text('2. Today and offline proof'), findsOneWidget);
    expect(find.text('3. Live caregiver loop'), findsOneWidget);
    expect(find.text('4. Inventory and insight'), findsOneWidget);
    expect(find.text('5. Bangladesh-first close'), findsOneWidget);
    expect(find.textContaining('demo OTP sends no SMS'), findsOneWidget);

    await tester.tap(find.text('2. Today and offline proof'));
    await tester.pumpAndSettle();
    expect(find.text("Today's care"), findsOneWidget);
    expect(find.text('Five-minute demo guide'), findsNothing);
  });

  testWidgets('opens the medicines segment from primary navigation', (
    tester,
  ) async {
    await tester.pumpWidget(
      CareMateApp(
        authCoordinator: authenticatedCoordinator(),
        patientMedicationGateway: existingPatientGateway(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Medicines'));
    await tester.pumpAndSettle();

    expect(find.text('Your medicines'), findsOneWidget);
    expect(find.text('Add your first medicine'), findsOneWidget);
  });
}
