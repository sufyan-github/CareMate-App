import 'package:caremate/features/medications/domain/patient_medication_models.dart';

typedef ReminderActionHandler =
    Future<void> Function(String occurrenceId, DoseAction action);

class ReminderReadiness {
  const ReminderReadiness({
    this.channelAllowed = true,
    required this.exactAlarmsAllowed,
    required this.notificationsAllowed,
    required this.supported,
  });

  final bool channelAllowed;
  final bool exactAlarmsAllowed;
  final bool notificationsAllowed;
  final bool supported;

  bool get ready =>
      supported && notificationsAllowed && channelAllowed && exactAlarmsAllowed;
  bool get degraded =>
      supported &&
      notificationsAllowed &&
      channelAllowed &&
      !exactAlarmsAllowed;
  bool get channelBlocked =>
      supported && notificationsAllowed && !channelAllowed;
}

abstract interface class ReminderScheduler {
  Future<void> initialize(ReminderActionHandler onAction);
  Future<void> openNotificationSettings();
  Future<ReminderReadiness> checkReadiness({bool request = false});
  Future<void> reconcile(List<DoseOccurrenceSummary> occurrences);
}

class UnsupportedReminderScheduler implements ReminderScheduler {
  const UnsupportedReminderScheduler();

  @override
  Future<void> initialize(ReminderActionHandler onAction) async {}

  @override
  Future<void> openNotificationSettings() async {}

  @override
  Future<ReminderReadiness> checkReadiness({bool request = false}) async =>
      const ReminderReadiness(
        exactAlarmsAllowed: false,
        notificationsAllowed: false,
        supported: false,
      );

  @override
  Future<void> reconcile(List<DoseOccurrenceSummary> occurrences) async {}
}
