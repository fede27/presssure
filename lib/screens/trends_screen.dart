import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/bp_category.dart';
import '../logic/formatting.dart';
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

  static const _labels = {
    TrendRange.threeMonths: '3 mesi',
    TrendRange.sixMonths: '6 mesi',
    TrendRange.year: '1 anno',
    TrendRange.all: 'Tutto',
  };

  DateTime? _from(DateTime now) => switch (_range) {
    TrendRange.threeMonths => DateTime(now.year, now.month - 3, now.day),
    TrendRange.sixMonths => DateTime(now.year, now.month - 6, now.day),
    TrendRange.year => DateTime(now.year - 1, now.month, now.day),
    TrendRange.all => null,
  };

  @override
  Widget build(BuildContext context) {
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
                      'Andamento',
                      style: AppText.display(32, weight: FontWeight.w700),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Esporta e condividi',
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
                    label: _labels[r]!,
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
                'Nessuna misura in questo periodo. Il grafico si riempie con '
                'le prossime.',
                style: AppText.body(14, color: AppColors.muted),
              ),
            )
          else ...[
            _AverageCard(items: items, rangeLabel: _labels[_range]!),
            const SizedBox(height: 12),
            _ChartCard(items: items, from: from, now: now),
            const SizedBox(height: 12),
            _QuarterCard(now: now),
            const SizedBox(height: 12),
            _RegularityCard(tracker: state.tracker, now: now),
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
    final list = items;
    final last4 = averageOfLast(list)!;
    final all = average(list)!;
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
                  'Ultime ${last4.count} misure',
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
                '${list.length} ${list.length == 1 ? 'misura' : 'misure'} in $rangeLabel',
                style: AppText.body(13, color: AppColors.muted),
              ),
              if (all.pulse != null)
                Text(
                  'Polso medio ${all.pulse}',
                  style: AppText.body(13, color: AppColors.muted),
                ),
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
    final state = AppScope.of(context);
    final list = items;
    final start = from ?? list.first.takenAt;
    final gaps = state.tracker.periods
        .where(
          (p) =>
              (p.status == PeriodStatus.missed ||
                  p.status == PeriodStatus.jolly) &&
              p.period.end.isAfter(start),
        )
        .map((p) => p.period)
        .toList();
    final last = list.last;
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
                    'Le tue misure',
                    style: AppText.body(15, weight: FontWeight.w800),
                  ),
                ),
                _swatch(AppColors.systolic, 'Sist.'),
                const SizedBox(width: 12),
                _swatch(AppColors.diastolic, 'Diast.'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          BpChart(
            items: list,
            thresholds: state.thresholds,
            from: start,
            to: now,
            gaps: gaps,
            periodDays: state.schedule.periodDays,
            highlightLabel: dateOnly(last.takenAt) == dateOnly(now)
                ? 'Oggi'
                : formatDayMonthShort(last.takenAt),
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
                  'Singola misura',
                ),
                _legend(
                  Container(width: 14, height: 3, color: AppColors.faint),
                  'Media delle ultime 4',
                ),
                _legend(
                  Container(width: 14, height: 10, color: AppColors.background),
                  'Saltate',
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
    final state = AppScope.of(context);
    final q = QuarterComparison.at(state.measurements, now);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Trimestre a confronto',
            style: AppText.body(15, weight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (q.hasBoth)
            QuarterRow(quarters: q)
          else
            Text(
              'Servono misure in due trimestri: '
              '${formatMonthRange(q.previousFrom, q.previousTo)} e '
              '${formatMonthRange(q.currentFrom, q.currentTo)}.',
              style: AppText.body(13, color: AppColors.muted),
            ),
        ],
      ),
    );
  }
}

class _RegularityCard extends StatelessWidget {
  const _RegularityCard({required this.tracker, required this.now});

  final HabitTracker tracker;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final periods = tracker.last(26);
    final schedule = tracker.schedule;
    final done = periods.where((p) => p.status == PeriodStatus.done).length;
    final elapsed = periods
        .where((p) => p.status != PeriodStatus.pending)
        .length;
    final streak = tracker.currentStreak;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Regolarità',
                  style: AppText.body(15, weight: FontWeight.w800),
                ),
              ),
              Text(
                '$done ${done == 1 ? schedule.occasionSingular : schedule.occasionPlural} su $elapsed',
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
            label: '$done misurate su $elapsed',
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
                    : formatDayMonth(periods.first.period.start),
                style: AppText.body(12, color: AppColors.muted),
              ),
              Expanded(
                child: Text(
                  streak > 0
                      ? '$streak ${streak == 1 ? schedule.occasionSingular : schedule.occasionPlural} di fila'
                      : '',
                  textAlign: TextAlign.center,
                  style: AppText.body(
                    12,
                    weight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Text('oggi', style: AppText.body(12, color: AppColors.muted)),
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
    final state = AppScope.of(context);
    final list = items;
    final counts = countByCategory(list, thresholds);
    final total = list.length;
    final quarterStart = DateTime(now.year, now.month - 2);
    final recent = list.where((m) => !m.takenAt.isBefore(quarterStart));
    final recentBelow = recent
        .where((m) => state.categoryOf(m) != BpCategory.high)
        .length;
    final order = [
      BpCategory.high,
      BpCategory.elevated,
      BpCategory.nonElevated,
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Misure per fascia',
            style: AppText.body(15, weight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Semantics(
            label: order.map((c) => '${c.label}: ${counts[c]}').join(', '),
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
                      c.rangeLabel(thresholds),
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
              'Da ${monthName(quarterStart.month)} $recentBelow misure su '
              '${recent.length} sono sotto '
              '${thresholds.highSystolic}/${thresholds.highDiastolic}.',
              style: AppText.body(12, height: 1.45, color: AppColors.muted),
            ),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  thresholds.isEsc2024
                      ? 'Fasce predefinite: linee guida europee ESC 2024, '
                            'misurazione a domicilio.'
                      : 'Soglie personalizzate. Le linee guida ESC 2024 per '
                            'la misura a domicilio usano 135/85.',
                  style: AppText.body(12, height: 1.45, color: AppColors.muted),
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
                child: const Text('Cambia soglie'),
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
    final values = [
      _highSys,
      _highDia,
      _elevSys,
      _elevDia,
    ].map((c) => int.tryParse(c.text)).toList();
    if (values.any((v) => v == null || v < 40 || v > 250)) {
      setState(() => _error = 'Inserisci valori tra 40 e 250.');
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
      setState(() => _error = 'La fascia elevata deve stare sotto la soglia.');
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
    return AlertDialog(
      title: const Text('Soglie'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Soglia (da qui «alta»)',
              style: AppText.body(13, weight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _field('Sistolica', _highSys),
                const SizedBox(width: 10),
                _field('Diastolica', _highDia),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Inizio fascia elevata',
              style: AppText.body(13, weight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _field('Sistolica', _elevSys),
                const SizedBox(width: 10),
                _field('Diastolica', _elevDia),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Cambiale solo se te lo indica il medico.',
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
        TextButton(onPressed: _reset, child: const Text('ESC 2024')),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        TextButton(onPressed: _save, child: const Text('Salva')),
      ],
    );
  }
}
