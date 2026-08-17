import 'package:caremate/app/theme/caremate_theme.dart';
import 'package:caremate/app/widgets/caremate_status_card.dart';
import 'package:caremate/features/medications/domain/patient_medication_models.dart';
import 'package:caremate/features/today/presentation/today_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('status cards expose their message and actionable control', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CareMateTheme.light,
        home: Scaffold(
          body: CareMateStatusCard(
            actionKey: const Key('retry-action'),
            actionLabel: 'Try again',
            liveRegion: true,
            message: 'Check your connection and retry.',
            onAction: () {},
            title: 'Could not continue',
            tone: CareMateStatusTone.error,
          ),
        ),
      ),
    );

    final cardSemantics = tester.getSemantics(find.byType(CareMateStatusCard));
    expect(
      cardSemantics.label,
      contains('Could not continue. Check your connection and retry.'),
    );

    final action = find.byKey(const Key('retry-action'));
    expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
    expect(
      tester
          .getSemantics(action)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
  });

  testWidgets('Today dose actions remain usable at 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now();
    final occurrence = DoseOccurrenceSummary(
      id: 'dose-large-text',
      medicationName: 'Metformin 500 mg extended release',
      plannedAt: now.subtract(const Duration(minutes: 2)),
      plannedLocalDateTime: '2026-08-17T08:30',
      quantityLabel: '1 tablet after breakfast',
      status: 'REMINDER_SENT',
      version: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: CareMateTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: TodayPage(
              occurrences: [occurrence],
              onAddCaregiver: () {},
              onAddMedicine: () {},
              onDoseAction: (_, _, {reason, snoozeMinutes}) async => true,
              onScanPrescription: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('confirm-dose-dose-large-text')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Snooze 10 min'), findsOneWidget);
    for (final key in [
      'confirm-dose-dose-large-text',
      'snooze-dose-dose-large-text',
      'skip-dose-dose-large-text',
    ]) {
      final action = find.byKey(Key(key));
      await tester.ensureVisible(action);
      expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
    }
  });
}
