import 'dart:convert';

import 'package:caremate/features/care/domain/care_access_gateway.dart';
import 'package:caremate/features/care/domain/caregiver_alert_notifier.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FlutterCaregiverAlertNotifier implements CaregiverAlertNotifier {
  FlutterCaregiverAlertNotifier({
    FlutterLocalNotificationsPlugin? notifications,
  }) : _notifications = notifications ?? FlutterLocalNotificationsPlugin();

  static const _channelId = 'caregiver_missed_dose_alerts';
  final FlutterLocalNotificationsPlugin _notifications;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      _initialized =
          await _notifications.initialize(
            settings: const InitializationSettings(
              android: AndroidInitializationSettings('caremate_notification'),
            ),
          ) ??
          false;
    } on Exception {
      _initialized = false;
    }
  }

  @override
  Future<void> show(CaregiverAlert alert) async {
    await initialize();
    if (!_initialized) return;
    await _notifications.show(
      id: _notificationId(alert.id),
      title: 'CareMate family alert',
      body: '${alert.patientDisplayName} has a dose that needs attention.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Caregiver missed-dose alerts',
          channelDescription:
              'Private alerts shared by a patient with a trusted caregiver',
          icon: 'caremate_notification',
          importance: Importance.max,
          priority: Priority.max,
          visibility: NotificationVisibility.private,
          category: AndroidNotificationCategory.reminder,
        ),
      ),
      payload: jsonEncode({'category': 'CAREGIVER_ALERT', 'alertId': alert.id}),
    );
  }

  int _notificationId(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }
}
