import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:presssure/models/measurement.dart';
import 'package:presssure/models/settings.dart';
import 'package:presssure/services/report.dart';
import 'package:presssure/services/report_pdf.dart';

import '../helpers.dart';

void main() {
  group('CSV', () {
    test('header and one row per reading, oldest first', () {
      final csv = buildCsv([
        reading(DateTime(2026, 9, 20, 8, 5), 126, 82, pulse: 66),
        reading(
          DateTime(2026, 9, 13, 8, 20),
          126,
          81,
          pulse: 69,
          note: 'Dormito poco',
        ),
      ]);
      final lines = const LineSplitter().convert(csv);
      expect(
        lines.first,
        'Data;Ora;Sistolica;Diastolica;Polso;Braccio;Posizione;Origine;Doppia lettura;Nota',
      );
      expect(
        lines[1],
        '13/09/2026;08:20;126;81;69;sinistro;seduto;manuale;no;Dormito poco',
      );
      expect(
        lines[2],
        '20/09/2026;08:05;126;82;66;sinistro;seduto;manuale;no;',
      );
    });

    test('notes with separators or quotes are escaped', () {
      final csv = buildCsv([
        reading(DateTime(2026, 9, 1), 120, 80, note: 'caffè; poi "corsa"'),
      ]);
      expect(csv, contains('"caffè; poi ""corsa"""'));
    });
  });

  group('ReportData', () {
    test('six months on the design data', () {
      final data = ReportData.build(
        measurements: designReadings(includeToday: true),
        settings: onboardedSettings,
        range: ReportRange.sixMonths,
        now: DateTime(2026, 9, 27, 9),
      );
      expect(data.items.length, 24);
      expect(data.lastFour.toString(), '125/80');
      expect(data.highCount, greaterThan(0));
      expect(data.withNotes.length, 3);
      expect(data.missedDays, [DateTime(2026, 8, 9), DateTime(2026, 8, 16)]);
      expect(data.rows.length, 26);
      expect(data.rows.where((r) => r.m == null).length, 2);
      expect(data.rangeLabel, '5 aprile 2026 – 27 settembre 2026 · 24 misure');
    });

    test('since the last share only includes newer readings', () {
      final data = ReportData.build(
        measurements: designReadings(includeToday: true),
        settings: onboardedSettings.copyWith(
          shares: [DateTime(2026, 6, 14, 12)],
        ),
        range: ReportRange.sinceLastShare,
        now: DateTime(2026, 9, 27, 9),
      );
      expect(data.items.first.takenAt, DateTime(2026, 6, 21, 7, 55));
      expect(data.items.length, 13);
    });

    test('empty diary', () {
      final data = ReportData.build(
        measurements: const [],
        settings: const AppSettings(),
        range: ReportRange.all,
        now: DateTime(2026, 9, 27),
      );
      expect(data.isEmpty, isTrue);
      expect(data.rows, isEmpty);
    });
  });

  test('the PDF is generated', () async {
    final data = ReportData.build(
      measurements: designReadings(includeToday: true),
      settings: onboardedSettings.copyWith(
        profile: const ReportProfile(name: 'Mario Rossi', device: 'Omron M3'),
      ),
      range: ReportRange.all,
      now: DateTime(2026, 9, 27, 9),
    );
    final bytes = await buildReportPdf(data, const ReportOptions());
    expect(utf8.decode(bytes.sublist(0, 5), allowMalformed: true), '%PDF-');
    expect(bytes.length, greaterThan(2000));

    final minimal = await buildReportPdf(
      data,
      const ReportOptions(chart: false, table: false, notes: false),
    );
    expect(minimal.length, lessThan(bytes.length));
  });

  test('photo readings are marked in the CSV', () {
    final csv = buildCsv([
      reading(DateTime(2026, 9, 1), 120, 80, source: ReadingSource.photo),
    ]);
    expect(csv, contains(';foto;'));
  });
}
