import 'package:flutter_test/flutter_test.dart';
import 'package:presssure/logic/event_impact.dart';
import 'package:presssure/logic/schedule.dart';
import 'package:presssure/models/life_event.dart';

import '../helpers.dart';

void main() {
  final readings = designReadings(includeToday: true);
  final events = designEvents();
  final tracker = HabitTracker(
    Schedule.fromSettings(onboardedSettings),
    readings,
    designNow,
  );

  EventImpact impactOf(
    LifeEvent e, [
    ImpactWindow window = ImpactWindow.oneMonth,
  ]) => EventImpact.of(
    event: e,
    measurements: readings,
    events: events,
    window: window,
    tracker: tracker,
    now: designNow,
  );

  test('a month before and after the new job, as in the design', () {
    final i = impactOf(events[1]);
    expect(i.beforeFrom, DateTime(2026, 6, 1));
    expect(i.beforeLast, DateTime(2026, 6, 30));
    expect(i.afterLast, DateTime(2026, 7, 31));
    expect('${i.beforeAvg} (${i.before.length})', '141/89 (4)');
    expect('${i.afterAvg} (${i.after.length})', '134/84 (4)');
    expect((i.deltaSystolic, i.deltaDiastolic), (-7, -5));
    expect(i.others, isEmpty);
    expect(i.afterOngoing, isFalse);
    expect(i.highBefore(onboardedSettings.thresholds), 4);
    expect(i.highAfter(onboardedSettings.thresholds), 3);
  });

  test('the walk: missing readings in the month before', () {
    final i = impactOf(events[2]);
    expect('${i.beforeAvg} (${i.before.length})', '129/82 (3)');
    expect('${i.afterAvg} (${i.after.length})', '127/80 (4)');
    expect(i.missedBefore, [DateTime(2026, 8, 9), DateTime(2026, 8, 16)]);
    expect(i.missedAfter, isEmpty);
  });

  test('three months: other events and a period still running', () {
    final i = impactOf(events[1], ImpactWindow.threeMonths);
    expect(i.beforeFrom, DateTime(2026, 4, 1));
    expect(i.afterLast, DateTime(2026, 9, 30));
    expect(i.before.length, 13);
    expect(i.after.length, 11);
    expect(i.others.map((e) => e.id), ['e1', 'e3']);
    expect(i.afterOngoing, isTrue);
    expect(i.missedAfter, [DateTime(2026, 8, 9), DateTime(2026, 8, 16)]);
  });

  test('two weeks: 14 days on each side', () {
    final i = impactOf(events[1], ImpactWindow.twoWeeks);
    expect(i.beforeFrom, DateTime(2026, 6, 17));
    expect(i.afterLast, DateTime(2026, 7, 14));
    expect(i.before.length, 2);
    expect(i.after.length, 2);
  });

  test("readings of the event's day count as after", () {
    final e = LifeEvent(
      id: 'x',
      day: DateTime(2026, 9, 20),
      category: EventCategory.other,
      title: 'x',
    );
    final i = impactOf(e, ImpactWindow.twoWeeks);
    expect(i.after.first.takenAt, DateTime(2026, 9, 20, 8, 5));
    expect(i.before.last.takenAt, DateTime(2026, 9, 13, 8, 20));
  });

  test('months keep within the month', () {
    expect(addMonths(DateTime(2026, 3, 31), -1), DateTime(2026, 2, 28));
    expect(addMonths(DateTime(2024, 3, 31), -1), DateTime(2024, 2, 29));
    expect(addMonths(DateTime(2026, 11, 30), 3), DateTime(2027, 2, 28));
    expect(addMonths(DateTime(2026, 7, 1), -1), DateTime(2026, 6, 1));
  });

  test('no readings after yet: no difference', () {
    final e = LifeEvent(
      id: 'x',
      day: DateTime(2026, 9, 28),
      category: EventCategory.other,
      title: 'x',
    );
    final i = impactOf(e);
    expect(i.after, isEmpty);
    expect(i.afterAvg, isNull);
    expect(i.hasBoth, isFalse);
  });

  test('the "after" period that ends today is still running', () {
    final e = LifeEvent(
      id: 'x',
      day: DateTime(2026, 9, 14),
      category: EventCategory.other,
      title: 'x',
    );
    final i = impactOf(e, ImpactWindow.twoWeeks);
    expect(i.afterLast, DateTime(2026, 9, 27));
    expect(i.afterOngoing, isTrue);
  });
}
