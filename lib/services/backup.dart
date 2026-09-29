import 'dart:convert';

import '../models/measurement.dart';
import '../models/settings.dart';
import 'data_format.dart';

/// The whole diary as one JSON file, to move it to another phone or keep a
/// copy: readings and settings, nothing else.
///
/// ```json
/// {"app": "presssure", "version": 1, "createdAt": "…",
///  "measurements": [...], "settings": {...}}
/// ```
///
/// `version` is the [dataVersion]: older backups are migrated on restore,
/// newer ones are refused with [DataTooNewException].
class Backup {
  const Backup({
    required this.createdAt,
    required this.measurements,
    required this.settings,
  });

  static const _app = 'presssure';

  final DateTime createdAt;
  final List<Measurement> measurements;
  final AppSettings settings;

  String encode() => const JsonEncoder.withIndent(' ').convert({
    'app': _app,
    'version': dataVersion,
    'createdAt': createdAt.toIso8601String(),
    'measurements': measurements.map((m) => m.toJson()).toList(),
    'settings': settings.toJson(),
  });

  /// Throws [FormatException] when [text] is not a PressSure backup and
  /// [DataTooNewException] when it comes from a newer version of the app.
  factory Backup.decode(String text) {
    final Map<String, Object?> json;
    final int version;
    try {
      json = (jsonDecode(text) as Map).cast<String, Object?>();
      if (json['app'] != _app) throw const FormatException('not a backup');
      version = json['version'] as int;
    } on FormatException {
      rethrow;
    } catch (e) {
      throw FormatException('invalid backup: $e');
    }
    final doc = migrateData({
      'measurements': json['measurements'],
      'settings': json['settings'],
    }, version);
    try {
      return Backup(
        createdAt: DateTime.parse(json['createdAt'] as String),
        measurements: (doc['measurements'] as List)
            .map((m) => Measurement.fromJson((m as Map).cast()))
            .toList(),
        settings: AppSettings.fromJson(
          (doc['settings'] as Map).cast<String, Object?>(),
        ),
      );
    } on FormatException {
      rethrow;
    } catch (e) {
      // Wrong types or missing required fields.
      throw FormatException('invalid backup: $e');
    }
  }
}
