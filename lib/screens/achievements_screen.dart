import 'package:flutter/material.dart';

import '../logic/achievements.dart';
import '../logic/formatting.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/badge_view.dart';
import '../widgets/common.dart';

/// "11 · Traguardi".
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final report = state.achievements;
    final tracker = state.tracker;
    final schedule = state.schedule;
    final now = state.now();
    final plural = schedule.occasionPlural;

    return Scaffold(
      appBar: AppBar(title: const Text('Traguardi'), titleSpacing: 0),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          Row(
            children: [
              _Stat(
                value: '${tracker.currentStreak}',
                label: '$plural di fila',
              ),
              const SizedBox(width: 8),
              _Stat(value: '${tracker.bestStreak}', label: 'record di fila'),
              const SizedBox(width: 8),
              _Stat(
                value: '${state.measurements.length}',
                label: 'misure totali',
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
                        tracker.jollyAvailable
                            ? 'Jolly del mese: 1 disponibile'
                            : 'Jolly del mese: già usato',
                        style: AppText.body(15, weight: FontWeight.w800),
                      ),
                      Text(
                        'Salti una ${schedule.occasionSingular}? Il jolly tiene '
                        'viva la serie. Ne ricevi uno ogni mese.',
                        style: AppText.body(
                          13,
                          height: 1.4,
                          color: AppColors.ink2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (final (group, title) in [
            (BadgeGroup.consistency, 'Costanza'),
            (BadgeGroup.habits, 'Buone abitudini'),
            (BadgeGroup.trend, 'Andamento'),
          ]) ...[
            const SizedBox(height: 22),
            _BadgeSection(
              title: title,
              badges: report.inGroup(group).toList(),
              now: now,
              note: group == BadgeGroup.trend
                  ? 'soglia ${state.thresholds.highSystolic}/'
                        '${state.thresholds.highDiastolic}, sulle medie mensili'
                  : null,
            ),
          ],
          const SizedBox(height: 22),
          SectionHeading('Record personali'),
          const SizedBox(height: 10),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                _RecordRow(
                  label: 'Serie più lunga',
                  value: report.bestStreak == 0
                      ? '–'
                      : '${report.bestStreak} $plural'
                            '${report.bestStreakRange == null ? '' : ' · ${report.bestStreakRange}'}',
                ),
                const Divider(),
                _RecordRow(
                  label: 'Mese con la media più bassa',
                  value: report.lowestMonth == null
                      ? '–'
                      : '${monthName(report.lowestMonth!.month)} · '
                            '${report.lowestMonth!.avg}',
                ),
                const Divider(),
                _RecordRow(
                  label: 'Mesi senza $plural saltate',
                  value: '${report.completeMonths} su ${report.monthsTracked}',
                ),
              ],
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
    required this.now,
    this.note,
  });

  final String title;
  final List<Achievement> badges;
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
          trailing: note ?? '$unlocked su ${badges.length}',
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
                      child: _BadgeTile(badge: b, now: now),
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
  const _BadgeTile({required this.badge, required this.now});

  final Achievement badge;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final b = badge;
    return Semantics(
      label:
          '${b.title}, ${b.unlocked ? 'sbloccato' : 'da sbloccare'}, '
          '${b.detail}',
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
                    label: 'NUOVO',
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
              b.title,
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
            b.detail,
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
