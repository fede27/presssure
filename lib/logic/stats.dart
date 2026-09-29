import '../models/measurement.dart';
import '../models/settings.dart';
import 'bp_category.dart';

/// Rounded average of some readings.
class BpAverage {
  const BpAverage(this.systolic, this.diastolic, this.pulse, this.count);

  final int systolic;
  final int diastolic;
  final int? pulse;
  final int count;

  bool isBelow(Thresholds t) =>
      systolic < t.highSystolic && diastolic < t.highDiastolic;

  @override
  String toString() => '$systolic/$diastolic';
}

BpAverage? average(Iterable<Measurement> items) {
  final list = items.toList();
  if (list.isEmpty) return null;
  final sys = list.fold<int>(0, (s, m) => s + m.systolic) / list.length;
  final dia = list.fold<int>(0, (s, m) => s + m.diastolic) / list.length;
  final pulses = list.where((m) => m.pulse != null).map((m) => m.pulse!);
  final pulse = pulses.isEmpty
      ? null
      : (pulses.reduce((a, b) => a + b) / pulses.length).round();
  return BpAverage(sys.round(), dia.round(), pulse, list.length);
}

/// Average of the last [n] readings of a chronologically sorted list.
BpAverage? averageOfLast(List<Measurement> sorted, [int n = 4]) =>
    average(sorted.length <= n ? sorted : sorted.sublist(sorted.length - n));

List<Measurement> sortedByDate(Iterable<Measurement> items) =>
    [...items]..sort((a, b) => a.takenAt.compareTo(b.takenAt));

/// Readings in [from] (inclusive) .. [to] (exclusive).
List<Measurement> between(
  Iterable<Measurement> items,
  DateTime from,
  DateTime to,
) => items
    .where((m) => !m.takenAt.isBefore(from) && m.takenAt.isBefore(to))
    .toList();

/// A calendar month with its readings.
class MonthGroup {
  MonthGroup(this.year, this.month, this.items);

  final int year;
  final int month;

  /// Newest first.
  final List<Measurement> items;

  BpAverage? get avg => average(items);
  DateTime get start => DateTime(year, month);
  DateTime get end => DateTime(year, month + 1);
}

/// Groups readings by month, newest month first.
List<MonthGroup> groupByMonth(Iterable<Measurement> items) {
  final sorted = sortedByDate(items).reversed;
  final groups = <MonthGroup>[];
  for (final m in sorted) {
    final last = groups.isEmpty ? null : groups.last;
    if (last != null &&
        last.year == m.takenAt.year &&
        last.month == m.takenAt.month) {
      last.items.add(m);
    } else {
      groups.add(MonthGroup(m.takenAt.year, m.takenAt.month, [m]));
    }
  }
  return groups;
}

/// The last three calendar months (current included) against the three
/// before them.
class QuarterComparison {
  QuarterComparison({
    required this.previousFrom,
    required this.previousTo,
    required this.previous,
    required this.currentFrom,
    required this.currentTo,
    required this.current,
  });

  factory QuarterComparison.at(Iterable<Measurement> items, DateTime now) {
    final currentFrom = DateTime(now.year, now.month - 2);
    final previousFrom = DateTime(now.year, now.month - 5);
    final end = DateTime(now.year, now.month + 1);
    return QuarterComparison(
      previousFrom: previousFrom,
      previousTo: DateTime(now.year, now.month - 3),
      previous: average(between(items, previousFrom, currentFrom)),
      currentFrom: currentFrom,
      currentTo: DateTime(now.year, now.month),
      current: average(between(items, currentFrom, end)),
    );
  }

  /// First month of each quarter and last month (as a date in that month).
  final DateTime previousFrom;
  final DateTime previousTo;
  final BpAverage? previous;
  final DateTime currentFrom;
  final DateTime currentTo;
  final BpAverage? current;

  bool get hasBoth => previous != null && current != null;
  int get deltaSystolic => current!.systolic - previous!.systolic;
  int get deltaDiastolic => current!.diastolic - previous!.diastolic;
}

/// Rolling average of the last [window] readings, one per reading.
List<({DateTime at, double systolic, double diastolic})> rollingAverage(
  List<Measurement> sorted, [
  int window = 4,
]) {
  final result = <({DateTime at, double systolic, double diastolic})>[];
  for (var i = 0; i < sorted.length; i++) {
    final from = i - window + 1 < 0 ? 0 : i - window + 1;
    final slice = sorted.sublist(from, i + 1);
    result.add((
      at: sorted[i].takenAt,
      systolic: slice.fold<int>(0, (s, m) => s + m.systolic) / slice.length,
      diastolic: slice.fold<int>(0, (s, m) => s + m.diastolic) / slice.length,
    ));
  }
  return result;
}

Map<BpCategory, int> countByCategory(
  Iterable<Measurement> items,
  Thresholds t,
) {
  final counts = {for (final c in BpCategory.values) c: 0};
  for (final m in items) {
    final c = classify(m.systolic, m.diastolic, t);
    counts[c] = counts[c]! + 1;
  }
  return counts;
}
