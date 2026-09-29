import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n.dart';
import '../logic/achievements.dart';
import '../logic/schedule.dart';
import '../models/settings.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/badge_view.dart';
import '../widgets/common.dart';

/// "11 · Traguardi".
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final dates = context.dates;
    final state = AppScope.of(context);
    final report = state.achievements;
    final tracker = state.tracker;
    final t = state.thresholds;
    final range = report.bestStreakPeriods;

    return Scaffold(
      appBar: AppBar(title: Text(l.achievements), titleSpacing: 0),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          Row(
            children: [
              _Stat(value: '${tracker.currentStreak}', label: l.inARowStat),
              const SizedBox(width: 8),
              _Stat(value: '${tracker.bestStreak}', label: l.recordInARow),
              const SizedBox(width: 8),
              _Stat(
                value: '${state.measurements.length}',
                label: l.totalReadings,
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppCard(
            color: AppColors.orangeSoft,
            borderColor: null,
            child: Row(
              children: [
                const IconTile(
                  icon: Icons.style_outlined,
                  background: Colors.white,
                  foreground: AppColors.systolicDark,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.jollyAvailable(tracker.jollies),
                        style: AppText.body(15, weight: FontWeight.w800),
                      ),
                      Text(
                        l.jollyBody(
                          HabitTracker.jollyEvery,
                          HabitTracker.jollyMax,
                        ),
                        style: AppText.body(
                          13,
                          height: 1.4,
                          color: AppColors.ink2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _JollyProgress(tracker: tracker),
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (final (group, title) in [
            (BadgeGroup.consistency, l.groupConsistency),
            (BadgeGroup.habits, l.groupHabits),
            (BadgeGroup.trend, l.groupTrend),
          ]) ...[
            const SizedBox(height: 22),
            _BadgeSection(
              title: title,
              badges: report.inGroup(group).toList(),
              thresholds: t,
              now: state.now(),
              note: group == BadgeGroup.trend
                  ? l.trendGroupNote(t.highSystolic, t.highDiastolic)
                  : null,
            ),
          ],
          const SizedBox(height: 22),
          SectionHeading(l.personalRecords),
          const SizedBox(height: 10),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                _RecordRow(
                  label: l.longestStreak,
                  value: report.bestStreak == 0
                      ? '–'
                      : [
                          l.inARow(report.bestStreak),
                          if (range != null)
                            dates.monthRange(
                              range.first.start,
                              range.last.start,
                            ),
                        ].join(' · '),
                ),
                const Divider(),
                _RecordRow(
                  label: l.lowestMonth,
                  value: report.lowestMonth == null
                      ? '–'
                      : '${dates.monthName(report.lowestMonth!.month)} · '
                            '${report.lowestMonth!.avg}',
                ),
                const Divider(),
                _RecordRow(
                  label: l.onSchedule,
                  value: report.dueSoFar == 0
                      ? '–'
                      : l.onScheduleValue(
                          report.doneOnSchedule,
                          report.dueSoFar,
                          NumberFormat.percentPattern(dates.locale)
                              .format(report.doneOnSchedule / report.dueSoFar),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Periods to go before the next jolly.
class _JollyProgress extends StatelessWidget {
  const _JollyProgress({required this.tracker});

  final HabitTracker tracker;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final next = tracker.nextJollyIn;
    const every = HabitTracker.jollyEvery;
    return Semantics(
      label: next == null ? l.jollyFull : l.jollyNextSemantics(next),
      excludeSemantics: true,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: next == null ? 1 : (every - next) / every,
                minHeight: 6,
                color: AppColors.gold,
                backgroundColor: AppColors.navBar,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            next == null ? l.jollyFull : l.jollyNext(next),
            style: AppText.body(
              12,
              weight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppText.display(30, tabular: true)),
            Text(
              label,
              style: AppText.body(
                12,
                weight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeSection extends StatelessWidget {
  const _BadgeSection({
    required this.title,
    required this.badges,
    required this.thresholds,
    required this.now,
    this.note,
  });

  final String title;
  final List<Achievement> badges;
  final Thresholds thresholds;
  final DateTime now;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final unlocked = badges.where((b) => b.unlocked).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeading(
          title,
          trailing: note ?? context.l10n.progressOf(unlocked, badges.length),
        ),
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.fromLTRB(6, 18, 6, 14),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth / 3;
              return Wrap(
                runSpacing: 18,
                children: [
                  for (final b in badges)
                    SizedBox(
                      width: w,
                      child: _BadgeTile(
                        badge: b,
                        thresholds: thresholds,
                        now: now,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({
    required this.badge,
    required this.thresholds,
    required this.now,
  });

  final Achievement badge;
  final Thresholds thresholds;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final b = badge;
    final title = achievementTitle(b, l);
    final detail = achievementDetail(b, l, context.dates, now, thresholds);
    return Semantics(
      label: l.badgeSemantics(
        title,
        b.unlocked ? l.badgeUnlocked : l.badgeLocked,
        detail,
      ),
      excludeSemantics: true,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              BadgeMedal(badge: b),
              if (b.count > 1)
                Positioned(
                  right: -6,
                  bottom: -2,
                  child: Pill(
                    label: '×${b.count}',
                    background: AppColors.gold,
                    foreground: AppColors.ink,
                    fontSize: 10,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                  ),
                ),
              if (b.isNew(now))
                Positioned(
                  right: -14,
                  top: -8,
                  child: Pill(
                    label: l.newTag,
                    background: AppColors.systolic,
                    foreground: Colors.white,
                    fontSize: 10,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppText.body(
                13,
                weight: FontWeight.w800,
                height: 1.2,
                color: b.unlocked ? AppColors.ink : AppColors.ink2,
              ),
            ),
          ),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: AppText.body(
              11,
              weight: b.unlocked ? FontWeight.w600 : FontWeight.w700,
              color: b.unlocked ? AppColors.muted : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.body(14))),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppText.body(14, weight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
