import 'package:caremate/features/medications/domain/patient_medication_models.dart';
import 'package:flutter/material.dart';
import 'package:caremate/features/reminders/domain/reminder_scheduler.dart';

typedef DoseActionCallback =
    Future<bool> Function(
      DoseOccurrenceSummary occurrence,
      DoseAction action, {
      String? reason,
      int? snoozeMinutes,
    });

class TodayPage extends StatelessWidget {
  const TodayPage({
    required this.onAddCaregiver,
    required this.onAddMedicine,
    required this.onScanPrescription,
    this.onDoseAction,
    this.onEnableReminders,
    this.onSyncNow,
    this.pendingSyncCount = 0,
    this.reminderReadiness,
    this.syncMessage,
    this.usingOfflineCache = false,
    this.canManage = true,
    this.occurrences = const [],
    super.key,
  });

  final VoidCallback onAddCaregiver;
  final VoidCallback onAddMedicine;
  final VoidCallback onScanPrescription;
  final DoseActionCallback? onDoseAction;
  final Future<void> Function()? onEnableReminders;
  final Future<void> Function()? onSyncNow;
  final int pendingSyncCount;
  final ReminderReadiness? reminderReadiness;
  final String? syncMessage;
  final bool usingOfflineCache;
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
                if (pendingSyncCount > 0 ||
                    usingOfflineCache ||
                    syncMessage != null) ...[
                  _SyncStatusCard(
                    message: syncMessage,
                    onSyncNow: onSyncNow,
                    pendingCount: pendingSyncCount,
                    usingOfflineCache: usingOfflineCache,
                  ),
                  const SizedBox(height: 16),
                ],
                _ReadinessCard(
                  onEnable: onEnableReminders,
                  readiness: reminderReadiness,
                ),
                const SizedBox(height: 16),
                if (occurrences.isEmpty)
                  _EmptyReminderCard(
                    canManage: canManage,
                    onAddMedicine: onAddMedicine,
                  )
                else
                  _OccurrenceList(
                    canManage: canManage,
                    occurrences: occurrences,
                    onDoseAction: onDoseAction,
                  ),
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
  const _OccurrenceList({
    required this.canManage,
    required this.occurrences,
    required this.onDoseAction,
  });

  final bool canManage;
  final List<DoseOccurrenceSummary> occurrences;
  final DoseActionCallback? onDoseAction;

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
          (occurrence) => _DoseOccurrenceCard(
            canManage: canManage,
            occurrence: occurrence,
            onDoseAction: onDoseAction,
          ),
        ),
      ],
    );
  }
}

class _DoseOccurrenceCard extends StatelessWidget {
  const _DoseOccurrenceCard({
    required this.canManage,
    required this.occurrence,
    required this.onDoseAction,
  });

  final bool canManage;
  final DoseOccurrenceSummary occurrence;
  final DoseActionCallback? onDoseAction;

  bool get _isDue =>
      occurrence.status != 'SCHEDULED' ||
      !occurrence.plannedAt.isAfter(DateTime.now());

  bool get _canConfirm => const {
    'SCHEDULED',
    'REMINDER_SENT',
    'SNOOZED',
    'MISSED',
  }.contains(occurrence.status);

  bool get _canSnooze =>
      const {'SCHEDULED', 'REMINDER_SENT'}.contains(occurrence.status);

  bool get _canSkip => const {
    'SCHEDULED',
    'REMINDER_SENT',
    'SNOOZED',
  }.contains(occurrence.status);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colors.primaryContainer,
                  child: const Icon(Icons.medication_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        occurrence.medicationName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_friendlyTime(occurrence.plannedLocalDateTime)} · ${occurrence.quantityLabel}',
                      ),
                    ],
                  ),
                ),
                _DoseStatusChip(occurrence: occurrence),
              ],
            ),
            const SizedBox(height: 10),
            Text(_statusMessage(occurrence)),
            if (canManage &&
                onDoseAction != null &&
                _canConfirm &&
                _isDue &&
                !occurrence.pendingSync) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      key: Key('confirm-dose-${occurrence.id}'),
                      onPressed: () => _runAction(context, DoseAction.confirm),
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(
                        occurrence.status == 'MISSED'
                            ? 'Confirm late'
                            : 'Confirm',
                      ),
                    ),
                  ),
                  if (_canSnooze) ...[
                    const SizedBox(width: 8),
                    OutlinedButton(
                      key: Key('snooze-dose-${occurrence.id}'),
                      onPressed: () => _runAction(
                        context,
                        DoseAction.snooze,
                        snoozeMinutes: 10,
                      ),
                      child: const Text('Snooze'),
                    ),
                  ],
                  if (_canSkip)
                    TextButton(
                      key: Key('skip-dose-${occurrence.id}'),
                      onPressed: () => _confirmSkip(context),
                      child: const Text('Skip'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _runAction(
    BuildContext context,
    DoseAction action, {
    String? reason,
    int? snoozeMinutes,
  }) async {
    final saved = await onDoseAction!(
      occurrence,
      action,
      reason: reason,
      snoozeMinutes: snoozeMinutes,
    );
    if (!context.mounted) return;
    final message = saved
        ? switch (action) {
            DoseAction.confirm => 'Dose action saved on this phone.',
            DoseAction.snooze =>
              'Snoozed for $snoozeMinutes minutes and saved on this phone.',
            DoseAction.skip => 'Skip action saved on this phone.',
          }
        : 'Could not save this dose action. Please try again.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmSkip(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Skip this planned dose?'),
        content: const Text(
          'CareMate will record your choice. This is not medical advice; contact a clinician or pharmacist if you are unsure.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Go back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Mark skipped'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _runAction(context, DoseAction.skip);
    }
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

class _DoseStatusChip extends StatelessWidget {
  const _DoseStatusChip({required this.occurrence});

  final DoseOccurrenceSummary occurrence;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        occurrence.pendingSync
            ? 'Pending sync'
            : switch (occurrence.status) {
                'CONFIRMED' => 'Confirmed',
                'SKIPPED' => 'Skipped',
                'MISSED' => 'No outcome',
                'SNOOZED' => 'Snoozed',
                'NOT_SHARED' => 'Private',
                _ => 'Planned',
              },
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}

String _statusMessage(DoseOccurrenceSummary occurrence) =>
    occurrence.pendingSync
    ? 'Saved securely on this phone. Waiting for CareMate server confirmation.'
    : occurrence.syncConflictCode != null
    ? 'CareMate kept the latest server state after resolving this saved change.'
    : switch (occurrence.status) {
        'CONFIRMED' =>
          occurrence.timingClassification == 'LATE'
              ? 'Confirmed by you after the response window.'
              : 'Confirmed by you',
        'SKIPPED' => 'You marked this planned dose as skipped.',
        'MISSED' =>
          'CareMate did not receive an outcome by the response deadline.',
        'SNOOZED' =>
          'Snoozed until ${_friendlyClock(occurrence.snoozedUntil)}.',
        'NOT_SHARED' => 'The profile owner has kept dose outcomes private.',
        _ => 'Report what you do when this planned dose is due.',
      };

String _friendlyClock(DateTime? value) {
  if (value == null) return 'the selected time';
  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}

class _SyncStatusCard extends StatelessWidget {
  const _SyncStatusCard({
    required this.message,
    required this.onSyncNow,
    required this.pendingCount,
    required this.usingOfflineCache,
  });

  final String? message;
  final Future<void> Function()? onSyncNow;
  final int pendingCount;
  final bool usingOfflineCache;

  @override
  Widget build(BuildContext context) {
    final pending = pendingCount > 0;
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(pending ? Icons.cloud_upload_outlined : Icons.cloud_off),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pending
                        ? '$pendingCount saved change${pendingCount == 1 ? '' : 's'} waiting to sync'
                        : usingOfflineCache
                        ? 'Showing the saved plan on this phone'
                        : 'Sync status',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message ??
                        (pending
                            ? 'CareMate will retry automatically when Android allows network work.'
                            : 'You can continue using today’s saved plan while offline.'),
                  ),
                  if (onSyncNow != null) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      key: const Key('sync-now-button'),
                      onPressed: onSyncNow,
                      icon: const Icon(Icons.sync),
                      label: const Text('Sync now'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({required this.onEnable, required this.readiness});

  final Future<void> Function()? onEnable;
  final ReminderReadiness? readiness;

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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(_message),
                  if (_showButton) ...[
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: onEnable,
                      child: Text(
                        readiness?.notificationsAllowed == true
                            ? 'Improve timing'
                            : 'Enable reminders',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _showButton =>
      onEnable != null &&
      readiness?.supported == true &&
      readiness?.channelBlocked != true &&
      readiness?.ready != true;

  String get _title {
    final value = readiness;
    if (value == null) return 'Checking reminders';
    if (!value.supported) return 'Reminders unavailable';
    if (!value.notificationsAllowed) return 'Reminders need permission';
    if (!value.channelAllowed) return 'Reminder channel is blocked';
    if (!value.exactAlarmsAllowed) return 'Reminder timing may vary';
    return 'Reminders ready';
  }

  String get _message {
    final value = readiness;
    if (value == null) return 'Checking this device’s notification settings.';
    if (!value.supported) {
      return 'This device cannot schedule CareMate notifications.';
    }
    if (!value.notificationsAllowed) {
      return 'Allow notifications so CareMate can show planned dose reminders.';
    }
    if (!value.channelAllowed) {
      return 'Open Notifications, then use Android settings to allow the Medication reminders channel.';
    }
    if (!value.exactAlarmsAllowed) {
      return 'Notifications are on, but Android may deliver dose reminders later than planned.';
    }
    return 'Notifications and precise alarm access are available on this device.';
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
