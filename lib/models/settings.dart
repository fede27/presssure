import 'json.dart';

/// How often the user wants to measure.
enum Frequency { daily, fewTimesWeek, weekly, biweekly, monthly }

/// Values out of 40–250 mmHg, or the intermediate band (ESC "elevated") not
/// below the threshold.
enum ThresholdsProblem { range, order }

/// Home blood-pressure bands. Defaults follow the ESC 2024 guidelines for
/// home measurement: intermediate (ESC "elevated") from 120/70, hypertension
/// from 135/85.
class Thresholds {
  const Thresholds({
    this.highSystolic = 135,
    this.highDiastolic = 85,
    this.elevatedSystolic = 120,
    this.elevatedDiastolic = 70,
  });

  static const esc2024 = Thresholds();

  final int highSystolic;
  final int highDiastolic;
  final int elevatedSystolic;
  final int elevatedDiastolic;

  bool get isEsc2024 =>
      highSystolic == esc2024.highSystolic &&
      highDiastolic == esc2024.highDiastolic &&
      elevatedSystolic == esc2024.elevatedSystolic &&
      elevatedDiastolic == esc2024.elevatedDiastolic;

  /// Why these values can't be used, or null when they are fine.
  ThresholdsProblem? get problem {
    final all = [
      highSystolic,
      highDiastolic,
      elevatedSystolic,
      elevatedDiastolic,
    ];
    if (all.any((v) => v < 40 || v > 250)) return ThresholdsProblem.range;
    if (elevatedSystolic >= highSystolic ||
        elevatedDiastolic >= highDiastolic) {
      return ThresholdsProblem.order;
    }
    return null;
  }

  Map<String, Object?> toJson() => {
    'highSys': highSystolic,
    'highDia': highDiastolic,
    'elevSys': elevatedSystolic,
    'elevDia': elevatedDiastolic,
  };

  factory Thresholds.fromJson(Map<String, Object?> json) => Thresholds(
    highSystolic: json['highSys'] as int? ?? 135,
    highDiastolic: json['highDia'] as int? ?? 85,
    elevatedSystolic: json['elevSys'] as int? ?? 120,
    elevatedDiastolic: json['elevDia'] as int? ?? 70,
  );
}

class AppSettings {
  const AppSettings({
    this.onboarded = false,
    this.frequency = Frequency.weekly,
    this.weekdays = const {DateTime.sunday},
    this.reminderHour = 8,
    this.reminderMinute = 0,
    this.remindNextDay = true,
    this.monthlySummary = true,
    this.thresholds = Thresholds.esc2024,
    this.anchor,
    this.shares = const [],
    this.backupReminder = true,
    this.lastBackup,
    this.keepScans,
  });

  final bool onboarded;
  final Frequency frequency;

  /// Selected weekdays ([DateTime.monday]..[DateTime.sunday]). Ignored for
  /// [Frequency.daily]; a single day for weekly, biweekly and monthly.
  final Set<int> weekdays;
  final int reminderHour;
  final int reminderMinute;
  final bool remindNextDay;
  final bool monthlySummary;
  final Thresholds thresholds;

  /// Reference day for the biweekly rhythm (when the habit was set).
  final DateTime? anchor;

  /// When the report was exported (saved or shared), oldest first.
  final List<DateTime> shares;

  /// Reminds to save a backup file once a month.
  final bool backupReminder;
  final DateTime? lastBackup;

  /// Beta builds: the tester agreed to keep the last readings for analysis;
  /// null until asked.
  final bool? keepScans;

  AppSettings copyWith({
    bool? onboarded,
    Frequency? frequency,
    Set<int>? weekdays,
    int? reminderHour,
    int? reminderMinute,
    bool? remindNextDay,
    bool? monthlySummary,
    Thresholds? thresholds,
    DateTime? anchor,
    List<DateTime>? shares,
    bool? backupReminder,
    DateTime? lastBackup,
    bool? keepScans,
  }) {
    return AppSettings(
      onboarded: onboarded ?? this.onboarded,
      frequency: frequency ?? this.frequency,
      weekdays: weekdays ?? this.weekdays,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      remindNextDay: remindNextDay ?? this.remindNextDay,
      monthlySummary: monthlySummary ?? this.monthlySummary,
      thresholds: thresholds ?? this.thresholds,
      anchor: anchor ?? this.anchor,
      shares: shares ?? this.shares,
      backupReminder: backupReminder ?? this.backupReminder,
      lastBackup: lastBackup ?? this.lastBackup,
      keepScans: keepScans ?? this.keepScans,
    );
  }

  Map<String, Object?> toJson() => {
    'onboarded': onboarded,
    'frequency': frequency.name,
    'weekdays': weekdays.toList()..sort(),
    'reminderHour': reminderHour,
    'reminderMinute': reminderMinute,
    'remindNextDay': remindNextDay,
    'monthlySummary': monthlySummary,
    'thresholds': thresholds.toJson(),
    'anchor': anchor?.toIso8601String(),
    'shares': shares.map((d) => d.toIso8601String()).toList(),
    'backupReminder': backupReminder,
    'lastBackup': lastBackup?.toIso8601String(),
    'keepScans': keepScans,
  };

  factory AppSettings.fromJson(Map<String, Object?> json) {
    final anchor = json['anchor'] as String?;
    final lastBackup = json['lastBackup'] as String?;
    return AppSettings(
      onboarded: json['onboarded'] as bool? ?? false,
      frequency: enumByName(
        Frequency.values,
        json['frequency'],
        Frequency.weekly,
      ),
      weekdays: ((json['weekdays'] as List?) ?? const [DateTime.sunday])
          .cast<int>()
          .toSet(),
      reminderHour: json['reminderHour'] as int? ?? 8,
      reminderMinute: json['reminderMinute'] as int? ?? 0,
      remindNextDay: json['remindNextDay'] as bool? ?? true,
      monthlySummary: json['monthlySummary'] as bool? ?? true,
      thresholds: json['thresholds'] == null
          ? Thresholds.esc2024
          : Thresholds.fromJson(
              (json['thresholds'] as Map).cast<String, Object?>(),
            ),
      anchor: anchor == null ? null : DateTime.parse(anchor),
      shares: ((json['shares'] as List?) ?? const [])
          .cast<String>()
          .map(DateTime.parse)
          .toList(),
      backupReminder: json['backupReminder'] as bool? ?? true,
      lastBackup: lastBackup == null ? null : DateTime.parse(lastBackup),
      keepScans: json['keepScans'] as bool?,
    );
  }
}
