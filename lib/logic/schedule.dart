import '../models/measurement.dart';
import '../models/settings.dart';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Adds calendar days (safe across daylight-saving changes).
DateTime addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days);

/// Whole calendar days from [a] to [b].
int daysBetween(DateTime a, DateTime b) => DateTime.utc(
  b.year,
  b.month,
  b.day,
).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

/// A measuring window: from a due day (inclusive) to the next one (exclusive).
class Period {
  const Period(this.start, this.end);

  final DateTime start;
  final DateTime end;

  bool contains(DateTime t) => !t.isBefore(start) && t.isBefore(end);

  @override
  bool operator ==(Object other) =>
      other is Period && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'Period($start – $end)';
}

/// The user's measuring rhythm: which days are due.
class Schedule {
  Schedule({
    required this.frequency,
    required Set<int> weekdays,
    DateTime? anchor,
  }) : weekdays = weekdays.isEmpty ? {DateTime.sunday} : weekdays,
       anchor = dateOnly(anchor ?? DateTime(2024, 1, 1));

  factory Schedule.fromSettings(AppSettings s) =>
      Schedule(frequency: s.frequency, weekdays: s.weekdays, anchor: s.anchor);

  final Frequency frequency;
  final Set<int> weekdays;
  final DateTime anchor;

  /// The chosen weekday (the first one for [Frequency.fewTimesWeek]).
  int get day => weekdays.first;

  bool isDue(DateTime date) {
    switch (frequency) {
      case Frequency.daily:
        return true;
      case Frequency.fewTimesWeek:
        return weekdays.contains(date.weekday);
      case Frequency.weekly:
        return date.weekday == day;
      case Frequency.biweekly:
        if (date.weekday != day) return false;
        final firstDue = addDays(anchor, (day - anchor.weekday) % 7);
        return (daysBetween(firstDue, date) ~/ 7) % 2 == 0;
      case Frequency.monthly:
        return date.weekday == day && date.day <= 7;
    }
  }

  /// The latest due day on or before [t].
  DateTime dueOnOrBefore(DateTime t) {
    var d = dateOnly(t);
    for (var i = 0; i < 40; i++) {
      if (isDue(d)) return d;
      d = addDays(d, -1);
    }
    return d;
  }

  /// The first due day strictly after the day of [t].
  DateTime nextDueAfter(DateTime t) {
    var d = addDays(dateOnly(t), 1);
    for (var i = 0; i < 40; i++) {
      if (isDue(d)) return d;
      d = addDays(d, 1);
    }
    return d;
  }

  Period periodContaining(DateTime t) {
    final start = dueOnOrBefore(t);
    return Period(start, nextDueAfter(start));
  }

  /// All periods overlapping [from]..[to], in order.
  List<Period> periodsBetween(DateTime from, DateTime to) {
    final result = <Period>[];
    var start = dueOnOrBefore(from);
    while (!start.isAfter(to)) {
      final end = nextDueAfter(start);
      result.add(Period(start, end));
      start = end;
    }
    return result;
  }

  /// Average length of a period in days.
  double get periodDays => switch (frequency) {
    Frequency.daily => 1,
    Frequency.fewTimesWeek => 7 / weekdays.length,
    Frequency.weekly => 7,
    Frequency.biweekly => 14,
    Frequency.monthly => 30.44,
  };

  /// How many periods cover roughly [days] days.
  int periodsFor(int days) => (days / periodDays).round().clamp(1, 100000);
}

enum PeriodStatus { done, missed, jolly, pending }

class TrackedPeriod {
  TrackedPeriod(this.period, this.status, this.measurements, this.streak);

  final Period period;
  final PeriodStatus status;
  final List<Measurement> measurements;

  /// Streak length right after this period.
  final int streak;
}

/// Follows the habit over time: which periods were measured, streaks and
/// the jollies that keep a streak alive when a period is missed.
///
/// A jolly is earned every [jollyEvery] periods that go by (measured or
/// not), up to [jollyMax]; a missed period spends one if the streak is
/// running.
class HabitTracker {
  HabitTracker._(
    this.schedule,
    this.periods,
    this.currentStreak,
    this.bestStreak,
    this.bestStreakPeriods,
    this.bestBeforeCurrentRun,
    this.recordBeatenAt,
    this.jollies,
    this._elapsedCount,
  );

  static const jollyEvery = 10;
  static const jollyMax = 3;

  factory HabitTracker(
    Schedule schedule,
    List<Measurement> measurements,
    DateTime now,
  ) {
    final sorted = [...measurements]
      ..sort((a, b) => a.takenAt.compareTo(b.takenAt));
    if (sorted.isEmpty) {
      return HabitTracker._(schedule, const [], 0, 0, null, 0, null, 0, 0);
    }

    final periods = schedule.periodsBetween(sorted.first.takenAt, now);
    final tracked = <TrackedPeriod>[];
    var index = 0;
    var running = 0;
    var runStart = 0;
    var best = 0;
    List<Period>? bestRange;
    var bestOfEndedRuns = 0;
    DateTime? recordBeatenAt;
    var jollies = 0;
    var elapsed = 0;

    for (var i = 0; i < periods.length; i++) {
      final p = periods[i];
      final inPeriod = <Measurement>[];
      while (index < sorted.length && sorted[index].takenAt.isBefore(p.end)) {
        if (!sorted[index].takenAt.isBefore(p.start)) {
          inPeriod.add(sorted[index]);
        }
        index++;
      }

      final PeriodStatus status;
      if (inPeriod.isNotEmpty) {
        status = PeriodStatus.done;
        if (running == 0) runStart = i;
        running++;
        if (running > best) {
          best = running;
          bestRange = [periods[runStart], p];
        }
        if (recordBeatenAt == null &&
            bestOfEndedRuns >= 2 &&
            running == bestOfEndedRuns + 1) {
          recordBeatenAt = inPeriod.first.takenAt;
        }
      } else if (p.contains(now)) {
        status = PeriodStatus.pending;
      } else if (running > 0 && jollies > 0) {
        status = PeriodStatus.jolly;
        jollies--;
      } else {
        status = PeriodStatus.missed;
        if (running > bestOfEndedRuns) bestOfEndedRuns = running;
        running = 0;
      }
      if (status != PeriodStatus.pending) {
        elapsed++;
        if (elapsed % jollyEvery == 0 && jollies < jollyMax) jollies++;
      }
      tracked.add(TrackedPeriod(p, status, inPeriod, running));
    }

    return HabitTracker._(
      schedule,
      tracked,
      running,
      best,
      bestRange,
      bestOfEndedRuns,
      recordBeatenAt,
      jollies,
      elapsed,
    );
  }

  final Schedule schedule;

  /// From the period of the first measurement up to the current one.
  final List<TrackedPeriod> periods;
  final int currentStreak;
  final int bestStreak;

  /// First and last period of the best streak.
  final List<Period>? bestStreakPeriods;

  /// Longest streak that already ended before the current one.
  final int bestBeforeCurrentRun;
  final DateTime? recordBeatenAt;

  /// Jollies available now.
  final int jollies;
  final int _elapsedCount;

  bool get jollyAvailable => jollies > 0;

  /// Periods still to go before the next jolly; null when the jollies are
  /// already at [jollyMax].
  int? get nextJollyIn =>
      jollies >= jollyMax ? null : jollyEvery - _elapsedCount % jollyEvery;

  TrackedPeriod? get current => periods.isEmpty ? null : periods.last;

  bool get currentDone => current?.status == PeriodStatus.done;

  /// Periods that are over (the current one is excluded unless done).
  Iterable<TrackedPeriod> get elapsed =>
      periods.where((p) => p.status != PeriodStatus.pending);

  int get doneCount =>
      periods.where((p) => p.status == PeriodStatus.done).length;

  /// Last [n] periods, oldest first.
  List<TrackedPeriod> last(int n) =>
      periods.length <= n ? periods : periods.sublist(periods.length - n);
}
