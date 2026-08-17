import 'package:caremate/app/caremate_app.dart';
import 'package:caremate/features/reminders/domain/reminder_scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/auth_test_support.dart';
import 'support/tolerant_golden_comparator.dart';

void main() {
  testWidgets('Today screen matches the reviewed phone layout', (tester) async {
    final previousComparator = installTolerantGoldenComparator();
    addTearDown(() => goldenFileComparator = previousComparator);
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      CareMateApp(
        authCoordinator: authenticatedCoordinator(),
        patientMedicationGateway: existingPatientGateway(),
        reminderScheduler: const UnsupportedReminderScheduler(),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/today_page.png'),
    );
  });
}
