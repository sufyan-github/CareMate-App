import 'package:flutter/material.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({
    required this.onAddCaregiver,
    required this.onAddMedicine,
    required this.onScanPrescription,
    super.key,
  });

  final VoidCallback onAddCaregiver;
  final VoidCallback onAddMedicine;
  final VoidCallback onScanPrescription;

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
                _EmptyReminderCard(onAddMedicine: onAddMedicine),
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
            ),
          ),
        ],
      ),
    );
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
  const _EmptyReminderCard({required this.onAddMedicine});

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
              'No medicine reminders yet',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add a medicine manually or scan a prescription. You will review every detail before reminders start.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAddMedicine,
              icon: const Icon(Icons.add),
              label: const Text('Add medicine'),
            ),
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
