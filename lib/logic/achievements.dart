import '../models/measurement.dart';
import '../models/settings.dart';
import 'bp_category.dart';
import 'formatting.dart';
import 'schedule.dart';
import 'stats.dart';

enum BadgeGroup { consistency, habits, trend }

/// One achievement, unlocked or with its progress.
class Achievement {
  const Achievement({
    required this.id,
    required this.group,
    required this.title,
    required this.unlocked,
    required this.detail,
    this.unlockedAt,
    this.progress = 0,
    this.count = 0,
  });

  final String id;
  final BadgeGroup group;
  final String title;
  final bool unlocked;
  final DateTime? unlockedAt;

  /// Date of unlock, or progress such as "6 su 26".
  final String detail;
  final double progress;

  /// For repeatable badges ("Mese completo ×5").
  final int count;

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
    required this.bestStreakRange,
    required this.lowestMonth,
    required this.completeMonths,
    required this.monthsTracked,
  });

  final List<Achievement> badges;
  final int bestStreak;
  final String? bestStreakRange;
  final MonthGroup? lowestMonth;
  final int completeMonths;
  final int monthsTracked;

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

String _when(DateTime d, DateTime now) =>
    dateOnly(d) == dateOnly(now) ? 'oggi' : formatDayMonthShort(d);

Achievement _progressBadge({
  required String id,
  required BadgeGroup group,
  required String title,
  required int value,
  required int target,
  DateTime? unlockedAt,
  required DateTime now,
}) {
  final unlocked = value >= target || unlockedAt != null;
  return Achievement(
    id: id,
    group: group,
    title: title,
    unlocked: unlocked,
    unlockedAt: unlocked ? unlockedAt : null,
    detail: unlocked && unlockedAt != null
        ? _when(unlockedAt, now)
        : '${value.clamp(0, target)} su $target',
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
List<({int year, int month, int count, DateTime completedAt})> _completeMonths(
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
  final result = <({int year, int month, int count, DateTime completedAt})>[];
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
        year: year,
        month: month,
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
      title: 'Primo passo',
      unlocked: sorted.isNotEmpty,
      unlockedAt: sorted.isEmpty ? null : sorted.first.takenAt,
      detail: sorted.isEmpty ? '0 su 1' : _when(sorted.first.takenAt, now),
      progress: sorted.isEmpty ? 0 : 1,
    ),
  );

  for (final (id, title, days) in [
    ('two_months', 'Due mesi di fila', 56),
    ('three_months', 'Tre mesi di fila', 91),
  ]) {
    final n = schedule.periodsFor(days);
    badges.add(
      _progressBadge(
        id: id,
        group: BadgeGroup.consistency,
        title: title,
        value: tracker.currentStreak,
        target: n,
        unlockedAt: _streakReached(tracker, n),
        now: now,
      ),
    );
  }

  final halfYear = schedule.periodsFor(182);
  final diaryAge = tracker.elapsed.length;
  badges.add(
    _progressBadge(
      id: 'six_months',
      group: BadgeGroup.consistency,
      title: 'Sei mesi di diario',
      value: diaryAge,
      target: halfYear,
      unlockedAt: diaryAge >= halfYear
          ? tracker.periods[halfYear - 1].period.start
          : null,
      now: now,
    ),
  );

  final complete = _completeMonths(tracker);
  badges.add(
    Achievement(
      id: 'month_complete',
      group: BadgeGroup.consistency,
      title: 'Mese completo',
      unlocked: complete.isNotEmpty,
      unlockedAt: complete.isEmpty ? null : complete.last.completedAt,
      detail: complete.isEmpty
          ? 'tutte le misure di un mese'
          : '${monthName(complete.last.month)}, '
                '${complete.last.count} su ${complete.last.count}',
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
      title: 'Ripartenza',
      unlocked: comeback != null,
      unlockedAt: comeback?.measurements.first.takenAt,
      detail: comeback == null
          ? 'riprendi dopo una pausa'
          : '${_when(comeback.measurements.first.takenAt, now)}, '
                'dopo la pausa',
      progress: 0,
    ),
  );

  badges.add(
    _progressBadge(
      id: 'no_pause',
      group: BadgeGroup.consistency,
      title: 'Mezzo anno senza pause',
      value: tracker.currentStreak,
      target: halfYear,
      unlockedAt: _streakReached(tracker, halfYear),
      now: now,
    ),
  );

  final toBeat = tracker.bestBeforeCurrentRun < 2
      ? 0
      : tracker.bestBeforeCurrentRun + 1;
  badges.add(
    Achievement(
      id: 'beat_record',
      group: BadgeGroup.consistency,
      title: 'Batti il record',
      unlocked: tracker.recordBeatenAt != null,
      unlockedAt: tracker.recordBeatenAt,
      detail: tracker.recordBeatenAt != null
          ? _when(tracker.recordBeatenAt!, now)
          : toBeat == 0
          ? 'dopo la prima serie'
          : '${tracker.currentStreak} su $toBeat',
      progress: toBeat == 0 ? 0 : (tracker.currentStreak / toBeat).clamp(0, 1),
    ),
  );

  final year = schedule.periodsFor(364);
  final yearTitle = switch (settings.frequency) {
    Frequency.daily || Frequency.fewTimesWeek => 'Un anno di misure',
    _ => 'Un anno di ${schedule.occasionPlural}',
  };
  final done = tracker.periods
      .where((p) => p.status == PeriodStatus.done)
      .toList();
  badges.add(
    _progressBadge(
      id: 'year',
      group: BadgeGroup.consistency,
      title: yearTitle,
      value: done.length,
      target: year,
      unlockedAt: done.length >= year
          ? done[year - 1].measurements.first.takenAt
          : null,
      now: now,
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
      title: 'Diario sincero',
      unlocked: firstHigh != null,
      unlockedAt: firstHigh?.takenAt,
      detail: 'registri anche i giorni no',
      progress: 0,
    ),
  );

  DateTime? nth(Iterable<Measurement> items, int n) =>
      items.length >= n ? items.elementAt(n - 1).takenAt : null;

  final photos = sorted.where((m) => m.source == ReadingSource.photo);
  badges.add(
    _progressBadge(
      id: 'lynx',
      group: BadgeGroup.habits,
      title: 'Occhio di lince',
      value: photos.length,
      target: 10,
      unlockedAt: nth(photos, 10),
      now: now,
    ),
  );

  badges.add(
    Achievement(
      id: 'first_pdf',
      group: BadgeGroup.habits,
      title: 'Primo PDF condiviso',
      unlocked: settings.shares.isNotEmpty,
      unlockedAt: settings.shares.firstOrNull,
      detail: settings.shares.isEmpty
          ? 'esporta il diario'
          : _when(settings.shares.first, now),
    ),
  );

  final notes = sorted.where((m) => m.hasNote);
  badges.add(
    _progressBadge(
      id: 'notes',
      group: BadgeGroup.habits,
      title: 'Note che aiutano',
      value: notes.length,
      target: 10,
      unlockedAt: nth(notes, 10),
      now: now,
    ),
  );

  final doubles = sorted.where((m) => m.doubleReading);
  badges.add(
    _progressBadge(
      id: 'double',
      group: BadgeGroup.habits,
      title: 'Doppia lettura',
      value: doubles.length,
      target: 5,
      unlockedAt: nth(doubles, 5),
      now: now,
    ),
  );

  // Andamento, sulle medie mensili.
  final months = groupByMonth(sorted).reversed.toList(); // oldest first
  final currentMonthStart = DateTime(now.year, now.month);
  final closed = months.where((g) => g.start.isBefore(currentMonthStart));
  final belowMonths = closed.where((g) => g.avg!.isBelow(t)).toList();
  final lastBelow = belowMonths.lastOrNull;
  badges.add(
    Achievement(
      id: 'month_below',
      group: BadgeGroup.trend,
      title: 'Mese sotto soglia',
      unlocked: lastBelow != null,
      unlockedAt: lastBelow?.end,
      detail: lastBelow == null
          ? 'media del mese sotto ${t.highSystolic}/${t.highDiastolic}'
          : '${monthName(lastBelow.month)} ${lastBelow.avg}',
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
      title: 'Tendenza in calo',
      unlocked: falling,
      detail: quarters.hasBoth
          ? '${signed(quarters.deltaSystolic)}/'
                '${signed(quarters.deltaDiastolic)} tra trimestri'
          : 'servono due trimestri',
    ),
  );

  // Three consecutive closed months below the threshold.
  var run = 0;
  var bestRun = 0;
  DateTime? quarterAt;
  MonthGroup? previous;
  for (final g in closed) {
    final consecutive =
        previous != null &&
        DateTime(previous.year, previous.month + 1) == g.start;
    run = g.avg!.isBelow(t) ? (consecutive ? run + 1 : 1) : 0;
    if (run > bestRun) bestRun = run;
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
  final lastDay = DateTime(now.year, now.month + 1, 0);
  badges.add(
    Achievement(
      id: 'quarter_below',
      group: BadgeGroup.trend,
      title: 'Trimestre sotto soglia',
      unlocked: quarterAt != null,
      unlockedAt: quarterAt,
      detail: quarterAt != null
          ? 'da ${formatDayMonthShort(quarterAt)}'
          : almost
          ? 'si sblocca il ${lastDay.day}'
          : '${run.clamp(0, 3)} su 3',
      progress: quarterAt != null ? 1 : (almost ? 0.9 : run / 3),
    ),
  );

  final range = tracker.bestStreakPeriods;
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
    bestStreakRange: range == null
        ? null
        : formatMonthRange(range.first.start, range.last.start),
    lowestMonth: lowest,
    completeMonths: complete.length,
    monthsTracked: _monthsTouched(tracker),
  );
}

int _monthsTouched(HabitTracker t) => t.periods
    .map((p) => p.period.start.year * 12 + p.period.start.month)
    .toSet()
    .length;
