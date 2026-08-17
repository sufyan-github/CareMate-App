import 'package:caremate/app/caremate_app.dart';
import 'package:caremate/features/care/domain/care_access_gateway.dart';
import 'package:caremate/features/medications/domain/patient_medication_models.dart';
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
        careAccessGateway: emptyCareAccessGateway(),
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

  testWidgets('accepts caregiver access and opens a read-only shared plan', (
    tester,
  ) async {
    final patientGateway = InMemoryPatientMedicationGateway();
    late final InMemoryCareAccessGateway careGateway;
    careGateway = InMemoryCareAccessGateway(
      initialInvitations: const [
        CareInvitation(
          deliveryStatus: 'IN_APP_PENDING',
          id: 'incoming-1',
          inviteePhoneMasked: '••••••3456',
          patientDisplayName: 'Parent',
          permissions: CarePermissions(
            canReceiveMissedDoseAlerts: true,
            canViewMedicationPlan: true,
          ),
          status: 'PENDING',
        ),
      ],
      onAccepted: () {
        patientGateway.profile = const PatientProfile(
          accessRole: 'CAREGIVER',
          canManage: false,
          displayName: 'Parent',
          id: 'shared-profile',
          timezone: 'Asia/Dhaka',
          version: 1,
        );
      },
    );
    await tester.pumpWidget(
      CareMateApp(
        authCoordinator: authenticatedCoordinator(),
        careAccessGateway: careGateway,
        patientMedicationGateway: patientGateway,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('You have been invited to help'), findsOneWidget);
    expect(find.text('Parent'), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('accept-caregiver-invitation-button')),
    );
    await tester.pumpAndSettle();

    expect(careGateway.invitations.single.status, 'ACCEPTED');
    expect(find.text('Shared care access'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Add medicine'), findsNothing);
    await tester.tap(find.text('Medicines'));
    await tester.pumpAndSettle();
    expect(find.text('Shared medicines'), findsOneWidget);
    expect(find.text('No shared medicines'), findsOneWidget);
  });

  testWidgets(
    'previews and activates a medicine schedule from a friendly flow',
    (tester) async {
      final patientGateway = existingPatientGateway();
      patientGateway.medications.add(
        const MedicationSummary(
          displayName: 'Napa',
          form: 'TABLET',
          id: 'medication-1',
          quantityLabel: '1 tablet',
          status: 'ACTIVE',
          strengthLabel: '500 mg',
        ),
      );
      await tester.pumpWidget(
        CareMateApp(
          authCoordinator: authenticatedCoordinator(),
          careAccessGateway: emptyCareAccessGateway(),
          patientMedicationGateway: patientGateway,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Medicines'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Napa'));
      await tester.pumpAndSettle();
      expect(find.text('Set medication schedule'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -420));
      await tester.pumpAndSettle();
      expect(find.text('8:00 AM'), findsOneWidget);
      await tester.tap(find.byKey(const Key('preview-schedule-button')));
      await tester.pumpAndSettle();
      expect(find.text('Review before activation'), findsOneWidget);
      expect(find.textContaining('1 tablet needed'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -240));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('activate-schedule-button')));
      await tester.pumpAndSettle();
      expect(find.text('Medication schedule active'), findsOneWidget);

      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();
      expect(find.text('Napa'), findsOneWidget);
      expect(find.textContaining('8:00 AM'), findsOneWidget);

      await tester.tap(find.text('Medicines'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Napa'));
      await tester.pumpAndSettle();
      expect(find.text('Manage medication schedule'), findsOneWidget);
      await tester.tap(find.byKey(const Key('pause-schedule-button')));
      await tester.pumpAndSettle();
      expect(find.text('Paused'), findsOneWidget);
      await tester.tap(find.byKey(const Key('resume-schedule-button')));
      await tester.pumpAndSettle();
      expect(find.text('Active'), findsOneWidget);
      await tester.tap(find.byKey(const Key('end-schedule-button')));
      await tester.pumpAndSettle();
      expect(find.text('End this schedule?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'End schedule'));
      await tester.pumpAndSettle();
      expect(find.text('Schedule ended'), findsOneWidget);
    },
  );

  testWidgets('supports a selected-weekday medication schedule', (
    tester,
  ) async {
    final patientGateway = existingPatientGateway();
    patientGateway.medications.add(
      const MedicationSummary(
        displayName: 'Weekly medicine',
        form: 'TABLET',
        id: 'weekly-medication',
        quantityLabel: '1 tablet',
        status: 'ACTIVE',
        strengthLabel: 'Strength not specified',
      ),
    );
    await tester.pumpWidget(
      CareMateApp(
        authCoordinator: authenticatedCoordinator(),
        careAccessGateway: emptyCareAccessGateway(),
        patientMedicationGateway: patientGateway,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Medicines'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weekly medicine'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Every day'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Selected weekdays').last);
    await tester.pumpAndSettle();
    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Sun'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -520));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('preview-schedule-button')));
    await tester.pumpAndSettle();

    expect(patientGateway.lastScheduleDraft?.recurrence, 'WEEKLY');
    expect(patientGateway.lastScheduleDraft?.daysOfWeek, isNotEmpty);
  });

  testWidgets('records confirm, snooze, and skip actions from Today', (
    tester,
  ) async {
    final patientGateway = existingPatientGateway();
    patientGateway.medications.add(
      const MedicationSummary(
        displayName: 'Napa',
        form: 'TABLET',
        id: 'medication-1',
        quantityLabel: '1 tablet',
        status: 'ACTIVE',
        strengthLabel: '500 mg',
      ),
    );
    patientGateway.activeSchedule = MedicationSchedulePlan(
      occurrences: [
        ScheduleOccurrencePreview(
          plannedAt: DateTime.now().subtract(const Duration(minutes: 1)),
          plannedLocalDateTime: '2026-08-17T08:00',
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
        times: const ['08:00'],
        timezone: 'Asia/Dhaka',
        version: 1,
      ),
    );
    await tester.pumpWidget(
      CareMateApp(
        authCoordinator: authenticatedCoordinator(),
        careAccessGateway: emptyCareAccessGateway(),
        patientMedicationGateway: patientGateway,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Confirm'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Snooze'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Skip'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Snooze'));
    await tester.pumpAndSettle();
    expect(find.text('Snoozed for 10 minutes'), findsOneWidget);
    expect(patientGateway.doseOutcomes['occurrence-1']?.status, 'SNOOZED');

    await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmed by you'), findsOneWidget);
    expect(patientGateway.doseOutcomes['occurrence-1']?.status, 'CONFIRMED');
  });
}
