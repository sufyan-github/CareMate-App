import 'package:caremate/app/caremate_app.dart';
import 'package:caremate/features/care/domain/care_access_gateway.dart';
import 'package:caremate/features/care/domain/caregiver_alert_notifier.dart';
import 'package:caremate/features/medications/domain/patient_medication_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/auth_test_support.dart';

class _RecordingNotifier implements CaregiverAlertNotifier {
  final List<CaregiverAlert> shown = [];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> show(CaregiverAlert alert) async => shown.add(alert);
}

void main() {
  testWidgets(
    'caregiver sees a private alert, receives notification, and acknowledges it',
    (tester) async {
      final careGateway = InMemoryCareAccessGateway();
      careGateway.alerts.add(
        CaregiverAlert(
          acknowledgedAt: null,
          callPhoneE164: '+8801700123456',
          deliveredAt: DateTime(2026, 8, 18, 12),
          generatedAt: DateTime(2026, 8, 18, 12),
          id: 'private-1',
          medicationName: null,
          patientDisplayName: 'Parent',
          plannedAt: DateTime(2026, 8, 18, 11, 14),
          resolvedAt: null,
          resolvedMinutesLate: null,
          status: 'ACTIVE',
        ),
      );
      final notifier = _RecordingNotifier();
      final patientGateway = InMemoryPatientMedicationGateway(
        profile: const PatientProfile(
          accessRole: 'CAREGIVER',
          canManage: false,
          canReceiveMissedDoseAlerts: true,
          canViewMedicationPlan: false,
          displayName: 'Parent',
          id: 'profile-1',
          timezone: 'Asia/Dhaka',
          version: 1,
        ),
      );

      await tester.pumpWidget(
        CareMateApp(
          authCoordinator: authenticatedCoordinator(),
          careAccessGateway: careGateway,
          caregiverAlertNotifier: notifier,
          patientMedicationGateway: patientGateway,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Caregiver alerts'), findsOneWidget);
      expect(find.text('A scheduled dose was missed'), findsOneWidget);
      expect(find.text('Napa'), findsNothing);
      expect(find.text('Needs attention'), findsOneWidget);
      expect(notifier.shown.map((alert) => alert.id), ['private-1']);

      await tester.tap(find.byKey(const Key('acknowledge-alert-private-1')));
      await tester.pumpAndSettle();
      expect(find.text('Acknowledged by you'), findsOneWidget);
      expect(find.text('Acknowledge'), findsNothing);
    },
  );

  testWidgets('competition owner can change grace and force a synthetic miss', (
    tester,
  ) async {
    final careGateway = InMemoryCareAccessGateway();
    await tester.pumpWidget(
      CareMateApp(
        authCoordinator: authenticatedCoordinator(),
        careAccessGateway: careGateway,
        competitionDemo: true,
        patientMedicationGateway: existingPatientGateway(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Care'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('missed-dose-grace-setting')), findsOneWidget);
    await tester.tap(find.byKey(const Key('simulate-missed-dose-button')));
    await tester.pumpAndSettle();
    expect(careGateway.simulatedMiss, isTrue);
    expect(find.textContaining('Synthetic miss created'), findsOneWidget);
  });
}
