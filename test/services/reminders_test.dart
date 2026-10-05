import 'package:flutter_test/flutter_test.dart';
import 'package:presssure/logic/reminder_plan.dart';
import 'package:presssure/services/reminders.dart';

import '../helpers.dart';

/// Keeps the scheduled notifications in memory, like the system would.
class FakeBackend implements NotificationBackend {
  final pending = <int, PlannedReminder>{};
  final calls = <String>[];
  int initFailures = 0;
  Set<int> refused = {};
  bool listFails = false;

  @override
  Future<void> init() async {
    calls.add('init');
    if (initFailures > 0) {
      initFailures--;
      throw StateError('plugin not ready');
    }
  }

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<Set<int>> pendingIds() async {
    if (listFails) throw StateError('cannot list');
    return pending.keys.toSet();
  }

  @override
  Future<void> schedule(
    PlannedReminder reminder, {
    required String channelName,
    required String channelDescription,
  }) async {
    calls.add('schedule ${reminder.id}');
    if (refused.contains(reminder.id)) throw StateError('refused');
    pending[reminder.id] = reminder;
  }

  @override
  Future<void> cancel(int id) async {
    calls.add('cancel $id');
    pending.remove(id);
  }

  List<DateTime>? onTime;
  bool onTimeFails = false;

  @override
  Future<void> keepOnTime(List<DateTime> times) async {
    if (onTimeFails) throw StateError('no hops');
    onTime = times;
  }
}

void main() {
  final now = DateTime(2026, 10, 4, 10);

  PlannedReminder at(int id, DateTime when) =>
      PlannedReminder(id, when, 'title $id', 'body');

  Future<void> reschedule(
    LocalNotificationReminderService service,
    List<PlannedReminder> plan,
  ) => service.reschedule(plan, channelName: 'c', channelDescription: 'd');

  late FakeBackend backend;
  late LocalNotificationReminderService service;

  setUp(() async {
    backend = FakeBackend();
    service = LocalNotificationReminderService(
      backend: backend,
      clock: () => now,
    );
    await service.init();
  });

  test('the new plan replaces the old one, leftovers are removed', () async {
    await reschedule(service, [
      at(100, DateTime(2026, 10, 4, 10, 30)),
      at(101, DateTime(2026, 10, 11, 10, 30)),
      at(200, DateTime(2026, 10, 5, 10, 30)),
    ]);
    // Measured: today's reminder and its nudge are no longer planned.
    await reschedule(service, [
      at(100, DateTime(2026, 10, 11, 10, 30)),
      at(101, DateTime(2026, 10, 18, 10, 30)),
    ]);
    expect(backend.pending.keys, unorderedEquals([100, 101]));
    expect(backend.pending[100]!.at, DateTime(2026, 10, 11, 10, 30));
  });

  test('scheduled first, then cancelled: never without reminders', () async {
    await reschedule(service, [at(100, DateTime(2026, 10, 4, 10, 30))]);
    backend.calls.clear();
    await reschedule(service, [at(101, DateTime(2026, 10, 11, 10, 30))]);
    expect(backend.calls, ['schedule 101', 'cancel 100']);
  });

  test('one reminder refused does not stop the others', () async {
    await reschedule(service, [at(101, DateTime(2026, 10, 11, 10, 30))]);
    backend.refused = {101};
    await reschedule(service, [
      at(100, DateTime(2026, 10, 4, 10, 30)),
      at(101, DateTime(2026, 10, 18, 10, 30)),
      at(102, DateTime(2026, 10, 25, 10, 30)),
    ]);
    // 101 kept its old time, which is no longer right: removed.
    expect(backend.pending.keys, unorderedEquals([100, 102]));
  });

  test('a time gone by while planning is skipped, not an error', () async {
    await reschedule(service, [
      at(100, now),
      at(101, DateTime(2026, 10, 11, 10, 30)),
    ]);
    expect(backend.pending.keys, [101]);
    expect(backend.calls, isNot(contains('schedule 100')));
  });

  test('without the list of pending ones, removes what it scheduled', () async {
    await reschedule(service, [
      at(100, DateTime(2026, 10, 4, 10, 30)),
      at(200, DateTime(2026, 10, 5, 10, 30)),
    ]);
    backend.listFails = true;
    await reschedule(service, [at(100, DateTime(2026, 10, 11, 10, 30))]);
    expect(backend.pending.keys, [100]);
  });

  test('if the plugin did not start, it is tried again', () async {
    backend = FakeBackend()..initFailures = 1;
    service = LocalNotificationReminderService(
      backend: backend,
      clock: () => now,
    );
    await service.init();
    await reschedule(service, [at(100, DateTime(2026, 10, 4, 10, 30))]);
    expect(backend.calls.where((c) => c == 'init').length, 2);
    expect(backend.pending.keys, [100]);
  });

  test('the scheduled times are kept on time', () async {
    backend.refused = {101};
    await reschedule(service, [
      at(100, now),
      at(101, DateTime(2026, 10, 11, 10, 30)),
      at(102, DateTime(2026, 10, 18, 10, 30)),
    ]);
    expect(backend.onTime, [DateTime(2026, 10, 18, 10, 30)]);
  });

  test('without hops the reminders are still scheduled', () async {
    backend.onTimeFails = true;
    await reschedule(service, [at(101, DateTime(2026, 10, 11, 10, 30))]);
    expect(backend.pending.keys, [101]);
  });

  test('a reading is saved even when reminders fail', () async {
    final state = await makeState(reminders: _FailingReminders());
    final m = reading(designNow, 128, 82, pulse: 70);
    await state.startReminders();
    await state.saveMeasurement(m);
    expect(state.measurements.map((x) => x.id), contains(m.id));
  });
}

class _FailingReminders implements ReminderService {
  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> reschedule(
    List<PlannedReminder> plan, {
    required String channelName,
    required String channelDescription,
  }) async => throw StateError('no notifications');
}
