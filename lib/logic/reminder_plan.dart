import '../models/measurement.dart';
import '../models/settings.dart';
import 'formatting.dart';
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
  Schedule schedule,
  DateTime due,
  Measurement? last,
) {
  final title = schedule.frequency == Frequency.daily
      ? 'È ora: 2 minuti per la pressione'
      : 'È ${weekdayName(due.weekday)}: 2 minuti per la pressione';
  final body = last == null
      ? 'Siediti, rilassati e registra la tua prima misura.'
      : 'L’ultima volta ${last.systolic}/${last.diastolic}. '
            'Misura e segna i valori: hai finito.';
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

  // A nudge for the current period when its reminder already went off and
  // nothing was measured yet.
  if (nudges && !currentDone && !remindToday) {
    final nudgeAt = _at(addDays(current.start, 1), settings);
    if (nudgeAt.isAfter(now) &&
        addDays(current.start, 1).isBefore(current.end)) {
      result.add(_nudge(0, nudgeAt, schedule, current.start, last));
    }
  }

  for (var i = 0; i < count; i++) {
    final text = reminderText(schedule, due, last);
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
      result.add(
        _nudge(i + 1, _at(addDays(due, 1), settings), schedule, due, last),
      );
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
      final name = capitalize(monthName(now.month));
      result.add(
        PlannedReminder(
          summaryIdBase,
          lastDay,
          'Il tuo $name',
          avg == null
              ? '$name: nessuna misura. Il mese nuovo è un buon inizio.'
              : '$name: ${avg.count} ${avg.count == 1 ? 'misura' : 'misure'}, '
                    'media $avg.',
        ),
      );
    }
  }
  return result;
}

DateTime _at(DateTime day, AppSettings s) =>
    DateTime(day.year, day.month, day.day, s.reminderHour, s.reminderMinute);

PlannedReminder _nudge(
  int index,
  DateTime at,
  Schedule schedule,
  DateTime due,
  Measurement? last,
) {
  return PlannedReminder(
    nudgeIdBase + index,
    at,
    'Ieri era ${weekdayName(due.weekday)}',
    'Nessun problema: misura oggi e la serie continua.',
  );
}
