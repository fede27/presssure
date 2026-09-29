/// How often the user wants to measure.
enum Frequency { daily, fewTimesWeek, weekly, biweekly, monthly }

/// Home blood-pressure bands. Defaults follow the ESC 2024 guidelines for
/// home measurement: elevated from 120/70, hypertension from 135/85.
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

/// Personal data printed on the PDF report. All optional.
class ReportProfile {
  const ReportProfile({this.name = '', this.birthDate = '', this.device = ''});

  final String name;
  final String birthDate;
  final String device;

  Map<String, Object?> toJson() => {
    'name': name,
    'birthDate': birthDate,
    'device': device,
  };

  factory ReportProfile.fromJson(Map<String, Object?> json) => ReportProfile(
    name: json['name'] as String? ?? '',
    birthDate: json['birthDate'] as String? ?? '',
    device: json['device'] as String? ?? '',
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
    this.profile = const ReportProfile(),
    this.shares = const [],
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
  final ReportProfile profile;

  /// When the report was shared or saved, oldest first.
  final List<DateTime> shares;

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
    ReportProfile? profile,
    List<DateTime>? shares,
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
      profile: profile ?? this.profile,
      shares: shares ?? this.shares,
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
    'profile': profile.toJson(),
    'shares': shares.map((d) => d.toIso8601String()).toList(),
  };

  factory AppSettings.fromJson(Map<String, Object?> json) {
    final anchor = json['anchor'] as String?;
    return AppSettings(
      onboarded: json['onboarded'] as bool? ?? false,
      frequency: Frequency.values.byName(
        json['frequency'] as String? ?? 'weekly',
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
      profile: json['profile'] == null
          ? const ReportProfile()
          : ReportProfile.fromJson(
              (json['profile'] as Map).cast<String, Object?>(),
            ),
      shares: ((json['shares'] as List?) ?? const [])
          .cast<String>()
          .map(DateTime.parse)
          .toList(),
    );
  }
}
