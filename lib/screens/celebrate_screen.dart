import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../logic/achievements.dart';
import '../logic/stats.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/badge_view.dart';
import '../widgets/common.dart';
import 'achievements_screen.dart';
import 'flows.dart';

/// "09 · Dopo il salvataggio: festeggiamo".
class CelebrateScreen extends StatelessWidget {
  const CelebrateScreen({super.key, required this.outcome});

  final SaveOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final dates = context.dates;
    final state = AppScope.of(context);
    final tracker = state.tracker;
    final schedule = state.schedule;
    final m = outcome.measurement;
    final value = '${m.systolic}/${m.diastolic}';
    final badge = outcome.newBadges.firstOrNull;
    final streak = tracker.currentStreak;
    final streakLabel = schedule.inARow(l, streak);
    final all = state.measurements;
    final lowest =
        all.length >= 3 &&
        all.every(
          (x) =>
              x.id == m.id ||
              x.systolic + x.diastolic > m.systolic + m.diastolic,
        );
    final last4 = averageOfLast(all);
    final closest = state.achievements.closest;
    final record = tracker.bestStreak;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        bottom: false,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
              child: Column(
                children: [
                  _Medal(badge: badge),
                  const SizedBox(height: 14),
                  Text(
                    badge != null ? l.newBadge : l.readingSaved,
                    style: AppText.body(
                      13,
                      weight: FontWeight.w800,
                      letterSpacing: 1,
                      color: AppColors.goldLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Semantics(
                    header: true,
                    child: Text(
                      badge != null
                          ? l.celebrateTitleBadge(
                              achievementTitle(badge, l, schedule),
                            )
                          : l.celebrateTitleStreak(streakLabel),
                      textAlign: TextAlign.center,
                      style: AppText.display(
                        34,
                        weight: FontWeight.w700,
                        height: 1.05,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    badge != null
                        ? _badgeLine(state, l, dates, outcome.newBadges.length)
                        : l.celebrateInDiary(value),
                    textAlign: TextAlign.center,
                    style: AppText.body(
                      15,
                      weight: FontWeight.w500,
                      height: 1.45,
                      color: const Color(0xFFD9ECEB),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _CardRow(
                          icon: Icons.local_fire_department_outlined,
                          background: AppColors.orangeSoft,
                          foreground: AppColors.systolicDark,
                          title: streakLabel,
                          subtitle: tracker.jollyAvailable
                              ? l.jollyAvailableLine
                              : l.jollyUsedLine,
                        ),
                        const SizedBox(height: 10),
                        _StreakBar(current: streak, record: record),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    child: _CardRow(
                      icon: Icons.trending_down_rounded,
                      background: AppColors.greenSoft,
                      foreground: AppColors.green,
                      title: lowest
                          ? l.lowestSince(
                              value,
                              dates.monthName(all.first.takenAt.month),
                            )
                          : l.readingStored(value),
                      subtitle: last4 == null
                          ? ''
                          : l.avgOfLast(last4.count, '$last4'),
                    ),
                  ),
                  if (closest != null) ...[
                    const SizedBox(height: 12),
                    AppCard(
                      child: Row(
                        children: [
                          BadgeMedal(badge: closest, size: 44),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l.almostBadge(
                                    achievementTitle(closest, l, schedule),
                                  ),
                                  style: AppText.body(
                                    16,
                                    weight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  achievementDetail(
                                    closest,
                                    l,
                                    dates,
                                    state.now(),
                                    state.thresholds,
                                  ),
                                  style: AppText.body(
                                    13,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primarySoft,
                            foregroundColor: AppColors.primary,
                          ),
                          onPressed: () => Navigator.of(context)
                              .pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const AchievementsScreen(),
                                ),
                              ),
                          child: Text(l.achievements),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => backToHome(context),
                          child: Text(l.done),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "Dal 5 aprile 24 misure su 26 domeniche."
  String _badgeLine(
    AppState state,
    AppLocalizations l,
    Dates dates,
    int count,
  ) {
    final first = state.measurements.first.takenAt;
    final done = state.tracker.doneCount;
    final total = state.tracker.periods.length;
    final more = count > 1 ? l.andMoreBadges(count - 1) : '';
    return l.celebrateSince(
          dates.dayMonth(first),
          l.readingsCount(done),
          total,
          state.schedule.occasions(l, total),
        ) +
        more;
  }
}

class _Medal extends StatelessWidget {
  const _Medal({required this.badge});

  final Achievement? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: const BoxDecoration(
        color: AppColors.gold,
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(10),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          badge == null ? Icons.check_rounded : badgeIcon(badge!.id),
          size: 56,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconTile(icon: icon, background: background, foreground: foreground),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.body(16, weight: FontWeight.w800)),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: AppText.body(13, height: 1.4, color: AppColors.muted),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Progress of the current streak towards the record.
class _StreakBar extends StatelessWidget {
  const _StreakBar({required this.current, required this.record});

  final int current;
  final int record;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isRecord = current >= record;
    final target = isRecord ? current : record + 1;
    final labelStyle = AppText.body(
      12,
      weight: FontWeight.w700,
      color: AppColors.muted,
    );
    return Semantics(
      label: isRecord
          ? l.streakRecordSemantics(current)
          : l.streakToBeat(current, record + 1, record),
      excludeSemantics: true,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: target == 0 ? 0 : current / target,
              minHeight: 8,
              color: AppColors.systolic,
              backgroundColor: AppColors.navBar,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l.streakNow(current), style: labelStyle),
              Text(
                isRecord ? l.newRecord : l.recordValue(record),
                style: labelStyle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
