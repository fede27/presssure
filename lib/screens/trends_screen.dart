import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../logic/bp_category.dart';
import '../logic/schedule.dart';
import '../logic/stats.dart';
import '../models/measurement.dart';
import '../models/settings.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/bp_chart.dart';
import '../widgets/common.dart';
import 'home_shell.dart';
import 'today_screen.dart';

enum TrendRange { threeMonths, sixMonths, year, all }

/// "06 · Andamento".
class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  var _range = TrendRange.sixMonths;

  String _label(AppLocalizations l, TrendRange r) => switch (r) {
    TrendRange.threeMonths => l.range3m,
    TrendRange.sixMonths => l.range6m,
    TrendRange.year => l.range1y,
    TrendRange.all => l.rangeAll,
  };

  DateTime? _from(DateTime now) => switch (_range) {
    TrendRange.threeMonths => DateTime(now.year, now.month - 3, now.day),
    TrendRange.sixMonths => DateTime(now.year, now.month - 6, now.day),
    TrendRange.year => DateTime(now.year - 1, now.month, now.day),
    TrendRange.all => null,
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = AppScope.of(context);
    final now = state.now();
    final from = _from(now);
    final items = state.measurements
        .where((m) => from == null || !m.takenAt.isBefore(from))
        .toList();
    final t = state.thresholds;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      l.navTrends,
                      style: AppText.display(32, weight: FontWeight.w700),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l.exportAndShare,
                  onPressed: () => HomeShell.select(context, HomeShell.share),
                  icon: const Icon(Icons.ios_share_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final r in TrendRange.values) ...[
                if (r != TrendRange.threeMonths) const SizedBox(width: 6),
                Expanded(
                  child: ChoicePill(
                    label: _label(l, r),
                    selected: _range == r,
                    minHeight: 40,
                    onTap: () => setState(() => _range = r),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Text(
                l.trendsEmpty,
                style: AppText.body(14, color: AppColors.muted),
              ),
            )
          else ...[
            _AverageCard(items: items, rangeLabel: _label(l, _range)),
            const SizedBox(height: 12),
            _ChartCard(items: items, from: from, now: now),
            const SizedBox(height: 12),
            _QuarterCard(now: now),
            const SizedBox(height: 12),
            _RegularityCard(tracker: state.tracker),
            const SizedBox(height: 12),
            _BandsCard(items: items, thresholds: t, now: now),
          ],
        ],
      ),
    );
  }
}

class _AverageCard extends StatelessWidget {
  const _AverageCard({required this.items, required this.rangeLabel});

  final List<Measurement> items;
  final String rangeLabel;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final last4 = averageOfLast(items)!;
    final all = average(items)!;
    final small = AppText.body(13, color: AppColors.muted);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.lastNReadings(last4.count),
                  style: AppText.body(
                    14,
                    weight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 4),
                BpValue(
                  systolic: last4.systolic,
                  diastolic: last4.diastolic,
                  size: 48,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l.readingsInRange(l.readingsCount(items.length), rangeLabel),
                style: small,
              ),
              if (all.pulse != null) Text(l.avgPulse(all.pulse!), style: small),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.items,
    required this.from,
    required this.now,
  });

  final List<Measurement> items;
  final DateTime? from;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = AppScope.of(context);
    final start = from ?? items.first.takenAt;
    final gaps = state.tracker.periods
        .where(
          (p) =>
              (p.status == PeriodStatus.missed ||
                  p.status == PeriodStatus.jolly) &&
              p.period.end.isAfter(start),
        )
        .map((p) => p.period)
        .toList();
    final last = items.last;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.yourReadings,
                    style: AppText.body(15, weight: FontWeight.w800),
                  ),
                ),
                _swatch(AppColors.systolic, l.sysShort),
                const SizedBox(width: 12),
                _swatch(AppColors.diastolic, l.diaShort),
              ],
            ),
          ),
          const SizedBox(height: 8),
          BpChart(
            items: items,
            thresholds: state.thresholds,
            from: start,
            to: now,
            gaps: gaps,
            periodDays: state.schedule.periodDays,
            highlightLabel: dateOnly(last.takenAt) == dateOnly(now)
                ? l.todayCapital
                : context.dates.dayMonthShort(last.takenAt),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _legend(
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.faint,
                      shape: BoxShape.circle,
                    ),
                  ),
                  l.legendSingle,
                ),
                _legend(
                  Container(width: 14, height: 3, color: AppColors.faint),
                  l.legendAvg4,
                ),
                _legend(
                  Container(width: 14, height: 10, color: AppColors.background),
                  l.legendSkipped,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _swatch(Color color, String label) => Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: AppText.body(12, weight: FontWeight.w700)),
    ],
  );

  Widget _legend(Widget marker, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      marker,
      const SizedBox(width: 6),
      Text(label, style: AppText.body(12, color: AppColors.muted)),
    ],
  );
}

class _QuarterCard extends StatelessWidget {
  const _QuarterCard({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final dates = context.dates;
    final state = AppScope.of(context);
    final q = QuarterComparison.at(state.measurements, now);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.quarterCompare,
            style: AppText.body(15, weight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (q.hasBoth)
            QuarterRow(quarters: q)
          else
            Text(
              l.quarterNeedTwo(
                dates.monthRange(q.previousFrom, q.previousTo),
                dates.monthRange(q.currentFrom, q.currentTo),
              ),
              style: AppText.body(13, color: AppColors.muted),
            ),
        ],
      ),
    );
  }
}

class _RegularityCard extends StatelessWidget {
  const _RegularityCard({required this.tracker});

  final HabitTracker tracker;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final periods = tracker.last(26);
    final schedule = tracker.schedule;
    final done = periods.where((p) => p.status == PeriodStatus.done).length;
    final elapsed = periods
        .where((p) => p.status != PeriodStatus.pending)
        .length;
    final streak = tracker.currentStreak;
    final small = AppText.body(12, color: AppColors.muted);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.regularity,
                  style: AppText.body(15, weight: FontWeight.w800),
                ),
              ),
              Text(
                l.regularityCount(done, schedule.occasions(l, done), elapsed),
                style: AppText.body(
                  13,
                  weight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Semantics(
            label: l.regularityLabel(done, elapsed),
            excludeSemantics: true,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const cols = 13;
                const gap = 5.0;
                final w = (constraints.maxWidth - gap * (cols - 1)) / cols;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [for (final p in periods) _cell(p.status, w)],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                periods.isEmpty
                    ? ''
                    : context.dates.dayMonth(periods.first.period.start),
                style: small,
              ),
              Expanded(
                child: Text(
                  streak > 0 ? schedule.inARow(l, streak) : '',
                  textAlign: TextAlign.center,
                  style: AppText.body(
                    12,
                    weight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Text(l.todayLower, style: small),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cell(PeriodStatus status, double w) {
    const h = 18.0;
    return switch (status) {
      PeriodStatus.done => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      PeriodStatus.pending => SizedBox(
        width: w,
        height: h,
        child: const DashedBorder(
          radius: 5,
          dash: 3,
          gap: 2,
          child: SizedBox.expand(),
        ),
      ),
      _ => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          border: Border.all(
            color: status == PeriodStatus.jolly
                ? AppColors.gold
                : AppColors.borderStrong,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    };
  }
}

class _BandsCard extends StatelessWidget {
  const _BandsCard({
    required this.items,
    required this.thresholds,
    required this.now,
  });

  final List<Measurement> items;
  final Thresholds thresholds;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = AppScope.of(context);
    final counts = countByCategory(items, thresholds);
    final total = items.length;
    final quarterStart = DateTime(now.year, now.month - 2);
    final recent = items.where((m) => !m.takenAt.isBefore(quarterStart));
    final recentBelow = recent
        .where((m) => state.categoryOf(m) != BpCategory.high)
        .length;
    final order = [
      BpCategory.high,
      BpCategory.elevated,
      BpCategory.nonElevated,
    ];
    final note = AppText.body(12, height: 1.45, color: AppColors.muted);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.bandsTitle, style: AppText.body(15, weight: FontWeight.w800)),
          const SizedBox(height: 12),
          Semantics(
            label: order.map((c) => '${c.label(l)}: ${counts[c]}').join(', '),
            excludeSemantics: true,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: SizedBox(
                height: 14,
                child: Row(
                  children: [
                    for (final c in order)
                      if (counts[c]! > 0)
                        Expanded(
                          flex: counts[c]!,
                          child: Container(
                            margin: const EdgeInsets.only(right: 3),
                            color: c.bandColor,
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final c in order)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: c.bandColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      c.rangeLabel(l, thresholds),
                      style: AppText.body(14),
                    ),
                  ),
                  Text(
                    '${counts[c]}',
                    style: AppText.body(
                      14,
                      weight: FontWeight.w800,
                      tabular: true,
                    ),
                  ),
                ],
              ),
            ),
          if (recent.isNotEmpty && recent.length != total)
            Text(
              l.bandsRecent(
                context.dates.monthName(quarterStart.month),
                recentBelow,
                recent.length,
                thresholds.highSystolic,
                thresholds.highDiastolic,
              ),
              style: note,
            ),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  thresholds.isEsc2024 ? l.bandsDefaultEsc : l.bandsCustom,
                  style: note,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => showThresholdsDialog(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(
                    color: AppColors.borderStrong,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: AppText.body(13, weight: FontWeight.w800),
                ),
                child: Text(l.changeThresholds),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> showThresholdsDialog(BuildContext context) async {
  final state = AppScope.read(context);
  final result = await showDialog<Thresholds>(
    context: context,
    builder: (_) => _ThresholdsDialog(initial: state.thresholds),
  );
  if (result != null) {
    await state.updateSettings(state.settings.copyWith(thresholds: result));
  }
}

class _ThresholdsDialog extends StatefulWidget {
  const _ThresholdsDialog({required this.initial});

  final Thresholds initial;

  @override
  State<_ThresholdsDialog> createState() => _ThresholdsDialogState();
}

class _ThresholdsDialogState extends State<_ThresholdsDialog> {
  late final _highSys = TextEditingController(
    text: '${widget.initial.highSystolic}',
  );
  late final _highDia = TextEditingController(
    text: '${widget.initial.highDiastolic}',
  );
  late final _elevSys = TextEditingController(
    text: '${widget.initial.elevatedSystolic}',
  );
  late final _elevDia = TextEditingController(
    text: '${widget.initial.elevatedDiastolic}',
  );
  String? _error;

  @override
  void dispose() {
    for (final c in [_highSys, _highDia, _elevSys, _elevDia]) {
      c.dispose();
    }
    super.dispose();
  }

  void _reset() {
    const e = Thresholds.esc2024;
    setState(() {
      _highSys.text = '${e.highSystolic}';
      _highDia.text = '${e.highDiastolic}';
      _elevSys.text = '${e.elevatedSystolic}';
      _elevDia.text = '${e.elevatedDiastolic}';
      _error = null;
    });
  }

  void _save() {
    final l = context.l10n;
    final values = [
      _highSys,
      _highDia,
      _elevSys,
      _elevDia,
    ].map((c) => int.tryParse(c.text)).toList();
    if (values.any((v) => v == null || v < 40 || v > 250)) {
      setState(() => _error = l.thresholdsErrRange);
      return;
    }
    final t = Thresholds(
      highSystolic: values[0]!,
      highDiastolic: values[1]!,
      elevatedSystolic: values[2]!,
      elevatedDiastolic: values[3]!,
    );
    if (t.elevatedSystolic >= t.highSystolic ||
        t.elevatedDiastolic >= t.highDiastolic) {
      setState(() => _error = l.thresholdsErrOrder);
      return;
    }
    Navigator.pop(context, t);
  }

  Widget _field(String label, TextEditingController c) => Expanded(
    child: TextField(
      controller: c,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(3),
      ],
      decoration: InputDecoration(labelText: label),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.thresholdsTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.thresholdHigh,
              style: AppText.body(13, weight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _field(l.systolic, _highSys),
                const SizedBox(width: 10),
                _field(l.diastolic, _highDia),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              l.thresholdElevated,
              style: AppText.body(13, weight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _field(l.systolic, _elevSys),
                const SizedBox(width: 10),
                _field(l.diastolic, _elevDia),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              l.thresholdsDoctorNote,
              style: AppText.body(12, color: AppColors.muted),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: AppText.body(
                  13,
                  weight: FontWeight.w700,
                  color: AppColors.high,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _reset, child: Text(l.esc2024)),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        TextButton(onPressed: _save, child: Text(l.save)),
      ],
    );
  }
}
