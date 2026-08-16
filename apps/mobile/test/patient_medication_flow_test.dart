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
}
