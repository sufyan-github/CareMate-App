class PatientProfile {
  const PatientProfile({
    this.accessRole = 'OWNER',
    this.canManage = true,
    required this.displayName,
    required this.id,
    required this.timezone,
    required this.version,
  });

  final String accessRole;
  final bool canManage;
  final String displayName;
  final String id;
  final String timezone;
  final int version;
}

class MedicationDraft {
  const MedicationDraft({
    required this.displayName,
    required this.form,
    required this.mealRelation,
    required this.quantityUnit,
    required this.quantityValue,
    required this.route,
    this.notes,
    this.sourceText,
    this.strengthUnit,
    this.strengthValue,
  });

  final String displayName;
  final String form;
  final String mealRelation;
  final String? notes;
  final String quantityUnit;
  final double quantityValue;
  final String route;
  final String? sourceText;
  final String? strengthUnit;
  final double? strengthValue;
}

class MedicationSummary {
  const MedicationSummary({
    this.activeSchedule,
    required this.displayName,
    required this.form,
    required this.id,
    required this.quantityLabel,
    required this.status,
    required this.strengthLabel,
  });

  final MedicationScheduleSummary? activeSchedule;
  final String displayName;
  final String form;
  final String id;
  final String quantityLabel;
  final String status;
  final String strengthLabel;
}

class MedicationScheduleDraft {
  const MedicationScheduleDraft({
    this.daysOfWeek = const [],
    required this.endDate,
    this.excludedDates = const [],
    this.recurrence = 'DAILY',
    required this.startDate,
    required this.times,
    required this.timezone,
  });

  final List<int> daysOfWeek;
  final DateTime? endDate;
  final List<DateTime> excludedDates;
  final String recurrence;
  final DateTime startDate;
  final List<String> times;
  final String timezone;
}

class ScheduleOccurrencePreview {
  const ScheduleOccurrencePreview({
    required this.plannedAt,
    required this.plannedLocalDateTime,
  });

  final DateTime plannedAt;
  final String plannedLocalDateTime;
}

class MedicationScheduleSummary {
  const MedicationScheduleSummary({
    this.daysOfWeek = const [],
    required this.endDate,
    this.excludedDates = const [],
    required this.id,
    required this.revision,
    this.recurrence = 'DAILY',
    required this.startDate,
    required this.status,
    required this.times,
    required this.timezone,
    required this.version,
  });

  final List<int> daysOfWeek;
  final DateTime? endDate;
  final List<DateTime> excludedDates;
  final String id;
  final int revision;
  final String recurrence;
  final DateTime startDate;
  final String status;
  final List<String> times;
  final String timezone;
  final int version;
}

class MedicationSchedulePlan {
  const MedicationSchedulePlan({
    required this.occurrences,
    required this.quantityRequired,
    required this.quantityUnit,
    this.schedule,
  });

  final List<ScheduleOccurrencePreview> occurrences;
  final double quantityRequired;
  final String quantityUnit;
  final MedicationScheduleSummary? schedule;
}

class DoseOccurrenceSummary {
  const DoseOccurrenceSummary({
    this.confirmedAt,
    required this.id,
    required this.medicationName,
    this.missedAt,
    required this.plannedAt,
    required this.plannedLocalDateTime,
    required this.quantityLabel,
    this.reminderSentAt,
    this.responseDueAt,
    this.ruleRevision = 1,
    this.snoozeCount = 0,
    this.snoozedUntil,
    required this.status,
    this.timingClassification,
    required this.version,
  });

  final DateTime? confirmedAt;
  final String id;
  final String medicationName;
  final DateTime? missedAt;
  final DateTime plannedAt;
  final String plannedLocalDateTime;
  final String quantityLabel;
  final DateTime? reminderSentAt;
  final DateTime? responseDueAt;
  final int ruleRevision;
  final int snoozeCount;
  final DateTime? snoozedUntil;
  final String status;
  final String? timingClassification;
  final int version;
}

enum DoseAction { confirm, snooze, skip }

class DoseCommand {
  const DoseCommand({
    required this.action,
    required this.clientAt,
    required this.clientMutationId,
    required this.occurrence,
    this.reason,
    this.snoozeMinutes,
  });

  final DoseAction action;
  final DateTime clientAt;
  final String clientMutationId;
  final DoseOccurrenceSummary occurrence;
  final String? reason;
  final int? snoozeMinutes;
}

enum ScheduleAction { pause, resume, end }
