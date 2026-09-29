import '../logic/bp_category.dart';
import '../logic/formatting.dart';
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
    DateTime? from;
    switch (range) {
      case ReportRange.sinceLastShare:
        from = settings.shares.lastOrNull;
      case ReportRange.sixMonths:
        from = DateTime(now.year, now.month - 6, now.day);
      case ReportRange.all:
        from = null;
    }
    final items = from == null
        ? sorted
        : sorted.where((m) => !m.takenAt.isBefore(from!)).toList();

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

  String get rangeLabel =>
      '${formatFullDate(from)} – ${formatFullDate(to)} · '
      '${items.length} ${items.length == 1 ? 'misura' : 'misure'}';

  /// Table rows: readings and missed days, oldest first.
  List<({DateTime day, Measurement? m})> get rows {
    final rows = [
      for (final m in items) (day: m.takenAt, m: m),
      for (final d in missedDays) (day: d, m: null),
    ]..sort((a, b) => a.day.compareTo(b.day));
    return rows;
  }
}

String _csvField(String value) {
  if (value.contains(RegExp('[;"\n\r]'))) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

String _armLabel(Arm a) => a == Arm.left ? 'sinistro' : 'destro';

String _postureLabel(Posture p) => switch (p) {
  Posture.sitting => 'seduto',
  Posture.standing => 'in piedi',
  Posture.lying => 'sdraiato',
};

/// Semicolon-separated values, as Italian spreadsheets expect.
String buildCsv(List<Measurement> items) {
  final buffer = StringBuffer(
    'Data;Ora;Sistolica;Diastolica;Polso;Braccio;Posizione;Origine;'
    'Doppia lettura;Nota\n',
  );
  for (final m in sortedByDate(items)) {
    buffer.writeln(
      [
        formatNumericDate(m.takenAt),
        formatTime(m.takenAt),
        m.systolic,
        m.diastolic,
        m.pulse ?? '',
        _armLabel(m.arm),
        _postureLabel(m.posture),
        m.source == ReadingSource.photo ? 'foto' : 'manuale',
        m.doubleReading ? 'sì' : 'no',
        _csvField(m.note.trim()),
      ].join(';'),
    );
  }
  return buffer.toString();
}
