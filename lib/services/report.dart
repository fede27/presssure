import 'package:intl/intl.dart';

import '../l10n/l10n.dart';
import '../logic/bp_category.dart';
import '../logic/schedule.dart';
import '../logic/stats.dart';
import '../models/measurement.dart';
import '../models/settings.dart';

enum ReportRange { sinceLastShare, sixMonths, all }

class ReportOptions {
  const ReportOptions({
    this.chart = true,
    this.table = true,
    this.notes = true,
  });

  final bool chart;
  final bool table;
  final bool notes;

  ReportOptions copyWith({bool? chart, bool? table, bool? notes}) =>
      ReportOptions(
        chart: chart ?? this.chart,
        table: table ?? this.table,
        notes: notes ?? this.notes,
      );
}

/// The numbers and rows that go in the exported report.
class ReportData {
  ReportData._({
    required this.from,
    required this.to,
    required this.items,
    required this.missedDays,
    required this.settings,
    required this.schedule,
    required this.generatedAt,
  });

  factory ReportData.build({
    required List<Measurement> measurements,
    required AppSettings settings,
    required ReportRange range,
    required DateTime now,
  }) {
    final sorted = sortedByDate(measurements);
    final schedule = Schedule.fromSettings(settings);
    final DateTime? from = switch (range) {
      ReportRange.sinceLastShare => settings.shares.lastOrNull,
      ReportRange.sixMonths => DateTime(now.year, now.month - 6, now.day),
      ReportRange.all => null,
    };
    final items = from == null
        ? sorted
        : sorted.where((m) => !m.takenAt.isBefore(from)).toList();

    final tracker = HabitTracker(schedule, sorted, now);
    final firstDay = items.isEmpty ? null : dateOnly(items.first.takenAt);
    final missed = firstDay == null
        ? <DateTime>[]
        : tracker.periods
              .where(
                (p) =>
                    (p.status == PeriodStatus.missed ||
                        p.status == PeriodStatus.jolly) &&
                    !p.period.start.isBefore(firstDay),
              )
              .map((p) => p.period.start)
              .toList();

    return ReportData._(
      from: items.isEmpty ? (from ?? now) : items.first.takenAt,
      to: now,
      items: items,
      missedDays: missed,
      settings: settings,
      schedule: schedule,
      generatedAt: now,
    );
  }

  final DateTime from;
  final DateTime to;

  /// Oldest first.
  final List<Measurement> items;

  /// Due days in range without a reading.
  final List<DateTime> missedDays;
  final AppSettings settings;
  final Schedule schedule;
  final DateTime generatedAt;

  Thresholds get thresholds => settings.thresholds;
  bool get isEmpty => items.isEmpty;

  BpAverage? get overall => average(items);
  BpAverage? get lastFour => averageOfLast(items);
  QuarterComparison get quarters => QuarterComparison.at(items, to);

  bool isHigh(Measurement m) =>
      classify(m.systolic, m.diastolic, thresholds) == BpCategory.high;

  int get highCount => items.where(isHigh).length;

  List<Measurement> get withNotes => items.where((m) => m.hasNote).toList();

  /// "5 aprile 2026 – 27 settembre 2026 · 24 misure".
  String rangeLabel(AppLocalizations l, Dates dates) => l.rangeLabel(
    dates.fullDate(from),
    dates.fullDate(to),
    l.readingsCount(items.length),
  );

  /// Table rows: readings and missed days, oldest first.
  List<({DateTime day, Measurement? m})> get rows {
    final rows = [
      for (final m in items) (day: m.takenAt, m: m),
      for (final d in missedDays) (day: d, m: null),
    ]..sort((a, b) => a.day.compareTo(b.day));
    return rows;
  }
}

/// Where the decimal separator is a comma, spreadsheets expect semicolons.
String csvSeparator(String locale) =>
    NumberFormat.decimalPattern(locale).symbols.DECIMAL_SEP == ',' ? ';' : ',';

String _csvField(String value, String separator) {
  if (value.contains(separator) ||
      value.contains('"') ||
      value.contains('\n') ||
      value.contains('\r')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

/// The readings as CSV, with headers, dates and separator for the locale.
String buildCsv(List<Measurement> items, AppLocalizations l, Dates dates) {
  final sep = csvSeparator(dates.locale);
  String row(List<Object> cells) =>
      cells.map((c) => _csvField('$c', sep)).join(sep);

  final buffer = StringBuffer()
    ..writeln(
      row([
        l.colDate,
        l.colTime,
        l.systolic,
        l.diastolic,
        l.pulse,
        l.arm,
        l.posture,
        l.csvSource,
        l.csvDouble,
        l.note,
      ]),
    );
  for (final m in sortedByDate(items)) {
    buffer.writeln(
      row([
        dates.numericDate(m.takenAt),
        dates.time(m.takenAt),
        m.systolic,
        m.diastolic,
        m.pulse ?? '',
        m.arm == Arm.left ? l.armLeft : l.armRight,
        switch (m.posture) {
          Posture.sitting => l.postureSitting,
          Posture.standing => l.postureStanding,
          Posture.lying => l.postureLying,
        },
        m.source == ReadingSource.photo ? l.csvPhoto : l.csvManual,
        m.doubleReading ? l.yes : l.no,
        m.note.trim(),
      ]),
    );
  }
  return buffer.toString();
}
