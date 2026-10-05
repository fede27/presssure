import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

/// What [LocalNotificationReminderService] needs from the notification
/// plugin; a fake in tests.
abstract class NotificationBackend {
  Future<void> init();

  Future<bool> requestPermission();

  /// Ids of the notifications scheduled and not shown yet.
  Future<Set<int>> pendingIds();

  /// Schedules [reminder], replacing the one with the same id.
  Future<void> schedule(
    PlannedReminder reminder, {
    required String channelName,
    required String channelDescription,
  });

  Future<void> cancel(int id);

  /// When the scheduled reminders go off: the app wakes up shortly before
  /// each one to bring it closer to its time (android ReminderHops.kt).
  Future<void> keepOnTime(List<DateTime> times);
}

/// Keeps the scheduled notifications in line with the plan, so that one
/// failure never leaves the user without reminders:
/// - the new plan is scheduled before the old notifications are removed
///   (same ids are replaced), never an empty gap in between;
/// - each reminder is scheduled on its own: one refused does not stop the
///   others;
/// - times gone by while planning are skipped instead of failing;
/// - if starting the plugin failed, it is tried again at the next plan.
///
/// Reminders are inexact (no special permission): Android may deliver them
/// up to an hour late, unless [NotificationBackend.keepOnTime] brings them
/// within about ten minutes.
class LocalNotificationReminderService implements ReminderService {
  LocalNotificationReminderService({
    NotificationBackend? backend,
    DateTime Function()? clock,
  }) : _backend = backend ?? PluginNotificationBackend(),
       _clock = clock ?? DateTime.now;

  final NotificationBackend _backend;
  final DateTime Function() _clock;
  bool _ready = false;

  /// Scheduled by this service since the app started: what to remove if
  /// the plugin can't list its pending notifications.
  final _scheduled = <int>{};

  @override
  Future<void> init() async {
    try {
      await _backend.init();
      _ready = true;
    } catch (e) {
      debugPrint('Reminders unavailable: $e');
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (!_ready) await init();
    if (!_ready) return false;
    try {
      return await _backend.requestPermission();
    } catch (e) {
      debugPrint('Notification permission not asked: $e');
      return false;
    }
  }

  @override
  Future<void> reschedule(
    List<PlannedReminder> plan, {
    required String channelName,
    required String channelDescription,
  }) async {
    if (!_ready) await init();
    if (!_ready) return;

    final kept = <int>{};
    for (final r in plan) {
      if (!r.at.isAfter(_clock())) continue;
      try {
        await _backend.schedule(
          r,
          channelName: channelName,
          channelDescription: channelDescription,
        );
        kept.add(r.id);
      } catch (e) {
        debugPrint('Reminder ${r.id} at ${r.at} not scheduled: $e');
      }
    }

    // The previous plan's leftovers, including a reminder that failed now
    // (its old time is no longer right).
    Set<int> pending;
    try {
      pending = await _backend.pendingIds();
    } catch (e) {
      debugPrint('Pending reminders not listed: $e');
      pending = {..._scheduled};
    }
    for (final id in pending.difference(kept)) {
      try {
        await _backend.cancel(id);
      } catch (e) {
        debugPrint('Reminder $id not cancelled: $e');
      }
    }
    _scheduled
      ..clear()
      ..addAll(kept);

    try {
      await _backend.keepOnTime([
        for (final r in plan)
          if (kept.contains(r.id)) r.at,
      ]);
    } catch (e) {
      debugPrint('Reminders not kept on time: $e');
    }
  }
}

/// flutter_local_notifications on Android.
class PluginNotificationBackend implements NotificationBackend {
  final _plugin = FlutterLocalNotificationsPlugin();

  @override
  Future<void> init() async {
    tzdata.initializeTimeZones();
    try {
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
    } catch (e) {
      // Reminders are scheduled as instants, so they still go off at the
      // right time; only the zone name is missing.
      debugPrint('Time zone unknown, reminders scheduled in UTC: $e');
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  }

  @override
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? true;
  }

  @override
  Future<Set<int>> pendingIds() async => {
    for (final r in await _plugin.pendingNotificationRequests()) r.id,
  };

  @override
  Future<void> schedule(
    PlannedReminder reminder, {
    required String channelName,
    required String channelDescription,
  }) => _plugin.zonedSchedule(
    id: reminder.id,
    scheduledDate: tz.TZDateTime.from(reminder.at, tz.local),
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        'reminders',
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    title: reminder.title,
    body: reminder.body,
  );

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  static const _channel = MethodChannel('presssure/reminders');

  @override
  Future<void> keepOnTime(List<DateTime> times) => _channel.invokeMethod(
    'setTargets',
    [for (final t in times) t.millisecondsSinceEpoch],
  );
}
