import 'package:flutter_test/flutter_test.dart';
import 'package:presssure/logic/stats.dart';
import 'package:presssure/models/settings.dart';

import '../helpers.dart';

void main() {
  final data = sortedByDate(designReadings(includeToday: true));

  test('average rounds values and skips missing pulses', () {
    final avg = average([
      reading(DateTime(2026), 120, 80, pulse: 60),
      reading(DateTime(2026), 125, 81),
    ])!;
    expect(avg.systolic, 123); // 122.5 rounds up
    expect(avg.diastolic, 81); // 80.5 rounds up
    expect(avg.pulse, 60);
    expect(avg.count, 2);
    expect(average(const []), isNull);
  });

  test('last 4 readings of the design average 125/80', () {
    expect(averageOfLast(data).toString(), '125/80');
  });

  test('quarters: apr – giu 141/90 against lug – set 129/81', () {
    final q = QuarterComparison.at(data, designNow);
    expect(q.previous.toString(), '141/90');
    expect(q.previous!.count, 13);
    expect(q.current.toString(), '129/81');
    expect(q.current!.count, 11);
    expect(q.deltaSystolic, -12);
    expect(q.deltaDiastolic, -9);
  });

  test('months are grouped newest first', () {
    final months = groupByMonth(data);
    expect(months.first.month, 9);
    expect(months.first.items.length, 4);
    expect(months.first.items.first.systolic, 124);
    expect(months.first.avg.toString(), '125/80');
    expect(months[1].month, 8);
    expect(months[1].avg.toString(), '128/81');
    expect(months.last.month, 4);
  });

  test('isBelow uses the high thresholds', () {
    final july = groupByMonth(data).firstWhere((g) => g.month == 7).avg!;
    expect(july.toString(), '134/84');
    expect(july.isBelow(Thresholds.esc2024), isTrue);
    expect(july.isBelow(const Thresholds(highSystolic: 130)), isFalse);
  });

  test('rolling average uses up to the last 4 readings', () {
    final r = rollingAverage([
      reading(DateTime(2026, 1, 1), 120, 80),
      reading(DateTime(2026, 1, 2), 130, 90),
      reading(DateTime(2026, 1, 3), 140, 70),
      reading(DateTime(2026, 1, 4), 150, 80),
      reading(DateTime(2026, 1, 5), 160, 100),
    ]);
    expect(r.first.systolic, 120);
    expect(r[1].systolic, 125);
    expect(r.last.systolic, 145); // 130, 140, 150, 160
    expect(r.last.diastolic, 85);
  });

  test('count by category on the design data', () {
    final counts = countByCategory(data, Thresholds.esc2024);
    expect(counts.values.reduce((a, b) => a + b), 24);
    expect(counts.values.where((c) => c > 0).length, 2);
  });
}
