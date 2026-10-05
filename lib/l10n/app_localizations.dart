import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'PressSure'**
  String get appTitle;

  /// No description provided for @navToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navToday;

  /// No description provided for @navDiary.
  ///
  /// In en, this message translates to:
  /// **'Diary'**
  String get navDiary;

  /// No description provided for @navTrends.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get navTrends;

  /// No description provided for @navShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get navShare;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'{feature}: coming soon.'**
  String comingSoon(String feature);

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t complete: {error}'**
  String errorGeneric(String error);

  /// Weekday as a noun in a sentence. day: mon..sun.
  ///
  /// In en, this message translates to:
  /// **'{day, select, mon{Monday} tue{Tuesday} wed{Wednesday} thu{Thursday} fri{Friday} sat{Saturday} sun{Sunday} other{day}}'**
  String weekdayName(String day);

  /// Weekday in a list of chosen days: 'Mondays and Thursdays'.
  ///
  /// In en, this message translates to:
  /// **'{day, select, mon{Mondays} tue{Tuesdays} wed{Wednesdays} thu{Thursdays} fri{Fridays} sat{Saturdays} sun{Sundays} other{days}}'**
  String weekdayInList(String day);

  /// No description provided for @onWeekday.
  ///
  /// In en, this message translates to:
  /// **'{day, select, mon{on Mondays} tue{on Tuesdays} wed{on Wednesdays} thu{on Thursdays} fri{on Fridays} sat{on Saturdays} sun{on Sundays} other{}}'**
  String onWeekday(String day);

  /// No description provided for @nounReadings.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{reading} other{readings}}'**
  String nounReadings(int count);

  /// No description provided for @readingsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 reading} other{{count} readings}}'**
  String readingsCount(int count);

  /// No description provided for @inARow.
  ///
  /// In en, this message translates to:
  /// **'{count} in a row'**
  String inARow(int count);

  /// No description provided for @readingsInARow.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 reading in a row} other{{count} readings in a row}}'**
  String readingsInARow(int count);

  /// No description provided for @progressOf.
  ///
  /// In en, this message translates to:
  /// **'{value} of {target}'**
  String progressOf(int value, int target);

  /// No description provided for @scheduleDaily.
  ///
  /// In en, this message translates to:
  /// **'every day'**
  String get scheduleDaily;

  /// No description provided for @scheduleWeekly.
  ///
  /// In en, this message translates to:
  /// **'every {weekday}'**
  String scheduleWeekly(String weekday);

  /// No description provided for @scheduleBiweekly.
  ///
  /// In en, this message translates to:
  /// **'{day, select, mon{every other Monday} tue{every other Tuesday} wed{every other Wednesday} thu{every other Thursday} fri{every other Friday} sat{every other Saturday} sun{every other Sunday} other{every other week}}'**
  String scheduleBiweekly(String day);

  /// No description provided for @scheduleMonthly.
  ///
  /// In en, this message translates to:
  /// **'{day, select, mon{the first Monday of the month} tue{the first Tuesday of the month} wed{the first Wednesday of the month} thu{the first Thursday of the month} fri{the first Friday of the month} sat{the first Saturday of the month} sun{the first Sunday of the month} other{once a month}}'**
  String scheduleMonthly(String day);

  /// No description provided for @scheduleList.
  ///
  /// In en, this message translates to:
  /// **'{days} and {last}'**
  String scheduleList(String days, String last);

  /// No description provided for @listSeparator.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get listSeparator;

  /// No description provided for @partOfDay.
  ///
  /// In en, this message translates to:
  /// **'{part, select, morning{morning} afternoon{afternoon} other{evening}}'**
  String partOfDay(String part);

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'{part, select, morning{Good morning} afternoon{Good afternoon} other{Good evening}}'**
  String greeting(String part);

  /// No description provided for @relativeToday.
  ///
  /// In en, this message translates to:
  /// **'Today, {time}'**
  String relativeToday(String time);

  /// No description provided for @relativeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday, {time}'**
  String relativeYesterday(String time);

  /// No description provided for @relativeDate.
  ///
  /// In en, this message translates to:
  /// **'{date}, {time}'**
  String relativeDate(String date, String time);

  /// No description provided for @todayLower.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get todayLower;

  /// No description provided for @todayCapital.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayCapital;

  /// No description provided for @latest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get latest;

  /// No description provided for @categoryNonElevated.
  ///
  /// In en, this message translates to:
  /// **'Optimal'**
  String get categoryNonElevated;

  /// No description provided for @categoryElevated.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get categoryElevated;

  /// No description provided for @categoryHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get categoryHigh;

  /// No description provided for @bandNonElevated.
  ///
  /// In en, this message translates to:
  /// **'Optimal (below {sys}/{dia})'**
  String bandNonElevated(int sys, int dia);

  /// No description provided for @bandElevated.
  ///
  /// In en, this message translates to:
  /// **'Intermediate ({sysFrom}–{sysTo} / {diaFrom}–{diaTo})'**
  String bandElevated(int sysFrom, int sysTo, int diaFrom, int diaTo);

  /// No description provided for @bandHigh.
  ///
  /// In en, this message translates to:
  /// **'Above threshold ({sys}/{dia})'**
  String bandHigh(int sys, int dia);

  /// No description provided for @aboveThreshold.
  ///
  /// In en, this message translates to:
  /// **'Above threshold'**
  String get aboveThreshold;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your blood pressure diary, worry-free'**
  String get welcomeTitle;

  /// No description provided for @welcomeFeaturePhoto.
  ///
  /// In en, this message translates to:
  /// **'Snap the display, the app writes down the values'**
  String get welcomeFeaturePhoto;

  /// No description provided for @welcomeFeaturePhotoCopy.
  ///
  /// In en, this message translates to:
  /// **'Snap the display and copy the values: soon the app will write them by itself'**
  String get welcomeFeaturePhotoCopy;

  /// No description provided for @welcomeFeatureReminder.
  ///
  /// In en, this message translates to:
  /// **'A reminder on the day you choose'**
  String get welcomeFeatureReminder;

  /// No description provided for @welcomeFeatureExport.
  ///
  /// In en, this message translates to:
  /// **'Export to PDF or CSV whenever you need'**
  String get welcomeFeatureExport;

  /// No description provided for @welcomeFeatureLocal.
  ///
  /// In en, this message translates to:
  /// **'Your data stays on your phone: no account, no server'**
  String get welcomeFeatureLocal;

  /// No description provided for @welcomeNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Good to know, just once'**
  String get welcomeNoticeTitle;

  /// No description provided for @welcomeNoticeBody.
  ///
  /// In en, this message translates to:
  /// **'PressSure is a personal diary: it is not a medical device and does not diagnose. The default bands follow the European ESC 2024 guidelines and you can change them. If you have doubts about your health, talk to your doctor.'**
  String get welcomeNoticeBody;

  /// No description provided for @welcomeStart.
  ///
  /// In en, this message translates to:
  /// **'Got it, let\'s start'**
  String get welcomeStart;

  /// No description provided for @habitTitle.
  ///
  /// In en, this message translates to:
  /// **'Your habit'**
  String get habitTitle;

  /// No description provided for @habitIntro.
  ///
  /// In en, this message translates to:
  /// **'Pick a rhythm you can keep. Reminders, charts and reports adapt.'**
  String get habitIntro;

  /// No description provided for @habitHowOften.
  ///
  /// In en, this message translates to:
  /// **'How often do you measure?'**
  String get habitHowOften;

  /// No description provided for @frequencyDaily.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get frequencyDaily;

  /// No description provided for @frequencyFewTimesWeek.
  ///
  /// In en, this message translates to:
  /// **'On several days a week'**
  String get frequencyFewTimesWeek;

  /// No description provided for @frequencyWeekly.
  ///
  /// In en, this message translates to:
  /// **'Once a week'**
  String get frequencyWeekly;

  /// No description provided for @frequencyBiweekly.
  ///
  /// In en, this message translates to:
  /// **'Every two weeks'**
  String get frequencyBiweekly;

  /// No description provided for @frequencyMonthly.
  ///
  /// In en, this message translates to:
  /// **'Once a month'**
  String get frequencyMonthly;

  /// No description provided for @habitWhen.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get habitWhen;

  /// No description provided for @habitPickTwoDays.
  ///
  /// In en, this message translates to:
  /// **'Pick at least two days'**
  String get habitPickTwoDays;

  /// No description provided for @habitReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get habitReminderTime;

  /// No description provided for @habitKeepOnTrack.
  ///
  /// In en, this message translates to:
  /// **'Stay on track'**
  String get habitKeepOnTrack;

  /// No description provided for @habitRemindNextDay.
  ///
  /// In en, this message translates to:
  /// **'If I skip, remind me the next day'**
  String get habitRemindNextDay;

  /// No description provided for @habitRemindNextDayHint.
  ///
  /// In en, this message translates to:
  /// **'Just once, then wait for the next planned reading'**
  String get habitRemindNextDayHint;

  /// No description provided for @habitMonthlySummary.
  ///
  /// In en, this message translates to:
  /// **'End-of-month summary'**
  String get habitMonthlySummary;

  /// No description provided for @habitMonthlySummaryHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. “September: 4 readings, average 125/80”'**
  String get habitMonthlySummaryHint;

  /// No description provided for @habitPreviewHeading.
  ///
  /// In en, this message translates to:
  /// **'This is how it arrives {when} at {time}'**
  String habitPreviewHeading(String when, String time);

  /// No description provided for @habitSaveAndStart.
  ///
  /// In en, this message translates to:
  /// **'Save and start'**
  String get habitSaveAndStart;

  /// No description provided for @habitCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your habit · {schedule} {part}'**
  String habitCardSubtitle(String schedule, String part);

  /// No description provided for @todayFirstReading.
  ///
  /// In en, this message translates to:
  /// **'Your first reading is waiting'**
  String get todayFirstReading;

  /// No description provided for @todayDoneDaily.
  ///
  /// In en, this message translates to:
  /// **'Done for today, see you tomorrow'**
  String get todayDoneDaily;

  /// No description provided for @todayDoneNext.
  ///
  /// In en, this message translates to:
  /// **'Done! Next reading {date}'**
  String todayDoneNext(String date);

  /// No description provided for @todayIsTheDay.
  ///
  /// In en, this message translates to:
  /// **'Today is measuring day'**
  String get todayIsTheDay;

  /// No description provided for @todayMissing.
  ///
  /// In en, this message translates to:
  /// **'Reading for {date} still to do'**
  String todayMissing(String date);

  /// No description provided for @todayStartStreak.
  ///
  /// In en, this message translates to:
  /// **'Every reading counts: start a streak.'**
  String get todayStartStreak;

  /// No description provided for @todayCompleteMonth.
  ///
  /// In en, this message translates to:
  /// **'Today you complete {month}.'**
  String todayCompleteMonth(String month);

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Snap'**
  String get takePhoto;

  /// No description provided for @byHand.
  ///
  /// In en, this message translates to:
  /// **'By hand'**
  String get byHand;

  /// No description provided for @habitAndReminders.
  ///
  /// In en, this message translates to:
  /// **'Habit and reminders'**
  String get habitAndReminders;

  /// No description provided for @periodDotsLabel.
  ///
  /// In en, this message translates to:
  /// **'Last {total} planned readings: {done} done, {missed} missed'**
  String periodDotsLabel(int total, int done, int missed);

  /// No description provided for @lastReadingOn.
  ///
  /// In en, this message translates to:
  /// **'Last reading · {date}'**
  String lastReadingOn(String date);

  /// No description provided for @pulseValue.
  ///
  /// In en, this message translates to:
  /// **'Pulse {pulse}'**
  String pulseValue(int pulse);

  /// No description provided for @pulseLower.
  ///
  /// In en, this message translates to:
  /// **'pulse {pulse}'**
  String pulseLower(int pulse);

  /// No description provided for @previousValue.
  ///
  /// In en, this message translates to:
  /// **'the time before {value}'**
  String previousValue(String value);

  /// No description provided for @previousReading.
  ///
  /// In en, this message translates to:
  /// **'previous reading {value}'**
  String previousReading(String value);

  /// No description provided for @bandByEsc.
  ///
  /// In en, this message translates to:
  /// **'band per the European ESC 2024 guidelines'**
  String get bandByEsc;

  /// No description provided for @bandByCustom.
  ///
  /// In en, this message translates to:
  /// **'band per your thresholds'**
  String get bandByCustom;

  /// No description provided for @last6Months.
  ///
  /// In en, this message translates to:
  /// **'Last 6 months'**
  String get last6Months;

  /// No description provided for @legendSingle.
  ///
  /// In en, this message translates to:
  /// **'Single reading'**
  String get legendSingle;

  /// No description provided for @legendAvg4.
  ///
  /// In en, this message translates to:
  /// **'Average of last 4'**
  String get legendAvg4;

  /// No description provided for @legendThreshold.
  ///
  /// In en, this message translates to:
  /// **'Threshold'**
  String get legendThreshold;

  /// No description provided for @legendSkipped.
  ///
  /// In en, this message translates to:
  /// **'Missed readings'**
  String get legendSkipped;

  /// No description provided for @trendEmpty.
  ///
  /// In en, this message translates to:
  /// **'After a few readings you\'ll see here how your blood pressure changes.'**
  String get trendEmpty;

  /// No description provided for @quarterSide.
  ///
  /// In en, this message translates to:
  /// **'{range} · {readings}'**
  String quarterSide(String range, String readings);

  /// No description provided for @emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No readings yet'**
  String get emptyTitle;

  /// No description provided for @emptyBody.
  ///
  /// In en, this message translates to:
  /// **'Sit with your back supported, rest for five minutes and measure on your arm with the cuff at heart level. Then log the values here: band, charts and reports build themselves.'**
  String get emptyBody;

  /// No description provided for @scanReadTitle.
  ///
  /// In en, this message translates to:
  /// **'Read from the photo'**
  String get scanReadTitle;

  /// No description provided for @photoCopyTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy the values from the display'**
  String get photoCopyTitle;

  /// No description provided for @scanPhotoNotSaved.
  ///
  /// In en, this message translates to:
  /// **'{when} · the photo isn\'t saved'**
  String scanPhotoNotSaved(String when);

  /// No description provided for @scanRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get scanRetake;

  /// No description provided for @scanSure.
  ///
  /// In en, this message translates to:
  /// **'Read with confidence'**
  String get scanSure;

  /// No description provided for @scanUnsure.
  ///
  /// In en, this message translates to:
  /// **'Blurry digit in the photo: compare with the display and fix it if needed.'**
  String get scanUnsure;

  /// No description provided for @scanMissing.
  ///
  /// In en, this message translates to:
  /// **'Not found in the photo: copy it from the display.'**
  String get scanMissing;

  /// No description provided for @scanNothingRead.
  ///
  /// In en, this message translates to:
  /// **'I can\'t read the values: try again avoiding reflections, or enter them by hand.'**
  String get scanNothingRead;

  /// No description provided for @scanTitle.
  ///
  /// In en, this message translates to:
  /// **'Photograph the display'**
  String get scanTitle;

  /// No description provided for @scanFlash.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get scanFlash;

  /// No description provided for @scanFrameHint.
  ///
  /// In en, this message translates to:
  /// **'Fit the display inside the frame'**
  String get scanFrameHint;

  /// No description provided for @scanGlareHint.
  ///
  /// In en, this message translates to:
  /// **'Avoid reflections: tilt the phone slightly'**
  String get scanGlareHint;

  /// No description provided for @scanFromGallery.
  ///
  /// In en, this message translates to:
  /// **'From gallery'**
  String get scanFromGallery;

  /// No description provided for @scanShutter.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get scanShutter;

  /// No description provided for @scanReading.
  ///
  /// In en, this message translates to:
  /// **'Reading the values…'**
  String get scanReading;

  /// No description provided for @scanCameraError.
  ///
  /// In en, this message translates to:
  /// **'I can\'t open the camera. Try again, or use a photo from the gallery.'**
  String get scanCameraError;

  /// No description provided for @scanCameraNeeded.
  ///
  /// In en, this message translates to:
  /// **'To photograph the display PressSure needs the camera. The photo isn\'t saved.'**
  String get scanCameraNeeded;

  /// No description provided for @scanCameraBlocked.
  ///
  /// In en, this message translates to:
  /// **'Camera permission was denied. Turn it on in the app settings, then come back here.'**
  String get scanCameraBlocked;

  /// No description provided for @scanAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get scanAllow;

  /// No description provided for @scanOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get scanOpenSettings;

  /// No description provided for @betaTitle.
  ///
  /// In en, this message translates to:
  /// **'Beta program'**
  String get betaTitle;

  /// No description provided for @keepScansTitle.
  ///
  /// In en, this message translates to:
  /// **'Help me improve the reading'**
  String get keepScansTitle;

  /// No description provided for @keepScansBody.
  ///
  /// In en, this message translates to:
  /// **'Keeps on this phone the last {count} photos of the display, with the values the app read and the ones you save. Nothing leaves by itself: you can email them to {email}. Turning it off deletes them.'**
  String keepScansBody(int count, String email);

  /// No description provided for @keptScansCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No readings kept} =1{1 reading kept} other{{count} readings kept}}'**
  String keptScansCount(int count);

  /// No description provided for @sendScans.
  ///
  /// In en, this message translates to:
  /// **'Send for analysis'**
  String get sendScans;

  /// No description provided for @clearScans.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get clearScans;

  /// No description provided for @scansCleared.
  ///
  /// In en, this message translates to:
  /// **'Kept readings deleted'**
  String get scansCleared;

  /// No description provided for @keepScansYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, keep the readings'**
  String get keepScansYes;

  /// No description provided for @keepScansNo.
  ///
  /// In en, this message translates to:
  /// **'No, thanks'**
  String get keepScansNo;

  /// No description provided for @noMailApp.
  ///
  /// In en, this message translates to:
  /// **'No email app available to send them.'**
  String get noMailApp;

  /// No description provided for @feedbackSubject.
  ///
  /// In en, this message translates to:
  /// **'PressSure {version}: display readings'**
  String feedbackSubject(String version);

  /// No description provided for @feedbackBody.
  ///
  /// In en, this message translates to:
  /// **'Attached, {count, plural, =1{1 reading} other{{count} readings}} of the display taken with PressSure: photos, values read by the app and values saved.\n\nNotes (optional):\n'**
  String feedbackBody(int count);

  /// No description provided for @scanPhotoKept.
  ///
  /// In en, this message translates to:
  /// **'{when} · the photo stays on the phone for analysis'**
  String scanPhotoKept(String when);

  /// No description provided for @scanRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get scanRetry;

  /// No description provided for @entryNewTitle.
  ///
  /// In en, this message translates to:
  /// **'Check and save'**
  String get entryNewTitle;

  /// No description provided for @entryEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit reading'**
  String get entryEditTitle;

  /// No description provided for @deleteReading.
  ///
  /// In en, this message translates to:
  /// **'Delete reading'**
  String get deleteReading;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this reading?'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The reading disappears from the diary, the charts and the reports. This can\'t be undone.'**
  String get deleteConfirmBody;

  /// No description provided for @errSysRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the systolic'**
  String get errSysRequired;

  /// No description provided for @errDiaRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the diastolic'**
  String get errDiaRequired;

  /// No description provided for @errRange.
  ///
  /// In en, this message translates to:
  /// **'Between {min} and {max}'**
  String errRange(int min, int max);

  /// No description provided for @errSysAboveDia.
  ///
  /// In en, this message translates to:
  /// **'Must be higher than the diastolic'**
  String get errSysAboveDia;

  /// No description provided for @systolic.
  ///
  /// In en, this message translates to:
  /// **'Systolic'**
  String get systolic;

  /// No description provided for @diastolic.
  ///
  /// In en, this message translates to:
  /// **'Diastolic'**
  String get diastolic;

  /// No description provided for @pulse.
  ///
  /// In en, this message translates to:
  /// **'Pulse'**
  String get pulse;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get optional;

  /// No description provided for @pickDayHelp.
  ///
  /// In en, this message translates to:
  /// **'Day of the reading'**
  String get pickDayHelp;

  /// No description provided for @pickTimeHelp.
  ///
  /// In en, this message translates to:
  /// **'Time of the reading'**
  String get pickTimeHelp;

  /// No description provided for @whenReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get whenReading;

  /// No description provided for @whenManual.
  ///
  /// In en, this message translates to:
  /// **'Entered by hand'**
  String get whenManual;

  /// No description provided for @scanTooltip.
  ///
  /// In en, this message translates to:
  /// **'Photograph the display'**
  String get scanTooltip;

  /// No description provided for @categoryHint.
  ///
  /// In en, this message translates to:
  /// **'“{category}” band {source}'**
  String categoryHint(String category, String source);

  /// No description provided for @hintSourceEsc.
  ///
  /// In en, this message translates to:
  /// **'per ESC 2024'**
  String get hintSourceEsc;

  /// No description provided for @hintSourceCustom.
  ///
  /// In en, this message translates to:
  /// **'per your thresholds'**
  String get hintSourceCustom;

  /// No description provided for @contextTitle.
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get contextTitle;

  /// No description provided for @arm.
  ///
  /// In en, this message translates to:
  /// **'Arm'**
  String get arm;

  /// No description provided for @armLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get armLeft;

  /// No description provided for @armRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get armRight;

  /// No description provided for @posture.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get posture;

  /// No description provided for @postureSitting.
  ///
  /// In en, this message translates to:
  /// **'Sitting'**
  String get postureSitting;

  /// No description provided for @postureStanding.
  ///
  /// In en, this message translates to:
  /// **'Standing'**
  String get postureStanding;

  /// No description provided for @postureLying.
  ///
  /// In en, this message translates to:
  /// **'Lying down'**
  String get postureLying;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. coffee half an hour before, slept badly'**
  String get noteHint;

  /// No description provided for @secondReading.
  ///
  /// In en, this message translates to:
  /// **'Second reading'**
  String get secondReading;

  /// No description provided for @secondAverageInfo.
  ///
  /// In en, this message translates to:
  /// **'The diary will save the average of the two readings.'**
  String get secondAverageInfo;

  /// No description provided for @secondAverageValue.
  ///
  /// In en, this message translates to:
  /// **'The average will be saved: {value}'**
  String secondAverageValue(String value);

  /// No description provided for @secondWaitTitle.
  ///
  /// In en, this message translates to:
  /// **'Relax, just a moment'**
  String get secondWaitTitle;

  /// No description provided for @secondWaitBody.
  ///
  /// In en, this message translates to:
  /// **'When time is up, measure again on the same arm.'**
  String get secondWaitBody;

  /// No description provided for @secondOptionalTitle.
  ///
  /// In en, this message translates to:
  /// **'Second reading? Optional'**
  String get secondOptionalTitle;

  /// No description provided for @secondOptionalBody.
  ///
  /// In en, this message translates to:
  /// **'If you take it a minute later, the app saves the average.'**
  String get secondOptionalBody;

  /// No description provided for @timerSkip.
  ///
  /// In en, this message translates to:
  /// **'{time} · Skip'**
  String timerSkip(String time);

  /// No description provided for @timerStart.
  ///
  /// In en, this message translates to:
  /// **'Timer 1:00'**
  String get timerStart;

  /// No description provided for @saveReading.
  ///
  /// In en, this message translates to:
  /// **'Save reading'**
  String get saveReading;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @fieldSemantics.
  ///
  /// In en, this message translates to:
  /// **'{label} in {unit}'**
  String fieldSemantics(String label, String unit);

  /// No description provided for @newBadge.
  ///
  /// In en, this message translates to:
  /// **'NEW BADGE'**
  String get newBadge;

  /// No description provided for @readingSaved.
  ///
  /// In en, this message translates to:
  /// **'READING SAVED'**
  String get readingSaved;

  /// No description provided for @celebrateTitleBadge.
  ///
  /// In en, this message translates to:
  /// **'{title}!'**
  String celebrateTitleBadge(String title);

  /// No description provided for @celebrateTitleStreak.
  ///
  /// In en, this message translates to:
  /// **'Done, {streak}'**
  String celebrateTitleStreak(String streak);

  /// No description provided for @celebrateInDiary.
  ///
  /// In en, this message translates to:
  /// **'{value} is in the diary.'**
  String celebrateInDiary(String value);

  /// No description provided for @celebrateSince.
  ///
  /// In en, this message translates to:
  /// **'Since {date}: {readings} out of {total} planned.'**
  String celebrateSince(String date, String readings, int total);

  /// No description provided for @andMoreBadges.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{ And 1 more badge.} other{ And {count} more badges.}}'**
  String andMoreBadges(int count);

  /// No description provided for @jollyLine.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No jokers left: don\'t skip the next one.} =1{You have a joker if you skip a reading.} other{You have {count} jokers if you skip a reading.}}'**
  String jollyLine(int count);

  /// No description provided for @lowestSince.
  ///
  /// In en, this message translates to:
  /// **'{value}, the lowest since {month}'**
  String lowestSince(String value, String month);

  /// No description provided for @readingStored.
  ///
  /// In en, this message translates to:
  /// **'{value} saved'**
  String readingStored(String value);

  /// No description provided for @avgOfLast.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Last reading: {value}.} other{Average of the last {count} readings: {value}.}}'**
  String avgOfLast(int count, String value);

  /// No description provided for @almostBadge.
  ///
  /// In en, this message translates to:
  /// **'Almost “{title}”'**
  String almostBadge(String title);

  /// No description provided for @streakRecordSemantics.
  ///
  /// In en, this message translates to:
  /// **'Record streak: {current}'**
  String streakRecordSemantics(int current);

  /// No description provided for @streakToBeat.
  ///
  /// In en, this message translates to:
  /// **'{current} of {target} to beat the record of {record}'**
  String streakToBeat(int current, int target, int record);

  /// No description provided for @streakNow.
  ///
  /// In en, this message translates to:
  /// **'{count} now'**
  String streakNow(int count);

  /// No description provided for @newRecord.
  ///
  /// In en, this message translates to:
  /// **'new record!'**
  String get newRecord;

  /// No description provided for @recordValue.
  ///
  /// In en, this message translates to:
  /// **'record {count}'**
  String recordValue(int count);

  /// No description provided for @savedAt.
  ///
  /// In en, this message translates to:
  /// **'Reading saved · {when}'**
  String savedAt(String when);

  /// No description provided for @higherThanUsual.
  ///
  /// In en, this message translates to:
  /// **'Higher than usual today'**
  String get higherThanUsual;

  /// No description provided for @aboveThresholdToday.
  ///
  /// In en, this message translates to:
  /// **'Above the threshold today'**
  String get aboveThresholdToday;

  /// No description provided for @usuallyAround.
  ///
  /// In en, this message translates to:
  /// **'You\'re usually around {value}. '**
  String usuallyAround(String value);

  /// No description provided for @remeasureHint.
  ///
  /// In en, this message translates to:
  /// **'If you like, measure again after a few minutes of rest: the diary keeps both.'**
  String get remeasureHint;

  /// No description provided for @veryHighWarning.
  ///
  /// In en, this message translates to:
  /// **'Values this high should be checked again. If they are confirmed or you don\'t feel well, contact your doctor or the emergency number.'**
  String get veryHighWarning;

  /// No description provided for @remeasure.
  ///
  /// In en, this message translates to:
  /// **'Measure again'**
  String get remeasure;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get addNote;

  /// No description provided for @badgeNamed.
  ///
  /// In en, this message translates to:
  /// **'Badge “{title}”'**
  String badgeNamed(String title);

  /// No description provided for @honestBody.
  ///
  /// In en, this message translates to:
  /// **'Bad days are part of the diary too.'**
  String get honestBody;

  /// No description provided for @streakSafe.
  ///
  /// In en, this message translates to:
  /// **'Streak safe · {streak}'**
  String streakSafe(String streak);

  /// No description provided for @diarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'{readings} since {month} · {schedule}'**
  String diarySubtitle(String readings, String month, String schedule);

  /// No description provided for @searchDiary.
  ///
  /// In en, this message translates to:
  /// **'Search the diary'**
  String get searchDiary;

  /// No description provided for @closeSearch.
  ///
  /// In en, this message translates to:
  /// **'Close search'**
  String get closeSearch;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search notes'**
  String get searchHint;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterNotes.
  ///
  /// In en, this message translates to:
  /// **'With notes'**
  String get filterNotes;

  /// No description provided for @noMatch.
  ///
  /// In en, this message translates to:
  /// **'No readings match.'**
  String get noMatch;

  /// No description provided for @monthSummary.
  ///
  /// In en, this message translates to:
  /// **'{readings} · average {avg}'**
  String monthSummary(String readings, String avg);

  /// No description provided for @averageOfTwo.
  ///
  /// In en, this message translates to:
  /// **'average of 2'**
  String get averageOfTwo;

  /// No description provided for @readFromPhoto.
  ///
  /// In en, this message translates to:
  /// **'Read from photo'**
  String get readFromPhoto;

  /// No description provided for @gapLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 missed reading} other{{count} missed readings}}'**
  String gapLabel(int count);

  /// No description provided for @newReading.
  ///
  /// In en, this message translates to:
  /// **'New reading'**
  String get newReading;

  /// No description provided for @diaryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'The diary is empty'**
  String get diaryEmptyTitle;

  /// No description provided for @diaryEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Every reading you save ends up here, grouped by month.'**
  String get diaryEmptyBody;

  /// No description provided for @diaryAddFirst.
  ///
  /// In en, this message translates to:
  /// **'Add your first reading'**
  String get diaryAddFirst;

  /// No description provided for @range3m.
  ///
  /// In en, this message translates to:
  /// **'3 months'**
  String get range3m;

  /// No description provided for @range6m.
  ///
  /// In en, this message translates to:
  /// **'6 months'**
  String get range6m;

  /// No description provided for @range1y.
  ///
  /// In en, this message translates to:
  /// **'1 year'**
  String get range1y;

  /// No description provided for @rangeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get rangeAll;

  /// No description provided for @exportAndShare.
  ///
  /// In en, this message translates to:
  /// **'Export and share'**
  String get exportAndShare;

  /// No description provided for @trendsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No readings in this period. The chart fills up with the next ones.'**
  String get trendsEmpty;

  /// No description provided for @lastNReadings.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Last reading} other{Last {count} readings}}'**
  String lastNReadings(int count);

  /// No description provided for @readingsInRange.
  ///
  /// In en, this message translates to:
  /// **'{readings} in {range}'**
  String readingsInRange(String readings, String range);

  /// No description provided for @avgPulse.
  ///
  /// In en, this message translates to:
  /// **'Average pulse {pulse}'**
  String avgPulse(int pulse);

  /// No description provided for @yourReadings.
  ///
  /// In en, this message translates to:
  /// **'Your readings'**
  String get yourReadings;

  /// No description provided for @sysShort.
  ///
  /// In en, this message translates to:
  /// **'Sys.'**
  String get sysShort;

  /// No description provided for @diaShort.
  ///
  /// In en, this message translates to:
  /// **'Dia.'**
  String get diaShort;

  /// No description provided for @quarterCompare.
  ///
  /// In en, this message translates to:
  /// **'Quarter vs quarter'**
  String get quarterCompare;

  /// No description provided for @quarterNeedTwo.
  ///
  /// In en, this message translates to:
  /// **'Readings in two quarters are needed: {first} and {second}.'**
  String quarterNeedTwo(String first, String second);

  /// No description provided for @regularity.
  ///
  /// In en, this message translates to:
  /// **'Regularity'**
  String get regularity;

  /// No description provided for @regularityCount.
  ///
  /// In en, this message translates to:
  /// **'{done, plural, =1{1 reading of {total} planned} other{{done} readings of {total} planned}}'**
  String regularityCount(int done, int total);

  /// No description provided for @regularityLabel.
  ///
  /// In en, this message translates to:
  /// **'{done} measured out of {total}'**
  String regularityLabel(int done, int total);

  /// No description provided for @bandsTitle.
  ///
  /// In en, this message translates to:
  /// **'Readings by band'**
  String get bandsTitle;

  /// No description provided for @bandsRecent.
  ///
  /// In en, this message translates to:
  /// **'Since {month}, {below} of {total} readings are below {sys}/{dia}.'**
  String bandsRecent(String month, int below, int total, int sys, int dia);

  /// No description provided for @bandsDefaultEsc.
  ///
  /// In en, this message translates to:
  /// **'Default bands: European ESC 2024 guidelines, home measurement.'**
  String get bandsDefaultEsc;

  /// No description provided for @bandsCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom thresholds. The ESC 2024 guidelines for home measurement use 135/85.'**
  String get bandsCustom;

  /// No description provided for @changeThresholds.
  ///
  /// In en, this message translates to:
  /// **'Change thresholds'**
  String get changeThresholds;

  /// No description provided for @restoreEsc.
  ///
  /// In en, this message translates to:
  /// **'Reset to ESC 2024'**
  String get restoreEsc;

  /// No description provided for @thresholdsDoctorNote.
  ///
  /// In en, this message translates to:
  /// **'Change them only if your doctor tells you to.'**
  String get thresholdsDoctorNote;

  /// No description provided for @thresholdsErrRange.
  ///
  /// In en, this message translates to:
  /// **'Enter values between 40 and 250.'**
  String get thresholdsErrRange;

  /// No description provided for @thresholdsErrOrder.
  ///
  /// In en, this message translates to:
  /// **'The intermediate band must be below the threshold.'**
  String get thresholdsErrOrder;

  /// No description provided for @reportScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your diary as PDF or CSV, when you need it'**
  String get reportScreenSubtitle;

  /// No description provided for @previewTitle.
  ///
  /// In en, this message translates to:
  /// **'Report preview'**
  String get previewTitle;

  /// No description provided for @neverExported.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t exported the diary yet'**
  String get neverExported;

  /// No description provided for @lastExported.
  ///
  /// In en, this message translates to:
  /// **'Last export: {date}'**
  String lastExported(String date);

  /// No description provided for @newSince.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new reading since then} other{{count} new readings since then}}'**
  String newSince(int count);

  /// No description provided for @rangeSinceLast.
  ///
  /// In en, this message translates to:
  /// **'Only new ones'**
  String get rangeSinceLast;

  /// No description provided for @noReadingsInPeriod.
  ///
  /// In en, this message translates to:
  /// **'No readings in this period'**
  String get noReadingsInPeriod;

  /// No description provided for @rangeLabel.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to} · {readings}'**
  String rangeLabel(String from, String to, String readings);

  /// No description provided for @includeTitle.
  ///
  /// In en, this message translates to:
  /// **'What to include'**
  String get includeTitle;

  /// No description provided for @includeChart.
  ///
  /// In en, this message translates to:
  /// **'Trend chart'**
  String get includeChart;

  /// No description provided for @includeTable.
  ///
  /// In en, this message translates to:
  /// **'Table of all readings'**
  String get includeTable;

  /// No description provided for @includeNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get includeNotes;

  /// No description provided for @downloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadPdf;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export data as CSV (for Excel)'**
  String get exportCsv;

  /// No description provided for @pdfA4.
  ///
  /// In en, this message translates to:
  /// **'PDF A4'**
  String get pdfA4;

  /// No description provided for @previewReadings.
  ///
  /// In en, this message translates to:
  /// **'Readings'**
  String get previewReadings;

  /// No description provided for @previewAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get previewAverage;

  /// No description provided for @previewLast4.
  ///
  /// In en, this message translates to:
  /// **'Last 4'**
  String get previewLast4;

  /// No description provided for @openPreview.
  ///
  /// In en, this message translates to:
  /// **'Open preview'**
  String get openPreview;

  /// No description provided for @openPreviewSemantics.
  ///
  /// In en, this message translates to:
  /// **'Open the PDF preview'**
  String get openPreviewSemantics;

  /// No description provided for @csvSubject.
  ///
  /// In en, this message translates to:
  /// **'Blood pressure diary (CSV)'**
  String get csvSubject;

  /// No description provided for @fileNameBase.
  ///
  /// In en, this message translates to:
  /// **'PressSure_diary'**
  String get fileNameBase;

  /// No description provided for @notYetExported.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t exported the diary yet.'**
  String get notYetExported;

  /// No description provided for @inARowStat.
  ///
  /// In en, this message translates to:
  /// **'readings in a row'**
  String get inARowStat;

  /// No description provided for @recordInARow.
  ///
  /// In en, this message translates to:
  /// **'record streak'**
  String get recordInARow;

  /// No description provided for @totalReadings.
  ///
  /// In en, this message translates to:
  /// **'total readings'**
  String get totalReadings;

  /// No description provided for @jollyAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Jokers: none available} =1{Jokers: 1 available} other{Jokers: {count} available}}'**
  String jollyAvailable(int count);

  /// No description provided for @jollyNext.
  ///
  /// In en, this message translates to:
  /// **'next in {count}'**
  String jollyNext(int count);

  /// No description provided for @jollyNextSemantics.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Next joker in 1 reading} other{Next joker in {count} readings}}'**
  String jollyNextSemantics(int count);

  /// No description provided for @jollyFull.
  ///
  /// In en, this message translates to:
  /// **'maximum reached'**
  String get jollyFull;

  /// No description provided for @jollyBody.
  ///
  /// In en, this message translates to:
  /// **'Skip a reading? A joker keeps your streak alive. You earn one every {every} planned readings, up to {max}.'**
  String jollyBody(int every, int max);

  /// No description provided for @groupConsistency.
  ///
  /// In en, this message translates to:
  /// **'Consistency'**
  String get groupConsistency;

  /// No description provided for @groupHabits.
  ///
  /// In en, this message translates to:
  /// **'Good habits'**
  String get groupHabits;

  /// No description provided for @groupTrend.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get groupTrend;

  /// No description provided for @trendGroupNote.
  ///
  /// In en, this message translates to:
  /// **'threshold {sys}/{dia}, on monthly averages'**
  String trendGroupNote(int sys, int dia);

  /// No description provided for @personalRecords.
  ///
  /// In en, this message translates to:
  /// **'Personal records'**
  String get personalRecords;

  /// No description provided for @longestStreak.
  ///
  /// In en, this message translates to:
  /// **'Longest streak'**
  String get longestStreak;

  /// No description provided for @lowestMonth.
  ///
  /// In en, this message translates to:
  /// **'Month with the lowest average'**
  String get lowestMonth;

  /// No description provided for @onSchedule.
  ///
  /// In en, this message translates to:
  /// **'Readings on the planned days'**
  String get onSchedule;

  /// No description provided for @onScheduleValue.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} · {percent}'**
  String onScheduleValue(int done, int total, String percent);

  /// No description provided for @badgeSemantics.
  ///
  /// In en, this message translates to:
  /// **'{title}, {state}, {detail}'**
  String badgeSemantics(String title, String state, String detail);

  /// No description provided for @badgeUnlocked.
  ///
  /// In en, this message translates to:
  /// **'unlocked'**
  String get badgeUnlocked;

  /// No description provided for @badgeLocked.
  ///
  /// In en, this message translates to:
  /// **'to unlock'**
  String get badgeLocked;

  /// No description provided for @newTag.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get newTag;

  /// No description provided for @badgeFirstStep.
  ///
  /// In en, this message translates to:
  /// **'First step'**
  String get badgeFirstStep;

  /// No description provided for @badgeTwoMonths.
  ///
  /// In en, this message translates to:
  /// **'Two months in a row'**
  String get badgeTwoMonths;

  /// No description provided for @badgeThreeMonths.
  ///
  /// In en, this message translates to:
  /// **'Three months in a row'**
  String get badgeThreeMonths;

  /// No description provided for @badgeSixMonths.
  ///
  /// In en, this message translates to:
  /// **'Six months of diary'**
  String get badgeSixMonths;

  /// No description provided for @badgeMonthComplete.
  ///
  /// In en, this message translates to:
  /// **'Full month'**
  String get badgeMonthComplete;

  /// No description provided for @badgeComeback.
  ///
  /// In en, this message translates to:
  /// **'Fresh start'**
  String get badgeComeback;

  /// No description provided for @badgeNoPause.
  ///
  /// In en, this message translates to:
  /// **'Half a year, no breaks'**
  String get badgeNoPause;

  /// No description provided for @badgeBeatRecord.
  ///
  /// In en, this message translates to:
  /// **'Beat your record'**
  String get badgeBeatRecord;

  /// No description provided for @badgeYear.
  ///
  /// In en, this message translates to:
  /// **'A year of tracking'**
  String get badgeYear;

  /// No description provided for @monthsProgress.
  ///
  /// In en, this message translates to:
  /// **'{value} of {target} months'**
  String monthsProgress(int value, int target);

  /// No description provided for @badgeHonest.
  ///
  /// In en, this message translates to:
  /// **'Honest diary'**
  String get badgeHonest;

  /// No description provided for @badgeLynx.
  ///
  /// In en, this message translates to:
  /// **'Eagle eye'**
  String get badgeLynx;

  /// No description provided for @badgeFirstPdf.
  ///
  /// In en, this message translates to:
  /// **'First PDF shared'**
  String get badgeFirstPdf;

  /// No description provided for @badgeNotes.
  ///
  /// In en, this message translates to:
  /// **'Helpful notes'**
  String get badgeNotes;

  /// No description provided for @badgeDouble.
  ///
  /// In en, this message translates to:
  /// **'Double reading'**
  String get badgeDouble;

  /// No description provided for @badgeMonthBelow.
  ///
  /// In en, this message translates to:
  /// **'Month below threshold'**
  String get badgeMonthBelow;

  /// No description provided for @badgeTrendDown.
  ///
  /// In en, this message translates to:
  /// **'Downward trend'**
  String get badgeTrendDown;

  /// No description provided for @badgeQuarterBelow.
  ///
  /// In en, this message translates to:
  /// **'Quarter below threshold'**
  String get badgeQuarterBelow;

  /// No description provided for @monthCompleteDetail.
  ///
  /// In en, this message translates to:
  /// **'{month}, {count} of {count}'**
  String monthCompleteDetail(String month, int count);

  /// No description provided for @monthCompleteHint.
  ///
  /// In en, this message translates to:
  /// **'every reading in a month'**
  String get monthCompleteHint;

  /// No description provided for @comebackDetail.
  ///
  /// In en, this message translates to:
  /// **'{when}, after the break'**
  String comebackDetail(String when);

  /// No description provided for @comebackHint.
  ///
  /// In en, this message translates to:
  /// **'start again after a break'**
  String get comebackHint;

  /// No description provided for @beatRecordHint.
  ///
  /// In en, this message translates to:
  /// **'after your first streak'**
  String get beatRecordHint;

  /// No description provided for @honestDetail.
  ///
  /// In en, this message translates to:
  /// **'you log the bad days too'**
  String get honestDetail;

  /// No description provided for @firstPdfHint.
  ///
  /// In en, this message translates to:
  /// **'export your diary'**
  String get firstPdfHint;

  /// No description provided for @monthAverage.
  ///
  /// In en, this message translates to:
  /// **'{month} {value}'**
  String monthAverage(String month, String value);

  /// No description provided for @monthBelowHint.
  ///
  /// In en, this message translates to:
  /// **'monthly average below {sys}/{dia}'**
  String monthBelowHint(int sys, int dia);

  /// No description provided for @trendDetail.
  ///
  /// In en, this message translates to:
  /// **'{delta} between quarters'**
  String trendDetail(String delta);

  /// No description provided for @trendHint.
  ///
  /// In en, this message translates to:
  /// **'needs two quarters'**
  String get trendHint;

  /// No description provided for @sinceDate.
  ///
  /// In en, this message translates to:
  /// **'since {date}'**
  String sinceDate(String date);

  /// No description provided for @unlocksOn.
  ///
  /// In en, this message translates to:
  /// **'unlocks on {date}'**
  String unlocksOn(String date);

  /// No description provided for @chartDescription.
  ///
  /// In en, this message translates to:
  /// **'Readings from {from} to {to}: systolic from {sys1} to {sys2}, diastolic from {dia1} to {dia2} mmHg'**
  String chartDescription(
    String from,
    String to,
    int sys1,
    int sys2,
    int dia1,
    int dia2,
  );

  /// No description provided for @bpSemantics.
  ///
  /// In en, this message translates to:
  /// **'{sys} over {dia} millimeters of mercury'**
  String bpSemantics(int sys, int dia);

  /// No description provided for @reminderChannel.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminderChannel;

  /// No description provided for @reminderChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Reminders to measure your blood pressure'**
  String get reminderChannelDescription;

  /// No description provided for @reminderTitleDaily.
  ///
  /// In en, this message translates to:
  /// **'Time for a 2-minute blood pressure check'**
  String get reminderTitleDaily;

  /// No description provided for @reminderTitleDay.
  ///
  /// In en, this message translates to:
  /// **'It\'s {weekday}: 2 minutes for your blood pressure'**
  String reminderTitleDay(String weekday);

  /// No description provided for @reminderBodyFirst.
  ///
  /// In en, this message translates to:
  /// **'Sit down, relax and log your first reading.'**
  String get reminderBodyFirst;

  /// No description provided for @reminderBody.
  ///
  /// In en, this message translates to:
  /// **'Last time {value}. Measure, log the values and you\'re done.'**
  String reminderBody(String value);

  /// No description provided for @nudgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Yesterday was {weekday}'**
  String nudgeTitle(String weekday);

  /// No description provided for @nudgeBody.
  ///
  /// In en, this message translates to:
  /// **'No problem: measure today and your streak goes on.'**
  String get nudgeBody;

  /// No description provided for @summaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Your {month}'**
  String summaryTitle(String month);

  /// No description provided for @summaryEmpty.
  ///
  /// In en, this message translates to:
  /// **'{month}: no readings. The new month is a good start.'**
  String summaryEmpty(String month);

  /// No description provided for @summaryBody.
  ///
  /// In en, this message translates to:
  /// **'{month}: {count, plural, =1{1 reading} other{{count} readings}}, average {avg}.'**
  String summaryBody(String month, int count, String avg);

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Blood pressure diary'**
  String get reportTitle;

  /// No description provided for @reportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Home readings, {schedule} · {from} – {to}'**
  String reportSubtitle(String schedule, String from, String to);

  /// No description provided for @generatedOn.
  ///
  /// In en, this message translates to:
  /// **'Generated on {date}'**
  String generatedOn(String date);

  /// No description provided for @averagePulse.
  ///
  /// In en, this message translates to:
  /// **'Average pulse'**
  String get averagePulse;

  /// No description provided for @reportChart.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get reportChart;

  /// No description provided for @reportNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get reportNotes;

  /// No description provided for @reportAllReadings.
  ///
  /// In en, this message translates to:
  /// **'All readings '**
  String get reportAllReadings;

  /// No description provided for @reportBoldNote.
  ///
  /// In en, this message translates to:
  /// **'· in bold, those above threshold ({sys}/{dia})'**
  String reportBoldNote(int sys, int dia);

  /// No description provided for @colDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get colDate;

  /// No description provided for @colTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get colTime;

  /// No description provided for @noReading.
  ///
  /// In en, this message translates to:
  /// **'no reading'**
  String get noReading;

  /// No description provided for @reportFooter.
  ///
  /// In en, this message translates to:
  /// **'* with note. Bands and threshold {sys}/{dia} mmHg: {source}. Values entered by the user, by hand or from a photo of the display. PressSure is a personal diary, not a medical device.'**
  String reportFooter(int sys, int dia, String source);

  /// No description provided for @footerSourceEsc.
  ///
  /// In en, this message translates to:
  /// **'European ESC 2024 guidelines for home measurement'**
  String get footerSourceEsc;

  /// No description provided for @footerSourceCustom.
  ///
  /// In en, this message translates to:
  /// **'custom thresholds'**
  String get footerSourceCustom;

  /// No description provided for @pageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {total}'**
  String pageOf(int page, int total);

  /// No description provided for @csvSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get csvSource;

  /// No description provided for @csvDouble.
  ///
  /// In en, this message translates to:
  /// **'Double reading'**
  String get csvDouble;

  /// No description provided for @csvPhoto.
  ///
  /// In en, this message translates to:
  /// **'photo'**
  String get csvPhoto;

  /// No description provided for @csvManual.
  ///
  /// In en, this message translates to:
  /// **'manual'**
  String get csvManual;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'no'**
  String get no;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @reminderSummary.
  ///
  /// In en, this message translates to:
  /// **'{schedule} · {time}'**
  String reminderSummary(String schedule, String time);

  /// No description provided for @thresholdsSection.
  ///
  /// In en, this message translates to:
  /// **'Band thresholds'**
  String get thresholdsSection;

  /// No description provided for @thresholdsIntro.
  ///
  /// In en, this message translates to:
  /// **'Default: European ESC 2024 guidelines, home measurement. They apply to charts, diary, achievements and exports.'**
  String get thresholdsIntro;

  /// No description provided for @elevatedFrom.
  ///
  /// In en, this message translates to:
  /// **'Intermediate from'**
  String get elevatedFrom;

  /// No description provided for @aboveThresholdFrom.
  ///
  /// In en, this message translates to:
  /// **'Above threshold from'**
  String get aboveThresholdFrom;

  /// No description provided for @thresholdFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'{band}, {value}'**
  String thresholdFieldLabel(String band, String value);

  /// No description provided for @dataTitle.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get dataTitle;

  /// No description provided for @dataIntro.
  ///
  /// In en, this message translates to:
  /// **'They stay on this phone only. To switch phones or keep them safe, save a backup file wherever you like.'**
  String get dataIntro;

  /// No description provided for @saveBackup.
  ///
  /// In en, this message translates to:
  /// **'Save backup'**
  String get saveBackup;

  /// No description provided for @restoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreBackup;

  /// No description provided for @backupReminder.
  ///
  /// In en, this message translates to:
  /// **'Remind me to back up every month'**
  String get backupReminder;

  /// No description provided for @lastBackup.
  ///
  /// In en, this message translates to:
  /// **'Last backup: {date}'**
  String lastBackup(String date);

  /// No description provided for @noBackupYet.
  ///
  /// In en, this message translates to:
  /// **'No backup yet'**
  String get noBackupYet;

  /// No description provided for @backupSaved.
  ///
  /// In en, this message translates to:
  /// **'Backup saved'**
  String get backupSaved;

  /// No description provided for @backupFileBase.
  ///
  /// In en, this message translates to:
  /// **'PressSure_backup'**
  String get backupFileBase;

  /// No description provided for @restoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore the backup?'**
  String get restoreTitle;

  /// No description provided for @restoreBody.
  ///
  /// In en, this message translates to:
  /// **'The diary, habit, reminders and thresholds on this phone are replaced by those in the backup from {date} ({readings}). This can\'t be undone.'**
  String restoreBody(String date, String readings);

  /// No description provided for @restoreDone.
  ///
  /// In en, this message translates to:
  /// **'Diary restored: {readings}'**
  String restoreDone(String readings);

  /// No description provided for @backupInvalid.
  ///
  /// In en, this message translates to:
  /// **'The chosen file isn\'t a PressSure backup.'**
  String get backupInvalid;

  /// No description provided for @backupTooNew.
  ///
  /// In en, this message translates to:
  /// **'This backup comes from a newer version of PressSure: update the app and try again.'**
  String get backupTooNew;

  /// No description provided for @aboutThresholds.
  ///
  /// In en, this message translates to:
  /// **'Disclaimer and threshold sources'**
  String get aboutThresholds;

  /// No description provided for @aboutDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Disclaimer'**
  String get aboutDisclaimer;

  /// No description provided for @aboutSources.
  ///
  /// In en, this message translates to:
  /// **'Threshold sources'**
  String get aboutSources;

  /// No description provided for @aboutBands.
  ///
  /// In en, this message translates to:
  /// **'Default bands for home measurement: optimal below {elevSys}/{elevDia}, intermediate from {elevSys}/{elevDia} (“elevated” in the guidelines), above threshold from {highSys}/{highDia} mmHg.'**
  String aboutBands(int elevSys, int elevDia, int highSys, int highDia);

  /// No description provided for @aboutSource.
  ///
  /// In en, this message translates to:
  /// **'Source: 2024 ESC Guidelines for the management of elevated blood pressure and hypertension, European Heart Journal, 2024.'**
  String get aboutSource;

  /// No description provided for @aboutCredits.
  ///
  /// In en, this message translates to:
  /// **'Acknowledgements'**
  String get aboutCredits;

  /// No description provided for @aboutModel.
  ///
  /// In en, this message translates to:
  /// **'Reading the display uses a model trained on the “Blood-Pressure-monitor-digit-reader” dataset by naphop (Roboflow Universe), CC BY 4.0 licence.'**
  String get aboutModel;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @privacyIntro.
  ///
  /// In en, this message translates to:
  /// **'PressSure doesn\'t collect your data: it stays on your phone. There is no account, no server, no ads and no usage analytics.'**
  String get privacyIntro;

  /// No description provided for @privacyDataTitle.
  ///
  /// In en, this message translates to:
  /// **'What the app saves'**
  String get privacyDataTitle;

  /// No description provided for @privacyData.
  ///
  /// In en, this message translates to:
  /// **'Your readings (systolic and diastolic pressure, pulse, date and time, arm, position, notes), your measuring habit and your settings. They are kept in the app\'s private storage on this phone and other apps can\'t access them.'**
  String get privacyData;

  /// No description provided for @privacyCameraTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera and photos'**
  String get privacyCameraTitle;

  /// No description provided for @privacyCamera.
  ///
  /// In en, this message translates to:
  /// **'The camera is only used to photograph the monitor display. The photo, taken or picked from the gallery, is read on the phone and deleted right after: it is never saved or sent to anyone. The app doesn\'t use the microphone, your location or your contacts.'**
  String get privacyCamera;

  /// No description provided for @privacyOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get privacyOfflineTitle;

  /// No description provided for @privacyOffline.
  ///
  /// In en, this message translates to:
  /// **'The app has no permission to access the internet and contains no tracking tools. Reminders are notifications scheduled on the phone. Android\'s automatic backup is turned off.'**
  String get privacyOffline;

  /// No description provided for @privacySharingTitle.
  ///
  /// In en, this message translates to:
  /// **'What leaves the phone, only if you choose'**
  String get privacySharingTitle;

  /// No description provided for @privacySharing.
  ///
  /// In en, this message translates to:
  /// **'The PDF or CSV of the diary, which you share with the app you pick, and the backup file, which you save wherever you like. These files contain your readings and aren\'t encrypted: from then on, you manage them.'**
  String get privacySharing;

  /// No description provided for @privacyDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Keeping and deleting'**
  String get privacyDeleteTitle;

  /// No description provided for @privacyDelete.
  ///
  /// In en, this message translates to:
  /// **'Data stays until you delete it: Settings › Delete all data, or by uninstalling the app. Since I don\'t have it, I can\'t read it or recover it.'**
  String get privacyDelete;

  /// No description provided for @privacyChildrenTitle.
  ///
  /// In en, this message translates to:
  /// **'Children and medical use'**
  String get privacyChildrenTitle;

  /// No description provided for @privacyChildren.
  ///
  /// In en, this message translates to:
  /// **'The app is not directed at children. PressSure is a personal diary: it is not a medical device and does not diagnose. If you have doubts about your health, talk to your doctor.'**
  String get privacyChildren;

  /// No description provided for @privacyContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get privacyContactTitle;

  /// No description provided for @privacyContact.
  ///
  /// In en, this message translates to:
  /// **'PressSure is developed by Federico Scarel. For questions about this policy write to {email}. If the way the app handles data changes, I update this page and the date below.'**
  String privacyContact(String email);

  /// No description provided for @privacyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String privacyUpdated(String date);

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete all data'**
  String get deleteAllData;

  /// No description provided for @deleteAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all data?'**
  String get deleteAllTitle;

  /// No description provided for @deleteAllBody.
  ///
  /// In en, this message translates to:
  /// **'Readings, habit and settings are erased from this phone. Without a backup they can\'t be recovered.'**
  String get deleteAllBody;

  /// No description provided for @deleteAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete everything'**
  String get deleteAllConfirm;

  /// No description provided for @backupReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Time for a backup'**
  String get backupReminderTitle;

  /// No description provided for @backupReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Save a copy of your diary wherever you like: Settings › Your data.'**
  String get backupReminderBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
