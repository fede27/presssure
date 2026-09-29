import '../l10n/l10n.dart';
import '../models/measurement.dart';
import '../models/settings.dart';
import 'schedule.dart';
import 'stats.dart';

class PlannedReminder {
  const PlannedReminder(this.id, this.at, this.title, this.body);

  final int id;
  final DateTime at;
  final String title;
  final String body;

  @override
  String toString() => 'PlannedReminder($id, $at, $title)';
}

/// Notification ids: reminders, next-day nudges and the monthly summary use
/// separate ranges so they can be told apart.
const reminderIdBase = 100;
const nudgeIdBase = 200;
const summaryIdBase = 300;

/// Title and body of the regular reminder, also shown as a preview in the
/// habit screen.
({String title, String body}) reminderText(
  AppLocalizations l,
  Schedule schedule,
  DateTime due,
  Measurement? last,
) {
  final title = schedule.frequency == Frequency.daily
      ? l.reminderTitleDaily
      : l.reminderTitleDay(l.weekdayName(weekdayKey(due.weekday)));
  final body = last == null
      ? l.reminderBodyFirst
      : l.reminderBody('${last.systolic}/${last.diastolic}');
  return (title: title, body: body);
}

/// The reminders to schedule from [now], replacing any previous ones.
///
/// Covers the next [count] due days (skipping the current one when already
/// measured), an optional nudge the day after each due day, and the
/// end-of-month summary.
List<PlannedReminder> planReminders({
  required AppSettings settings,
  required List<Measurement> measurements,
  required DateTime now,
  required AppLocalizations l10n,
  required Dates dates,
  int count = 8,
}) {
  final schedule = Schedule.fromSettings(settings);
  final sorted = sortedByDate(measurements);
  final last = sorted.lastOrNull;
  final result = <PlannedReminder>[];

  final current = schedule.periodContaining(now);
  final currentDone = sorted.any((m) => current.contains(m.takenAt));

  // Today's reminder is still useful if its time has not passed yet.
  final remindToday =
      !currentDone &&
      current.start == dateOnly(now) &&
      _at(current.start, settings).isAfter(now);
  var due = remindToday ? current.start : schedule.nextDueAfter(current.start);

  final nudges =
      settings.remindNextDay &&
      settings.frequency != Frequency.daily &&
      settings.frequency != Frequency.fewTimesWeek;

  PlannedReminder nudge(int index, DateTime dueDay) => PlannedReminder(
    nudgeIdBase + index,
    _at(addDays(dueDay, 1), settings),
    l10n.nudgeTitle(l10n.weekdayName(weekdayKey(dueDay.weekday))),
    l10n.nudgeBody,
  );

  // A nudge for the current period when its reminder already went off and
  // nothing was measured yet.
  if (nudges && !currentDone && !remindToday) {
    final nudgeDay = addDays(current.start, 1);
    if (_at(nudgeDay, settings).isAfter(now) &&
        nudgeDay.isBefore(current.end)) {
      result.add(nudge(0, current.start));
    }
  }

  for (var i = 0; i < count; i++) {
    final text = reminderText(l10n, schedule, due, last);
    result.add(
      PlannedReminder(
        reminderIdBase + i,
        _at(due, settings),
        text.title,
        text.body,
      ),
    );
    final next = schedule.nextDueAfter(due);
    if (nudges && addDays(due, 1).isBefore(next)) {
      result.add(nudge(i + 1, due));
    }
    due = next;
  }

  if (settings.monthlySummary) {
    final lastDay = DateTime(now.year, now.month + 1, 0, 20);
    if (lastDay.isAfter(now)) {
      final month = between(
        sorted,
        DateTime(now.year, now.month),
        DateTime(now.year, now.month + 1),
      );
      final avg = average(month);
      final name = capitalize(dates.monthName(now.month));
      result.add(
        PlannedReminder(
          summaryIdBase,
          lastDay,
          l10n.summaryTitle(dates.monthName(now.month)),
          avg == null
              ? l10n.summaryEmpty(name)
              : l10n.summaryBody(name, avg.count, '$avg'),
        ),
      );
    }
  }
  return result;
}

DateTime _at(DateTime day, AppSettings s) =>
    DateTime(day.year, day.month, day.day, s.reminderHour, s.reminderMinute);
