import 'package:flutter_test/flutter_test.dart';
import 'package:presssure/l10n/l10n.dart';
import 'package:presssure/logic/reminder_plan.dart';
import 'package:presssure/models/measurement.dart';
import 'package:presssure/models/settings.dart';

import '../helpers.dart';

void main() {
  const weekly = AppSettings(onboarded: true, monthlySummary: false);

  List<PlannedReminder> makePlan({
    required AppSettings settings,
    required List<Measurement> measurements,
    required DateTime now,
    AppLocalizations? l10n,
    Dates? dates,
  }) => planReminders(
    settings: settings,
    measurements: measurements,
    now: now,
    l10n: l10n ?? itL10n,
    dates: dates ?? itDates,
  );

  List<PlannedReminder> reminders(List<PlannedReminder> plan) =>
      plan.where((r) => r.id >= reminderIdBase && r.id < nudgeIdBase).toList();

  List<PlannedReminder> nudges(List<PlannedReminder> plan) =>
      plan.where((r) => r.id >= nudgeIdBase && r.id < summaryIdBase).toList();

  test('on Saturday the next reminder is Sunday at 8', () {
    final plan = makePlan(
      settings: weekly,
      measurements: const [],
      now: DateTime(2026, 9, 26, 10),
    );
    final r = reminders(plan);
    expect(r.length, 8);
    expect(r.first.at, DateTime(2026, 9, 27, 8));
    expect(r[1].at, DateTime(2026, 10, 4, 8));
    expect(r.first.title, 'È domenica: 2 minuti per la pressione');
    expect(nudges(plan).first.at, DateTime(2026, 9, 28, 8));
  });

  test('on Sunday before 8 today still gets its reminder', () {
    final plan = makePlan(
      settings: weekly,
      measurements: designReadings(),
      now: DateTime(2026, 9, 27, 7),
    );
    expect(reminders(plan).first.at, DateTime(2026, 9, 27, 8));
    expect(reminders(plan).first.body, contains('126/82'));
  });

  test('after measuring, today is skipped, nudge included', () {
    final plan = makePlan(
      settings: weekly,
      measurements: designReadings(includeToday: true),
      now: DateTime(2026, 9, 27, 9),
    );
    expect(reminders(plan).first.at, DateTime(2026, 10, 4, 8));
    expect(
      nudges(plan).map((n) => n.at),
      isNot(contains(DateTime(2026, 9, 28, 8))),
    );
  });

  test('missed this morning: nudge tomorrow', () {
    final plan = makePlan(
      settings: weekly,
      measurements: designReadings(),
      now: DateTime(2026, 9, 27, 20),
    );
    expect(nudges(plan).first.at, DateTime(2026, 9, 28, 8));
    expect(nudges(plan).first.title, 'Ieri era domenica');
  });

  test('nudges can be turned off', () {
    final plan = makePlan(
      settings: weekly.copyWith(remindNextDay: false),
      measurements: const [],
      now: DateTime(2026, 9, 26, 10),
    );
    expect(nudges(plan), isEmpty);
  });

  test('monthly summary on the last day of the month', () {
    final plan = makePlan(
      settings: weekly.copyWith(monthlySummary: true),
      measurements: designReadings(includeToday: true),
      now: DateTime(2026, 9, 27, 9),
    );
    final summary = plan.firstWhere((r) => r.id == summaryIdBase);
    expect(summary.at, DateTime(2026, 9, 30, 20));
    expect(summary.body, 'Settembre: 4 misure, media 125/80.');
  });

  test('daily reminders use the chosen time', () {
    final plan = makePlan(
      settings: weekly.copyWith(
        frequency: Frequency.daily,
        reminderHour: 21,
        reminderMinute: 30,
      ),
      measurements: const [],
      now: DateTime(2026, 9, 26, 10),
    );
    expect(reminders(plan).first.at, DateTime(2026, 9, 26, 21, 30));
    expect(reminders(plan)[1].at, DateTime(2026, 9, 27, 21, 30));
    expect(nudges(plan), isEmpty);
  });

  test('reminders cover four weeks even when daily', () {
    final plan = makePlan(
      settings: weekly.copyWith(frequency: Frequency.daily),
      measurements: const [],
      now: DateTime(2026, 9, 26, 10),
    );
    final r = reminders(plan);
    expect(r.last.at, DateTime(2026, 10, 24, 8));
    expect(r.map((x) => x.id).toSet().length, r.length);
    expect(r.last.id, lessThan(nudgeIdBase));
  });

  test('reminders are written in the phone language', () {
    final plan = makePlan(
      settings: weekly.copyWith(monthlySummary: true),
      measurements: designReadings(includeToday: true),
      now: DateTime(2026, 9, 27, 9),
      l10n: enL10n,
      dates: enDates,
    );
    final first = reminders(plan).first;
    expect(first.title, "It's Sunday: 2 minutes for your blood pressure");
    expect(first.body, contains('Last time 124/77'));
    expect(nudges(plan).first.title, 'Yesterday was Sunday');
    final summary = plan.firstWhere((r) => r.id == summaryIdBase);
    expect(summary.title, 'Your September');
    expect(summary.body, 'September: 4 readings, average 125/80.');
  });

  group('backup reminder', () {
    PlannedReminder? backup(List<PlannedReminder> plan) =>
        plan.where((r) => r.id == backupIdBase).firstOrNull;

    test('a month after the last backup, at the reminder time', () {
      final plan = makePlan(
        settings: weekly.copyWith(lastBackup: DateTime(2026, 9, 1, 21)),
        measurements: designReadings(),
        now: DateTime(2026, 9, 26, 10),
      );
      final r = backup(plan)!;
      expect(r.at, DateTime(2026, 10, 1, 8));
      expect(r.title, 'È ora di un backup');
    });

    test('overdue: the next day; never saved: a month after the start', () {
      final overdue = makePlan(
        settings: weekly.copyWith(lastBackup: DateTime(2026, 7, 1)),
        measurements: designReadings(),
        now: DateTime(2026, 9, 26, 10),
      );
      expect(backup(overdue)!.at, DateTime(2026, 9, 27, 8));

      final never = makePlan(
        settings: weekly,
        measurements: [reading(DateTime(2026, 9, 6, 8), 120, 80)],
        now: DateTime(2026, 9, 26, 10),
      );
      expect(backup(never)!.at, DateTime(2026, 10, 6, 8));
    });

    test('not when switched off or with an empty diary', () {
      expect(
        backup(
          makePlan(
            settings: weekly.copyWith(backupReminder: false),
            measurements: designReadings(),
            now: DateTime(2026, 9, 26, 10),
          ),
        ),
        isNull,
      );
      expect(
        backup(
          makePlan(
            settings: weekly,
            measurements: const [],
            now: DateTime(2026, 9, 26, 10),
          ),
        ),
        isNull,
      );
    });
  });

  test('nothing is planned before the habit is set', () {
    final plan = makePlan(
      settings: const AppSettings(),
      measurements: designReadings(),
      now: DateTime(2026, 9, 26, 10),
    );
    expect(plan, isEmpty);
  });
}
