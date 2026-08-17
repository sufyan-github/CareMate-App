import 'dart:async';

import 'package:caremate/features/medications/application/patient_medication_coordinator.dart';
import 'package:caremate/features/care/domain/care_access_gateway.dart';
import 'package:caremate/features/care/presentation/care_access_entry_page.dart';
import 'package:caremate/features/medications/domain/patient_medication_gateway.dart';
import 'package:caremate/features/insights/domain/insights_gateway.dart';
import 'package:caremate/features/more/domain/account_settings_gateway.dart';
import 'package:caremate/features/prescription/domain/prescription_text_recognizer.dart';
import 'package:caremate/features/prescription/domain/prescription_extraction_gateway.dart';
import 'package:caremate/features/shell/presentation/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:caremate/features/reminders/domain/reminder_scheduler.dart';
import 'package:caremate/features/sync/application/dose_sync_coordinator.dart';
import 'package:caremate/features/sync/domain/background_sync_scheduler.dart';
import 'package:caremate/features/sync/domain/dose_sync_gateway.dart';
import 'package:caremate/features/sync/domain/dose_sync_models.dart';

class AuthenticatedExperience extends StatefulWidget {
  const AuthenticatedExperience({
    required this.accountSettingsGateway,
    required this.accessToken,
    required this.accessTokenProvider,
    required this.backgroundSyncScheduler,
    required this.careAccessGateway,
    required this.gateway,
    required this.installationId,
    required this.insightsGateway,
    required this.doseMutationStore,
    required this.doseSyncGateway,
    required this.onLogout,
    required this.prescriptionExtractionGateway,
    required this.prescriptionTextRecognizer,
    required this.reminderScheduler,
    required this.refreshAccessToken,
    required this.userId,
    super.key,
  });

  final AccountSettingsGateway accountSettingsGateway;
  final String accessToken;
  final Future<String> Function() accessTokenProvider;
  final BackgroundSyncScheduler backgroundSyncScheduler;
  final CareAccessGateway careAccessGateway;
  final PatientMedicationGateway gateway;
  final Future<String> Function() installationId;
  final InsightsGateway insightsGateway;
  final DoseMutationStore doseMutationStore;
  final DoseSyncGateway doseSyncGateway;
  final Future<void> Function() onLogout;
  final PrescriptionExtractionGateway prescriptionExtractionGateway;
  final PrescriptionTextRecognizer prescriptionTextRecognizer;
  final ReminderScheduler reminderScheduler;
  final Future<String> Function() refreshAccessToken;
  final String userId;

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
    final doseSync = DoseSyncCoordinator(
      accessToken: widget.accessTokenProvider,
      backgroundScheduler: widget.backgroundSyncScheduler,
      gateway: widget.doseSyncGateway,
      installationId: widget.installationId,
      refreshAccessToken: widget.refreshAccessToken,
      store: widget.doseMutationStore,
    );
    _coordinator = PatientMedicationCoordinator(
      accessToken: widget.accessToken,
      accessTokenProvider: widget.accessTokenProvider,
      doseSync: doseSync,
      gateway: widget.gateway,
      reminderScheduler: widget.reminderScheduler,
    );
    unawaited(_initializeCoordinator());
    unawaited(_registerInstallation(doseSync));
  }

  Future<void> _initializeCoordinator() =>
      _coordinator.initialize(userId: widget.userId);

  Future<void> _registerInstallation(DoseSyncCoordinator doseSync) async {
    try {
      await doseSync.registerInstallation(
        installationId: await widget.installationId(),
      );
    } on Object {
      // Registration is retried on a later foreground/background sync.
    }
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
          insightsGateway: widget.insightsGateway,
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
                    onPressed: _initializeCoordinator,
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
