import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../logic/achievements.dart';
import '../logic/bp_category.dart';
import '../logic/schedule.dart';
import '../models/settings.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// Date formats for the phone's regional settings.
  Dates get dates => Dates.of(this);
}

/// Key used by the weekday `select` messages: mon..sun.
String weekdayKey(int weekday) =>
    const ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'][weekday - 1];

/// Locale for dates and numbers.
///
/// Texts come in the app languages only, but dates follow the phone's
/// region when its language matches the one shown: an English phone set to
/// the UK gets "27 September", one set to the US gets "September 27".
String dateLocaleFor(Locale ui, List<Locale> deviceLocales) {
  for (final device in deviceLocales) {
    if (device.languageCode != ui.languageCode) continue;
    final tag = Intl.canonicalizedLocale(device.toString());
    if (DateFormat.localeExists(tag)) return tag;
    break;
  }
  return ui.languageCode;
}

/// Locale-aware date and time formatting.
class Dates {
  Dates(this.locale, {this.use24h = false});

  factory Dates.of(BuildContext context) => Dates(
    dateLocaleFor(
      Localizations.localeOf(context),
      WidgetsBinding.instance.platformDispatcher.locales,
    ),
    use24h: MediaQuery.maybeAlwaysUse24HourFormatOf(context) ?? false,
  );

  final String locale;

  /// The phone's 24-hour setting; otherwise the locale decides.
  final bool use24h;

  /// 07:42 or 7:42 AM.
  String time(DateTime d) =>
      (use24h ? DateFormat.Hm(locale) : DateFormat.jm(locale)).format(d);

  /// 27 settembre / September 27.
  String dayMonth(DateTime d) => DateFormat.MMMMd(locale).format(d);

  /// 27 set / Sep 27.
  String dayMonthShort(DateTime d) => DateFormat.MMMd(locale).format(d);

  /// domenica 27 settembre / Sunday, September 27.
  String weekdayDayMonth(DateTime d) => DateFormat.MMMMEEEEd(locale).format(d);

  /// 27 settembre 2026 / September 27, 2026.
  String fullDate(DateTime d) => DateFormat.yMMMMd(locale).format(d);

  /// 27/9/2026 / 9/27/2026.
  String numericDate(DateTime d) => DateFormat.yMd(locale).format(d);

  /// settembre / September.
  String monthName(int month) =>
      DateFormat.MMMM(locale).format(DateTime(2000, month));

  /// set / Sep.
  String monthShort(int month) =>
      DateFormat.MMM(locale).format(DateTime(2000, month));

  /// dom / Sun.
  String weekdayShort(DateTime d) => DateFormat.E(locale).format(d);

  /// D / S: one letter, for the weekday picker.
  String weekdayNarrow(int weekday) =>
      DateFormat.EEEEE(locale).format(_dayOfWeek(weekday));

  /// Full weekday name, for accessibility labels.
  String weekdayLong(int weekday) =>
      DateFormat.EEEE(locale).format(_dayOfWeek(weekday));

  /// apr – giu / Apr – Jun.
  String monthRange(DateTime from, DateTime to) =>
      '${monthShort(from.month)} – ${monthShort(to.month)}';

  /// "Oggi, 07:42", "Ieri, 08:10" or "Domenica 20 settembre, 08:10".
  String relative(DateTime d, DateTime now, AppLocalizations l) {
    final diff = daysBetween(d, now);
    final t = time(d);
    if (diff == 0) return l.relativeToday(t);
    if (diff == 1) return l.relativeYesterday(t);
    return l.relativeDate(capitalize(weekdayDayMonth(d)), t);
  }

  /// "oggi" or the short date.
  String when(DateTime d, DateTime now, AppLocalizations l) =>
      dateOnly(d) == dateOnly(now) ? l.todayLower : dayMonthShort(d);

  /// 2024-01-01 is a Monday.
  static DateTime _dayOfWeek(int weekday) => DateTime(2024, 1, weekday);
}

String capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Signed difference with a real minus sign: "−12", "+3", "0".
String signed(int n) {
  if (n < 0) return '−${-n}';
  if (n > 0) return '+$n';
  return '0';
}

String partOfDayKey(int hour) {
  if (hour < 12) return 'morning';
  if (hour < 18) return 'afternoon';
  return 'evening';
}

String greetingKey(DateTime now) {
  if (now.hour < 13) return 'morning';
  if (now.hour < 18) return 'afternoon';
  return 'evening';
}

extension ScheduleText on Schedule {
  /// "ogni domenica", "ogni giorno", "lunedì e giovedì"...
  String describe(AppLocalizations l) {
    final key = weekdayKey(day);
    switch (frequency) {
      case Frequency.daily:
        return l.scheduleDaily;
      case Frequency.fewTimesWeek:
        final names = (weekdays.toList()..sort())
            .map((d) => l.weekdayInList(weekdayKey(d)))
            .toList();
        if (names.length == 1) return l.scheduleWeekly(l.weekdayName(key));
        return l.scheduleList(
          names.sublist(0, names.length - 1).join(l.listSeparator),
          names.last,
        );
      case Frequency.weekly:
        return l.scheduleWeekly(l.weekdayName(key));
      case Frequency.biweekly:
        return l.scheduleBiweekly(key);
      case Frequency.monthly:
        return l.scheduleMonthly(key);
    }
  }
}

extension BpCategoryText on BpCategory {
  String label(AppLocalizations l) => switch (this) {
    BpCategory.nonElevated => l.categoryNonElevated,
    BpCategory.elevated => l.categoryElevated,
    BpCategory.high => l.categoryHigh,
  };

  /// Label with the band limits, for legends.
  String rangeLabel(AppLocalizations l, Thresholds t) => switch (this) {
    BpCategory.nonElevated => l.bandNonElevated(
      t.elevatedSystolic,
      t.elevatedDiastolic,
    ),
    BpCategory.elevated => l.bandElevated(
      t.elevatedSystolic,
      t.highSystolic - 1,
      t.elevatedDiastolic,
      t.highDiastolic - 1,
    ),
    BpCategory.high => l.bandHigh(t.highSystolic, t.highDiastolic),
  };
}

String achievementTitle(Achievement a, AppLocalizations l) => switch (a.id) {
  'first_step' => l.badgeFirstStep,
  'two_months' => l.badgeTwoMonths,
  'three_months' => l.badgeThreeMonths,
  'six_months' => l.badgeSixMonths,
  'month_complete' => l.badgeMonthComplete,
  'comeback' => l.badgeComeback,
  'no_pause' => l.badgeNoPause,
  'beat_record' => l.badgeBeatRecord,
  'year' => l.badgeYear,
  'honest' => l.badgeHonest,
  'lynx' => l.badgeLynx,
  'first_pdf' => l.badgeFirstPdf,
  'notes' => l.badgeNotes,
  'double' => l.badgeDouble,
  'month_below' => l.badgeMonthBelow,
  'trend_down' => l.badgeTrendDown,
  'quarter_below' => l.badgeQuarterBelow,
  _ => a.id,
};

/// Unlock date, progress such as "6 su 26", or a hint.
String achievementDetail(
  Achievement a,
  AppLocalizations l,
  Dates dates,
  DateTime now,
  Thresholds t,
) {
  String when(DateTime d) => dates.when(d, now, l);
  String progress() =>
      l.progressOf(a.value.clamp(0, a.target).toInt(), a.target);

  switch (a.id) {
    case 'month_complete':
      return a.unlocked
          ? l.monthCompleteDetail(dates.monthName(a.month!.month), a.value)
          : l.monthCompleteHint;
    case 'comeback':
      return a.unlocked
          ? l.comebackDetail(when(a.unlockedAt!))
          : l.comebackHint;
    case 'beat_record':
      if (a.unlocked) return when(a.unlockedAt!);
      return a.target == 0 ? l.beatRecordHint : progress();
    case 'honest':
      return l.honestDetail;
    case 'first_pdf':
      return a.unlocked ? when(a.unlockedAt!) : l.firstPdfHint;
    case 'month_below':
      return a.unlocked
          ? l.monthAverage(dates.monthName(a.month!.month), '${a.average}')
          : l.monthBelowHint(t.highSystolic, t.highDiastolic);
    case 'trend_down':
      return a.deltaSystolic == null
          ? l.trendHint
          : l.trendDetail(
              '${signed(a.deltaSystolic!)}/${signed(a.deltaDiastolic!)}',
            );
    case 'year':
      return a.unlocked
          ? when(a.unlockedAt!)
          : l.monthsProgress(a.value.clamp(0, a.target).toInt(), a.target);
    case 'quarter_below':
      if (a.unlocked) return l.sinceDate(dates.dayMonthShort(a.unlockedAt!));
      if (a.unlocksOn != null) return l.unlocksOn(dates.dayMonth(a.unlocksOn!));
      return progress();
    default:
      return a.unlocked && a.unlockedAt != null
          ? when(a.unlockedAt!)
          : progress();
  }
}
