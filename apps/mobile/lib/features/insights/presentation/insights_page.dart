import 'package:caremate/features/medications/application/patient_medication_coordinator.dart';
import 'package:flutter/material.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({required this.coordinator, super.key});

  final PatientMedicationCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    final medicationCount = coordinator.medications.length;
    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            'Your insights',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Medication overview',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '$medicationCount',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    medicationCount == 1
                        ? 'active medicine recorded'
                        : 'active medicines recorded',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: ListTile(
              leading: Icon(Icons.event_available_outlined),
              title: Text('Dose history not available yet'),
              subtitle: Text(
                'App-based adherence indicators will appear after schedules and dose confirmations are enabled.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
