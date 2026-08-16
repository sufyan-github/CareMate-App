import 'package:caremate/features/medications/application/patient_medication_coordinator.dart';
import 'package:caremate/features/medications/domain/patient_medication_gateway.dart';
import 'package:caremate/features/medications/presentation/profile_setup_page.dart';
import 'package:caremate/features/shell/presentation/app_shell.dart';
import 'package:flutter/material.dart';

class AuthenticatedExperience extends StatefulWidget {
  const AuthenticatedExperience({
    required this.accessToken,
    required this.gateway,
    required this.onLogout,
    super.key,
  });

  final String accessToken;
  final PatientMedicationGateway gateway;
  final Future<void> Function() onLogout;

  @override
  State<AuthenticatedExperience> createState() =>
      _AuthenticatedExperienceState();
}

class _AuthenticatedExperienceState extends State<AuthenticatedExperience> {
  late final PatientMedicationCoordinator _coordinator;

  @override
  void initState() {
    super.initState();
    _coordinator = PatientMedicationCoordinator(
      accessToken: widget.accessToken,
      gateway: widget.gateway,
    )..initialize();
  }

  @override
  void dispose() {
    _coordinator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _coordinator,
      builder: (context, _) => switch (_coordinator.status) {
        PatientMedicationStatus.loading => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        PatientMedicationStatus.needsProfile => ProfileSetupPage(
          coordinator: _coordinator,
        ),
        PatientMedicationStatus.ready => AppShell(
          medicationCoordinator: _coordinator,
          onLogout: widget.onLogout,
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
