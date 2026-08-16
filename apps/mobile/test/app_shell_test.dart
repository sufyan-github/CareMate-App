import 'package:caremate/app/caremate_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/auth_test_support.dart';

void main() {
  testWidgets('shows the CareMate Today experience on launch', (tester) async {
    await tester.pumpWidget(
      CareMateApp(authCoordinator: authenticatedCoordinator()),
    );
    await tester.pumpAndSettle();

    expect(find.text('CareMate'), findsOneWidget);
    expect(find.text("Today's care"), findsOneWidget);
    expect(find.text('No medicine reminders yet'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Add medicine'), findsOneWidget);
  });

  testWidgets('opens the medicines segment from primary navigation', (
    tester,
  ) async {
    await tester.pumpWidget(
      CareMateApp(authCoordinator: authenticatedCoordinator()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Medicines'));
    await tester.pumpAndSettle();

    expect(find.text('Your medicines'), findsOneWidget);
    expect(find.text('Add your first medicine'), findsOneWidget);
  });
}
