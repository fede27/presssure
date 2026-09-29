import '../models/measurement.dart';
import '../models/settings.dart';
import 'formatting.dart';

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

  int get _day => weekdays.first;

  bool isDue(DateTime day) {
    switch (frequency) {
      case Frequency.daily:
        return true;
      case Frequency.fewTimesWeek:
        return weekdays.contains(day.weekday);
      case Frequency.weekly:
        return day.weekday == _day;
      case Frequency.biweekly:
        if (day.weekday != _day) return false;
        final firstDue = addDays(anchor, (_day - anchor.weekday) % 7);
        return (daysBetween(firstDue, day) ~/ 7) % 2 == 0;
      case Frequency.monthly:
        return day.weekday == _day && day.day <= 7;
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

  /// "domeniche", "giorni" or "misure": what a period is called in copy.
  String get occasionPlural => switch (frequency) {
    Frequency.daily => 'giorni',
    Frequency.fewTimesWeek => 'misure',
    _ => weekdayPlural(_day),
  };

  /// "domenica", "giorno" or "misura".
  String get occasionSingular => switch (frequency) {
    Frequency.daily => 'giorno',
    Frequency.fewTimesWeek => 'misura',
    _ => weekdayName(_day),
  };

  /// "ogni domenica", "ogni giorno", "lunedì e giovedì"...
  String describe() {
    switch (frequency) {
      case Frequency.daily:
        return 'ogni giorno';
      case Frequency.fewTimesWeek:
        final days = weekdays.toList()..sort();
        final names = days.map(weekdayName).toList();
        if (names.length == 1) return 'ogni ${names.first}';
        return '${names.sublist(0, names.length - 1).join(', ')} '
            'e ${names.last}';
      case Frequency.weekly:
        return 'ogni ${weekdayName(_day)}';
      case Frequency.biweekly:
        return 'ogni due ${weekdayPlural(_day)}';
      case Frequency.monthly:
        final first = _day == DateTime.sunday ? 'la prima' : 'il primo';
        return '$first ${weekdayName(_day)} del mese';
    }
  }
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
/// the monthly "jolly" that forgives one missed period per month.
class HabitTracker {
  HabitTracker._(
    this.schedule,
    this.periods,
    this.currentStreak,
    this.bestStreak,
    this.bestStreakPeriods,
    this.bestBeforeCurrentRun,
    this.recordBeatenAt,
    this.jollyAvailable,
  );

  factory HabitTracker(
    Schedule schedule,
    List<Measurement> measurements,
    DateTime now,
  ) {
    final sorted = [...measurements]
      ..sort((a, b) => a.takenAt.compareTo(b.takenAt));
    if (sorted.isEmpty) {
      return HabitTracker._(schedule, const [], 0, 0, null, 0, null, true);
    }

    final periods = schedule.periodsBetween(sorted.first.takenAt, now);
    final tracked = <TrackedPeriod>[];
    final jollyMonths = <int>{};
    var index = 0;
    var running = 0;
    var runStart = 0;
    var best = 0;
    List<Period>? bestRange;
    var bestOfEndedRuns = 0;
    DateTime? recordBeatenAt;

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
      } else {
        final month = p.start.year * 12 + p.start.month;
        if (running > 0 && jollyMonths.add(month)) {
          status = PeriodStatus.jolly;
        } else {
          status = PeriodStatus.missed;
          if (running > bestOfEndedRuns) bestOfEndedRuns = running;
          running = 0;
        }
      }
      tracked.add(TrackedPeriod(p, status, inPeriod, running));
    }

    final month = now.year * 12 + now.month;
    return HabitTracker._(
      schedule,
      tracked,
      running,
      best,
      bestRange,
      bestOfEndedRuns,
      recordBeatenAt,
      !jollyMonths.contains(month),
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
  final bool jollyAvailable;

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
