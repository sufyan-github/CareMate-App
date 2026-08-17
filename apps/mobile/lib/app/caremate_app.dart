import 'package:caremate/app/theme/caremate_theme.dart';
import 'package:caremate/features/auth/application/auth_coordinator.dart';
import 'package:caremate/features/auth/data/http_auth_gateway.dart';
import 'package:caremate/features/auth/data/secure_session_store.dart';
import 'package:caremate/features/auth/presentation/auth_flow_page.dart';
import 'package:caremate/features/care/data/http_care_access_gateway.dart';
import 'package:caremate/features/care/domain/care_access_gateway.dart';
import 'package:caremate/features/medications/data/http_patient_medication_gateway.dart';
import 'package:caremate/features/medications/domain/patient_medication_gateway.dart';
import 'package:caremate/features/medications/presentation/authenticated_experience.dart';
import 'package:caremate/features/more/data/http_account_settings_gateway.dart';
import 'package:caremate/features/more/domain/account_settings_gateway.dart';
import 'package:caremate/features/prescription/data/mlkit_prescription_text_recognizer.dart';
import 'package:caremate/features/prescription/data/http_prescription_extraction_gateway.dart';
import 'package:caremate/features/prescription/domain/prescription_extraction_gateway.dart';
import 'package:caremate/features/prescription/domain/prescription_text_recognizer.dart';
import 'package:caremate/features/reminders/domain/reminder_scheduler.dart';
import 'package:caremate/features/reminders/data/flutter_reminder_scheduler.dart';
import 'package:flutter/material.dart';

class CareMateApp extends StatefulWidget {
  const CareMateApp({
    this.accountSettingsGateway,
    this.authCoordinator,
    this.careAccessGateway,
    this.patientMedicationGateway,
    this.prescriptionExtractionGateway,
    this.prescriptionTextRecognizer,
    this.reminderScheduler,
    super.key,
  });

  final AccountSettingsGateway? accountSettingsGateway;
  final AuthCoordinator? authCoordinator;
  final CareAccessGateway? careAccessGateway;
  final PatientMedicationGateway? patientMedicationGateway;
  final PrescriptionExtractionGateway? prescriptionExtractionGateway;
  final PrescriptionTextRecognizer? prescriptionTextRecognizer;
  final ReminderScheduler? reminderScheduler;

  @override
  State<CareMateApp> createState() => _CareMateAppState();
}

class _CareMateAppState extends State<CareMateApp> {
  late final AccountSettingsGateway _accountSettingsGateway;
  late final AuthCoordinator _authCoordinator;
  late final CareAccessGateway _careAccessGateway;
  late final bool _ownsCoordinator;
  late final PatientMedicationGateway _patientMedicationGateway;
  late final PrescriptionExtractionGateway _prescriptionExtractionGateway;
  late final PrescriptionTextRecognizer _prescriptionTextRecognizer;
  late final ReminderScheduler _reminderScheduler;

  @override
  void initState() {
    super.initState();
    _accountSettingsGateway =
        widget.accountSettingsGateway ??
        HttpAccountSettingsGateway(
          baseUrl: const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'http://10.0.2.2:3000/api/v1',
          ),
        );
    _ownsCoordinator = widget.authCoordinator == null;
    _careAccessGateway =
        widget.careAccessGateway ??
        HttpCareAccessGateway(
          baseUrl: const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'http://10.0.2.2:3000/api/v1',
          ),
        );
    _authCoordinator =
        widget.authCoordinator ??
        AuthCoordinator(
          gateway: HttpAuthGateway(
            baseUrl: const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://10.0.2.2:3000/api/v1',
            ),
          ),
          sessionStore: SecureSessionStore(),
        );
    _patientMedicationGateway =
        widget.patientMedicationGateway ??
        HttpPatientMedicationGateway(
          baseUrl: const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'http://10.0.2.2:3000/api/v1',
          ),
        );
    _prescriptionExtractionGateway =
        widget.prescriptionExtractionGateway ??
        HttpPrescriptionExtractionGateway(
          baseUrl: const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'http://10.0.2.2:3000/api/v1',
          ),
        );
    _prescriptionTextRecognizer =
        widget.prescriptionTextRecognizer ?? MlKitPrescriptionTextRecognizer();
    _reminderScheduler = widget.reminderScheduler ?? FlutterReminderScheduler();
    _authCoordinator.initialize();
  }

  @override
  void dispose() {
    if (_ownsCoordinator) _authCoordinator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CareMate',
      theme: CareMateTheme.light,
      darkTheme: CareMateTheme.dark,
      themeMode: ThemeMode.system,
      home: AnimatedBuilder(
        animation: _authCoordinator,
        builder: (context, _) => switch (_authCoordinator.status) {
          AuthStatus.restoring => const _RestoringSessionPage(),
          AuthStatus.signedIn => AuthenticatedExperience(
            accountSettingsGateway: _accountSettingsGateway,
            accessToken: _authCoordinator.session!.accessToken,
            careAccessGateway: _careAccessGateway,
            gateway: _patientMedicationGateway,
            onLogout: _authCoordinator.logout,
            prescriptionExtractionGateway: _prescriptionExtractionGateway,
            prescriptionTextRecognizer: _prescriptionTextRecognizer,
            reminderScheduler: _reminderScheduler,
          ),
          AuthStatus.signedOut ||
          AuthStatus.awaitingOtp => AuthFlowPage(coordinator: _authCoordinator),
        },
      ),
    );
  }
}

class _RestoringSessionPage extends StatelessWidget {
  const _RestoringSessionPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Semantics(
          label: 'Restoring your secure CareMate session',
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }
}
