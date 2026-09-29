import 'package:flutter/widgets.dart';

import '../l10n/l10n.dart';
import '../logic/achievements.dart';
import '../logic/bp_category.dart';
import '../logic/reminder_plan.dart';
import '../logic/schedule.dart';
import '../logic/stats.dart';
import '../models/measurement.dart';
import '../models/settings.dart';
import '../services/reminders.dart';
import '../services/repository.dart';

/// What happened when a new reading was saved, to pick the next screen.
class SaveOutcome {
  SaveOutcome({
    required this.measurement,
    required this.category,
    required this.newBadges,
    required this.usualAverage,
  });

  final Measurement measurement;
  final BpCategory category;
  final List<Achievement> newBadges;

  /// Average of the last 4 readings before this one.
  final BpAverage? usualAverage;
}

class AppState extends ChangeNotifier {
  AppState({
    required this._repository,
    required this._reminders,
    DateTime Function()? clock,
    Locale locale = const Locale('en'),
  }) : _clock = clock ?? DateTime.now,
       _locale = locale,
       _dateLocale = locale.languageCode {
    _measurements = sortedByDate(_repository.loadMeasurements());
    _settings = _repository.loadSettings();
  }

  final Repository _repository;
  final ReminderService _reminders;
  final DateTime Function() _clock;
  Locale _locale;
  String _dateLocale;
  bool _remindersStarted = false;
  Future<void> _pendingReschedule = Future.value();

  late List<Measurement> _measurements;
  late AppSettings _settings;
  HabitTracker? _tracker;
  AchievementsReport? _achievements;

  DateTime now() => _clock();

  /// Oldest first.
  List<Measurement> get measurements => List.unmodifiable(_measurements);
  AppSettings get settings => _settings;
  Thresholds get thresholds => _settings.thresholds;
  Measurement? get latest => _measurements.lastOrNull;

  Schedule get schedule => Schedule.fromSettings(_settings);

  HabitTracker get tracker =>
      _tracker ??= HabitTracker(schedule, _measurements, now());

  AchievementsReport get achievements => _achievements ??= computeAchievements(
    tracker: tracker,
    measurements: _measurements,
    settings: _settings,
    now: now(),
  );

  BpCategory categoryOf(Measurement m) =>
      classify(m.systolic, m.diastolic, thresholds);

  /// Recomputes derived data, e.g. when the app comes back after midnight.
  void refresh() {
    _invalidate();
    notifyListeners();
  }

  void _invalidate() {
    _tracker = null;
    _achievements = null;
  }

  /// Language of the texts and locale of the dates in notifications. Set by
  /// the app from the resolved locale (see [updateLocale]).
  Locale get locale => _locale;
  String get dateLocale => _dateLocale;
  AppLocalizations get l10n => lookupAppLocalizations(_locale);

  /// Called when the app resolves (or the phone changes) its locale:
  /// scheduled notifications are rewritten in the new language.
  void updateLocale(Locale locale, String dateLocale) {
    if (locale == _locale && dateLocale == _dateLocale) return;
    _locale = locale;
    _dateLocale = dateLocale;
    if (_remindersStarted) _reschedule();
  }

  Future<void> startReminders() async {
    await _reminders.init();
    _remindersStarted = true;
    await _reschedule();
  }

  Future<bool> requestReminderPermission() => _reminders.requestPermission();

  /// Reschedules one at a time, so overlapping calls never mix plans.
  Future<void> _reschedule() =>
      _pendingReschedule = _pendingReschedule.catchError((_) {}).then((_) {
        final l = l10n;
        return _reminders.reschedule(
          planReminders(
            settings: _settings,
            measurements: _measurements,
            now: now(),
            l10n: l,
            dates: Dates(_dateLocale),
          ),
          channelName: l.reminderChannel,
          channelDescription: l.reminderChannelDescription,
        );
      });

  String newId() => now().microsecondsSinceEpoch.toRadixString(36);

  /// Adds a reading, or replaces the one with the same id.
  Future<SaveOutcome> saveMeasurement(Measurement m) async {
    final before = achievements.unlockedKeys;
    final previous = sortedByDate(
      _measurements.where((x) => x.id != m.id && x.takenAt.isBefore(m.takenAt)),
    );

    _measurements = sortedByDate([
      ..._measurements.where((x) => x.id != m.id),
      m,
    ]);
    _invalidate();
    await _repository.saveMeasurements(_measurements);
    await _reschedule();
    notifyListeners();

    final unlocked = achievements.badges
        .where((b) => b.unlocked && !before.contains(b.key))
        .toList();
    return SaveOutcome(
      measurement: m,
      category: categoryOf(m),
      newBadges: unlocked,
      usualAverage: averageOfLast(previous),
    );
  }

  Future<void> deleteMeasurement(String id) async {
    _measurements = _measurements.where((m) => m.id != id).toList();
    _invalidate();
    await _repository.saveMeasurements(_measurements);
    await _reschedule();
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings settings) async {
    _settings = settings;
    _invalidate();
    await _repository.saveSettings(_settings);
    await _reschedule();
    notifyListeners();
  }

  Future<void> recordShare() =>
      updateSettings(_settings.copyWith(shares: [..._settings.shares, now()]));
}

/// Makes [AppState] available to the widget tree.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Access without rebuilding on changes (for callbacks).
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
