import '../models/life_event.dart';
import '../models/measurement.dart';
import '../models/settings.dart';
import 'bp_category.dart';
import 'schedule.dart';
import 'stats.dart';

/// How long before and after an event the readings are compared.
enum ImpactWindow { twoWeeks, oneMonth, twoMonths, threeMonths }

/// [d] moved by [months] calendar months, kept within the month (31 March
/// minus one month is 28 or 29 February, not 3 March).
DateTime addMonths(DateTime d, int months) {
  final first = DateTime(d.year, d.month + months);
  final lastDay = DateTime(first.year, first.month + 1, 0).day;
  return DateTime(first.year, first.month, d.day > lastDay ? lastDay : d.day);
}

/// The readings before and after an event, over the same length of time.
///
/// Readings taken on the event's day count as "after". The averages show
/// whether the readings changed around that day, not why.
class EventImpact {
  EventImpact._({
    required this.event,
    required this.window,
    required this.beforeFrom,
    required this.afterTo,
    required this.before,
    required this.after,
    required this.missedBefore,
    required this.missedAfter,
    required this.others,
    required this.now,
  });

  factory EventImpact.of({
    required LifeEvent event,
    required List<Measurement> measurements,
    required List<LifeEvent> events,
    required ImpactWindow window,
    required HabitTracker tracker,
    required DateTime now,
  }) {
    final day = dateOnly(event.day);
    final (from, to) = switch (window) {
      ImpactWindow.twoWeeks => (addDays(day, -14), addDays(day, 14)),
      ImpactWindow.oneMonth => (addMonths(day, -1), addMonths(day, 1)),
      ImpactWindow.twoMonths => (addMonths(day, -2), addMonths(day, 2)),
      ImpactWindow.threeMonths => (addMonths(day, -3), addMonths(day, 3)),
    };
    List<DateTime> missed(DateTime a, DateTime b) => [
      for (final p in tracker.periods)
        if ((p.status == PeriodStatus.missed ||
                p.status == PeriodStatus.jolly) &&
            !p.period.start.isBefore(a) &&
            p.period.start.isBefore(b))
          p.period.start,
    ];
    return EventImpact._(
      event: event,
      window: window,
      beforeFrom: from,
      afterTo: to,
      before: sortedByDate(between(measurements, from, day)),
      after: sortedByDate(between(measurements, day, to)),
      missedBefore: missed(from, day),
      missedAfter: missed(day, to),
      others: [
        for (final e in sortedEvents(events))
          if (e.id != event.id && !e.day.isBefore(from) && e.day.isBefore(to))
            e,
      ],
      now: now,
    );
  }

  final LifeEvent event;
  final ImpactWindow window;
  final DateTime now;

  /// First day before (inclusive) and the day after the "after" period
  /// (exclusive); the event's day splits them.
  final DateTime beforeFrom;
  final DateTime afterTo;
  DateTime get day => dateOnly(event.day);

  /// Last day of each period, for labels ("1 – 30 giugno").
  DateTime get beforeLast => addDays(day, -1);
  DateTime get afterLast => addDays(afterTo, -1);

  /// Oldest first.
  final List<Measurement> before;
  final List<Measurement> after;

  /// Due days without a reading in each period.
  final List<DateTime> missedBefore;
  final List<DateTime> missedAfter;

  /// Other events within the two periods, which may have counted too.
  final List<LifeEvent> others;

  BpAverage? get beforeAvg => average(before);
  BpAverage? get afterAvg => average(after);
  bool get hasBoth => before.isNotEmpty && after.isNotEmpty;

  int get deltaSystolic => afterAvg!.systolic - beforeAvg!.systolic;
  int get deltaDiastolic => afterAvg!.diastolic - beforeAvg!.diastolic;

  /// The "after" period has not ended yet (its last day is today or later).
  bool get afterOngoing => afterTo.isAfter(dateOnly(now));

  /// The event is still to come: nothing "after" yet.
  bool get upcoming => day.isAfter(now);

  int highBefore(Thresholds t) => _high(before, t);
  int highAfter(Thresholds t) => _high(after, t);

  static int _high(List<Measurement> items, Thresholds t) => items
      .where((m) => classify(m.systolic, m.diastolic, t) == BpCategory.high)
      .length;
}
