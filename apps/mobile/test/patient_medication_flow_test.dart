import 'package:caremate/app/caremate_app.dart';
import 'package:caremate/features/care/domain/care_access_gateway.dart';
import 'package:caremate/features/medications/domain/patient_medication_models.dart';
import 'package:caremate/features/sync/domain/dose_sync_gateway.dart';
import 'package:caremate/features/sync/domain/dose_sync_models.dart';
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
      await tester.pump();
      for (var attempt = 0; attempt < 20; attempt += 1) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.text('Schedule ended').evaluate().isNotEmpty) break;
      }
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayText = today.toIso8601String().substring(0, 10);
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
          plannedLocalDateTime: '${todayText}T08:00',
        ),
      ],
      quantityRequired: 1,
      quantityUnit: 'TABLET',
      schedule: MedicationScheduleSummary(
        endDate: today,
        id: 'schedule-1',
        revision: 1,
        startDate: today,
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
        doseSyncGateway: const _AcceptingDoseSyncGateway(),
        patientMedicationGateway: patientGateway,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Confirm'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Snooze 10 min'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextButton, 'Skip'), findsOneWidget);

    final snoozeButton = find.widgetWithText(OutlinedButton, 'Snooze 10 min');
    await tester.ensureVisible(snoozeButton);
    await tester.pumpAndSettle();
    await tester.tap(snoozeButton);
    await tester.pumpAndSettle();
    expect(find.textContaining('Snoozed until'), findsOneWidget);
    expect(find.text('Pending sync'), findsNothing);

    final confirmButton = find.widgetWithText(FilledButton, 'Confirm');
    await tester.ensureVisible(confirmButton);
    await tester.drag(
      find.byKey(const PageStorageKey('today-page')),
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();
    expect(find.text('Confirmed by you'), findsOneWidget);
  });

  testWidgets('shows an offline dose action as pending until sync succeeds', (
    tester,
  ) async {
    final patientGateway = existingPatientGateway();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayText = today.toIso8601String().substring(0, 10);
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
          plannedLocalDateTime: '${todayText}T08:00',
        ),
      ],
      quantityRequired: 1,
      quantityUnit: 'TABLET',
      schedule: MedicationScheduleSummary(
        endDate: today,
        id: 'schedule-1',
        revision: 1,
        startDate: today,
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

    final snoozeButton = find.widgetWithText(OutlinedButton, 'Snooze 10 min');
    await tester.ensureVisible(snoozeButton);
    await tester.pumpAndSettle();
    await tester.tap(snoozeButton);
    await tester.pumpAndSettle();

    expect(find.text('Pending sync'), findsOneWidget);
    expect(find.text('1 saved change waiting to sync'), findsOneWidget);
    expect(find.byKey(const Key('sync-now-button')), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Confirm'), findsNothing);
    expect(
      find.textContaining('Waiting for CareMate server confirmation'),
      findsOneWidget,
    );
  });
}

class _AcceptingDoseSyncGateway implements DoseSyncGateway {
  const _AcceptingDoseSyncGateway();

  @override
  Future<List<DoseSyncResult>> push(
    String accessToken,
    List<DoseSyncMutation> mutations,
  ) async => mutations
      .map(
        (mutation) => DoseSyncResult(
          authoritative: AuthoritativeDoseState(
            confirmedAt: mutation.action == DoseAction.confirm
                ? mutation.clientAt
                : null,
            id: mutation.occurrenceId,
            reminderSentAt: mutation.clientAt,
            responseDueAt: mutation.action == DoseAction.snooze
                ? mutation.clientAt.add(const Duration(minutes: 70))
                : null,
            snoozeCount: mutation.action == DoseAction.snooze ? 1 : 0,
            snoozedUntil: mutation.action == DoseAction.snooze
                ? mutation.clientAt.add(const Duration(minutes: 10))
                : null,
            status: switch (mutation.action) {
              DoseAction.confirm => 'CONFIRMED',
              DoseAction.snooze => 'SNOOZED',
              DoseAction.skip => 'SKIPPED',
            },
            timingClassification: mutation.action == DoseAction.confirm
                ? 'ON_TIME'
                : null,
            version: mutation.expectedVersion + 1,
          ),
          mutationId: mutation.id,
          status: SyncMutationStatus.accepted,
        ),
      )
      .toList(growable: false);

  @override
  Future<void> registerInstallation({
    required String accessToken,
    required String appVersion,
    required String deviceName,
    required String installationId,
    required String locale,
    required String platform,
    String? pushToken,
  }) async {}
}
