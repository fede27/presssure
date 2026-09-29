import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../logic/formatting.dart';
import '../logic/stats.dart';
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
    .replaceAll('»', '"');

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

/// Builds the A4 report shown in the design ("08 · PDF esportato").
Future<Uint8List> buildReportPdf(ReportData data, ReportOptions options) {
  final doc = pw.Document(
    title: 'Diario della pressione',
    author: data.settings.profile.name.isEmpty
        ? 'PressSure'
        : data.settings.profile.name,
    creator: 'PressSure',
  );
  final t = data.thresholds;

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
                  '* con nota. Fasce e soglia ${t.highSystolic}/${t.highDiastolic}'
                  ' mmHg: ${t.isEsc2024 ? 'linee guida europee ESC 2024 per la '
                            'misurazione a domicilio' : 'soglie personalizzate'}. '
                  'Valori confermati dall\'utente. PressSure è un diario '
                  'personale, non un dispositivo medico.',
                  size: 7,
                  color: _muted,
                ),
              ),
              pw.SizedBox(width: 16),
              _t(
                'Pagina ${context.pageNumber} di ${context.pagesCount}',
                size: 7,
                color: _muted,
              ),
            ],
          ),
        ],
      ),
      build: (context) => [
        _header(data),
        pw.SizedBox(height: 12),
        _profile(data),
        pw.SizedBox(height: 12),
        _summary(data),
        if (options.chart && data.items.length >= 2) ...[
          pw.SizedBox(height: 16),
          _chart(data),
        ],
        if (options.notes && data.withNotes.isNotEmpty) ...[
          pw.SizedBox(height: 16),
          _notes(data),
        ],
        if (options.table && data.items.isNotEmpty) ...[
          pw.SizedBox(height: 16),
          _table(data),
        ],
      ],
    ),
  );
  return doc.save();
}

pw.Widget _header(ReportData data) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _t('Diario della pressione', size: 20, bold: true),
            pw.SizedBox(height: 4),
            _t(
              'Misure a domicilio, ${data.schedule.describe()} · '
              '${formatFullDate(data.from)} – ${formatFullDate(data.to)}',
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
          'Generato il ${formatNumericDate(data.generatedAt)}',
          size: 8,
          color: _muted,
        ),
      ),
    ],
  );
}

pw.Widget _profile(ReportData data) {
  final p = data.settings.profile;
  pw.Widget field(String label, String value) => pw.Expanded(
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _t(label, size: 7, color: _muted),
        pw.SizedBox(height: 2),
        _t(value.trim().isEmpty ? '-' : value, size: 10, bold: true),
      ],
    ),
  );
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 8),
    decoration: const pw.BoxDecoration(
      border: pw.Border.symmetric(horizontal: pw.BorderSide(color: _line)),
    ),
    child: pw.Row(
      children: [
        field('Paziente', p.name),
        field('Data di nascita', p.birthDate),
        field('Apparecchio', p.device),
      ],
    ),
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

pw.Widget _summary(ReportData data) {
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
        'Ultime 4 misure',
        last4?.toString() ?? '-',
        lastItems.isEmpty
            ? ''
            : '${formatDayMonthShort(lastItems.first.takenAt)} – '
                  '${formatDayMonthShort(lastItems.last.takenAt)}',
      ),
      _box(
        capitalize(formatMonthRange(q.previousFrom, q.previousTo)),
        q.previous?.toString() ?? '-',
        '${q.previous?.count ?? 0} misure',
      ),
      _box(
        capitalize(formatMonthRange(q.currentFrom, q.currentTo)),
        q.current?.toString() ?? '-',
        '${q.current?.count ?? 0} misure',
      ),
      _box('Polso medio', all?.pulse?.toString() ?? '-', 'bpm'),
      _box(
        'Oltre ${t.highSystolic}/${t.highDiastolic}',
        '${data.highCount} su ${data.items.length}',
        'misure',
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

pw.Widget _chart(ReportData data) {
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
          pw.Expanded(child: _t('Andamento', size: 12, bold: true)),
          _legend(_sys, 'Sistolica'),
          _legend(_dia, 'Diastolica'),
          _legend(_muted, 'Media ultime 4'),
          _legend(_sysLine, 'Soglia', dashed: true),
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
                },
              ),
            ),
            pw.Positioned(
              left: left,
              top: height + 4,
              child: _t(
                formatNumericDate(items.first.takenAt),
                size: 7,
                color: _muted,
              ),
            ),
            pw.Positioned(
              right: 0,
              top: height + 4,
              child: _t(
                formatNumericDate(items.last.takenAt),
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

pw.Widget _notes(ReportData data) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _t('Note', size: 12, bold: true),
      pw.SizedBox(height: 6),
      for (final m in data.withNotes)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 3),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 80,
                child: _t(formatDayMonth(m.takenAt), bold: true),
              ),
              pw.Expanded(child: _t('"${m.note.trim()}"')),
            ],
          ),
        ),
    ],
  );
}

pw.Widget _table(ReportData data) {
  final t = data.thresholds;
  pw.Widget cell(String text, {bool bold = false, PdfColor color = _ink}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: _t(text, bold: bold, color: color),
      );

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.RichText(
        text: pw.TextSpan(
          style: const pw.TextStyle(fontSize: 12, color: _ink),
          children: [
            pw.TextSpan(
              text: 'Tutte le misure ',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.TextSpan(
              text: _s(
                '· in grassetto quelle oltre '
                '${t.highSystolic}/${t.highDiastolic}',
              ),
              style: const pw.TextStyle(fontSize: 8, color: _muted),
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 6),
      pw.Table(
        columnWidths: const {
          0: pw.FixedColumnWidth(60),
          1: pw.FixedColumnWidth(40),
          2: pw.FixedColumnWidth(60),
          3: pw.FixedColumnWidth(40),
          4: pw.FlexColumnWidth(),
        },
        border: const pw.TableBorder(
          horizontalInside: pw.BorderSide(color: _grid, width: 0.5),
        ),
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: _primary)),
            ),
            children: [
              cell('Data', bold: true),
              cell('Ora', bold: true),
              cell('mmHg', bold: true),
              cell('Polso', bold: true),
              cell('Nota', bold: true),
            ],
          ),
          for (final row in data.rows)
            if (row.m == null)
              pw.TableRow(
                children: [
                  cell(formatNumericDate(row.day), color: _muted),
                  cell(''),
                  cell('nessuna misura', color: _muted),
                  cell(''),
                  cell(''),
                ],
              )
            else
              pw.TableRow(
                children: [
                  cell(
                    formatNumericDate(row.day) + (row.m!.hasNote ? ' *' : ''),
                  ),
                  cell(formatTime(row.m!.takenAt)),
                  cell(
                    '${row.m!.systolic}/${row.m!.diastolic}',
                    bold: data.isHigh(row.m!),
                  ),
                  cell(row.m!.pulse?.toString() ?? ''),
                  cell(row.m!.note.trim(), color: _muted),
                ],
              ),
        ],
      ),
    ],
  );
}
