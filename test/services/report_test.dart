import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presssure/l10n/l10n.dart';
import 'package:presssure/models/measurement.dart';
import 'package:presssure/models/settings.dart';
import 'package:presssure/services/report.dart';
import 'package:presssure/services/report_pdf.dart';

import '../helpers.dart';

void main() {
  group('CSV', () {
    final readings = [
      reading(DateTime(2026, 9, 20, 8, 5), 126, 82, pulse: 66),
      reading(
        DateTime(2026, 9, 13, 8, 20),
        126,
        81,
        pulse: 69,
        note: 'Dormito poco',
      ),
    ];

    test('Italian: semicolons, day/month dates, oldest first', () {
      final lines = const LineSplitter().convert(
        buildCsv(readings, itL10n, itDates),
      );
      expect(
        lines.first,
        'Data;Ora;Sistolica;Diastolica;Polso;Braccio;Posizione;Origine;'
        'Doppia lettura;Nota',
      );
      expect(
        lines[1],
        '13/09/2026;08:20;126;81;69;Sinistro;Seduto;manuale;no;Dormito poco',
      );
      expect(
        lines[2],
        '20/09/2026;08:05;126;82;66;Sinistro;Seduto;manuale;no;',
      );
    });

    test('US English: commas and month/day dates', () {
      final lines = const LineSplitter().convert(
        buildCsv(readings, enL10n, enDates),
      );
      expect(lines.first, startsWith('Date,Time,Systolic,Diastolic,Pulse'));
      expect(lines[1], startsWith('9/13/2026,8:20'));
      expect(lines[1], endsWith(',Left,Sitting,manual,no,Dormito poco'));
    });

    test('the separator follows the decimal comma of the region', () {
      expect(csvSeparator('it'), ';');
      expect(csvSeparator('de_DE'), ';');
      expect(csvSeparator('en_US'), ',');
      expect(csvSeparator('en_GB'), ',');
    });

    test('notes with separators or quotes are escaped', () {
      final csv = buildCsv(
        [reading(DateTime(2026, 9, 1), 120, 80, note: 'caffè; poi "corsa"')],
        itL10n,
        itDates,
      );
      expect(csv, contains('"caffè; poi ""corsa"""'));
    });

    test('photo readings are marked', () {
      final csv = buildCsv(
        [reading(DateTime(2026, 9, 1), 120, 80, source: ReadingSource.photo)],
        itL10n,
        itDates,
      );
      expect(csv, contains(';foto;'));
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
      expect(
        data.rangeLabel(itL10n, itDates),
        '5 aprile 2026 – 27 settembre 2026 · 24 misure',
      );
      expect(
        data.rangeLabel(enL10n, enDates),
        'April 5, 2026 – September 27, 2026 · 24 readings',
      );
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

  test('the PDF is generated in both languages', () async {
    final data = ReportData.build(
      measurements: designReadings(includeToday: true),
      settings: onboardedSettings,
      range: ReportRange.all,
      now: DateTime(2026, 9, 27, 9),
    );
    for (final (l, dates) in [(itL10n, itDates), (enL10n, enDates)]) {
      final bytes = await buildReportPdf(data, const ReportOptions(), l, dates);
      expect(utf8.decode(bytes.sublist(0, 5), allowMalformed: true), '%PDF-');
      expect(bytes.length, greaterThan(2000));

      final minimal = await buildReportPdf(
        data,
        const ReportOptions(chart: false, table: false, notes: false),
        l,
        dates,
      );
      expect(minimal.length, lessThan(bytes.length));
    }
  });

  test('English dates use the phone region', () {
    final day = DateTime(2026, 9, 27, 19, 42);
    expect(Dates('en_US').weekdayDayMonth(day), 'Sunday, September 27');
    expect(Dates('en_GB').weekdayDayMonth(day), 'Sunday 27 September');
    expect(Dates('it').weekdayDayMonth(day), 'domenica 27 settembre');
    expect(Dates('en_US').time(day), '7:42 PM');
    expect(Dates('en_US', use24h: true).time(day), '19:42');
    expect(Dates('it').time(day), '19:42');
    expect(Dates('en_GB').numericDate(day), '27/09/2026');
  });

  test('the date locale keeps the region only for the same language', () {
    const it = Locale('it');
    const en = Locale('en');
    expect(dateLocaleFor(en, const [Locale('en', 'GB')]), 'en_GB');
    expect(dateLocaleFor(it, const [Locale('it', 'CH')]), 'it_CH');
    // A German phone gets the English texts: dates stay English too.
    expect(dateLocaleFor(en, const [Locale('de', 'DE')]), 'en');
  });
}
