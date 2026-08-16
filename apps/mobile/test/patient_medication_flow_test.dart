import 'package:caremate/app/caremate_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/auth_test_support.dart';

void main() {
  testWidgets('sets up a patient profile and adds the first medicine', (
    tester,
  ) async {
    final patientGateway = InMemoryPatientMedicationGateway();
    await tester.pumpWidget(
      CareMateApp(
        authCoordinator: authenticatedCoordinator(),
        patientMedicationGateway: patientGateway,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Set up your profile'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('profile-name-input')),
      'Abu Sufyan',
    );
    await tester.tap(find.text('Continue to CareMate'));
    await tester.pumpAndSettle();

    expect(find.text('CareMate'), findsOneWidget);
    await tester.tap(find.text('Medicines'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add medicine'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('medication-name-input')),
      'Napa',
    );
    await tester.tap(find.byKey(const Key('save-medication-button')));
    await tester.pumpAndSettle();

    expect(find.text('Napa'), findsOneWidget);
    expect(patientGateway.medications, hasLength(1));
  });
}
