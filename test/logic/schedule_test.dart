import 'package:flutter_test/flutter_test.dart';
import 'package:presssure/l10n/l10n.dart';
import 'package:presssure/logic/schedule.dart';
import 'package:presssure/models/settings.dart';

import '../helpers.dart';

void main() {
  group('Schedule', () {
    test('weekly is due on the chosen weekday only', () {
      final s = Schedule(
        frequency: Frequency.weekly,
        weekdays: {DateTime.sunday},
      );
      expect(s.isDue(DateTime(2026, 9, 27)), isTrue); // Sunday
      expect(s.isDue(DateTime(2026, 9, 28)), isFalse);
      expect(s.dueOnOrBefore(DateTime(2026, 9, 30)), DateTime(2026, 9, 27));
      expect(s.nextDueAfter(DateTime(2026, 9, 27)), DateTime(2026, 10, 4));
      expect(s.describe(itL10n), 'ogni domenica');
      expect(s.occasions(itL10n, 2), 'domeniche');
      expect(s.describe(enL10n), 'every Sunday');
      expect(s.inARow(enL10n, 1), '1 Sunday in a row');
      expect(s.inARow(itL10n, 5), '5 domeniche di fila');
    });

    test('daily is always due', () {
      final s = Schedule(frequency: Frequency.daily, weekdays: {});
      expect(s.isDue(DateTime(2026, 9, 28)), isTrue);
      expect(s.nextDueAfter(DateTime(2026, 9, 28, 20)), DateTime(2026, 9, 29));
      expect(s.describe(itL10n), 'ogni giorno');
    });

    test('few times a week uses all selected days', () {
      final s = Schedule(
        frequency: Frequency.fewTimesWeek,
        weekdays: {DateTime.monday, DateTime.thursday},
      );
      expect(s.isDue(DateTime(2026, 9, 28)), isTrue); // Monday
      expect(s.isDue(DateTime(2026, 10, 1)), isTrue); // Thursday
      expect(s.isDue(DateTime(2026, 9, 29)), isFalse);
      expect(s.describe(itL10n), 'lunedì e giovedì');
      expect(s.describe(enL10n), 'Mondays and Thursdays');
    });

    test('biweekly alternates weeks from the anchor', () {
      final s = Schedule(
        frequency: Frequency.biweekly,
        weekdays: {DateTime.sunday},
        anchor: DateTime(2026, 9, 24),
      );
      expect(s.isDue(DateTime(2026, 9, 27)), isTrue);
      expect(s.isDue(DateTime(2026, 10, 4)), isFalse);
      expect(s.isDue(DateTime(2026, 10, 11)), isTrue);
      expect(s.isDue(DateTime(2026, 9, 13)), isTrue);
    });

    test('monthly is the first chosen weekday of the month', () {
      final s = Schedule(
        frequency: Frequency.monthly,
        weekdays: {DateTime.sunday},
      );
      expect(s.isDue(DateTime(2026, 9, 6)), isTrue);
      expect(s.isDue(DateTime(2026, 9, 13)), isFalse);
      expect(s.nextDueAfter(DateTime(2026, 9, 6)), DateTime(2026, 10, 4));
      expect(s.describe(itL10n), 'la prima domenica del mese');
      expect(s.describe(enL10n), 'the first Sunday of the month');
    });

    test('periods are contiguous windows between due days', () {
      final s = Schedule(
        frequency: Frequency.weekly,
        weekdays: {DateTime.sunday},
      );
      final periods = s.periodsBetween(
        DateTime(2026, 9, 1),
        DateTime(2026, 9, 27, 8),
      );
      expect(periods.first.start, DateTime(2026, 8, 30));
      expect(periods.last.start, DateTime(2026, 9, 27));
      for (var i = 1; i < periods.length; i++) {
        expect(periods[i].start, periods[i - 1].end);
      }
    });

    test('daylight saving change does not shift days', () {
      final s = Schedule(frequency: Frequency.daily, weekdays: {});
      // Europe switches back on the last Sunday of October.
      expect(s.nextDueAfter(DateTime(2026, 10, 25)), DateTime(2026, 10, 26));
      expect(daysBetween(DateTime(2026, 10, 24), DateTime(2026, 10, 27)), 3);
    });
  });

  group('HabitTracker on the design data', () {
    final schedule = Schedule(
      frequency: Frequency.weekly,
      weekdays: {DateTime.sunday},
    );

    test('before today: the current Sunday is pending', () {
      final t = HabitTracker(schedule, designReadings(), designNow);
      expect(t.periods.length, 26);
      expect(t.current!.status, PeriodStatus.pending);
      expect(t.currentStreak, 5);
      expect(t.bestStreak, 18);
    });

    test(
      'the monthly jolly forgives 9 August, 16 August breaks the streak',
      () {
        final t = HabitTracker(
          schedule,
          designReadings(includeToday: true),
          designNow,
        );
        final aug9 = t.periods.firstWhere(
          (p) => p.period.start == DateTime(2026, 8, 9),
        );
        final aug16 = t.periods.firstWhere(
          (p) => p.period.start == DateTime(2026, 8, 16),
        );
        expect(aug9.status, PeriodStatus.jolly);
        expect(aug16.status, PeriodStatus.missed);
        expect(t.currentStreak, 6);
        expect(t.bestStreak, 18);
        expect(t.bestStreakPeriods!.first.start, DateTime(2026, 4, 5));
        expect(t.bestStreakPeriods!.last.start, DateTime(2026, 8, 2));
        expect(t.bestBeforeCurrentRun, 18);
        expect(t.recordBeatenAt, isNull);
        expect(t.doneCount, 24);
        // September's jolly is still available.
        expect(t.jollyAvailable, isTrue);
      },
    );

    test('no readings: empty tracker', () {
      final t = HabitTracker(schedule, const [], designNow);
      expect(t.periods, isEmpty);
      expect(t.current, isNull);
      expect(t.currentStreak, 0);
    });

    test('a streak longer than an earlier one beats the record', () {
      final readings = [
        for (var i = 0; i < 3; i++)
          reading(DateTime(2026, 5, 3 + i * 7, 8), 120, 80),
        // 24 and 31 May missed: the jolly covers only one per month.
        for (var i = 0; i < 4; i++)
          reading(DateTime(2026, 6, 7 + i * 7, 8), 120, 80),
      ];
      final t = HabitTracker(schedule, readings, DateTime(2026, 6, 29));
      expect(t.bestBeforeCurrentRun, 3);
      expect(t.currentStreak, 4);
      expect(t.recordBeatenAt, DateTime(2026, 6, 28, 8));
    });
  });
}
