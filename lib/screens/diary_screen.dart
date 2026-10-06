import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../logic/bp_category.dart';
import '../logic/event_impact.dart';
import '../logic/schedule.dart';
import '../logic/stats.dart';
import '../models/life_event.dart';
import '../models/measurement.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/event_widgets.dart';
import 'flows.dart';

enum _Filter { all, events, notes, high }

/// "05 · Diario": readings and events by month, with skipped days and
/// filters; "14 · Diario: solo eventi" with the events filter.
class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  var _filter = _Filter.all;
  var _searching = false;
  var _window = ImpactWindow.oneMonth;
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
      _Filter.events => false,
      _Filter.notes => m.hasNote,
      _Filter.high => state.categoryOf(m) == BpCategory.high,
    };
  }

  /// Events show among the readings ("Tutte") and on their own ("Eventi").
  bool _matchesEvent(LifeEvent e) {
    if (_filter != _Filter.all && _filter != _Filter.events) return false;
    final q = _query.text.trim().toLowerCase();
    return q.isEmpty ||
        e.title.toLowerCase().contains(q) ||
        e.note.toLowerCase().contains(q);
  }

  void _toggle(int key) => setState(
    () => _toggled.contains(key) ? _toggled.remove(key) : _toggled.add(key),
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final dates = context.dates;
    final state = AppScope.of(context);
    final all = state.measurements;
    final allEvents = state.events;
    final filtered = all.where((m) => _matches(m, state)).toList();
    final events = allEvents.where(_matchesEvent).toList();
    final months = _months(groupByMonth(filtered), events);
    final showGaps = _filter == _Filter.all && _query.text.trim().isEmpty;
    final gaps = showGaps ? _gapGroups(state.tracker) : <_Gap>[];
    final subtitle = all.isEmpty
        ? l.emptyTitle
        : allEvents.isEmpty
        ? l.diarySubtitle(
            l.readingsCount(all.length),
            dates.monthName(all.first.takenAt.month),
            state.schedule.describe(l),
          )
        : l.diarySubtitleEvents(
            l.readingsCount(all.length),
            l.eventsCount(allEvents.length),
            dates.monthName(all.first.takenAt.month),
            state.schedule.describe(l),
          );

    return Scaffold(
      floatingActionButton: _filter == _Filter.events
          ? null
          : FloatingActionButton.extended(
              onPressed: () => openNewMeasurement(context),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(
                l.newReading,
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
                            l.navDiary,
                            style: AppText.display(32, weight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          subtitle,
                          style: AppText.body(14, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: _searching ? l.closeSearch : l.searchDiary,
                    onPressed: () => setState(() {
                      _searching = !_searching;
                      if (!_searching) _query.clear();
                    }),
                    icon: Icon(
                      _searching ? Icons.close_rounded : Icons.search_rounded,
                    ),
                  ),
                  const SizedBox(width: 4),
                  OutlinedButton.icon(
                    onPressed: () => openNewEvent(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
                      foregroundColor: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      textStyle: AppText.body(14, weight: FontWeight.w800),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text(l.eventButton),
                  ),
                ],
              ),
            ),
            if (_searching) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _query,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l.searchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
              ),
            ],
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (f, label) in [
                    (_Filter.all, l.filterAll),
                    (_Filter.events, '${l.filterEvents} ${allEvents.length}'),
                    (_Filter.notes, l.filterNotes),
                    (_Filter.high, l.aboveThreshold),
                  ]) ...[
                    ChoicePill(
                      label: label,
                      selected: _filter == f,
                      minHeight: 40,
                      icon: f == _Filter.events ? Icons.flag_outlined : null,
                      onTap: () => setState(() => _filter = f),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (_filter == _Filter.events)
              _EventsView(
                events: events,
                window: _window,
                onWindow: (w) => setState(() => _window = w),
              )
            else if (all.isEmpty && allEvents.isEmpty)
              _EmptyDiary(onAdd: () => openNewMeasurement(context))
            else if (months.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l.noMatch,
                  textAlign: TextAlign.center,
                  style: AppText.body(14, color: AppColors.muted),
                ),
              ),
            if (_filter != _Filter.events)
              for (var i = 0; i < months.length; i++)
                _monthSection(context, months[i], i, gaps, state),
          ],
        ),
      ),
    );
  }

  /// Months with readings or events, newest first.
  List<_Month> _months(List<MonthGroup> readings, List<LifeEvent> events) {
    final byKey = <int, _Month>{
      for (final g in readings) g.year * 12 + g.month: _Month(g, []),
    };
    for (final e in events) {
      final key = e.day.year * 12 + e.day.month;
      byKey
          .putIfAbsent(
            key,
            () => _Month(MonthGroup(e.day.year, e.day.month, []), []),
          )
          .events
          .add(e);
    }
    return byKey.values.toList()
      ..sort((a, b) => b.group.start.compareTo(a.group.start));
  }

  Widget _monthSection(
    BuildContext context,
    _Month month,
    int index,
    List<_Gap> gaps,
    AppState state,
  ) {
    final l = context.l10n;
    final dates = context.dates;
    final g = month.group;
    final key = g.year * 12 + g.month;
    final open = (index < 2) != _toggled.contains(key);
    final title =
        capitalize(dates.monthName(g.month)) +
        (g.year == state.now().year ? '' : ' ${g.year}');
    final events = l.eventsCount(month.events.length);
    final summary = g.items.isEmpty
        ? events
        : month.events.isEmpty
        ? l.monthSummary(l.readingsCount(g.items.length), '${g.avg}')
        : l.monthSummaryEvents(
            l.readingsCount(g.items.length),
            '${g.avg}',
            events,
          );

    if (!open) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppCard(
          radius: 18,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          onTap: () => _toggle(key),
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
      for (final gap in monthGaps) (gap.last, _GapRow(gap: gap)),
      // At the start of its day: readings of that day come above it.
      for (final e in month.events) (e.day, _EventRow(event: e)),
    ]..sort((a, b) => b.$1.compareTo(a.$1));

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => _toggle(key),
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

class _Month {
  _Month(this.group, this.events);

  final MonthGroup group;
  final List<LifeEvent> events;
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
    final l = context.l10n;
    final dates = context.dates;
    final m = measurement;
    final details = [
      dates.time(m.takenAt),
      if (m.pulse != null) l.pulseLower(m.pulse!),
      if (m.doubleReading) l.averageOfTwo,
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
                weekday: dates.weekdayShort(m.takenAt),
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
                          Icon(
                            Icons.photo_camera_outlined,
                            size: 15,
                            color: AppColors.muted,
                            semanticLabel: l.readFromPhoto,
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
  const _GapRow({required this.gap});

  final _Gap gap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final n = gap.days.length;
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
              weekday: context.dates.weekdayShort(gap.first),
              day: gap.days.map((d) => d.day).join(' · '),
              muted: true,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l.gapLabel(n),
                style: AppText.body(14, color: AppColors.muted),
              ),
            ),
            TextButton(
              onPressed: () => openNewMeasurement(context, day: gap.first),
              child: Text(l.add),
            ),
          ],
        ),
      ),
    );
  }
}

/// An event among the readings, in the colours of its kind.
class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});

  final LifeEvent event;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final dates = context.dates;
    final c = event.category;
    return Semantics(
      button: true,
      label: l.diaryEventSemantics(dates.dayMonth(event.day), event.title),
      excludeSemantics: true,
      child: Material(
        color: c.soft,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openEditEvent(context, event),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 68),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: Column(
                      children: [
                        Text(
                          dates.weekdayShort(event.day).toUpperCase(),
                          style: AppText.body(
                            11,
                            weight: FontWeight.w800,
                            color: c.ink,
                          ),
                        ),
                        Text(
                          '${event.day.day}',
                          style: AppText.display(22, height: 1.1, color: c.ink),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  EventTile(c, size: 40, on: AppColors.surface),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: AppText.body(
                            15,
                            weight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        Text(
                          l.diaryEventKind(c.label(l)),
                          style: AppText.body(13, color: c.ink),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.edit_outlined, size: 20, color: c.ink),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The events list on its own page, from "Elenco" in "Andamento".
class EventsListScreen extends StatefulWidget {
  const EventsListScreen({super.key});

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  var _window = ImpactWindow.oneMonth;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.filterEvents),
        titleSpacing: 0,
        actions: [
          IconButton(
            tooltip: l.eventNew,
            onPressed: () => openNewEvent(context),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _EventsView(
            events: AppScope.of(context).events,
            window: _window,
            onWindow: (w) => setState(() => _window = w),
          ),
        ],
      ),
    );
  }
}

/// "14 · Diario: solo eventi": each event with the readings before and
/// after it.
class _EventsView extends StatelessWidget {
  const _EventsView({
    required this.events,
    required this.window,
    required this.onWindow,
  });

  final List<LifeEvent> events;
  final ImpactWindow window;
  final ValueChanged<ImpactWindow> onWindow;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = AppScope.of(context);
    if (state.events.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.eventsEmptyTitle,
              style: AppText.body(16, weight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              l.eventsEmptyBody,
              style: AppText.body(14, height: 1.4, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => openNewEvent(context),
              icon: const Icon(Icons.add_rounded),
              label: Text(l.eventNew),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            l.eventsCompareTitle,
            style: AppText.body(
              13,
              weight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SegmentedChoice<ImpactWindow>(
          label: l.impactPeriodGroup,
          value: window,
          options: [
            (ImpactWindow.twoWeeks, l.windowTwoWeeks),
            (ImpactWindow.oneMonth, l.windowOneMonth),
            (ImpactWindow.threeMonths, l.windowThreeMonths),
          ],
          onChanged: onWindow,
        ),
        const SizedBox(height: 12),
        if (events.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l.noMatch,
              textAlign: TextAlign.center,
              style: AppText.body(14, color: AppColors.muted),
            ),
          ),
        for (final e in sortedEvents(events).reversed) ...[
          _EventCard(
            event: e,
            impact: EventImpact.of(
              event: e,
              measurements: state.measurements,
              events: state.events,
              window: window,
              tracker: state.tracker,
              now: state.now(),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            l.eventsFootnote,
            style: AppText.body(12, height: 1.45, color: AppColors.muted),
          ),
        ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.impact});

  final LifeEvent event;
  final EventImpact impact;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final dates = context.dates;
    String days(List<DateTime> list) => list.map(dates.dayMonth).join(', ');
    final notes = [
      if (impact.missedBefore.isNotEmpty)
        l.impactMissingBefore(
          impact.missedBefore.length,
          days(impact.missedBefore),
        ),
      if (impact.missedAfter.isNotEmpty)
        l.impactMissingAfter(
          impact.missedAfter.length,
          days(impact.missedAfter),
        ),
    ];
    return AppCard(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              EventTile(event.category),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: AppText.body(16, weight: FontWeight.w800),
                    ),
                    Text(
                      '${dates.weekdayShort(event.day)} '
                      '${dates.dayMonth(event.day)} · '
                      '${event.category.label(l)}',
                      style: AppText.body(13, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l.eventEdit,
                onPressed: () => openEditEvent(context, event),
                icon: const Icon(Icons.edit_outlined, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: BeforeAfterRow(
              impact: impact,
              onTap: () =>
                  openEventImpact(context, event, window: impact.window),
            ),
          ),
          if (event.hasNote) ...[
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '“${event.note.trim()}”',
                style: AppText.body(13, height: 1.4, color: AppColors.ink2),
              ),
            ),
          ],
          for (final note in notes) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InfoNote(note),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyDiary extends StatelessWidget {
  const _EmptyDiary({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.diaryEmptyTitle,
            style: AppText.body(16, weight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            l.diaryEmptyBody,
            style: AppText.body(14, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: Text(l.diaryAddFirst),
          ),
        ],
      ),
    );
  }
}
