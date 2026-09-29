// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PressSure';

  @override
  String get navToday => 'Today';

  @override
  String get navDiary => 'Diary';

  @override
  String get navTrends => 'Trends';

  @override
  String get navShare => 'Share';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get done => 'Done';

  @override
  String get close => 'Close';

  @override
  String get delete => 'Delete';

  @override
  String get change => 'Change';

  @override
  String get add => 'Add';

  @override
  String get back => 'Back';

  @override
  String comingSoon(String feature) {
    return '$feature: coming soon.';
  }

  @override
  String errorGeneric(String error) {
    return 'Couldn\'t complete: $error';
  }

  @override
  String weekdayName(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      'mon': 'Monday',
      'tue': 'Tuesday',
      'wed': 'Wednesday',
      'thu': 'Thursday',
      'fri': 'Friday',
      'sat': 'Saturday',
      'sun': 'Sunday',
      'other': 'day',
    });
    return '$_temp0';
  }

  @override
  String weekdayInList(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      'mon': 'Mondays',
      'tue': 'Tuesdays',
      'wed': 'Wednesdays',
      'thu': 'Thursdays',
      'fri': 'Fridays',
      'sat': 'Saturdays',
      'sun': 'Sundays',
      'other': 'days',
    });
    return '$_temp0';
  }

  @override
  String onWeekday(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      'mon': 'on Mondays',
      'tue': 'on Tuesdays',
      'wed': 'on Wednesdays',
      'thu': 'on Thursdays',
      'fri': 'on Fridays',
      'sat': 'on Saturdays',
      'sun': 'on Sundays',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String nounReadings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'readings',
      one: 'reading',
    );
    return '$_temp0';
  }

  @override
  String readingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count readings',
      one: '1 reading',
    );
    return '$_temp0';
  }

  @override
  String inARow(int count) {
    return '$count in a row';
  }

  @override
  String readingsInARow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count readings in a row',
      one: '1 reading in a row',
    );
    return '$_temp0';
  }

  @override
  String progressOf(int value, int target) {
    return '$value of $target';
  }

  @override
  String get scheduleDaily => 'every day';

  @override
  String scheduleWeekly(String weekday) {
    return 'every $weekday';
  }

  @override
  String scheduleBiweekly(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      'mon': 'every other Monday',
      'tue': 'every other Tuesday',
      'wed': 'every other Wednesday',
      'thu': 'every other Thursday',
      'fri': 'every other Friday',
      'sat': 'every other Saturday',
      'sun': 'every other Sunday',
      'other': 'every other week',
    });
    return '$_temp0';
  }

  @override
  String scheduleMonthly(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      'mon': 'the first Monday of the month',
      'tue': 'the first Tuesday of the month',
      'wed': 'the first Wednesday of the month',
      'thu': 'the first Thursday of the month',
      'fri': 'the first Friday of the month',
      'sat': 'the first Saturday of the month',
      'sun': 'the first Sunday of the month',
      'other': 'once a month',
    });
    return '$_temp0';
  }

  @override
  String scheduleList(String days, String last) {
    return '$days and $last';
  }

  @override
  String get listSeparator => ', ';

  @override
  String partOfDay(String part) {
    String _temp0 = intl.Intl.selectLogic(part, {
      'morning': 'morning',
      'afternoon': 'afternoon',
      'other': 'evening',
    });
    return '$_temp0';
  }

  @override
  String greeting(String part) {
    String _temp0 = intl.Intl.selectLogic(part, {
      'morning': 'Good morning',
      'afternoon': 'Good afternoon',
      'other': 'Good evening',
    });
    return '$_temp0';
  }

  @override
  String relativeToday(String time) {
    return 'Today, $time';
  }

  @override
  String relativeYesterday(String time) {
    return 'Yesterday, $time';
  }

  @override
  String relativeDate(String date, String time) {
    return '$date, $time';
  }

  @override
  String get todayLower => 'today';

  @override
  String get todayCapital => 'Today';

  @override
  String get latest => 'Latest';

  @override
  String get categoryNonElevated => 'Not elevated';

  @override
  String get categoryElevated => 'Elevated';

  @override
  String get categoryHigh => 'High';

  @override
  String bandNonElevated(int sys, int dia) {
    return 'Not elevated (below $sys/$dia)';
  }

  @override
  String bandElevated(int sysFrom, int sysTo, int diaFrom, int diaTo) {
    return 'Elevated ($sysFrom–$sysTo / $diaFrom–$diaTo)';
  }

  @override
  String bandHigh(int sys, int dia) {
    return 'Above threshold ($sys/$dia)';
  }

  @override
  String get aboveThreshold => 'Above threshold';

  @override
  String get welcomeTitle => 'Your blood pressure diary, worry-free';

  @override
  String get welcomeFeaturePhoto =>
      'Snap the display, the app writes down the values';

  @override
  String get welcomeFeatureReminder => 'A reminder on the day you choose';

  @override
  String get welcomeFeatureExport => 'Export to PDF or CSV whenever you need';

  @override
  String get welcomeFeatureLocal =>
      'Your data stays on your phone: no account, no server';

  @override
  String get welcomeNoticeTitle => 'Good to know, just once';

  @override
  String get welcomeNoticeBody =>
      'PressSure is a personal diary: it is not a medical device and does not diagnose. The default bands follow the European ESC 2024 guidelines and you can change them. If you have doubts about your health, talk to your doctor.';

  @override
  String get welcomeStart => 'Got it, let\'s start';

  @override
  String get habitTitle => 'Your habit';

  @override
  String get habitIntro =>
      'Pick a rhythm you can keep. Reminders, charts and reports adapt.';

  @override
  String get habitHowOften => 'How often do you measure?';

  @override
  String get frequencyDaily => 'Every day';

  @override
  String get frequencyFewTimesWeek => 'On several days a week';

  @override
  String get frequencyWeekly => 'Once a week';

  @override
  String get frequencyBiweekly => 'Every two weeks';

  @override
  String get frequencyMonthly => 'Once a month';

  @override
  String get habitWhen => 'When';

  @override
  String get habitPickTwoDays => 'Pick at least two days';

  @override
  String get habitReminderTime => 'Reminder time';

  @override
  String get habitKeepOnTrack => 'Stay on track';

  @override
  String get habitRemindNextDay => 'If I skip, remind me the next day';

  @override
  String get habitRemindNextDayHint =>
      'Just once, then wait for the next planned reading';

  @override
  String get habitMonthlySummary => 'End-of-month summary';

  @override
  String get habitMonthlySummaryHint =>
      'E.g. “September: 4 readings, average 125/80”';

  @override
  String habitPreviewHeading(String when, String time) {
    return 'This is how it arrives $when at $time';
  }

  @override
  String get habitSaveAndStart => 'Save and start';

  @override
  String habitCardSubtitle(String schedule, String part) {
    return 'Your habit · $schedule $part';
  }

  @override
  String get todayFirstReading => 'Your first reading is waiting';

  @override
  String get todayDoneDaily => 'Done for today, see you tomorrow';

  @override
  String todayDoneNext(String date) {
    return 'Done! Next reading $date';
  }

  @override
  String get todayIsTheDay => 'Today is measuring day';

  @override
  String todayMissing(String date) {
    return 'Reading for $date still to do';
  }

  @override
  String get todayStartStreak => 'Every reading counts: start a streak.';

  @override
  String todayCompleteMonth(String month) {
    return 'Today you complete $month.';
  }

  @override
  String get achievements => 'Achievements';

  @override
  String get takePhoto => 'Snap';

  @override
  String get byHand => 'By hand';

  @override
  String get habitAndReminders => 'Habit and reminders';

  @override
  String periodDotsLabel(int total, int done, int missed) {
    return 'Last $total planned readings: $done done, $missed missed';
  }

  @override
  String lastReadingOn(String date) {
    return 'Last reading · $date';
  }

  @override
  String pulseValue(int pulse) {
    return 'Pulse $pulse';
  }

  @override
  String pulseLower(int pulse) {
    return 'pulse $pulse';
  }

  @override
  String previousValue(String value) {
    return 'the time before $value';
  }

  @override
  String previousReading(String value) {
    return 'previous reading $value';
  }

  @override
  String get bandByEsc => 'band per the European ESC 2024 guidelines';

  @override
  String get bandByCustom => 'band per your thresholds';

  @override
  String get last6Months => 'Last 6 months';

  @override
  String get legendSingle => 'Single reading';

  @override
  String get legendAvg4 => 'Average of last 4';

  @override
  String get legendThreshold => 'Threshold';

  @override
  String get legendSkipped => 'Missed readings';

  @override
  String get trendEmpty =>
      'After a few readings you\'ll see here how your blood pressure changes.';

  @override
  String quarterSide(String range, String readings) {
    return '$range · $readings';
  }

  @override
  String get emptyTitle => 'No readings yet';

  @override
  String get emptyBody =>
      'Sit with your back supported, rest for five minutes and measure on your arm with the cuff at heart level. Then log the values here: band, charts and reports build themselves.';

  @override
  String get scanPlaceholder =>
      'Reading from the display is coming soon. For now, enter the values by hand.';

  @override
  String get entryNewTitle => 'Check and save';

  @override
  String get entryEditTitle => 'Edit reading';

  @override
  String get deleteReading => 'Delete reading';

  @override
  String get deleteConfirmTitle => 'Delete this reading?';

  @override
  String get deleteConfirmBody =>
      'The reading disappears from the diary, the charts and the reports. This can\'t be undone.';

  @override
  String get errSysRequired => 'Enter the systolic';

  @override
  String get errDiaRequired => 'Enter the diastolic';

  @override
  String errRange(int min, int max) {
    return 'Between $min and $max';
  }

  @override
  String get errSysAboveDia => 'Must be higher than the diastolic';

  @override
  String get systolic => 'Systolic';

  @override
  String get diastolic => 'Diastolic';

  @override
  String get pulse => 'Pulse';

  @override
  String get optional => 'optional';

  @override
  String get pickDayHelp => 'Day of the reading';

  @override
  String get pickTimeHelp => 'Time of the reading';

  @override
  String get whenReading => 'Reading';

  @override
  String get whenManual => 'Entered by hand';

  @override
  String get scanTooltip => 'Read from the display (coming soon)';

  @override
  String categoryHint(String category, String source) {
    return '“$category” band $source';
  }

  @override
  String get hintSourceEsc => 'per ESC 2024';

  @override
  String get hintSourceCustom => 'per your thresholds';

  @override
  String get contextTitle => 'Context';

  @override
  String get arm => 'Arm';

  @override
  String get armLeft => 'Left';

  @override
  String get armRight => 'Right';

  @override
  String get posture => 'Position';

  @override
  String get postureSitting => 'Sitting';

  @override
  String get postureStanding => 'Standing';

  @override
  String get postureLying => 'Lying down';

  @override
  String get note => 'Note';

  @override
  String get noteHint => 'E.g. coffee half an hour before, slept badly';

  @override
  String get secondReading => 'Second reading';

  @override
  String get secondAverageInfo =>
      'The diary will save the average of the two readings.';

  @override
  String secondAverageValue(String value) {
    return 'The average will be saved: $value';
  }

  @override
  String get secondWaitTitle => 'Relax, just a moment';

  @override
  String get secondWaitBody =>
      'When time is up, measure again on the same arm.';

  @override
  String get secondOptionalTitle => 'Second reading? Optional';

  @override
  String get secondOptionalBody =>
      'If you take it a minute later, the app saves the average.';

  @override
  String timerSkip(String time) {
    return '$time · Skip';
  }

  @override
  String get timerStart => 'Timer 1:00';

  @override
  String get saveReading => 'Save reading';

  @override
  String get saveChanges => 'Save changes';

  @override
  String fieldSemantics(String label, String unit) {
    return '$label in $unit';
  }

  @override
  String get newBadge => 'NEW BADGE';

  @override
  String get readingSaved => 'READING SAVED';

  @override
  String celebrateTitleBadge(String title) {
    return '$title!';
  }

  @override
  String celebrateTitleStreak(String streak) {
    return 'Done, $streak';
  }

  @override
  String celebrateInDiary(String value) {
    return '$value is in the diary.';
  }

  @override
  String celebrateSince(String date, String readings, int total) {
    return 'Since $date: $readings out of $total planned.';
  }

  @override
  String andMoreBadges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' And $count more badges.',
      one: ' And 1 more badge.',
    );
    return '$_temp0';
  }

  @override
  String jollyLine(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You have $count jokers if you skip a reading.',
      one: 'You have a joker if you skip a reading.',
      zero: 'No jokers left: don\'t skip the next one.',
    );
    return '$_temp0';
  }

  @override
  String lowestSince(String value, String month) {
    return '$value, the lowest since $month';
  }

  @override
  String readingStored(String value) {
    return '$value saved';
  }

  @override
  String avgOfLast(int count, String value) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Average of the last $count readings: $value.',
      one: 'Last reading: $value.',
    );
    return '$_temp0';
  }

  @override
  String almostBadge(String title) {
    return 'Almost “$title”';
  }

  @override
  String streakRecordSemantics(int current) {
    return 'Record streak: $current';
  }

  @override
  String streakToBeat(int current, int target, int record) {
    return '$current of $target to beat the record of $record';
  }

  @override
  String streakNow(int count) {
    return '$count now';
  }

  @override
  String get newRecord => 'new record!';

  @override
  String recordValue(int count) {
    return 'record $count';
  }

  @override
  String savedAt(String when) {
    return 'Reading saved · $when';
  }

  @override
  String get higherThanUsual => 'Higher than usual today';

  @override
  String get aboveThresholdToday => 'Above the threshold today';

  @override
  String usuallyAround(String value) {
    return 'You\'re usually around $value. ';
  }

  @override
  String get remeasureHint =>
      'If you like, measure again after a few minutes of rest: the diary keeps both.';

  @override
  String get veryHighWarning =>
      'Values this high should be checked again. If they are confirmed or you don\'t feel well, contact your doctor or the emergency number.';

  @override
  String get remeasure => 'Measure again';

  @override
  String get addNote => 'Add note';

  @override
  String badgeNamed(String title) {
    return 'Badge “$title”';
  }

  @override
  String get honestBody => 'Bad days are part of the diary too.';

  @override
  String streakSafe(String streak) {
    return 'Streak safe · $streak';
  }

  @override
  String diarySubtitle(String readings, String month, String schedule) {
    return '$readings since $month · $schedule';
  }

  @override
  String get searchDiary => 'Search the diary';

  @override
  String get closeSearch => 'Close search';

  @override
  String get searchHint => 'Search notes';

  @override
  String get filterAll => 'All';

  @override
  String get filterNotes => 'With notes';

  @override
  String get noMatch => 'No readings match.';

  @override
  String monthSummary(String readings, String avg) {
    return '$readings · average $avg';
  }

  @override
  String get averageOfTwo => 'average of 2';

  @override
  String get readFromPhoto => 'Read from photo';

  @override
  String gapLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count missed readings',
      one: '1 missed reading',
    );
    return '$_temp0';
  }

  @override
  String get newReading => 'New reading';

  @override
  String get diaryEmptyTitle => 'The diary is empty';

  @override
  String get diaryEmptyBody =>
      'Every reading you save ends up here, grouped by month.';

  @override
  String get diaryAddFirst => 'Add your first reading';

  @override
  String get range3m => '3 months';

  @override
  String get range6m => '6 months';

  @override
  String get range1y => '1 year';

  @override
  String get rangeAll => 'All';

  @override
  String get exportAndShare => 'Export and share';

  @override
  String get trendsEmpty =>
      'No readings in this period. The chart fills up with the next ones.';

  @override
  String lastNReadings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Last $count readings',
      one: 'Last reading',
    );
    return '$_temp0';
  }

  @override
  String readingsInRange(String readings, String range) {
    return '$readings in $range';
  }

  @override
  String avgPulse(int pulse) {
    return 'Average pulse $pulse';
  }

  @override
  String get yourReadings => 'Your readings';

  @override
  String get sysShort => 'Sys.';

  @override
  String get diaShort => 'Dia.';

  @override
  String get quarterCompare => 'Quarter vs quarter';

  @override
  String quarterNeedTwo(String first, String second) {
    return 'Readings in two quarters are needed: $first and $second.';
  }

  @override
  String get regularity => 'Regularity';

  @override
  String regularityCount(int done, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: '$done readings of $total planned',
      one: '1 reading of $total planned',
    );
    return '$_temp0';
  }

  @override
  String regularityLabel(int done, int total) {
    return '$done measured out of $total';
  }

  @override
  String get bandsTitle => 'Readings by band';

  @override
  String bandsRecent(String month, int below, int total, int sys, int dia) {
    return 'Since $month, $below of $total readings are below $sys/$dia.';
  }

  @override
  String get bandsDefaultEsc =>
      'Default bands: European ESC 2024 guidelines, home measurement.';

  @override
  String get bandsCustom =>
      'Custom thresholds. The ESC 2024 guidelines for home measurement use 135/85.';

  @override
  String get changeThresholds => 'Change thresholds';

  @override
  String get restoreEsc => 'Reset to ESC 2024';

  @override
  String get thresholdsDoctorNote =>
      'Change them only if your doctor tells you to.';

  @override
  String get thresholdsErrRange => 'Enter values between 40 and 250.';

  @override
  String get thresholdsErrOrder =>
      'The elevated band must be below the threshold.';

  @override
  String get reportScreenSubtitle =>
      'Your diary as PDF or CSV, when you need it';

  @override
  String get previewTitle => 'Report preview';

  @override
  String get neverExported => 'You haven\'t exported the diary yet';

  @override
  String lastExported(String date) {
    return 'Last export: $date';
  }

  @override
  String newSince(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new readings since then',
      one: '1 new reading since then',
    );
    return '$_temp0';
  }

  @override
  String get rangeSinceLast => 'Only new ones';

  @override
  String get noReadingsInPeriod => 'No readings in this period';

  @override
  String rangeLabel(String from, String to, String readings) {
    return '$from – $to · $readings';
  }

  @override
  String get includeTitle => 'What to include';

  @override
  String get includeChart => 'Trend chart';

  @override
  String get includeTable => 'Table of all readings';

  @override
  String get includeNotes => 'Notes';

  @override
  String get downloadPdf => 'Download PDF';

  @override
  String get share => 'Share';

  @override
  String get exportCsv => 'Export data as CSV (for Excel)';

  @override
  String get pdfA4 => 'PDF A4';

  @override
  String get previewReadings => 'Readings';

  @override
  String get previewAverage => 'Average';

  @override
  String get previewLast4 => 'Last 4';

  @override
  String get openPreview => 'Open preview';

  @override
  String get openPreviewSemantics => 'Open the PDF preview';

  @override
  String get csvSubject => 'Blood pressure diary (CSV)';

  @override
  String get fileNameBase => 'PressSure_diary';

  @override
  String get notYetExported => 'You haven\'t exported the diary yet.';

  @override
  String get inARowStat => 'readings in a row';

  @override
  String get recordInARow => 'record streak';

  @override
  String get totalReadings => 'total readings';

  @override
  String jollyAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Jokers: $count available',
      one: 'Jokers: 1 available',
      zero: 'Jokers: none available',
    );
    return '$_temp0';
  }

  @override
  String jollyNext(int count) {
    return 'next in $count';
  }

  @override
  String jollyNextSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Next joker in $count readings',
      one: 'Next joker in 1 reading',
    );
    return '$_temp0';
  }

  @override
  String get jollyFull => 'maximum reached';

  @override
  String jollyBody(int every, int max) {
    return 'Skip a reading? A joker keeps your streak alive. You earn one every $every planned readings, up to $max.';
  }

  @override
  String get groupConsistency => 'Consistency';

  @override
  String get groupHabits => 'Good habits';

  @override
  String get groupTrend => 'Trend';

  @override
  String trendGroupNote(int sys, int dia) {
    return 'threshold $sys/$dia, on monthly averages';
  }

  @override
  String get personalRecords => 'Personal records';

  @override
  String get longestStreak => 'Longest streak';

  @override
  String get lowestMonth => 'Month with the lowest average';

  @override
  String get onSchedule => 'Readings on the planned days';

  @override
  String onScheduleValue(int done, int total, String percent) {
    return '$done of $total · $percent';
  }

  @override
  String badgeSemantics(String title, String state, String detail) {
    return '$title, $state, $detail';
  }

  @override
  String get badgeUnlocked => 'unlocked';

  @override
  String get badgeLocked => 'to unlock';

  @override
  String get newTag => 'NEW';

  @override
  String get badgeFirstStep => 'First step';

  @override
  String get badgeTwoMonths => 'Two months in a row';

  @override
  String get badgeThreeMonths => 'Three months in a row';

  @override
  String get badgeSixMonths => 'Six months of diary';

  @override
  String get badgeMonthComplete => 'Full month';

  @override
  String get badgeComeback => 'Fresh start';

  @override
  String get badgeNoPause => 'Half a year, no breaks';

  @override
  String get badgeBeatRecord => 'Beat your record';

  @override
  String get badgeYear => 'A year of tracking';

  @override
  String monthsProgress(int value, int target) {
    return '$value of $target months';
  }

  @override
  String get badgeHonest => 'Honest diary';

  @override
  String get badgeLynx => 'Eagle eye';

  @override
  String get badgeFirstPdf => 'First PDF shared';

  @override
  String get badgeNotes => 'Helpful notes';

  @override
  String get badgeDouble => 'Double reading';

  @override
  String get badgeMonthBelow => 'Month below threshold';

  @override
  String get badgeTrendDown => 'Downward trend';

  @override
  String get badgeQuarterBelow => 'Quarter below threshold';

  @override
  String monthCompleteDetail(String month, int count) {
    return '$month, $count of $count';
  }

  @override
  String get monthCompleteHint => 'every reading in a month';

  @override
  String comebackDetail(String when) {
    return '$when, after the break';
  }

  @override
  String get comebackHint => 'start again after a break';

  @override
  String get beatRecordHint => 'after your first streak';

  @override
  String get honestDetail => 'you log the bad days too';

  @override
  String get firstPdfHint => 'export your diary';

  @override
  String monthAverage(String month, String value) {
    return '$month $value';
  }

  @override
  String monthBelowHint(int sys, int dia) {
    return 'monthly average below $sys/$dia';
  }

  @override
  String trendDetail(String delta) {
    return '$delta between quarters';
  }

  @override
  String get trendHint => 'needs two quarters';

  @override
  String sinceDate(String date) {
    return 'since $date';
  }

  @override
  String unlocksOn(String date) {
    return 'unlocks on $date';
  }

  @override
  String chartDescription(
    String from,
    String to,
    int sys1,
    int sys2,
    int dia1,
    int dia2,
  ) {
    return 'Readings from $from to $to: systolic from $sys1 to $sys2, diastolic from $dia1 to $dia2 mmHg';
  }

  @override
  String bpSemantics(int sys, int dia) {
    return '$sys over $dia millimeters of mercury';
  }

  @override
  String get reminderChannel => 'Reminders';

  @override
  String get reminderChannelDescription =>
      'Reminders to measure your blood pressure';

  @override
  String get reminderTitleDaily => 'Time for a 2-minute blood pressure check';

  @override
  String reminderTitleDay(String weekday) {
    return 'It\'s $weekday: 2 minutes for your blood pressure';
  }

  @override
  String get reminderBodyFirst => 'Sit down, relax and log your first reading.';

  @override
  String reminderBody(String value) {
    return 'Last time $value. Measure, log the values and you\'re done.';
  }

  @override
  String nudgeTitle(String weekday) {
    return 'Yesterday was $weekday';
  }

  @override
  String get nudgeBody => 'No problem: measure today and your streak goes on.';

  @override
  String summaryTitle(String month) {
    return 'Your $month';
  }

  @override
  String summaryEmpty(String month) {
    return '$month: no readings. The new month is a good start.';
  }

  @override
  String summaryBody(String month, int count, String avg) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count readings',
      one: '1 reading',
    );
    return '$month: $_temp0, average $avg.';
  }

  @override
  String get reportTitle => 'Blood pressure diary';

  @override
  String reportSubtitle(String schedule, String from, String to) {
    return 'Home readings, $schedule · $from – $to';
  }

  @override
  String generatedOn(String date) {
    return 'Generated on $date';
  }

  @override
  String get averagePulse => 'Average pulse';

  @override
  String get reportChart => 'Trend';

  @override
  String get reportNotes => 'Notes';

  @override
  String get reportAllReadings => 'All readings ';

  @override
  String reportBoldNote(int sys, int dia) {
    return '· in bold, those above threshold ($sys/$dia)';
  }

  @override
  String get colDate => 'Date';

  @override
  String get colTime => 'Time';

  @override
  String get noReading => 'no reading';

  @override
  String reportFooter(int sys, int dia, String source) {
    return '* with note. Bands and threshold $sys/$dia mmHg: $source. Values entered by the user, by hand or from a photo of the display. PressSure is a personal diary, not a medical device.';
  }

  @override
  String get footerSourceEsc =>
      'European ESC 2024 guidelines for home measurement';

  @override
  String get footerSourceCustom => 'custom thresholds';

  @override
  String pageOf(int page, int total) {
    return 'Page $page of $total';
  }

  @override
  String get csvSource => 'Source';

  @override
  String get csvDouble => 'Double reading';

  @override
  String get csvPhoto => 'photo';

  @override
  String get csvManual => 'manual';

  @override
  String get yes => 'yes';

  @override
  String get no => 'no';

  @override
  String get settingsTitle => 'Settings';

  @override
  String reminderSummary(String schedule, String time) {
    return '$schedule · $time';
  }

  @override
  String get thresholdsSection => 'Band thresholds';

  @override
  String get thresholdsIntro =>
      'Default: European ESC 2024 guidelines, home measurement. They apply to charts, diary, achievements and exports.';

  @override
  String get elevatedFrom => 'Elevated from';

  @override
  String get aboveThresholdFrom => 'Above threshold from';

  @override
  String thresholdFieldLabel(String band, String value) {
    return '$band, $value';
  }

  @override
  String get dataTitle => 'Your data';

  @override
  String get dataIntro =>
      'They stay on this phone only. To switch phones or keep them safe, save a backup file wherever you like.';

  @override
  String get saveBackup => 'Save backup';

  @override
  String get restoreBackup => 'Restore';

  @override
  String get backupReminder => 'Remind me to back up every month';

  @override
  String lastBackup(String date) {
    return 'Last backup: $date';
  }

  @override
  String get noBackupYet => 'No backup yet';

  @override
  String get backupSaved => 'Backup saved';

  @override
  String get backupFileBase => 'PressSure_backup';

  @override
  String get restoreTitle => 'Restore the backup?';

  @override
  String restoreBody(String date, String readings) {
    return 'The diary on this phone is replaced by the backup from $date ($readings). This can\'t be undone.';
  }

  @override
  String restoreDone(String readings) {
    return 'Diary restored: $readings';
  }

  @override
  String get backupInvalid => 'The chosen file isn\'t a PressSure backup.';

  @override
  String get backupTooNew =>
      'This backup comes from a newer version of PressSure: update the app and try again.';

  @override
  String get aboutThresholds => 'Disclaimer and threshold sources';

  @override
  String get aboutDisclaimer => 'Disclaimer';

  @override
  String get aboutSources => 'Threshold sources';

  @override
  String aboutBands(int elevSys, int elevDia, int highSys, int highDia) {
    return 'Default bands for home measurement: non-elevated below $elevSys/$elevDia, elevated from $elevSys/$elevDia, above threshold from $highSys/$highDia mmHg.';
  }

  @override
  String get aboutSource =>
      'Source: 2024 ESC Guidelines for the management of elevated blood pressure and hypertension, European Heart Journal, 2024.';

  @override
  String get version => 'Version';

  @override
  String get deleteAllData => 'Delete all data';

  @override
  String get deleteAllTitle => 'Delete all data?';

  @override
  String get deleteAllBody =>
      'Readings, habit and settings are erased from this phone. Without a backup they can\'t be recovered.';

  @override
  String get deleteAllConfirm => 'Delete everything';

  @override
  String get backupReminderTitle => 'Time for a backup';

  @override
  String get backupReminderBody =>
      'Save a copy of your diary wherever you like: Settings › Your data.';
}
