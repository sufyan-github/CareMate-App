import 'dart:convert';

import 'package:caremate/features/medications/domain/patient_medication_models.dart';
import 'package:caremate/features/reminders/domain/reminder_plan.dart';
import 'package:caremate/features/reminders/domain/reminder_scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class FlutterReminderScheduler implements ReminderScheduler {
  FlutterReminderScheduler({
    FlutterLocalNotificationsPlugin? notifications,
    ReminderPlanBuilder? planBuilder,
  }) : _notifications = notifications ?? FlutterLocalNotificationsPlugin(),
       _planBuilder = planBuilder ?? ReminderPlanBuilder();

  static const _category = 'MEDICATION_REMINDER';
  static const _channelId = 'medication_reminders';

  final FlutterLocalNotificationsPlugin _notifications;
  final ReminderPlanBuilder _planBuilder;
  ReminderActionHandler? _onAction;
  bool _initialized = false;

  @override
  Future<void> initialize(ReminderActionHandler onAction) async {
    _onAction = onAction;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    tz.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } on Exception {
      tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));
    }
    _initialized =
        await _notifications.initialize(
          settings: const InitializationSettings(
            android: AndroidInitializationSettings('caremate_notification'),
          ),
          onDidReceiveNotificationResponse: _handleResponse,
        ) ??
        false;
  }

  @override
  Future<ReminderReadiness> checkReadiness({bool request = false}) async {
    if (!_initialized ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return const ReminderReadiness(
        exactAlarmsAllowed: false,
        notificationsAllowed: false,
        supported: false,
      );
    }
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) {
      return const ReminderReadiness(
        exactAlarmsAllowed: false,
        notificationsAllowed: false,
        supported: false,
      );
    }
    if (request) {
      final notificationsAllowed =
          await android.requestNotificationsPermission() ?? false;
      if (notificationsAllowed) {
        await android.requestExactAlarmsPermission();
      }
    }
    final channels = await android.getNotificationChannels() ?? const [];
    final reminderChannel = channels
        .where((channel) => channel.id == _channelId)
        .firstOrNull;
    return ReminderReadiness(
      channelAllowed:
          reminderChannel == null ||
          reminderChannel.importance != Importance.none,
      exactAlarmsAllowed:
          await android.canScheduleExactNotifications() ?? false,
      notificationsAllowed: await android.areNotificationsEnabled() ?? false,
      supported: true,
    );
  }

  @override
  Future<void> openNotificationSettings() async {
    await _notifications.openAppNotificationSettings();
  }

  @override
  Future<void> reconcile(List<DoseOccurrenceSummary> occurrences) async {
    if (!_initialized) return;
    final readiness = await checkReadiness();
    if (!readiness.notificationsAllowed || !readiness.channelAllowed) return;
    final plan = _planBuilder.build(occurrences);
    final desiredIds = plan.map((item) => item.notificationId).toSet();
    final pending = await _notifications.pendingNotificationRequests();
    for (final notification in pending) {
      if (_isMedicationReminder(notification.payload) &&
          !desiredIds.contains(notification.id)) {
        await _notifications.cancel(id: notification.id);
      }
    }

    final scheduleMode = readiness.exactAlarmsAllowed
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    for (final reminder in plan) {
      await _notifications.cancel(id: reminder.notificationId);
      await _notifications.zonedSchedule(
        id: reminder.notificationId,
        title: 'CareMate reminder',
        body: 'You have a CareMate reminder.',
        scheduledDate: tz.TZDateTime.from(reminder.scheduledAt, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Medication reminders',
            channelDescription:
                'Planned dose reminders confirmed by the CareMate user',
            icon: 'caremate_notification',
            importance: Importance.max,
            priority: Priority.max,
            visibility: NotificationVisibility.private,
            category: AndroidNotificationCategory.alarm,
            actions: [
              AndroidNotificationAction(
                'CONFIRM',
                'Confirm',
                showsUserInterface: true,
              ),
              AndroidNotificationAction(
                'SNOOZE',
                'Snooze 10 min',
                showsUserInterface: true,
              ),
              AndroidNotificationAction(
                'SKIP',
                'Skip',
                showsUserInterface: true,
              ),
            ],
          ),
        ),
        androidScheduleMode: scheduleMode,
        payload: jsonEncode({
          'category': _category,
          'occurrenceId': reminder.occurrenceId,
          'version': reminder.occurrence.version,
        }),
      );
    }
  }

  Future<void> _handleResponse(NotificationResponse response) async {
    final action = switch (response.actionId) {
      'CONFIRM' => DoseAction.confirm,
      'SNOOZE' => DoseAction.snooze,
      'SKIP' => DoseAction.skip,
      _ => null,
    };
    final payload = _payload(response.payload);
    final occurrenceId = payload?['occurrenceId'];
    if (action == null || occurrenceId is! String) return;
    await _onAction?.call(occurrenceId, action);
  }

  bool _isMedicationReminder(String? payload) =>
      _payload(payload)?['category'] == _category;

  Map<String, dynamic>? _payload(String? value) {
    if (value == null) return null;
    try {
      return jsonDecode(value) as Map<String, dynamic>;
    } on FormatException {
      return null;
    }
  }
}
