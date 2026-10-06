import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../logic/event_impact.dart';
import '../models/settings.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/event_widgets.dart';
import 'flows.dart';

/// "17 · Prima e dopo un evento".
class EventImpactScreen extends StatefulWidget {
  const EventImpactScreen({
    super.key,
    required this.eventId,
    this.window = ImpactWindow.oneMonth,
  });

  final String eventId;
  final ImpactWindow window;

  @override
  State<EventImpactScreen> createState() => _EventImpactScreenState();
}

class _EventImpactScreenState extends State<EventImpactScreen> {
  late var _window = widget.window;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final dates = context.dates;
    final state = AppScope.of(context);
    final event = state.events.where((e) => e.id == widget.eventId).firstOrNull;
    // Deleted from the edit screen opened here.
    if (event == null) return const Scaffold();
    final numbers = eventNumbers(state.events);
    final impact = EventImpact.of(
      event: event,
      measurements: state.measurements,
      events: state.events,
      window: _window,
      tracker: state.tracker,
      now: state.now(),
    );
    final t = state.thresholds;
    final notes = impactNotes(impact, l, dates, numbers);

    return Scaffold(
      appBar: AppBar(title: Text(l.impactTitle), titleSpacing: 0),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          AppCard(
            padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
            child: Row(
              children: [
                EventTile(event.category),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: AppText.body(17, weight: FontWeight.w800),
                      ),
                      Text(
                        l.impactEventLine(
                          numbers[event.id]!,
                          dates.weekdayDayMonth(event.day),
                          event.category.label(l),
                        ),
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
          ),
          const SizedBox(height: 14),
          SegmentedChoice<ImpactWindow>(
            label: l.impactPeriodGroup,
            value: _window,
            options: [
              (ImpactWindow.twoWeeks, l.windowTwoWeeksShort),
              (ImpactWindow.oneMonth, l.windowOneMonth),
              (ImpactWindow.twoMonths, l.windowTwoMonths),
              (ImpactWindow.threeMonths, l.windowThreeMonths),
            ],
            onChanged: (w) => setState(() => _window = w),
          ),
          const SizedBox(height: 14),
          _Averages(impact: impact),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    l.impactChartTitle,
                    style: AppText.body(15, weight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 8),
                _ImpactChart(
                  impact: impact,
                  thresholds: t,
                  number: numbers[event.id]!,
                  numbers: numbers,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    _legend(_dot(AppColors.systolic), l.systolic),
                    _legend(_dot(AppColors.diastolic), l.diastolic),
                    _legend(
                      Container(width: 14, height: 4, color: AppColors.ink2),
                      l.legendPeriodAverage,
                    ),
                    _legend(
                      Container(width: 14, height: 1.5, color: AppColors.faint),
                      l.legendThresholdValue(t.highSystolic, t.highDiastolic),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Details(impact: impact, thresholds: t),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  for (final (i, n) in notes.indexed) ...[
                    if (i > 0) const SizedBox(height: 8),
                    InfoNote(n),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          AppCard(
            color: AppColors.primarySoft,
            borderColor: null,
            padding: const EdgeInsets.all(14),
            child: Text(
              l.impactCaution,
              style: AppText.body(
                13,
                height: 1.45,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              l.impactMethod,
              style: AppText.body(12, height: 1.45, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
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

/// PRIMA and DOPO side by side, then the difference.
class _Averages extends StatelessWidget {
  const _Averages({required this.impact});

  final EventImpact impact;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final dates = context.dates;
    final delta = impact.hasBoth
        ? '${signed(impact.deltaSystolic)}/${signed(impact.deltaDiastolic)} mmHg'
        : '–';

    Widget box({
      required String title,
      required DateTime from,
      required DateTime to,
      required String value,
      required int count,
      required bool after,
    }) => Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: after ? AppColors.surface : AppColors.background,
        border: after
            ? Border.all(color: AppColors.borderStrong, width: 1.5)
            : null,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppText.body(
              11,
              weight: FontWeight.w800,
              letterSpacing: 0.7,
              color: after ? AppColors.primary : AppColors.muted,
            ),
          ),
          Text(
            dates.dayRange(from, to),
            style: AppText.body(13, color: AppColors.muted),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppText.display(34, height: 1.05, tabular: true),
            ),
          ),
          Text(
            l.readingsCount(count),
            style: AppText.body(
              13,
              weight: FontWeight.w700,
              color: AppColors.ink2,
            ),
          ),
        ],
      ),
    );

    return Semantics(
      label: l.impactAverages,
      container: true,
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: box(
                      title: l.impactBefore,
                      from: impact.beforeFrom,
                      to: impact.beforeLast,
                      value: impact.beforeAvg?.toString() ?? '–',
                      count: impact.before.length,
                      after: false,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: box(
                      title: l.impactAfter,
                      from: impact.day,
                      to: impact.afterLast,
                      value: impact.afterAvg?.toString() ?? '–',
                      count: impact.after.length,
                      after: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.impactDelta,
                    style: AppText.body(14, color: AppColors.ink2),
                  ),
                ),
                Text(
                  delta,
                  style: AppText.body(
                    15,
                    weight: FontWeight.w800,
                    tabular: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.impact, required this.thresholds});

  final EventImpact impact;
  final Thresholds thresholds;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final b = impact.beforeAvg;
    final a = impact.afterAvg;
    final t = thresholds;
    final rows = [
      (
        l.impactAvgSystolic,
        '${b?.systolic ?? '–'} → ${a?.systolic ?? '–'}',
        impact.hasBoth ? signed(impact.deltaSystolic) : '',
      ),
      (
        l.impactAvgDiastolic,
        '${b?.diastolic ?? '–'} → ${a?.diastolic ?? '–'}',
        impact.hasBoth ? signed(impact.deltaDiastolic) : '',
      ),
      (
        l.impactAbove(t.highSystolic, t.highDiastolic),
        '${l.progressOf(impact.highBefore(t), impact.before.length)} → '
            '${l.progressOf(impact.highAfter(t), impact.after.length)}',
        '',
      ),
    ];
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.impactDetail,
            style: AppText.body(15, weight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          for (final (i, (label, values, delta)) in rows.indexed) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: AppText.body(14, color: AppColors.ink2),
                    ),
                  ),
                  Text(
                    values,
                    style: AppText.body(
                      14,
                      weight: FontWeight.w700,
                      tabular: true,
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text(
                      delta,
                      textAlign: TextAlign.right,
                      style: AppText.body(
                        14,
                        weight: FontWeight.w800,
                        tabular: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The readings of both periods, their averages and the event in between.
class _ImpactChart extends StatelessWidget {
  const _ImpactChart({
    required this.impact,
    required this.thresholds,
    required this.number,
    required this.numbers,
  });

  final EventImpact impact;
  final Thresholds thresholds;
  final int number;
  final Map<String, int> numbers;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    String describe(int count, Object? avg) => avg == null
        ? l.readingsCount(0)
        : l.impactPeriodAverage(l.readingsCount(count), '$avg');
    return Semantics(
      image: true,
      label: l.impactChartSemantics(
        describe(impact.before.length, impact.beforeAvg),
        describe(impact.after.length, impact.afterAvg),
      ),
      excludeSemantics: true,
      child: SizedBox(
        height: 240,
        width: double.infinity,
        child: CustomPaint(
          painter: _ImpactPainter(
            impact: impact,
            thresholds: thresholds,
            number: number,
            numbers: numbers,
            before: l.impactBefore.toUpperCase(),
            after: l.impactAfter.toUpperCase(),
            dayLabel: context.dates.dayMonthShort,
          ),
        ),
      ),
    );
  }
}

class _ImpactPainter extends CustomPainter {
  _ImpactPainter({
    required this.impact,
    required this.thresholds,
    required this.number,
    required this.numbers,
    required this.before,
    required this.after,
    required this.dayLabel,
  });

  final EventImpact impact;
  final Thresholds thresholds;
  final int number;
  final Map<String, int> numbers;
  final String before;
  final String after;
  final String Function(DateTime) dayLabel;

  void _text(
    Canvas canvas,
    String text,
    Offset at,
    TextStyle style, {
    TextAlign align = TextAlign.left,
    bool halo = false,
  }) {
    TextPainter painter(TextStyle s) => TextPainter(
      text: TextSpan(text: text, style: s),
      textDirection: TextDirection.ltr,
    )..layout();
    final tp = painter(style);
    var dx = at.dx;
    if (align == TextAlign.right) dx -= tp.width;
    if (align == TextAlign.center) dx -= tp.width / 2;
    final offset = Offset(dx, at.dy - tp.height / 2);
    if (halo) {
      painter(
        style.copyWith(
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = Colors.white,
          color: null,
        ),
      ).paint(canvas, offset);
    }
    tp.paint(canvas, offset);
  }

  void _dashed(
    Canvas canvas,
    Offset a,
    Offset b,
    Paint paint,
    double dash,
    double gap,
  ) {
    final total = (b - a).distance;
    final dir = (b - a) / total;
    for (var d = 0.0; d < total; d += dash + gap) {
      canvas.drawLine(a + dir * d, a + dir * math.min(d + dash, total), paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    const left = 40.0, right = 8.0, top = 30.0, bottom = 26.0;
    final plotW = size.width - left - right;
    final plotH = size.height - top - bottom;
    final t = thresholds;
    final all = [...impact.before, ...impact.after];
    final lows = [t.highDiastolic, ...all.map((m) => m.diastolic)];
    final highs = [t.highSystolic, ...all.map((m) => m.systolic)];
    final minV = ((lows.reduce(math.min) - 8) / 20).floorToDouble() * 20;
    final maxV = ((highs.reduce(math.max) + 8) / 20).ceilToDouble() * 20;

    final fromMs = impact.beforeFrom.millisecondsSinceEpoch.toDouble();
    final spanMs = impact.afterTo.millisecondsSinceEpoch - fromMs;
    double x(DateTime d) =>
        left + (d.millisecondsSinceEpoch - fromMs) / spanMs * plotW;
    double y(num v) => top + (maxV - v) / (maxV - minV) * plotH;
    final ex = x(impact.day);

    // The period before, shaded.
    canvas.drawRect(
      Rect.fromLTRB(left, top, ex, top + plotH),
      Paint()..color = AppColors.background,
    );

    final label = AppText.body(11, color: AppColors.faint);
    final grid = Paint()
      ..color = AppColors.navBar
      ..strokeWidth = 1;
    for (var v = minV; v <= maxV; v += 20) {
      canvas.drawLine(Offset(left, y(v)), Offset(left + plotW, y(v)), grid);
      _text(
        canvas,
        '${v.round()}',
        Offset(left - 8, y(v)),
        label,
        align: TextAlign.right,
      );
    }

    for (final (v, c) in [
      (t.highSystolic, AppColors.systolicDark),
      (t.highDiastolic, AppColors.diastolic),
    ]) {
      _dashed(
        canvas,
        Offset(left, y(v)),
        Offset(left + plotW, y(v)),
        Paint()
          ..color = c.withValues(alpha: 0.6)
          ..strokeWidth = 1,
        3,
        4,
      );
    }

    // Other events in the window.
    for (final e in impact.others) {
      final ox = x(e.day);
      _dashed(
        canvas,
        Offset(ox, top - 4),
        Offset(ox, top + plotH),
        Paint()
          ..color = AppColors.ink.withValues(alpha: 0.5)
          ..strokeWidth = 1.2,
        3,
        3,
      );
      _text(
        canvas,
        '${numbers[e.id]}',
        Offset(ox, top - 12),
        AppText.body(10, weight: FontWeight.w800, color: AppColors.ink),
        align: TextAlign.center,
      );
    }

    // Readings.
    for (final m in all) {
      canvas.drawCircle(
        Offset(x(m.takenAt), y(m.systolic)),
        3.2,
        Paint()..color = AppColors.systolic,
      );
      canvas.drawCircle(
        Offset(x(m.takenAt), y(m.diastolic)),
        3.2,
        Paint()..color = AppColors.diastolic,
      );
    }

    // Average of each period, over a white halo.
    void avgLine(double x0, double x1, double v, Color c) {
      final a = Offset(x0, y(v)), b = Offset(x1, y(v));
      canvas
        ..drawLine(
          a,
          b,
          Paint()
            ..color = Colors.white
            ..strokeWidth = 7
            ..strokeCap = StrokeCap.round,
        )
        ..drawLine(
          a,
          b,
          Paint()
            ..color = c
            ..strokeWidth = 3.5
            ..strokeCap = StrokeCap.round,
        );
    }

    final bAvg = impact.beforeAvg;
    final aAvg = impact.afterAvg;
    final strong = AppText.body(12, weight: FontWeight.w800);
    if (bAvg != null) {
      avgLine(left + 4, ex - 6, bAvg.systolic.toDouble(), AppColors.systolic);
      avgLine(left + 4, ex - 6, bAvg.diastolic.toDouble(), AppColors.diastolic);
      _text(
        canvas,
        '${bAvg.systolic}',
        Offset(left + 8, y(bAvg.systolic) - 10),
        strong.copyWith(color: AppColors.systolicDark),
        halo: true,
      );
      _text(
        canvas,
        '${bAvg.diastolic}',
        Offset(left + 8, y(bAvg.diastolic) + 12),
        strong.copyWith(color: AppColors.diastolic),
        halo: true,
      );
    }
    if (aAvg != null) {
      final end = math.min(x(impact.after.last.takenAt) + 12, left + plotW - 4);
      final x1 = impact.afterOngoing
          ? math.max(end, ex + 24)
          : left + plotW - 4;
      avgLine(ex + 6, x1, aAvg.systolic.toDouble(), AppColors.systolic);
      avgLine(ex + 6, x1, aAvg.diastolic.toDouble(), AppColors.diastolic);
      _text(
        canvas,
        '${aAvg.systolic}',
        Offset(x1 - 4, y(aAvg.systolic) - 10),
        strong.copyWith(color: AppColors.systolicDark),
        align: TextAlign.right,
        halo: true,
      );
      _text(
        canvas,
        '${aAvg.diastolic}',
        Offset(x1 - 4, y(aAvg.diastolic) + 12),
        strong.copyWith(color: AppColors.diastolic),
        align: TextAlign.right,
        halo: true,
      );
    }

    // The event.
    canvas.drawLine(
      Offset(ex, top - 8),
      Offset(ex, top + plotH),
      Paint()
        ..color = AppColors.primary
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      Offset(ex, top - 14),
      10,
      Paint()..color = AppColors.primary,
    );
    _text(
      canvas,
      '$number',
      Offset(ex, top - 14),
      AppText.body(11, weight: FontWeight.w800, color: Colors.white),
      align: TextAlign.center,
    );
    final caps = AppText.body(
      10,
      weight: FontWeight.w800,
      color: AppColors.muted,
      letterSpacing: 0.6,
    );
    _text(
      canvas,
      before,
      Offset(ex - 16, top - 14),
      caps,
      align: TextAlign.right,
    );
    _text(
      canvas,
      after,
      Offset(ex + 16, top - 14),
      caps.copyWith(color: AppColors.primary),
    );

    // Dates: start, event, end.
    final atY = size.height - 9;
    _text(canvas, dayLabel(impact.beforeFrom), Offset(left, atY), label);
    _text(
      canvas,
      dayLabel(impact.day),
      Offset(ex, atY),
      AppText.body(11, weight: FontWeight.w800, color: AppColors.primary),
      align: TextAlign.center,
    );
    _text(
      canvas,
      dayLabel(impact.afterLast),
      Offset(left + plotW, atY),
      label,
      align: TextAlign.right,
    );
  }

  @override
  bool shouldRepaint(_ImpactPainter old) =>
      old.impact != impact || old.thresholds != thresholds;
}
