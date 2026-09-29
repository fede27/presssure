import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../logic/schedule.dart';
import '../logic/stats.dart';
import '../models/measurement.dart';
import '../models/settings.dart';
import '../theme.dart';

/// Systolic and diastolic readings over time, with the rolling average of the
/// last 4, the thresholds and the skipped periods.
class BpChart extends StatelessWidget {
  const BpChart({
    super.key,
    required this.items,
    required this.thresholds,
    required this.from,
    required this.to,
    this.gaps = const [],
    this.compact = false,
    this.height = 244,
    this.periodDays = 7,
    this.highlightLabel,
  });

  /// Oldest first.
  final List<Measurement> items;
  final Thresholds thresholds;
  final DateTime from;
  final DateTime to;

  /// Missed periods, shaded in the full chart.
  final List<Period> gaps;
  final bool compact;
  final double height;

  /// Typical distance between readings; longer gaps break the average line.
  final double periodDays;

  /// Label of the latest-reading tooltip; "Ultima" by default.
  final String? highlightLabel;

  String _description(AppLocalizations l, Dates dates) {
    if (items.isEmpty) return l.noReadingsInPeriod;
    final first = items.first;
    final last = items.last;
    return l.chartDescription(
      dates.dayMonth(first.takenAt),
      dates.dayMonth(last.takenAt),
      first.systolic,
      last.systolic,
      first.diastolic,
      last.diastolic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final dates = context.dates;
    return Semantics(
      label: _description(l, dates),
      image: true,
      excludeSemantics: true,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _BpChartPainter(
            this,
            highlightLabel ?? l.latest,
            dates.monthShort,
          ),
        ),
      ),
    );
  }
}

class _BpChartPainter extends CustomPainter {
  _BpChartPainter(this.chart, this.highlightLabel, this.monthLabel);

  final BpChart chart;
  final String highlightLabel;
  final String Function(int month) monthLabel;

  static const _labelStyle = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation.weight(600)],
    color: AppColors.faint,
  );

  void _text(
    Canvas canvas,
    String text,
    Offset at,
    TextStyle style, {
    TextAlign align = TextAlign.left,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout();
    var dx = at.dx;
    if (align == TextAlign.right) dx -= tp.width;
    if (align == TextAlign.center) dx -= tp.width / 2;
    tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
  }

  void _dashed(
    Canvas canvas,
    Offset a,
    Offset b,
    Paint paint, {
    double dash = 4,
    double gap = 4,
  }) {
    final total = (b - a).distance;
    final dir = (b - a) / total;
    var d = 0.0;
    while (d < total) {
      canvas.drawLine(a + dir * d, a + dir * math.min(d + dash, total), paint);
      d += dash + gap;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final items = chart.items;
    final t = chart.thresholds;
    final compact = chart.compact;
    final left = compact ? 4.0 : 34.0;
    final right = compact ? 8.0 : 8.0;
    final top = compact ? 6.0 : 12.0;
    final bottom = compact ? 6.0 : 28.0;
    final plotW = size.width - left - right;
    final plotH = size.height - top - bottom;

    final lows = [t.highDiastolic, ...items.map((m) => m.diastolic)];
    final highs = [t.highSystolic, ...items.map((m) => m.systolic)];
    final double minV;
    final double maxV;
    if (compact) {
      minV = lows.reduce(math.min) - 6.0;
      maxV = highs.reduce(math.max) + 6.0;
    } else {
      minV = ((lows.reduce(math.min) - 8) / 20).floorToDouble() * 20;
      maxV = ((highs.reduce(math.max) + 8) / 20).ceilToDouble() * 20;
    }

    final fromMs = chart.from.millisecondsSinceEpoch.toDouble();
    final spanMs = math.max(
      1.0,
      chart.to.millisecondsSinceEpoch.toDouble() - fromMs,
    );
    double x(DateTime d) =>
        left + (d.millisecondsSinceEpoch - fromMs) / spanMs * plotW;
    double y(num v) => top + (maxV - v) / (maxV - minV) * plotH;

    // Skipped periods.
    if (!compact) {
      final shade = Paint()..color = AppColors.background;
      for (final p in chart.gaps) {
        final x0 = x(p.start).clamp(left, left + plotW);
        final x1 = x(p.end).clamp(left, left + plotW);
        if (x1 > x0) {
          canvas.drawRect(Rect.fromLTRB(x0, top, x1, top + plotH), shade);
        }
      }
    }

    // Grid and axis labels.
    if (!compact) {
      final grid = Paint()
        ..color = AppColors.navBar
        ..strokeWidth = 1;
      for (var v = minV; v <= maxV; v += 20) {
        canvas.drawLine(Offset(left, y(v)), Offset(left + plotW, y(v)), grid);
        _text(
          canvas,
          v.round().toString(),
          Offset(left - 6, y(v)),
          _labelStyle,
          align: TextAlign.right,
        );
      }
      _monthLabels(canvas, x, left, plotW, size.height - 10);
    }

    // Thresholds.
    for (final (value, color) in [
      (t.highSystolic, AppColors.systolicDark),
      (t.highDiastolic, AppColors.diastolic),
    ]) {
      final paint = Paint()
        ..color = color.withValues(alpha: compact ? 0.55 : 1)
        ..strokeWidth = compact ? 1 : 1.3;
      _dashed(
        canvas,
        Offset(left, y(value)),
        Offset(left + plotW, y(value)),
        paint,
        dash: compact ? 3 : 4,
      );
      if (!compact) {
        _text(
          canvas,
          '$value',
          Offset(left + 4, y(value) + 9),
          _labelStyle.copyWith(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            fontVariations: const [FontVariation.weight(800)],
          ),
        );
      }
    }

    if (items.isEmpty) return;

    // Rolling average of the last 4, broken where readings were skipped.
    final rolling = rollingAverage(items);
    final maxGap = Duration(hours: (chart.periodDays * 1.6 * 24).round());
    for (final systolic in [true, false]) {
      final path = Path();
      for (var i = 0; i < rolling.length; i++) {
        final r = rolling[i];
        final p = Offset(x(r.at), y(systolic ? r.systolic : r.diastolic));
        final broken = i == 0 || r.at.difference(rolling[i - 1].at) > maxGap;
        broken ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = systolic ? AppColors.systolic : AppColors.diastolic
          ..style = PaintingStyle.stroke
          ..strokeWidth = compact ? 2.2 : 2.6
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }

    // Single readings.
    final radius = compact ? 2.0 : 3.0;
    for (final m in items) {
      canvas.drawCircle(
        Offset(x(m.takenAt), y(m.systolic)),
        radius,
        Paint()..color = AppColors.systolic.withValues(alpha: 0.55),
      );
      canvas.drawCircle(
        Offset(x(m.takenAt), y(m.diastolic)),
        radius,
        Paint()..color = AppColors.diastolic.withValues(alpha: 0.55),
      );
    }

    // Highlight the latest reading.
    final last = items.last;
    final lx = x(last.takenAt);
    for (final (v, color) in [
      (last.systolic, AppColors.systolic),
      (last.diastolic, AppColors.diastolic),
    ]) {
      canvas.drawCircle(Offset(lx, y(v)), 5, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(lx, y(v)), 3.5, Paint()..color = color);
    }

    if (!compact) {
      final midY = (y(last.systolic) + y(last.diastolic)) / 2;
      final value = TextPainter(
        text: TextSpan(
          text: '${last.systolic}/${last.diastolic}',
          style: AppText.body(14, weight: FontWeight.w800, color: Colors.white),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final label = TextPainter(
        text: TextSpan(
          text: highlightLabel,
          style: AppText.body(
            10,
            weight: FontWeight.w700,
            color: const Color(0xFFC9D0D4),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final w = math.max(value.width, label.width) + 20;
      const h = 42.0;
      var bx = lx - w - 8;
      if (bx < left) bx = lx + 8;
      final box = Rect.fromLTWH(bx, midY - h / 2, w, h);
      canvas.drawLine(
        Offset(lx, y(last.systolic) + 6),
        Offset(lx, y(last.diastolic) - 6),
        Paint()..color = AppColors.ink.withValues(alpha: 0.35),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(box, const Radius.circular(10)),
        Paint()..color = AppColors.ink,
      );
      label.paint(canvas, Offset(box.left + 10, box.top + 6));
      value.paint(canvas, Offset(box.left + 10, box.top + 19));
    }
  }

  void _monthLabels(
    Canvas canvas,
    double Function(DateTime) x,
    double left,
    double plotW,
    double atY,
  ) {
    var month = DateTime(chart.from.year, chart.from.month + 1);
    final labels = <(DateTime, double)>[(chart.from, left)];
    while (month.isBefore(chart.to)) {
      labels.add((month, x(month)));
      month = DateTime(month.year, month.month + 1);
    }
    // Keep labels apart on long ranges.
    final step = (labels.length / 7).ceil();
    double? lastX;
    for (var i = 0; i < labels.length; i += step) {
      final (date, lx) = labels[i];
      if (lastX != null && lx - lastX < 28) continue;
      final start = i == 0;
      _text(
        canvas,
        monthLabel(date.month),
        Offset(lx, atY),
        _labelStyle,
        align: start ? TextAlign.left : TextAlign.center,
      );
      lastX = lx;
    }
  }

  @override
  bool shouldRepaint(_BpChartPainter old) =>
      old.chart != chart || old.highlightLabel != highlightLabel;
}
