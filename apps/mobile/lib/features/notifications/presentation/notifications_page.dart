import 'package:caremate/features/medications/application/patient_medication_coordinator.dart';
import 'package:caremate/features/reminders/domain/reminder_plan.dart';
import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({required this.coordinator, super.key});

  final PatientMedicationCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: coordinator,
      builder: (context, _) {
        final plan = ReminderPlanBuilder().build(
          coordinator.reminderOccurrences,
        );
        final readiness = coordinator.reminderReadiness;
        return Scaffold(
          appBar: AppBar(title: const Text('Notifications')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          readiness?.ready == true
                              ? Icons.notifications_active_outlined
                              : Icons.notifications_off_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 32,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _readinessTitle(coordinator),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(_readinessMessage(coordinator)),
                              if (readiness?.supported == true &&
                                  readiness?.ready != true) ...[
                                const SizedBox(height: 12),
                                FilledButton(
                                  onPressed: readiness?.channelBlocked == true
                                      ? coordinator.openReminderSettings
                                      : coordinator.requestReminderPermissions,
                                  child: Text(
                                    readiness?.channelBlocked == true
                                        ? 'Open notification settings'
                                        : readiness?.notificationsAllowed ==
                                              true
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
                ),
                const SizedBox(height: 22),
                Text(
                  'Upcoming reminders',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                Text(
                  'CareMate keeps a rolling 14-day device plan. Schedule changes are reconciled when the app opens.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                if (plan.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No unresolved dose reminders are scheduled in the next 14 days.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  for (final reminder in plan)
                    Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          child: Text(
                            _day(reminder.occurrence.plannedLocalDateTime),
                          ),
                        ),
                        title: Text(
                          reminder.occurrence.medicationName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${_friendlyDateTime(reminder.occurrence.plannedLocalDateTime)} · ${reminder.occurrence.quantityLabel}',
                        ),
                        trailing: Icon(
                          readiness?.notificationsAllowed == true
                              ? Icons.schedule
                              : Icons.warning_amber_rounded,
                        ),
                      ),
                    ),
                const SizedBox(height: 18),
                const Text(
                  'Lock-screen messages hide medicine names by default. Notification actions record your own report; they do not prove that medicine was swallowed.',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String _readinessTitle(PatientMedicationCoordinator coordinator) {
  final readiness = coordinator.reminderReadiness;
  if (readiness == null) return 'Checking this device';
  if (!readiness.supported) return 'Device reminders unavailable';
  if (!readiness.notificationsAllowed) return 'Notification permission needed';
  if (!readiness.channelAllowed) return 'Reminder channel is blocked';
  if (!readiness.exactAlarmsAllowed) return 'Best-allowed timing active';
  return 'Precise reminders ready';
}

String _readinessMessage(PatientMedicationCoordinator coordinator) {
  final readiness = coordinator.reminderReadiness;
  if (readiness == null) return 'Reading Android notification settings.';
  if (!readiness.supported) {
    return 'CareMate could not access this device’s notification service.';
  }
  if (!readiness.notificationsAllowed) {
    return 'Allow notifications before CareMate can display planned dose reminders.';
  }
  if (!readiness.channelAllowed) {
    return 'Allow the Medication reminders channel in Android settings.';
  }
  if (!readiness.exactAlarmsAllowed) {
    return 'Reminders are scheduled, but Android may deliver them later than planned.';
  }
  return 'Notifications and precise alarm access are available.';
}

String _day(String localDateTime) => localDateTime.substring(8, 10);

String _friendlyDateTime(String localDateTime) {
  final date = DateTime.parse(localDateTime);
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';
  return '${date.day}/${date.month}/${date.year} · $hour:$minute $period';
}
