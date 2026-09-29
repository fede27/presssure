import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../logic/reminder_plan.dart';

/// Schedules the reminders computed by [planReminders].
abstract class ReminderService {
  Future<void> init();

  /// Asks for the notification permission (Android 13+). Returns whether
  /// notifications are allowed.
  Future<bool> requestPermission();

  /// Replaces every scheduled notification with [plan]. The channel name
  /// and description are shown in the Android notification settings.
  Future<void> reschedule(
    List<PlannedReminder> plan, {
    required String channelName,
    required String channelDescription,
  });
}

/// Used in tests and on platforms without notifications.
class NoopReminderService implements ReminderService {
  List<PlannedReminder> lastPlan = const [];

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> reschedule(
    List<PlannedReminder> plan, {
    required String channelName,
    required String channelDescription,
  }) async => lastPlan = plan;
}

class LocalNotificationReminderService implements ReminderService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  @override
  Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('Reminders unavailable: $e');
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? true;
  }

  @override
  Future<void> reschedule(
    List<PlannedReminder> plan, {
    required String channelName,
    required String channelDescription,
  }) async {
    if (!_ready) return;
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'reminders',
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _plugin.cancelAll();
    for (final r in plan) {
      await _plugin.zonedSchedule(
        id: r.id,
        scheduledDate: tz.TZDateTime.from(r.at, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: r.title,
        body: r.body,
      );
    }
  }
}
