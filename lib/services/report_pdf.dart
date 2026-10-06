import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../l10n/l10n.dart';
import '../logic/stats.dart';
import '../widgets/event_widgets.dart' show EventCategoryLook;
import '../logic/event_impact.dart';
import 'report.dart';

const _ink = PdfColor.fromInt(0xFF1A1D21);
const _muted = PdfColor.fromInt(0xFF545A60);
const _line = PdfColor.fromInt(0xFFE6E0D6);
const _grid = PdfColor.fromInt(0xFFECE7DE);
const _soft = PdfColor.fromInt(0xFFF4F1EB);
const _sys = PdfColor.fromInt(0xFFC4581F);
const _sysLine = PdfColor.fromInt(0xFFA8481A);
const _dia = PdfColor.fromInt(0xFF2B5F8E);
const _primary = PdfColor.fromInt(0xFF0F4C5C);

/// The built-in PDF fonts only cover Latin-1: swap the typographic
/// characters the app uses for plain equivalents.
String _s(String text) => text
    .replaceAll('–', '-')
    .replaceAll('−', '-')
    .replaceAll('’', "'")
    .replaceAll('“', '"')
    .replaceAll('”', '"')
    .replaceAll('«', '"')
    .replaceAll('»', '"')
    .replaceAll('→', '->')
    .replaceAll('…', '...')
    .replaceAll(' ', ' ')
    .replaceAll(' ', ' ');

pw.Text _t(
  String text, {
  double size = 9,
  bool bold = false,
  PdfColor color = _ink,
}) => pw.Text(
  _s(text),
  style: pw.TextStyle(
    fontSize: size,
    fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    color: color,
  ),
);

/// Builds the A4 report shown in the design ("08 · PDF esportato"), in the
/// language of [l] with dates formatted by [dates].
Future<Uint8List> buildReportPdf(
  ReportData data,
  ReportOptions options,
  AppLocalizations l,
  Dates dates,
) {
  final doc = pw.Document(
    title: l.reportTitle,
    author: l.appTitle,
    creator: l.appTitle,
  );
  final t = data.thresholds;
  final events = options.events ? data.events : const <EventImpact>[];

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 30),
      footer: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Divider(color: _line, height: 12),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _t(
                  (events.isEmpty ? l.reportFooter : l.reportFooterEvents)(
                    t.highSystolic,
                    t.highDiastolic,
                    t.isEsc2024 ? l.footerSourceEsc : l.footerSourceCustom,
                  ),
                  size: 7,
                  color: _muted,
                ),
              ),
              pw.SizedBox(width: 16),
              _t(
                l.pageOf(context.pageNumber, context.pagesCount),
                size: 7,
                color: _muted,
              ),
            ],
          ),
        ],
      ),
      build: (context) => [
        _header(data, l, dates),
        pw.SizedBox(height: 12),
        _summary(data, l, dates),
        if (options.chart && data.items.length >= 2) ...[
          pw.SizedBox(height: 16),
          _chart(data, events, l, dates),
        ],
        if (events.isNotEmpty) ...[
          pw.SizedBox(height: 16),
          ..._events(events, l, dates),
        ],
        if (options.notes && data.withNotes.isNotEmpty) ...[
          pw.SizedBox(height: 16),
          ..._notes(data, l, dates),
        ],
        if (options.table && data.items.isNotEmpty) ...[
          pw.SizedBox(height: 16),
          ..._table(data, l, dates),
        ],
      ],
    ),
  );
  return doc.save();
}

pw.Widget _header(ReportData data, AppLocalizations l, Dates dates) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _t(l.reportTitle, size: 20, bold: true),
            pw.SizedBox(height: 4),
            _t(
              l.reportSubtitle(
                data.schedule.describe(l),
                dates.fullDate(data.from),
                dates.fullDate(data.to),
              ),
              size: 10,
              color: _muted,
            ),
          ],
        ),
      ),
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: pw.BoxDecoration(
          color: _soft,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: _t(
          l.generatedOn(dates.numericDate(data.generatedAt)),
          size: 8,
          color: _muted,
        ),
      ),
    ],
  );
}

pw.Widget _box(String label, String value, String detail) {
  return pw.Expanded(
    child: pw.Container(
      margin: const pw.EdgeInsets.only(right: 6),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: _soft,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _t(label, size: 7, color: _muted),
          pw.SizedBox(height: 3),
          _t(value, size: 15, bold: true),
          pw.SizedBox(height: 2),
          _t(detail, size: 7, color: _muted),
        ],
      ),
    ),
  );
}

pw.Widget _summary(ReportData data, AppLocalizations l, Dates dates) {
  final last4 = data.lastFour;
  final q = data.quarters;
  final all = data.overall;
  final t = data.thresholds;
  final lastItems = data.items.length <= 4
      ? data.items
      : data.items.sublist(data.items.length - 4);
  return pw.Row(
    children: [
      _box(
        l.lastNReadings(4),
        last4?.toString() ?? '-',
        lastItems.isEmpty
            ? ''
            : '${dates.dayMonthShort(lastItems.first.takenAt)} – '
                  '${dates.dayMonthShort(lastItems.last.takenAt)}',
      ),
      _box(
        capitalize(dates.monthRange(q.previousFrom, q.previousTo)),
        q.previous?.toString() ?? '-',
        l.readingsCount(q.previous?.count ?? 0),
      ),
      _box(
        capitalize(dates.monthRange(q.currentFrom, q.currentTo)),
        q.current?.toString() ?? '-',
        l.readingsCount(q.current?.count ?? 0),
      ),
      _box(l.averagePulse, all?.pulse?.toString() ?? '-', 'bpm'),
      _box(
        l.bandHigh(t.highSystolic, t.highDiastolic),
        l.progressOf(data.highCount, data.items.length),
        l.nounReadings(data.items.length),
      ),
    ],
  );
}

pw.Widget _legend(PdfColor color, String label, {bool dashed = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(left: 10),
    child: pw.Row(
      children: [
        pw.Container(width: 10, height: dashed ? 1 : 3, color: color),
        pw.SizedBox(width: 4),
        _t(label, size: 7, color: _muted),
      ],
    ),
  );
}

pw.Widget _chart(
  ReportData data,
  List<EventImpact> events,
  AppLocalizations l,
  Dates dates,
) {
  const height = 170.0;
  final items = data.items;
  final t = data.thresholds;
  final rolling = rollingAverage(items);

  var minV = items.map((m) => m.diastolic).reduce((a, b) => a < b ? a : b);
  var maxV = items.map((m) => m.systolic).reduce((a, b) => a > b ? a : b);
  minV = ((minV < t.highDiastolic ? minV : t.highDiastolic) - 10) ~/ 20 * 20;
  maxV = ((maxV > t.highSystolic ? maxV : t.highSystolic) + 29) ~/ 20 * 20;
  final from = items.first.takenAt.millisecondsSinceEpoch.toDouble();
  final to = items.last.takenAt.millisecondsSinceEpoch.toDouble();
  final span = to - from == 0 ? 1.0 : to - from;
  const left = 28.0;
  // A4 width minus the margins, minus the axis labels.
  final chartWidth = PdfPageFormat.a4.width - 72 - left;

  /// Number and position of the events within the chart's dates.
  List<(int, double)> eventXs(double width) => [
    for (final (i, e) in events.indexed)
      if (e.day.millisecondsSinceEpoch >= from &&
          e.day.millisecondsSinceEpoch <= to)
        (i + 1, (e.day.millisecondsSinceEpoch - from) / span * (width - 8) + 4),
  ];

  final labels = <pw.Widget>[];
  for (var v = minV; v <= maxV; v += 20) {
    final y = height - (v - minV) / (maxV - minV) * height;
    labels.add(
      pw.Positioned(
        left: 0,
        top: y - 5,
        child: _t('$v', size: 7, color: _muted),
      ),
    );
  }

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(
        children: [
          pw.Expanded(child: _t(l.reportChart, size: 12, bold: true)),
          _legend(_sys, l.systolic),
          _legend(_dia, l.diastolic),
          _legend(_muted, l.legendAvg4),
          _legend(_sysLine, l.legendThreshold, dashed: true),
          if (events.isNotEmpty) _legend(_primary, l.legendEvent, dashed: true),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.SizedBox(
        height: height + 14,
        child: pw.Stack(
          children: [
            ...labels,
            pw.Positioned(
              left: left,
              top: 0,
              right: 0,
              child: pw.CustomPaint(
                size: const PdfPoint(double.infinity, height),
                painter: (canvas, size) {
                  double x(DateTime d) =>
                      (d.millisecondsSinceEpoch - from) / span * (size.x - 8) +
                      4;
                  double y(num v) => (v - minV) / (maxV - minV) * size.y;

                  canvas
                    ..setStrokeColor(_grid)
                    ..setLineWidth(0.5);
                  for (var v = minV; v <= maxV; v += 20) {
                    canvas
                      ..moveTo(0, y(v))
                      ..lineTo(size.x, y(v));
                  }
                  canvas.strokePath();

                  canvas
                    ..setLineDashPattern([3, 3])
                    ..setStrokeColor(_sysLine)
                    ..moveTo(0, y(t.highSystolic))
                    ..lineTo(size.x, y(t.highSystolic))
                    ..strokePath()
                    ..setStrokeColor(_dia)
                    ..moveTo(0, y(t.highDiastolic))
                    ..lineTo(size.x, y(t.highDiastolic))
                    ..strokePath()
                    ..setLineDashPattern();

                  for (final systolic in [true, false]) {
                    canvas
                      ..setStrokeColor(systolic ? _sys : _dia)
                      ..setLineWidth(1.4);
                    for (var i = 0; i < rolling.length; i++) {
                      final r = rolling[i];
                      final px = x(r.at);
                      final py = y(systolic ? r.systolic : r.diastolic);
                      i == 0 ? canvas.moveTo(px, py) : canvas.lineTo(px, py);
                    }
                    canvas.strokePath();
                  }

                  for (final m in items) {
                    canvas
                      ..setFillColor(_sys)
                      ..drawEllipse(x(m.takenAt), y(m.systolic), 1.8, 1.8)
                      ..fillPath()
                      ..setFillColor(_dia)
                      ..drawEllipse(x(m.takenAt), y(m.diastolic), 1.8, 1.8)
                      ..fillPath();
                  }

                  // Events: dashed lines, numbered on top.
                  canvas
                    ..setStrokeColor(_primary)
                    ..setLineWidth(0.9)
                    ..setLineDashPattern([2, 1.5]);
                  for (final (_, ex) in eventXs(size.x)) {
                    canvas
                      ..moveTo(ex, 0)
                      ..lineTo(ex, size.y - 10)
                      ..strokePath();
                  }
                  canvas.setLineDashPattern();
                  for (final (_, ex) in eventXs(size.x)) {
                    canvas
                      ..setFillColor(_primary)
                      ..drawEllipse(ex, size.y - 5, 5, 5)
                      ..fillPath();
                  }
                },
              ),
            ),
            for (final (n, ex) in eventXs(chartWidth))
              pw.Positioned(
                left: left + ex - 5,
                top: 1.5,
                child: pw.SizedBox(
                  width: 10,
                  child: pw.Text(
                    '$n',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 6.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ),
            pw.Positioned(
              left: left,
              top: height + 4,
              child: _t(
                dates.numericDate(items.first.takenAt),
                size: 7,
                color: _muted,
              ),
            ),
            pw.Positioned(
              right: 0,
              top: height + 4,
              child: _t(
                dates.numericDate(items.last.takenAt),
                size: 7,
                color: _muted,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

/// Rows kept with the heading of their section, so that a heading never
/// sits alone at the bottom of a page.
const _keptRows = 3;

/// [heading] with the start of [items] as one block, which moves to the
/// next page whole; the other items follow and can break across pages.
List<pw.Widget> _keptWithHeading(pw.Widget heading, List<pw.Widget> items) => [
  pw.Inseparable(
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [heading, pw.SizedBox(height: 6), ...items.take(_keptRows)],
    ),
  ),
  ...items.skip(_keptRows),
];

/// A table whose heading, column titles and first rows stay together.
List<pw.Widget> _keptTable({
  required pw.Widget heading,
  required Map<int, pw.TableColumnWidth> columnWidths,
  required pw.TableRow header,
  required List<pw.TableRow> rows,
}) {
  const line = pw.BorderSide(color: _grid, width: 0.5);
  return [
    pw.Inseparable(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          heading,
          pw.SizedBox(height: 6),
          pw.Table(
            columnWidths: columnWidths,
            border: const pw.TableBorder(horizontalInside: line),
            children: [header, ...rows.take(_keptRows)],
          ),
        ],
      ),
    ),
    if (rows.length > _keptRows)
      pw.Table(
        columnWidths: columnWidths,
        border: const pw.TableBorder(top: line, horizontalInside: line),
        children: rows.skip(_keptRows).toList(),
      ),
  ];
}

/// "Eventi annotati": what changed and the month before and after.
List<pw.Widget> _events(
  List<EventImpact> events,
  AppLocalizations l,
  Dates dates,
) {
  pw.Widget cell(pw.Widget child) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    child: child,
  );
  return [
    ..._keptTable(
      heading: _t(l.reportEventsTitle, size: 12, bold: true),
      columnWidths: const {
        0: pw.FixedColumnWidth(78),
        1: pw.FlexColumnWidth(),
        2: pw.FixedColumnWidth(112),
      },
      header: pw.TableRow(
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _primary)),
        ),
        children: [
          cell(_t(l.colDate, bold: true)),
          cell(_t(l.eventTitleLabel, bold: true)),
          cell(_t(l.reportEventsCompare, bold: true)),
        ],
      ),
      rows: [
        for (final (i, e) in events.indexed)
          pw.TableRow(
            children: [
              cell(
                pw.Row(
                  children: [
                    pw.Container(
                      width: 11,
                      height: 11,
                      alignment: pw.Alignment.center,
                      decoration: const pw.BoxDecoration(
                        color: _primary,
                        shape: pw.BoxShape.circle,
                      ),
                      child: pw.Text(
                        '${i + 1}',
                        style: pw.TextStyle(
                          fontSize: 6.5,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 5),
                    _t(dates.numericDate(e.day)),
                  ],
                ),
              ),
              cell(
                pw.RichText(
                  text: pw.TextSpan(
                    style: const pw.TextStyle(fontSize: 9, color: _ink),
                    children: [
                      pw.TextSpan(
                        text: _s(e.event.title),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.TextSpan(
                        text: _s(' · ${e.event.category.label(l)}'),
                        style: const pw.TextStyle(color: _muted),
                      ),
                    ],
                  ),
                ),
              ),
              cell(
                _t(
                  '${e.beforeAvg?.toString() ?? '-'} → '
                  '${e.afterAvg?.toString() ?? '-'}',
                ),
              ),
            ],
          ),
      ],
    ),
    pw.SizedBox(height: 4),
    _t(l.reportEventsNote, size: 7, color: _muted),
  ];
}

List<pw.Widget> _notes(ReportData data, AppLocalizations l, Dates dates) {
  return _keptWithHeading(_t(l.reportNotes, size: 12, bold: true), [
    for (final m in data.withNotes)
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 90,
              // The asterisk matches the one in the table and the footer.
              child: _t('${dates.dayMonth(m.takenAt)} *', bold: true),
            ),
            pw.Expanded(child: _t('"${m.note.trim()}"')),
          ],
        ),
      ),
  ]);
}

List<pw.Widget> _table(ReportData data, AppLocalizations l, Dates dates) {
  final t = data.thresholds;
  pw.Widget cell(String text, {bool bold = false, PdfColor color = _ink}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: _t(text, bold: bold, color: color),
      );

  return _keptTable(
    heading: pw.RichText(
      text: pw.TextSpan(
        style: const pw.TextStyle(fontSize: 12, color: _ink),
        children: [
          pw.TextSpan(
            text: _s(l.reportAllReadings),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.TextSpan(
            text: _s(l.reportBoldNote(t.highSystolic, t.highDiastolic)),
            style: const pw.TextStyle(fontSize: 8, color: _muted),
          ),
        ],
      ),
    ),
    columnWidths: const {
      0: pw.FixedColumnWidth(64),
      1: pw.FixedColumnWidth(48),
      2: pw.FixedColumnWidth(56),
      3: pw.FixedColumnWidth(40),
      4: pw.FlexColumnWidth(),
    },
    header: pw.TableRow(
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _primary)),
      ),
      children: [
        cell(l.colDate, bold: true),
        cell(l.colTime, bold: true),
        cell('mmHg', bold: true),
        cell(l.pulse, bold: true),
        cell(l.note, bold: true),
      ],
    ),
    rows: [
      for (final row in data.rows)
        if (row.m == null)
          pw.TableRow(
            children: [
              cell(dates.numericDate(row.day), color: _muted),
              cell(''),
              cell(l.noReading, color: _muted),
              cell(''),
              cell(''),
            ],
          )
        else
          pw.TableRow(
            children: [
              cell(dates.numericDate(row.day) + (row.m!.hasNote ? ' *' : '')),
              cell(dates.time(row.m!.takenAt)),
              cell(
                '${row.m!.systolic}/${row.m!.diastolic}',
                bold: data.isHigh(row.m!),
              ),
              cell(row.m!.pulse?.toString() ?? ''),
              cell(row.m!.note.trim(), color: _muted),
            ],
          ),
    ],
  );
}
