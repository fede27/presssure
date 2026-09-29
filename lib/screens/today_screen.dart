import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../logic/bp_category.dart';
import '../logic/schedule.dart';
import '../logic/stats.dart';
import '../models/settings.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/bp_chart.dart';
import '../widgets/common.dart';
import 'achievements_screen.dart';
import 'flows.dart';
import 'home_shell.dart';
import 'settings_screen.dart';

/// "01 · Oggi".
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final now = state.now();
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        children: [
          _Header(now: now),
          const SizedBox(height: 14),
          const _HabitCard(),
          const SizedBox(height: 14),
          if (state.latest == null)
            const _EmptyCard()
          else ...[
            const _LastReadingCard(),
            const SizedBox(height: 14),
            const _TrendCard(),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    LogoMark(size: 24),
                    SizedBox(width: 8),
                    Wordmark(size: 18),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  capitalize(context.dates.weekdayDayMonth(now)),
                  style: AppText.body(14, color: AppColors.muted),
                ),
                Semantics(
                  header: true,
                  child: Text(
                    l.greeting(greetingKey(now)),
                    style: AppText.display(32, weight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          Tooltip(
            message: l.settingsTitle,
            child: Material(
              color: AppColors.surface,
              shape: const CircleBorder(
                side: BorderSide(color: Color(0xFFDDD6CA)),
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => openSettings(context),
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.settings_outlined, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The dark card: today's task, the last periods and the two entry points.
class _HabitCard extends StatelessWidget {
  const _HabitCard();

  String _title(AppState state, AppLocalizations l, Dates dates) {
    final tracker = state.tracker;
    final now = state.now();
    if (state.latest == null) return l.todayFirstReading;
    final current = tracker.current!;
    if (current.status == PeriodStatus.done) {
      if (state.settings.frequency == Frequency.daily) return l.todayDoneDaily;
      final next = state.schedule.nextDueAfter(current.period.start);
      return l.todayDoneNext(dates.weekdayDayMonth(next));
    }
    if (current.period.start == dateOnly(now)) return l.todayIsTheDay;
    return l.todayMissing(dates.weekdayDayMonth(current.period.start));
  }

  /// "Oggi chiudi settembre al completo." when today's reading would
  /// complete the month.
  String? _encouragement(AppState state, AppLocalizations l, Dates dates) {
    final tracker = state.tracker;
    final current = tracker.current;
    if (current == null || tracker.currentDone) return null;
    final month = current.period.start.month;
    final next = state.schedule.nextDueAfter(current.period.start);
    final sameMonth = tracker.periods.where(
      (p) => p.period.start.month == month && p != current,
    );
    final firstDue = state.schedule.nextDueAfter(
      DateTime(current.period.start.year, month, 0),
    );
    final allDone = sameMonth.every((p) => p.status == PeriodStatus.done);
    final coversMonth = sameMonth.isEmpty
        ? current.period.start == firstDue
        : sameMonth.first.period.start == firstDue;
    if (next.month != month && allDone && coversMonth) {
      return l.todayCompleteMonth(dates.monthName(month));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final dates = context.dates;
    final state = AppScope.of(context);
    final tracker = state.tracker;
    final schedule = state.schedule;
    final streak = tracker.currentStreak;
    final extra = _encouragement(state, l, dates);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.habitCardSubtitle(
              schedule.describe(l),
              l.partOfDay(partOfDayKey(state.settings.reminderHour)),
            ),
            style: AppText.body(
              13,
              weight: FontWeight.w700,
              color: AppColors.onPrimaryMuted,
            ),
          ),
          const SizedBox(height: 4),
          Semantics(
            header: true,
            child: Text(
              _title(state, l, dates),
              style: AppText.display(
                28,
                color: Colors.white,
                height: 1.1,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _PeriodDots(periods: tracker.last(9)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: AppText.body(13, color: AppColors.onPrimarySoft),
                    children: [
                      if (streak > 0)
                        TextSpan(
                          text: '${l.inARow(streak)}.',
                          style: AppText.body(
                            13,
                            weight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        )
                      else
                        TextSpan(text: l.todayStartStreak),
                      if (extra != null) TextSpan(text: ' $extra'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppColors.primaryMuted,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AchievementsScreen(),
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.emoji_events_outlined,
                            size: 16,
                            color: AppColors.goldLight,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l.achievements,
                            style: AppText.body(
                              12,
                              weight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => showScanPlaceholder(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                  ),
                  icon: const Icon(Icons.photo_camera_outlined, size: 22),
                  label: Text(l.takePhoto),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => openNewMeasurement(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(64, 56),
                    foregroundColor: Colors.white,
                    side: const BorderSide(
                      color: AppColors.primaryOutline,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: AppText.body(15, weight: FontWeight.w800),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 22),
                  label: Text(l.byHand),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeriodDots extends StatelessWidget {
  const _PeriodDots({required this.periods});

  final List<TrackedPeriod> periods;

  @override
  Widget build(BuildContext context) {
    final done = periods.where((p) => p.status == PeriodStatus.done).length;
    final missed = periods
        .where(
          (p) =>
              p.status == PeriodStatus.missed || p.status == PeriodStatus.jolly,
        )
        .length;
    return Semantics(
      label: context.l10n.periodDotsLabel(periods.length, done, missed),
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < 9; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            Expanded(child: _dot(i < periods.length ? periods[i] : null)),
          ],
        ],
      ),
    );
  }

  Widget _dot(TrackedPeriod? p) {
    const height = 10.0;
    return switch (p?.status) {
      PeriodStatus.done => Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      PeriodStatus.pending => const DashedBorder(
        color: Colors.white,
        radius: 5,
        dash: 3,
        gap: 2,
        child: SizedBox(height: height),
      ),
      PeriodStatus.jolly => Container(
        height: height,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.goldLight, width: 1.5),
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      PeriodStatus.missed => Container(
        height: height,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primaryFaint, width: 1.5),
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      null => const SizedBox(height: height),
    };
  }
}

class _LastReadingCard extends StatelessWidget {
  const _LastReadingCard();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = AppScope.of(context);
    final list = state.measurements;
    final last = list.last;
    final before = list.length > 1 ? list[list.length - 2] : null;
    final parts = [
      if (last.pulse != null) l.pulseValue(last.pulse!),
      if (before != null)
        l.previousValue('${before.systolic}/${before.diastolic}'),
      state.thresholds.isEsc2024 ? l.bandByEsc : l.bandByCustom,
    ];
    return AppCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      onTap: () => openEditMeasurement(context, last),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.lastReadingOn(context.dates.weekdayDayMonth(last.takenAt)),
                  style: AppText.body(
                    14,
                    weight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                ),
              ),
              CategoryChip(state.categoryOf(last)),
            ],
          ),
          const SizedBox(height: 10),
          BpValue(systolic: last.systolic, diastolic: last.diastolic),
          const SizedBox(height: 10),
          Text(
            parts.join(' · '),
            style: AppText.body(13, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = AppScope.of(context);
    final now = state.now();
    final from = DateTime(now.year, now.month - 6, now.day);
    final items = state.measurements
        .where((m) => !m.takenAt.isBefore(from))
        .toList();
    final quarters = QuarterComparison.at(state.measurements, now);

    return AppCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l.last6Months,
                    style: AppText.body(16, weight: FontWeight.w800),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => HomeShell.select(context, HomeShell.trends),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l.navTrends),
                    const Icon(Icons.chevron_right_rounded, size: 18),
                  ],
                ),
              ),
            ],
          ),
          if (quarters.hasBoth) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: QuarterRow(quarters: quarters, compact: true),
            ),
            const SizedBox(height: 10),
          ],
          if (items.length >= 2) ...[
            BpChart(
              items: items,
              thresholds: state.thresholds,
              from: items.first.takenAt,
              to: items.last.takenAt,
              compact: true,
              height: 76,
              periodDays: state.schedule.periodDays,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _legend(const _DotLegend(), l.legendSingle),
                _legend(const _LineLegend(), l.legendAvg4),
                _legend(const _LineLegend(dashed: true), l.legendThreshold),
              ],
            ),
          ] else
            Text(l.trendEmpty, style: AppText.body(13, color: AppColors.muted)),
        ],
      ),
    );
  }

  Widget _legend(Widget marker, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      marker,
      const SizedBox(width: 6),
      Text(label, style: AppText.body(12, color: AppColors.muted)),
    ],
  );
}

class _DotLegend extends StatelessWidget {
  const _DotLegend();

  @override
  Widget build(BuildContext context) => Container(
    width: 6,
    height: 6,
    decoration: const BoxDecoration(
      color: AppColors.faint,
      shape: BoxShape.circle,
    ),
  );
}

class _LineLegend extends StatelessWidget {
  const _LineLegend({this.dashed = false});

  final bool dashed;

  @override
  Widget build(BuildContext context) => dashed
      ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              Container(width: 3, height: 1.5, color: AppColors.faint),
            ],
          ],
        )
      : Container(
          width: 14,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.faint,
            borderRadius: BorderRadius.circular(2),
          ),
        );
}

/// "apr – giu 141/90 → lug – set 129/81  −12/−9".
class QuarterRow extends StatelessWidget {
  const QuarterRow({super.key, required this.quarters, this.compact = false});

  final QuarterComparison quarters;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final dates = context.dates;
    final q = quarters;
    final down = q.deltaSystolic <= 0 && q.deltaDiastolic <= 0;
    final up = q.deltaSystolic > 0 && q.deltaDiastolic >= 0;
    final valueSize = compact ? 22.0 : 30.0;

    Widget side(DateTime from, DateTime to, BpAverage avg) {
      final range = dates.monthRange(from, to);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            compact ? range : l.quarterSide(range, l.readingsCount(avg.count)),
            style: AppText.body(
              12,
              weight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
          Text('$avg', style: AppText.display(valueSize, tabular: true)),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                side(q.previousFrom, q.previousTo, q.previous!),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: AppColors.faint,
                  ),
                ),
                side(q.currentFrom, q.currentTo, q.current!),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: down
                ? AppColors.greenSoft
                : up
                ? AppColors.warnSoft
                : AppColors.navBar,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${signed(q.deltaSystolic)}/${signed(q.deltaDiastolic)}',
            style: AppText.body(
              13,
              weight: FontWeight.w800,
              tabular: true,
              color: down
                  ? AppColors.green
                  : up
                  ? AppColors.warn
                  : AppColors.ink2,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = AppScope.of(context).thresholds;
    return AppCard(
      radius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.emptyTitle, style: AppText.body(16, weight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            l.emptyBody,
            style: AppText.body(
              14,
              weight: FontWeight.w500,
              height: 1.5,
              color: AppColors.ink2,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in BpCategory.values)
                Pill(
                  label: c.rangeLabel(l, t),
                  background: c.chipBackground,
                  foreground: c.chipForeground,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
