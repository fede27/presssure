import 'package:flutter/material.dart';

import '../logic/bp_category.dart';
import '../logic/formatting.dart';
import '../logic/schedule.dart';
import '../logic/stats.dart';
import '../models/measurement.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'flows.dart';

enum _Filter { all, notes, high }

/// "05 · Diario": readings by month, with skipped days and filters.
class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  var _filter = _Filter.all;
  var _searching = false;
  final _query = TextEditingController();

  /// Months opened or closed by the user; by default the two most recent
  /// are open.
  final _toggled = <int>{};

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  bool _matches(Measurement m, AppState state) {
    final q = _query.text.trim().toLowerCase();
    if (q.isNotEmpty && !m.note.toLowerCase().contains(q)) return false;
    return switch (_filter) {
      _Filter.all => true,
      _Filter.notes => m.hasNote,
      _Filter.high => state.categoryOf(m) == BpCategory.high,
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final all = state.measurements;
    final filtered = all.where((m) => _matches(m, state)).toList();
    final months = groupByMonth(filtered);
    final showGaps = _filter == _Filter.all && _query.text.trim().isEmpty;
    final gaps = showGaps ? _gapGroups(state.tracker) : <_Gap>[];
    final t = state.thresholds;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openNewMeasurement(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Nuova misura',
          style: AppText.body(15, weight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 96),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            'Diario',
                            style: AppText.display(32, weight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          all.isEmpty
                              ? 'Ancora nessuna misura'
                              : '${all.length} ${all.length == 1 ? 'misura' : 'misure'} '
                                    'da ${monthName(all.first.takenAt.month)} · '
                                    '${state.schedule.describe()}',
                          style: AppText.body(14, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: _searching ? 'Chiudi ricerca' : 'Cerca nel diario',
                    onPressed: () => setState(() {
                      _searching = !_searching;
                      if (!_searching) _query.clear();
                    }),
                    icon: Icon(
                      _searching ? Icons.close_rounded : Icons.search_rounded,
                    ),
                  ),
                ],
              ),
            ),
            if (_searching) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _query,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Cerca nelle note',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ],
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (f, label) in [
                    (_Filter.all, 'Tutte'),
                    (_Filter.notes, 'Con note'),
                    (
                      _Filter.high,
                      'Oltre ${t.highSystolic}/${t.highDiastolic}',
                    ),
                  ]) ...[
                    ChoicePill(
                      label: label,
                      selected: _filter == f,
                      minHeight: 40,
                      onTap: () => setState(() => _filter = f),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (all.isEmpty)
              _EmptyDiary(onAdd: () => openNewMeasurement(context))
            else if (months.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Nessuna misura corrisponde.',
                  textAlign: TextAlign.center,
                  style: AppText.body(14, color: AppColors.muted),
                ),
              ),
            for (var i = 0; i < months.length; i++)
              _monthSection(context, months[i], i, gaps, state),
          ],
        ),
      ),
    );
  }

  Widget _monthSection(
    BuildContext context,
    MonthGroup g,
    int index,
    List<_Gap> gaps,
    AppState state,
  ) {
    final key = g.year * 12 + g.month;
    final open = (index < 2) != _toggled.contains(key);
    final title =
        capitalize(monthName(g.month)) +
        (g.year == state.now().year ? '' : ' ${g.year}');
    final summary =
        '${g.items.length} ${g.items.length == 1 ? 'misura' : 'misure'} · media ${g.avg}';

    if (!open) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppCard(
          radius: 18,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          onTap: () => setState(
            () => _toggled.contains(key)
                ? _toggled.remove(key)
                : _toggled.add(key),
          ),
          child: Row(
            children: [
              Text(title, style: AppText.body(16, weight: FontWeight.w800)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  summary,
                  textAlign: TextAlign.right,
                  style: AppText.body(13, color: AppColors.muted),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.expand_more_rounded, color: AppColors.muted),
            ],
          ),
        ),
      );
    }

    final monthGaps = gaps.where(
      (gap) => gap.first.year == g.year && gap.first.month == g.month,
    );
    final rows = <(DateTime, Widget)>[
      for (final m in g.items)
        (m.takenAt, _EntryCard(measurement: m, category: state.categoryOf(m))),
      for (final gap in monthGaps)
        (gap.last, _GapRow(gap: gap, schedule: state.schedule)),
    ]..sort((a, b) => b.$1.compareTo(a.$1));

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(
              () => _toggled.contains(key)
                  ? _toggled.remove(key)
                  : _toggled.add(key),
            ),
            child: SectionHeading(title, trailing: summary),
          ),
          const SizedBox(height: 10),
          for (final (_, w) in rows) ...[w, const SizedBox(height: 8)],
        ],
      ),
    );
  }

  /// Consecutive skipped periods within the same month.
  List<_Gap> _gapGroups(HabitTracker tracker) {
    final groups = <_Gap>[];
    List<DateTime>? current;
    for (final p in tracker.periods) {
      final skipped =
          p.status == PeriodStatus.missed || p.status == PeriodStatus.jolly;
      final day = p.period.start;
      if (skipped &&
          current != null &&
          current.last.month == day.month &&
          current.last.year == day.year) {
        current.add(day);
      } else if (skipped) {
        current = [day];
        groups.add(_Gap(current));
      } else {
        current = null;
      }
    }
    return groups;
  }
}

class _Gap {
  _Gap(this.days);

  final List<DateTime> days;
  DateTime get first => days.first;
  DateTime get last => days.last;
}

class _DateBox extends StatelessWidget {
  const _DateBox({
    required this.weekday,
    required this.day,
    this.muted = false,
  });

  final String weekday;
  final String day;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final color = muted ? AppColors.faint : null;
    return SizedBox(
      width: 48,
      child: Column(
        children: [
          Text(
            weekday.toUpperCase(),
            style: AppText.body(
              11,
              weight: FontWeight.w800,
              color: color ?? AppColors.muted,
            ),
          ),
          Text(
            day,
            textAlign: TextAlign.center,
            style: AppText.display(
              muted ? 18 : 22,
              height: 1.1,
              color: color ?? AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.measurement, required this.category});

  final Measurement measurement;
  final BpCategory category;

  @override
  Widget build(BuildContext context) {
    final m = measurement;
    final details = [
      formatTime(m.takenAt),
      if (m.pulse != null) 'polso ${m.pulse}',
      if (m.doubleReading) 'media di 2',
    ].join(' · ');
    return AppCard(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
      onTap: () => openEditMeasurement(context, m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _DateBox(
                weekday: weekdayShort[m.takenAt.weekday - 1],
                day: '${m.takenAt.day}',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${m.systolic}/${m.diastolic}',
                      style: AppText.display(24, tabular: true),
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            details,
                            style: AppText.body(13, color: AppColors.muted),
                          ),
                        ),
                        if (m.source == ReadingSource.photo) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.photo_camera_outlined,
                            size: 15,
                            color: AppColors.muted,
                            semanticLabel: 'Letto da foto',
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              CategoryChip(category),
            ],
          ),
          if (m.hasNote) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 60),
              child: Text(
                '“${m.note.trim()}”',
                style: AppText.body(
                  13,
                  weight: FontWeight.w500,
                  height: 1.4,
                  color: AppColors.ink2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GapRow extends StatelessWidget {
  const _GapRow({required this.gap, required this.schedule});

  final _Gap gap;
  final Schedule schedule;

  @override
  Widget build(BuildContext context) {
    final n = gap.days.length;
    final label = n == 1
        ? '1 ${schedule.occasionSingular} senza misura'
        : '$n ${schedule.occasionPlural} senza misura';
    return DashedBorder(
      color: AppColors.borderStrong,
      radius: 18,
      dash: 5,
      gap: 4,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
        child: Row(
          children: [
            _DateBox(
              weekday: weekdayShort[gap.first.weekday - 1],
              day: gap.days.map((d) => d.day).join(' · '),
              muted: true,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppText.body(14, color: AppColors.muted),
              ),
            ),
            TextButton(
              onPressed: () => openNewMeasurement(context, day: gap.first),
              child: const Text('Aggiungi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDiary extends StatelessWidget {
  const _EmptyDiary({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Il diario è vuoto',
            style: AppText.body(16, weight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Ogni misura che salvi finisce qui, raggruppata per mese.',
            style: AppText.body(14, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Aggiungi la prima misura'),
          ),
        ],
      ),
    );
  }
}
