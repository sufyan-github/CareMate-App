import 'dart:async';

import 'package:caremate/features/medications/application/patient_medication_coordinator.dart';
import 'package:caremate/features/care/domain/care_access_gateway.dart';
import 'package:caremate/features/care/presentation/care_access_entry_page.dart';
import 'package:caremate/features/medications/domain/patient_medication_gateway.dart';
import 'package:caremate/features/more/domain/account_settings_gateway.dart';
import 'package:caremate/features/prescription/domain/prescription_text_recognizer.dart';
import 'package:caremate/features/prescription/domain/prescription_extraction_gateway.dart';
import 'package:caremate/features/shell/presentation/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:caremate/features/reminders/domain/reminder_scheduler.dart';

class AuthenticatedExperience extends StatefulWidget {
  const AuthenticatedExperience({
    required this.accountSettingsGateway,
    required this.accessToken,
    required this.careAccessGateway,
    required this.gateway,
    required this.onLogout,
    required this.prescriptionExtractionGateway,
    required this.prescriptionTextRecognizer,
    required this.reminderScheduler,
    super.key,
  });

  final AccountSettingsGateway accountSettingsGateway;
  final String accessToken;
  final CareAccessGateway careAccessGateway;
  final PatientMedicationGateway gateway;
  final Future<void> Function() onLogout;
  final PrescriptionExtractionGateway prescriptionExtractionGateway;
  final PrescriptionTextRecognizer prescriptionTextRecognizer;
  final ReminderScheduler reminderScheduler;

  @override
  State<AuthenticatedExperience> createState() =>
      _AuthenticatedExperienceState();
}

class _AuthenticatedExperienceState extends State<AuthenticatedExperience>
    with WidgetsBindingObserver {
  late final PatientMedicationCoordinator _coordinator;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _coordinator = PatientMedicationCoordinator(
      accessToken: widget.accessToken,
      gateway: widget.gateway,
      reminderScheduler: widget.reminderScheduler,
    )..initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _coordinator.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_coordinator.refreshAfterAppResume());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _coordinator,
      builder: (context, _) => switch (_coordinator.status) {
        PatientMedicationStatus.loading => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        PatientMedicationStatus.needsProfile => CareAccessEntryPage(
          accessToken: widget.accessToken,
          coordinator: _coordinator,
          gateway: widget.careAccessGateway,
        ),
        PatientMedicationStatus.ready => AppShell(
          accountSettingsGateway: widget.accountSettingsGateway,
          careAccessGateway: widget.careAccessGateway,
          medicationCoordinator: _coordinator,
          onLogout: widget.onLogout,
          prescriptionExtractionGateway: widget.prescriptionExtractionGateway,
          prescriptionTextRecognizer: widget.prescriptionTextRecognizer,
        ),
        PatientMedicationStatus.error => Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    _coordinator.errorMessage ?? 'Could not load your profile.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _coordinator.initialize,
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      },
    );
  }
}
