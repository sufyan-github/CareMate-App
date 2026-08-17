import 'package:caremate/features/medications/domain/patient_medication_models.dart';
import 'package:caremate/features/reminders/domain/reminder_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds a deterministic bounded plan for unresolved occurrences', () {
    final now = DateTime.parse('2026-08-17T02:00:00.000Z');
    final builder = ReminderPlanBuilder(now: () => now);
    final due = _occurrence(
      id: 'due-1',
      plannedAt: now.add(const Duration(hours: 1)),
    );
    final snoozed = _occurrence(
      id: 'snoozed-1',
      plannedAt: now.subtract(const Duration(minutes: 5)),
      snoozedUntil: now.add(const Duration(minutes: 10)),
      status: 'SNOOZED',
    );
    final confirmed = _occurrence(
      id: 'confirmed-1',
      plannedAt: now.add(const Duration(hours: 2)),
      status: 'CONFIRMED',
    );
    final beyondHorizon = _occurrence(
      id: 'future-1',
      plannedAt: now.add(const Duration(days: 15)),
    );

    final plan = builder.build([due, snoozed, confirmed, beyondHorizon, due]);

    expect(plan, hasLength(2));
    expect(plan.map((item) => item.occurrenceId), ['snoozed-1', 'due-1']);
    expect(plan.first.scheduledAt, now.add(const Duration(minutes: 10)));
    expect(plan.last.scheduledAt, now.add(const Duration(hours: 1)));
    expect(plan.last.notificationId, greaterThan(0));
    expect(
      builder.build([due]).single.notificationId,
      plan.last.notificationId,
    );
    expect(
      builder.notificationIdFor('due-1', ruleRevision: 1),
      isNot(builder.notificationIdFor('due-1', ruleRevision: 2)),
    );
  });
}

DoseOccurrenceSummary _occurrence({
  required String id,
  required DateTime plannedAt,
  DateTime? snoozedUntil,
  String status = 'SCHEDULED',
}) => DoseOccurrenceSummary(
  id: id,
  medicationName: 'Napa',
  plannedAt: plannedAt,
  plannedLocalDateTime: '2026-08-17T08:00',
  quantityLabel: '1 tablet',
  snoozedUntil: snoozedUntil,
  status: status,
  version: 1,
);
