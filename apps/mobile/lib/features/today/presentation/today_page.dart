import 'package:caremate/features/medications/domain/patient_medication_models.dart';
import 'package:flutter/material.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({
    required this.onAddCaregiver,
    required this.onAddMedicine,
    required this.onScanPrescription,
    this.canManage = true,
    this.occurrences = const [],
    super.key,
  });

  final VoidCallback onAddCaregiver;
  final VoidCallback onAddMedicine;
  final VoidCallback onScanPrescription;
  final bool canManage;
  final List<DoseOccurrenceSummary> occurrences;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: CustomScrollView(
        key: const PageStorageKey('today-page'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            sliver: SliverList.list(
              children: [
                Text(
                  "Today's care",
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your medicine plan and family support, in one calm place.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                const _ReadinessCard(),
                const SizedBox(height: 16),
                if (occurrences.isEmpty)
                  _EmptyReminderCard(
                    canManage: canManage,
                    onAddMedicine: onAddMedicine,
                  )
                else
                  _OccurrenceList(occurrences: occurrences),
                if (canManage) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Quick actions',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _QuickAction(
                        icon: Icons.document_scanner_outlined,
                        label: 'Scan prescription',
                        onPressed: onScanPrescription,
                      ),
                      _QuickAction(
                        icon: Icons.person_add_alt_1_outlined,
                        label: 'Add caregiver',
                        onPressed: onAddCaregiver,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OccurrenceList extends StatelessWidget {
  const _OccurrenceList({required this.occurrences});

  final List<DoseOccurrenceSummary> occurrences;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Today's doses",
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ...occurrences.map(
          (occurrence) => Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: const Icon(Icons.medication_outlined),
              ),
              title: Text(
                occurrence.medicationName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${_friendlyTime(occurrence.plannedLocalDateTime)} · ${occurrence.quantityLabel}',
              ),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        ),
      ],
    );
  }

  String _friendlyTime(String localDateTime) {
    final time = localDateTime.substring(localDateTime.length - 5);
    final parts = time.split(':').map(int.parse).toList();
    final hour = parts.first;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:${parts.last.toString().padLeft(2, '0')} $period';
  }
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.tertiaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.notifications_active_outlined,
                color: colors.onTertiaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reminder setup',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 3),
                  Text('Add a medicine to check device reminder readiness.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyReminderCard extends StatelessWidget {
  const _EmptyReminderCard({
    required this.canManage,
    required this.onAddMedicine,
  });

  final bool canManage;
  final VoidCallback onAddMedicine;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: colors.primaryContainer,
              foregroundColor: colors.onPrimaryContainer,
              child: const Icon(Icons.medication_outlined, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              canManage ? 'No medicine reminders yet' : 'Shared care access',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              canManage
                  ? 'Add a medicine manually or scan a prescription. You will review every detail before reminders start.'
                  : 'You can view the confirmed medication plan. Only the patient can add or change medicines.',
              textAlign: TextAlign.center,
            ),
            if (canManage) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onAddMedicine,
                icon: const Icon(Icons.add),
                label: const Text('Add medicine'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 20),
      label: Text(label),
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    );
  }
}
