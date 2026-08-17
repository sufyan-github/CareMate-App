import 'package:caremate/app/caremate_app.dart';
import 'package:caremate/features/medications/domain/patient_medication_models.dart';
import 'package:caremate/features/reminders/domain/reminder_scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/auth_test_support.dart';

void main() {
  testWidgets('explains reminder readiness and schedules after permission', (
    tester,
  ) async {
    final gateway = existingPatientGateway();
    gateway.medications.add(
      const MedicationSummary(
        displayName: 'Napa',
        form: 'TABLET',
        id: 'medication-1',
        quantityLabel: '1 tablet',
        status: 'ACTIVE',
        strengthLabel: '500 mg',
      ),
    );
    gateway.activeSchedule = MedicationSchedulePlan(
      occurrences: [
        ScheduleOccurrencePreview(
          plannedAt: DateTime.now().add(const Duration(hours: 1)),
          plannedLocalDateTime: '2026-08-17T12:00',
        ),
      ],
      quantityRequired: 1,
      quantityUnit: 'TABLET',
      schedule: MedicationScheduleSummary(
        endDate: DateTime(2026, 8, 17),
        id: 'schedule-1',
        revision: 1,
        startDate: DateTime(2026, 8, 17),
        status: 'ACTIVE',
        times: const ['12:00'],
        timezone: 'Asia/Dhaka',
        version: 1,
      ),
    );
    final scheduler = _FakeReminderScheduler();

    await tester.pumpWidget(
      CareMateApp(
        authCoordinator: authenticatedCoordinator(),
        careAccessGateway: emptyCareAccessGateway(),
        patientMedicationGateway: gateway,
        reminderScheduler: scheduler,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reminders need permission'), findsOneWidget);
    expect(find.byKey(const Key('confirm-dose-occurrence-1')), findsNothing);
    expect(
      find.widgetWithText(FilledButton, 'Enable reminders'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Enable reminders'));
    await tester.pumpAndSettle();

    expect(find.text('Reminders ready'), findsOneWidget);
    expect(scheduler.permissionRequests, 1);
    expect(scheduler.scheduledOccurrenceIds, ['occurrence-1']);

    final reconciliationsBeforeResume = scheduler.reconciliations;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(scheduler.reconciliations, reconciliationsBeforeResume + 1);

    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();
    expect(find.text('Upcoming reminders'), findsOneWidget);
    expect(find.text('Napa'), findsOneWidget);
  });
}

class _FakeReminderScheduler implements ReminderScheduler {
  ReminderActionHandler? handler;
  int permissionRequests = 0;
  int reconciliations = 0;
  final List<String> scheduledOccurrenceIds = [];
  bool ready = false;

  @override
  Future<void> initialize(ReminderActionHandler onAction) async {
    handler = onAction;
  }

  @override
  Future<void> openNotificationSettings() async {}

  @override
  Future<ReminderReadiness> checkReadiness({bool request = false}) async {
    if (request) {
      permissionRequests += 1;
      ready = true;
    }
    return ReminderReadiness(
      exactAlarmsAllowed: ready,
      notificationsAllowed: ready,
      supported: true,
    );
  }

  @override
  Future<void> reconcile(List<DoseOccurrenceSummary> occurrences) async {
    reconciliations += 1;
    scheduledOccurrenceIds
      ..clear()
      ..addAll(occurrences.map((occurrence) => occurrence.id));
  }
}
