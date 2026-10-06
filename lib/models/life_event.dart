import 'json.dart';

/// What kind of change an event is.
enum EventCategory { lifeWork, diet, activity, other }

/// A change in the user's life ("nuovo lavoro", "meno sale"), to see if the
/// readings changed around it. A day, not a time: readings taken on that
/// day count as "after".
class LifeEvent {
  const LifeEvent({
    required this.id,
    required this.day,
    required this.category,
    required this.title,
    this.note = '',
    this.showInChart = true,
    this.inReport = true,
  });

  final String id;

  /// Midnight of the day the change started.
  final DateTime day;
  final EventCategory category;
  final String title;
  final String note;

  /// A line in the "Andamento" chart.
  final bool showInChart;

  /// In the PDF for the doctor.
  final bool inReport;

  bool get hasNote => note.trim().isNotEmpty;

  LifeEvent copyWith({
    DateTime? day,
    EventCategory? category,
    String? title,
    String? note,
    bool? showInChart,
    bool? inReport,
  }) => LifeEvent(
    id: id,
    day: day ?? this.day,
    category: category ?? this.category,
    title: title ?? this.title,
    note: note ?? this.note,
    showInChart: showInChart ?? this.showInChart,
    inReport: inReport ?? this.inReport,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'day': _dayString(day),
    'category': category.name,
    'title': title,
    'note': note,
    'chart': showInChart,
    'report': inReport,
  };

  factory LifeEvent.fromJson(Map<String, Object?> json) => LifeEvent(
    id: json['id'] as String,
    day: DateTime.parse(json['day'] as String),
    category: enumByName(
      EventCategory.values,
      json['category'],
      EventCategory.other,
    ),
    title: json['title'] as String? ?? '',
    note: json['note'] as String? ?? '',
    showInChart: json['chart'] as bool? ?? true,
    inReport: json['report'] as bool? ?? true,
  );

  /// "2026-07-01": a calendar day, the same wherever the phone is.
  static String _dayString(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// Oldest first; same day in the order they were added.
List<LifeEvent> sortedEvents(Iterable<LifeEvent> events) =>
    [...events]..sort((a, b) => a.day.compareTo(b.day));
