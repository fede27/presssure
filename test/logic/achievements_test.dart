import 'package:flutter_test/flutter_test.dart';
import 'package:presssure/l10n/l10n.dart';
import 'package:presssure/logic/achievements.dart';
import 'package:presssure/logic/schedule.dart';
import 'package:presssure/models/measurement.dart';
import 'package:presssure/models/settings.dart';

import '../helpers.dart';

final _now = DateTime(2026, 9, 27, 8);

AchievementsReport compute(
  List<Measurement> readings, {
  AppSettings settings = onboardedSettings,
  DateTime? now,
}) {
  final at = now ?? _now;
  return computeAchievements(
    tracker: HabitTracker(Schedule.fromSettings(settings), readings, at),
    measurements: readings,
    settings: settings,
    now: at,
  );
}

void main() {
  final schedule = Schedule.fromSettings(onboardedSettings);

  group('on the design data (after saving 27 September)', () {
    final report = compute(designReadings(includeToday: true));

    String it(String id) => achievementDetail(
      report.byId(id),
      itL10n,
      itDates,
      _now,
      Thresholds.esc2024,
    );

    String en(String id) => achievementDetail(
      report.byId(id),
      enL10n,
      enDates,
      _now,
      Thresholds.esc2024,
    );

    test('consistency badges match the mockup', () {
      expect(it('first_step'), '5 apr');
      expect(it('two_months'), '24 mag');
      expect(it('three_months'), '28 giu');
      expect(report.byId('six_months').unlocked, isTrue);
      expect(it('six_months'), 'oggi');
      expect(report.byId('month_complete').count, 5);
      expect(it('month_complete'), 'settembre, 4 su 4');
      expect(it('comeback'), '23 ago, dopo la pausa');
      expect(it('no_pause'), '6 su 26');
      expect(it('beat_record'), '6 su 19');
      expect(it('year'), '24 su 52');
      expect(
        achievementTitle(report.byId('year'), itL10n, schedule),
        'Un anno di domeniche',
      );
    });

    test('habits', () {
      expect(report.byId('honest').unlocked, isTrue);
      expect(it('lynx'), '0 su 10');
      expect(report.byId('first_pdf').unlocked, isFalse);
      expect(it('notes'), '3 su 10');
      expect(it('double'), '0 su 5');
    });

    test('trend badges', () {
      expect(it('month_below'), 'agosto 128/81');
      expect(report.byId('trend_down').unlocked, isTrue);
      expect(it('trend_down'), '−12/−9 tra trimestri');
      expect(report.byId('quarter_below').unlocked, isFalse);
      expect(it('quarter_below'), 'si sblocca il 30 settembre');
    });

    test('the same details in English', () {
      expect(en('first_step'), 'Apr 5');
      expect(en('six_months'), 'today');
      expect(en('month_complete'), 'September, 4 of 4');
      expect(en('comeback'), 'Aug 23, after the break');
      expect(en('beat_record'), '6 of 19');
      expect(en('trend_down'), '−12/−9 between quarters');
      expect(en('quarter_below'), 'unlocks on September 30');
      expect(
        achievementTitle(report.byId('year'), enL10n, schedule),
        'A year of Sundays',
      );
      expect(
        achievementTitle(report.byId('comeback'), enL10n, schedule),
        'Fresh start',
      );
    });

    test('records', () {
      expect(report.bestStreak, 18);
      expect(report.bestStreakPeriods!.first.start, DateTime(2026, 4, 5));
      expect(report.bestStreakPeriods!.last.start, DateTime(2026, 8, 2));
      expect(report.lowestMonth!.month, 9);
      expect(report.completeMonths, 5);
      expect(report.monthsTracked, 6);
    });

    test('new badges are the ones unlocked in the last days', () {
      expect(report.byId('six_months').isNew(_now), isTrue);
      expect(report.byId('first_step').isNew(_now), isFalse);
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
    expect(
      achievementDetail(
        report.byId('first_pdf'),
        itL10n,
        itDates,
        _now,
        Thresholds.esc2024,
      ),
      '14 giu',
    );
  });
}
