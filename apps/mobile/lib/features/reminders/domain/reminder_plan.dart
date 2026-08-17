import 'package:caremate/features/medications/domain/patient_medication_models.dart';

class PlannedReminder {
  const PlannedReminder({
    required this.notificationId,
    required this.occurrence,
    required this.occurrenceId,
    required this.scheduledAt,
  });

  final int notificationId;
  final DoseOccurrenceSummary occurrence;
  final String occurrenceId;
  final DateTime scheduledAt;
}

class ReminderPlanBuilder {
  ReminderPlanBuilder({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  List<PlannedReminder> build(List<DoseOccurrenceSummary> occurrences) {
    final now = _now().toUtc();
    final horizon = now.add(const Duration(days: 14));
    final byOccurrence = <String, PlannedReminder>{};
    final usedNotificationIds = <int>{};
    for (final occurrence in occurrences) {
      if (byOccurrence.containsKey(occurrence.id)) continue;
      if (!const {
        'SCHEDULED',
        'REMINDER_SENT',
        'SNOOZED',
      }.contains(occurrence.status)) {
        continue;
      }
      final scheduledAt = occurrence.status == 'SNOOZED'
          ? occurrence.snoozedUntil?.toUtc()
          : occurrence.plannedAt.toUtc();
      if (scheduledAt == null || !scheduledAt.isAfter(now)) continue;
      if (scheduledAt.isAfter(horizon)) continue;
      var notificationId = notificationIdFor(
        occurrence.id,
        ruleRevision: occurrence.ruleRevision,
      );
      while (!usedNotificationIds.add(notificationId)) {
        notificationId = notificationId == 0x7fffffff ? 1 : notificationId + 1;
      }
      byOccurrence[occurrence.id] = PlannedReminder(
        notificationId: notificationId,
        occurrence: occurrence,
        occurrenceId: occurrence.id,
        scheduledAt: scheduledAt,
      );
    }
    final plan = byOccurrence.values.toList(growable: false)
      ..sort((left, right) {
        final time = left.scheduledAt.compareTo(right.scheduledAt);
        return time != 0
            ? time
            : left.occurrenceId.compareTo(right.occurrenceId);
      });
    return plan;
  }

  int notificationIdFor(String occurrenceId, {int ruleRevision = 1}) {
    var hash = 0x811c9dc5;
    for (final codeUnit in '$occurrenceId:$ruleRevision'.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }
}
