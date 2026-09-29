import 'package:flutter_test/flutter_test.dart';
import 'package:presssure/logic/achievements.dart';
import 'package:presssure/logic/schedule.dart';
import 'package:presssure/models/measurement.dart';
import 'package:presssure/models/settings.dart';

import '../helpers.dart';

AchievementsReport compute(
  List<Measurement> readings, {
  AppSettings settings = onboardedSettings,
  DateTime? now,
}) {
  final at = now ?? DateTime(2026, 9, 27, 8);
  return computeAchievements(
    tracker: HabitTracker(Schedule.fromSettings(settings), readings, at),
    measurements: readings,
    settings: settings,
    now: at,
  );
}

void main() {
  group('on the design data (after saving 27 September)', () {
    final report = compute(designReadings(includeToday: true));

    test('consistency badges match the mockup', () {
      expect(report.byId('first_step').detail, '5 apr');
      expect(report.byId('two_months').detail, '24 mag');
      expect(report.byId('three_months').detail, '28 giu');
      expect(report.byId('six_months').unlocked, isTrue);
      expect(report.byId('six_months').detail, 'oggi');
      expect(report.byId('month_complete').count, 5);
      expect(report.byId('month_complete').detail, 'settembre, 4 su 4');
      expect(report.byId('comeback').detail, '23 ago, dopo la pausa');
      expect(report.byId('no_pause').detail, '6 su 26');
      expect(report.byId('beat_record').detail, '6 su 19');
      expect(report.byId('year').detail, '24 su 52');
      expect(report.byId('year').title, 'Un anno di domeniche');
    });

    test('habits', () {
      expect(report.byId('honest').unlocked, isTrue);
      expect(report.byId('lynx').detail, '0 su 10');
      expect(report.byId('first_pdf').unlocked, isFalse);
      expect(report.byId('notes').detail, '3 su 10');
      expect(report.byId('double').detail, '0 su 5');
    });

    test('trend badges', () {
      expect(report.byId('month_below').detail, 'agosto 128/81');
      expect(report.byId('trend_down').unlocked, isTrue);
      expect(report.byId('trend_down').detail, '−12/−9 tra trimestri');
      final quarter = report.byId('quarter_below');
      expect(quarter.unlocked, isFalse);
      expect(quarter.detail, 'si sblocca il 30');
    });

    test('records', () {
      expect(report.bestStreak, 18);
      expect(report.bestStreakRange, 'apr – ago');
      expect(report.lowestMonth!.month, 9);
      expect(report.completeMonths, 5);
      expect(report.monthsTracked, 6);
    });

    test('new badges are the ones unlocked in the last days', () {
      final now = DateTime(2026, 9, 27, 8);
      expect(report.byId('six_months').isNew(now), isTrue);
      expect(report.byId('first_step').isNew(now), isFalse);
    });
  });

  test('saving today unlocks new badges', () {
    final before = compute(designReadings()).unlockedKeys;
    final after = compute(designReadings(includeToday: true)).unlockedKeys;
    final gained = after.difference(before);
    expect(gained, containsAll(['six_months:0', 'month_complete:5']));
  });

  test('empty diary: nothing unlocked', () {
    final report = compute(const []);
    expect(report.badges.where((b) => b.unlocked), isEmpty);
    expect(report.bestStreak, 0);
    expect(report.lowestMonth, isNull);
    expect(report.closest, isNull);
  });

  test('first PDF shared', () {
    final report = compute(
      designReadings(),
      settings: onboardedSettings.copyWith(shares: [DateTime(2026, 6, 14)]),
    );
    expect(report.byId('first_pdf').unlocked, isTrue);
    expect(report.byId('first_pdf').detail, '14 giu');
  });
}
