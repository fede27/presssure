import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/l10n.dart';
import '../services/report.dart';
import '../services/report_pdf.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// "07 · Esporta e condividi".
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  var _range = ReportRange.sixMonths;
  var _options = const ReportOptions();
  var _busy = false;

  String _rangeLabel(AppLocalizations l, ReportRange r) => switch (r) {
    ReportRange.sinceLastShare => l.rangeSinceLast,
    ReportRange.sixMonths => l.range6m,
    ReportRange.all => l.rangeAll,
  };

  ReportData _data(AppState state) => ReportData.build(
    measurements: state.measurements,
    events: state.events,
    settings: state.settings,
    range: _range,
    now: state.now(),
  );

  String _fileName(AppState state, String ext) {
    final d = state.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${context.l10n.fileNameBase}_'
        '${d.year}-${two(d.month)}-${two(d.day)}.$ext';
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) showSnack(context, context.l10n.errorGeneric('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<Uint8List> _pdf(AppState state) =>
      buildReportPdf(_data(state), _options, context.l10n, context.dates);

  Future<void> _downloadPdf() => _run(() async {
    final state = AppScope.read(context);
    final name = _fileName(state, 'pdf');
    final bytes = await _pdf(state);
    final done = await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: name,
    );
    if (done) await state.recordShare();
  });

  Future<void> _sharePdf() => _run(() async {
    final state = AppScope.read(context);
    final name = _fileName(state, 'pdf');
    final subject = context.l10n.reportTitle;
    final bytes = await _pdf(state);
    final shared = await Printing.sharePdf(
      bytes: bytes,
      filename: name,
      subject: subject,
    );
    if (shared) await state.recordShare();
  });

  Future<void> _shareCsv() => _run(() async {
    final state = AppScope.read(context);
    final l = context.l10n;
    final name = _fileName(state, 'csv');
    final csv = buildCsv(_data(state).items, l, context.dates);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsString(csv);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv')],
        subject: l.csvSubject,
      ),
    );
  });

  void _openPreview() {
    final state = AppScope.read(context);
    final name = _fileName(state, 'pdf');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(context.l10n.previewTitle),
            titleSpacing: 0,
          ),
          body: PdfPreview(
            build: (_) => buildReportPdf(
              _data(state),
              _options,
              context.l10n,
              context.dates,
            ),
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            pdfFileName: name,
            onShared: (_) => state.recordShare(),
            onPrinted: (_) => state.recordShare(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final dates = context.dates;
    final state = AppScope.of(context);
    final settings = state.settings;
    final data = _data(state);
    final lastShare = settings.shares.lastOrNull;
    final newSince = lastShare == null
        ? 0
        : state.measurements.where((m) => m.takenAt.isAfter(lastShare)).length;
    // Events have no time: those dated after the last export.
    final newEvents = lastShare == null
        ? 0
        : state.events.where((e) => e.day.isAfter(lastShare)).length;
    final canExport = !data.isEmpty && !_busy;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    l.exportAndShare,
                    style: AppText.display(30, weight: FontWeight.w700),
                  ),
                ),
                Text(
                  l.reportScreenSubtitle,
                  style: AppText.body(14, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            color: AppColors.primarySoft,
            borderColor: null,
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(
              children: [
                const IconTile(
                  icon: Icons.share_outlined,
                  background: Colors.white,
                  foreground: AppColors.primary,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lastShare == null
                            ? l.neverExported
                            : l.lastExported(dates.dayMonth(lastShare)),
                        style: AppText.body(
                          14,
                          weight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      if (lastShare != null)
                        Text(
                          newEvents == 0
                              ? l.newSince(newSince)
                              : l.newSinceEvents(
                                  l.readingsCount(newSince),
                                  l.eventsCount(newEvents),
                                ),
                          style: AppText.body(13, color: AppColors.ink2),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final r in ReportRange.values) ...[
                if (r != ReportRange.sinceLastShare) const SizedBox(width: 6),
                Expanded(
                  flex: r == ReportRange.sinceLastShare ? 3 : 2,
                  child: ChoicePill(
                    label: _rangeLabel(l, r),
                    selected: _range == r,
                    minHeight: 40,
                    onTap: r == ReportRange.sinceLastShare && lastShare == null
                        ? () => showSnack(context, l.notYetExported)
                        : () => setState(() => _range = r),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              data.isEmpty ? l.noReadingsInPeriod : data.rangeLabel(l, dates),
              style: AppText.body(13, color: AppColors.muted),
            ),
          ),
          const SizedBox(height: 12),
          _PreviewCard(data: data, onOpen: data.isEmpty ? null : _openPreview),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.includeTitle,
                  style: AppText.body(15, weight: FontWeight.w800),
                ),
                _toggle(
                  l.includeChart,
                  _options.chart,
                  (v) => setState(() => _options = _options.copyWith(chart: v)),
                ),
                _toggle(
                  l.includeTable,
                  _options.table,
                  (v) => setState(() => _options = _options.copyWith(table: v)),
                ),
                _toggle(
                  l.includeNotes,
                  _options.notes,
                  (v) => setState(() => _options = _options.copyWith(notes: v)),
                ),
                if (data.events.isNotEmpty)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _options.events,
                    onChanged: (v) =>
                        setState(() => _options = _options.copyWith(events: v)),
                    title: Text(
                      l.includeEvents(data.events.length),
                      style: AppText.body(15),
                    ),
                    subtitle: Text(
                      l.includeEventsSub,
                      style: AppText.body(13, color: AppColors.muted),
                    ),
                  ),
              ],
            ),
          ),
          if (state.events.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                l.eventsPdfNote,
                style: AppText.body(12, height: 1.4, color: AppColors.muted),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: canExport ? _downloadPdf : null,
                  icon: const Icon(Icons.download_rounded, size: 20),
                  label: Text(l.downloadPdf),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: canExport ? _sharePdf : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primarySoft,
                    foregroundColor: AppColors.primary,
                  ),
                  icon: const Icon(Icons.share_outlined, size: 20),
                  label: Text(l.share),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: canExport ? _shareCsv : null,
              child: Text(l.exportCsv),
            ),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: onChanged,
      title: Text(label, style: AppText.body(15)),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.data, required this.onOpen});

  final ReportData data;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final rows = [
      (l.previewReadings, '${data.items.length}'),
      (l.previewAverage, data.overall?.toString() ?? '–'),
      (l.previewLast4, data.lastFour?.toString() ?? '–'),
      (l.aboveThreshold, '${data.highCount}'),
      if (data.events.isNotEmpty) (l.filterEvents, '${data.events.length}'),
    ];
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label: l.openPreviewSemantics,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: onOpen,
              child: const _PageThumbnail(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.previewTitle,
                  style: AppText.body(15, weight: FontWeight.w800),
                ),
                Text(l.pdfA4, style: AppText.body(12, color: AppColors.muted)),
                const SizedBox(height: 10),
                for (final (label, value) in rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: AppText.body(13, color: AppColors.muted),
                          ),
                        ),
                        Text(
                          value,
                          style: AppText.body(
                            13,
                            weight: FontWeight.w800,
                            tabular: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (onOpen != null)
                  TextButton(
                    onPressed: onOpen,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: Text(l.openPreview),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Stylised miniature of the PDF page.
class _PageThumbnail extends StatelessWidget {
  const _PageThumbnail();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, Color c, {double h = 3}) => Container(
      width: w,
      height: h,
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
    return Container(
      width: 96,
      height: 136,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x141A1D21),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(44, AppColors.ink, h: 4),
          bar(66, const Color(0xFFB7B0A5)),
          const SizedBox(height: 4),
          Row(
            children: [
              for (var i = 0; i < 4; i++)
                Expanded(
                  child: Container(
                    height: 12,
                    margin: const EdgeInsets.only(right: 2),
                    color: AppColors.background,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          CustomPaint(size: const Size(80, 30), painter: _MiniChartPainter()),
          const SizedBox(height: 8),
          for (var i = 0; i < 4; i++) bar(80, AppColors.border),
        ],
      ),
    );
  }
}

class _MiniChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint stroke(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final sys = Path()
      ..moveTo(0, 6)
      ..lineTo(size.width * 0.4, 7)
      ..lineTo(size.width * 0.7, 10)
      ..lineTo(size.width, 12);
    final dia = Path()
      ..moveTo(0, 20)
      ..lineTo(size.width * 0.4, 21)
      ..lineTo(size.width * 0.7, 23)
      ..lineTo(size.width, 25);
    canvas.drawPath(sys, stroke(AppColors.systolic));
    canvas.drawPath(dia, stroke(AppColors.diastolic));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
