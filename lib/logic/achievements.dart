import '../models/measurement.dart';
import '../models/settings.dart';
import 'bp_category.dart';
import 'schedule.dart';
import 'stats.dart';

enum BadgeGroup { consistency, habits, trend }

/// One achievement, unlocked or with its progress. Titles and details are
/// worded by `achievementTitle` / `achievementDetail` in `lib/l10n`.
class Achievement {
  const Achievement({
    required this.id,
    required this.group,
    required this.unlocked,
    this.unlockedAt,
    this.progress = 0,
    this.count = 0,
    this.value = 0,
    this.target = 0,
    this.month,
    this.average,
    this.deltaSystolic,
    this.deltaDiastolic,
    this.unlocksOn,
  });

  final String id;
  final BadgeGroup group;
  final bool unlocked;
  final DateTime? unlockedAt;
  final double progress;

  /// For repeatable badges ("Mese completo ×5").
  final int count;

  /// Progress so far and goal ("6 su 26"); for "Mese completo" the number of
  /// readings in the last complete month.
  final int value;
  final int target;

  /// Month the detail refers to ("settembre, 4 su 4", "agosto 128/81").
  final DateTime? month;
  final BpAverage? average;

  /// Change between quarters, for "Tendenza in calo".
  final int? deltaSystolic;
  final int? deltaDiastolic;

  /// Day the badge will unlock if things stay as they are.
  final DateTime? unlocksOn;

  /// Changes whenever the badge is unlocked again.
  String get key => '$id:$count';

  bool isNew(DateTime now) =>
      unlocked &&
      unlockedAt != null &&
      now.difference(unlockedAt!).inDays < 3 &&
      !unlockedAt!.isAfter(now);
}

/// Everything the achievements screen shows.
class AchievementsReport {
  AchievementsReport({
    required this.badges,
    required this.bestStreak,
    required this.bestStreakPeriods,
    required this.lowestMonth,
    required this.doneOnSchedule,
    required this.dueSoFar,
  });

  final List<Achievement> badges;
  final int bestStreak;

  /// First and last period of the best streak.
  final List<Period>? bestStreakPeriods;
  final MonthGroup? lowestMonth;

  /// Periods measured and periods gone by: "24 su 26".
  final int doneOnSchedule;
  final int dueSoFar;

  Iterable<Achievement> inGroup(BadgeGroup g) =>
      badges.where((b) => b.group == g);

  Achievement byId(String id) => badges.firstWhere((b) => b.id == id);

  Set<String> get unlockedKeys =>
      badges.where((b) => b.unlocked).map((b) => b.key).toSet();

  /// The locked badge closest to being unlocked.
  Achievement? get closest {
    final locked = badges.where((b) => !b.unlocked && b.progress > 0).toList()
      ..sort((a, b) => b.progress.compareTo(a.progress));
    return locked.isEmpty ? null : locked.first;
  }
}

Achievement _progressBadge({
  required String id,
  required BadgeGroup group,
  required int value,
  required int target,
  DateTime? unlockedAt,
}) {
  final unlocked = value >= target || unlockedAt != null;
  return Achievement(
    id: id,
    group: group,
    unlocked: unlocked,
    unlockedAt: unlocked ? unlockedAt : null,
    value: value,
    target: target,
    progress: (value / target).clamp(0, 1).toDouble(),
  );
}

/// When the running streak first reached [n], if ever.
DateTime? _streakReached(HabitTracker t, int n) {
  for (final p in t.periods) {
    if (p.status == PeriodStatus.done && p.streak >= n) {
      return p.measurements.first.takenAt;
    }
  }
  return null;
}

/// Months whose due periods were all measured, oldest first.
List<({DateTime month, int count, DateTime completedAt})> _completeMonths(
  HabitTracker t,
) {
  final schedule = t.schedule;
  final byMonth = <int, List<TrackedPeriod>>{};
  for (final p in t.periods) {
    byMonth
        .putIfAbsent(
          p.period.start.year * 12 + p.period.start.month - 1,
          () => [],
        )
        .add(p);
  }
  final result = <({DateTime month, int count, DateTime completedAt})>[];
  for (final entry in byMonth.entries) {
    final list = entry.value;
    final year = entry.key ~/ 12;
    final month = entry.key % 12 + 1;
    final firstDue = schedule.nextDueAfter(DateTime(year, month, 0));
    final afterLast = schedule.nextDueAfter(list.last.period.start);
    final covers =
        list.first.period.start == firstDue &&
        (afterLast.month != month || afterLast.year != year);
    if (covers && list.every((p) => p.status == PeriodStatus.done)) {
      result.add((
        month: DateTime(year, month),
        count: list.length,
        completedAt: list.last.measurements.first.takenAt,
      ));
    }
  }
  return result;
}

AchievementsReport computeAchievements({
  required HabitTracker tracker,
  required List<Measurement> measurements,
  required AppSettings settings,
  required DateTime now,
}) {
  final sorted = sortedByDate(measurements);
  final schedule = tracker.schedule;
  final t = settings.thresholds;
  final badges = <Achievement>[];

  // Costanza.
  badges.add(
    Achievement(
      id: 'first_step',
      group: BadgeGroup.consistency,
      unlocked: sorted.isNotEmpty,
      unlockedAt: sorted.firstOrNull?.takenAt,
      value: sorted.isEmpty ? 0 : 1,
      target: 1,
      progress: sorted.isEmpty ? 0 : 1,
    ),
  );

  for (final (id, days) in [('two_months', 56), ('three_months', 91)]) {
    final n = schedule.periodsFor(days);
    badges.add(
      _progressBadge(
        id: id,
        group: BadgeGroup.consistency,
        value: tracker.currentStreak,
        target: n,
        unlockedAt: _streakReached(tracker, n),
      ),
    );
  }

  final halfYear = schedule.periodsFor(182);
  final elapsed = tracker.elapsed.toList();
  badges.add(
    _progressBadge(
      id: 'six_months',
      group: BadgeGroup.consistency,
      value: elapsed.length,
      target: halfYear,
      unlockedAt: elapsed.length >= halfYear
          ? elapsed[halfYear - 1].period.start
          : null,
    ),
  );

  final complete = _completeMonths(tracker);
  badges.add(
    Achievement(
      id: 'month_complete',
      group: BadgeGroup.consistency,
      unlocked: complete.isNotEmpty,
      unlockedAt: complete.lastOrNull?.completedAt,
      month: complete.lastOrNull?.month,
      value: complete.lastOrNull?.count ?? 0,
      progress: complete.isEmpty ? 0 : 1,
      count: complete.length,
    ),
  );

  TrackedPeriod? comeback;
  for (var i = 1; i < tracker.periods.length; i++) {
    if (tracker.periods[i].status == PeriodStatus.done &&
        tracker.periods[i - 1].status == PeriodStatus.missed) {
      comeback = tracker.periods[i];
    }
  }
  badges.add(
    Achievement(
      id: 'comeback',
      group: BadgeGroup.consistency,
      unlocked: comeback != null,
      unlockedAt: comeback?.measurements.first.takenAt,
    ),
  );

  badges.add(
    _progressBadge(
      id: 'no_pause',
      group: BadgeGroup.consistency,
      value: tracker.currentStreak,
      target: halfYear,
      unlockedAt: _streakReached(tracker, halfYear),
    ),
  );

  final toBeat = tracker.bestBeforeCurrentRun < 2
      ? 0
      : tracker.bestBeforeCurrentRun + 1;
  badges.add(
    Achievement(
      id: 'beat_record',
      group: BadgeGroup.consistency,
      unlocked: tracker.recordBeatenAt != null,
      unlockedAt: tracker.recordBeatenAt,
      value: tracker.currentStreak,
      target: toBeat,
      progress: toBeat == 0
          ? 0
          : (tracker.currentStreak / toBeat).clamp(0, 1).toDouble(),
    ),
  );

  // Twelve months with at least one reading; the first reading of each
  // month marks it.
  final diaryMonths = <DateTime>[];
  for (final m in sorted) {
    final month = DateTime(m.takenAt.year, m.takenAt.month);
    if (diaryMonths.isEmpty || diaryMonths.last != month) {
      diaryMonths.add(month);
    }
  }
  DateTime? firstIn(DateTime month) => sorted
      .firstWhere((m) => DateTime(m.takenAt.year, m.takenAt.month) == month)
      .takenAt;
  badges.add(
    _progressBadge(
      id: 'year',
      group: BadgeGroup.consistency,
      value: diaryMonths.length,
      target: 12,
      unlockedAt: diaryMonths.length >= 12 ? firstIn(diaryMonths[11]) : null,
    ),
  );

  // Buone abitudini.
  final firstHigh = sorted
      .where((m) => classify(m.systolic, m.diastolic, t) == BpCategory.high)
      .firstOrNull;
  badges.add(
    Achievement(
      id: 'honest',
      group: BadgeGroup.habits,
      unlocked: firstHigh != null,
      unlockedAt: firstHigh?.takenAt,
    ),
  );

  DateTime? nth(Iterable<Measurement> items, int n) =>
      items.length >= n ? items.elementAt(n - 1).takenAt : null;

  final photos = sorted.where((m) => m.source == ReadingSource.photo);
  badges.add(
    _progressBadge(
      id: 'lynx',
      group: BadgeGroup.habits,
      value: photos.length,
      target: 10,
      unlockedAt: nth(photos, 10),
    ),
  );

  badges.add(
    Achievement(
      id: 'first_pdf',
      group: BadgeGroup.habits,
      unlocked: settings.shares.isNotEmpty,
      unlockedAt: settings.shares.firstOrNull,
    ),
  );

  final notes = sorted.where((m) => m.hasNote);
  badges.add(
    _progressBadge(
      id: 'notes',
      group: BadgeGroup.habits,
      value: notes.length,
      target: 10,
      unlockedAt: nth(notes, 10),
    ),
  );

  final doubles = sorted.where((m) => m.doubleReading);
  badges.add(
    _progressBadge(
      id: 'double',
      group: BadgeGroup.habits,
      value: doubles.length,
      target: 5,
      unlockedAt: nth(doubles, 5),
    ),
  );

  // Andamento, sulle medie mensili.
  final months = groupByMonth(sorted).reversed.toList(); // oldest first
  final currentMonthStart = DateTime(now.year, now.month);
  final closed = months.where((g) => g.start.isBefore(currentMonthStart));
  final lastBelow = closed.where((g) => g.avg!.isBelow(t)).lastOrNull;
  badges.add(
    Achievement(
      id: 'month_below',
      group: BadgeGroup.trend,
      unlocked: lastBelow != null,
      unlockedAt: lastBelow?.end,
      month: lastBelow?.start,
      average: lastBelow?.avg,
    ),
  );

  final quarters = QuarterComparison.at(sorted, now);
  final falling =
      quarters.hasBoth &&
      quarters.deltaSystolic < 0 &&
      quarters.deltaDiastolic <= 0;
  badges.add(
    Achievement(
      id: 'trend_down',
      group: BadgeGroup.trend,
      unlocked: falling,
      deltaSystolic: quarters.hasBoth ? quarters.deltaSystolic : null,
      deltaDiastolic: quarters.hasBoth ? quarters.deltaDiastolic : null,
    ),
  );

  // Three consecutive closed months below the threshold.
  var run = 0;
  DateTime? quarterAt;
  MonthGroup? previous;
  for (final g in closed) {
    final consecutive =
        previous != null &&
        DateTime(previous.year, previous.month + 1) == g.start;
    run = g.avg!.isBelow(t) ? (consecutive ? run + 1 : 1) : 0;
    if (run >= 3) quarterAt ??= g.end;
    previous = g;
  }
  final currentMonth = months.where((g) => g.start == currentMonthStart);
  final currentBelow =
      currentMonth.isNotEmpty && currentMonth.first.avg!.isBelow(t);
  final lastClosedIsPrevious =
      closed.isNotEmpty &&
      DateTime(closed.last.year, closed.last.month + 1) == currentMonthStart;
  final almost =
      quarterAt == null && run == 2 && lastClosedIsPrevious && currentBelow;
  badges.add(
    Achievement(
      id: 'quarter_below',
      group: BadgeGroup.trend,
      unlocked: quarterAt != null,
      unlockedAt: quarterAt,
      value: run.clamp(0, 3),
      target: 3,
      unlocksOn: almost ? DateTime(now.year, now.month + 1, 0) : null,
      progress: quarterAt != null ? 1 : (almost ? 0.9 : run / 3),
    ),
  );

  MonthGroup? lowest;
  for (final g in months) {
    if (lowest == null ||
        g.avg!.systolic + g.avg!.diastolic <
            lowest.avg!.systolic + lowest.avg!.diastolic) {
      lowest = g;
    }
  }

  return AchievementsReport(
    badges: badges,
    bestStreak: tracker.bestStreak,
    bestStreakPeriods: tracker.bestStreakPeriods,
    lowestMonth: lowest,
    doneOnSchedule: tracker.doneCount,
    dueSoFar: tracker.elapsed.length,
  );
}
