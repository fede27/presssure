import 'json.dart';

/// Arm used for the reading.
enum Arm { left, right }

/// Body position during the reading.
enum Posture { sitting, standing, lying }

/// How the values were entered.
enum ReadingSource { manual, photo }

/// A single blood-pressure reading stored in the diary.
class Measurement {
  const Measurement({
    required this.id,
    required this.takenAt,
    required this.systolic,
    required this.diastolic,
    this.pulse,
    this.arm = Arm.left,
    this.posture = Posture.sitting,
    this.note = '',
    this.source = ReadingSource.manual,
    this.doubleReading = false,
  });

  final String id;
  final DateTime takenAt;
  final int systolic;
  final int diastolic;
  final int? pulse;
  final Arm arm;
  final Posture posture;
  final String note;
  final ReadingSource source;

  /// True when the stored values are the average of two readings.
  final bool doubleReading;

  bool get hasNote => note.trim().isNotEmpty;

  Measurement copyWith({
    DateTime? takenAt,
    int? systolic,
    int? diastolic,
    int? Function()? pulse,
    Arm? arm,
    Posture? posture,
    String? note,
    ReadingSource? source,
    bool? doubleReading,
  }) {
    return Measurement(
      id: id,
      takenAt: takenAt ?? this.takenAt,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      pulse: pulse != null ? pulse() : this.pulse,
      arm: arm ?? this.arm,
      posture: posture ?? this.posture,
      note: note ?? this.note,
      source: source ?? this.source,
      doubleReading: doubleReading ?? this.doubleReading,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'takenAt': takenAt.toIso8601String(),
    'sys': systolic,
    'dia': diastolic,
    'pulse': pulse,
    'arm': arm.name,
    'posture': posture.name,
    'note': note,
    'source': source.name,
    'double': doubleReading,
  };

  factory Measurement.fromJson(Map<String, Object?> json) {
    return Measurement(
      id: json['id'] as String,
      takenAt: DateTime.parse(json['takenAt'] as String),
      systolic: json['sys'] as int,
      diastolic: json['dia'] as int,
      pulse: json['pulse'] as int?,
      arm: enumByName(Arm.values, json['arm'], Arm.left),
      posture: enumByName(Posture.values, json['posture'], Posture.sitting),
      note: json['note'] as String? ?? '',
      source: enumByName(
        ReadingSource.values,
        json['source'],
        ReadingSource.manual,
      ),
      doubleReading: json['double'] as bool? ?? false,
    );
  }
}
