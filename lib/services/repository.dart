import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/life_event.dart';
import '../models/measurement.dart';
import '../models/settings.dart';
import 'data_format.dart';

/// Stores the diary on the device as JSON in shared preferences.
///
/// The data carries its [dataVersion]; data saved by an older version of
/// the app is migrated (see `data_format.dart`) when the repository opens.
class Repository {
  Repository._(this._prefs);

  static Future<Repository> open() async {
    final repository = Repository._(await SharedPreferences.getInstance());
    await repository._migrate();
    return repository;
  }

  // The key names are fixed: the version lives in [_versionKey].
  static const _measurementsKey = 'measurements.v1';
  static const _settingsKey = 'settings.v1';
  static const _eventsKey = 'events';
  static const _versionKey = 'dataVersion';

  final SharedPreferences _prefs;

  /// Data written before versioning counts as version 1.
  int get storedVersion => _prefs.getInt(_versionKey) ?? 1;

  Future<void> _migrate() async {
    final version = storedVersion;
    // Nothing to do, or data from a newer app (only after a downgrade): it
    // is read as it is, unknown fields and values fall back to defaults.
    if (version >= dataVersion) return;
    final doc = migrateData({
      'measurements': jsonDecode(_prefs.getString(_measurementsKey) ?? '[]'),
      'settings': jsonDecode(_prefs.getString(_settingsKey) ?? '{}'),
      if (_prefs.getString(_eventsKey) case final events?)
        'events': jsonDecode(events),
    }, version);
    await _prefs.setString(_measurementsKey, jsonEncode(doc['measurements']));
    await _prefs.setString(_settingsKey, jsonEncode(doc['settings']));
    await _prefs.setString(_eventsKey, jsonEncode(doc['events'] ?? []));
    await _prefs.setInt(_versionKey, dataVersion);
  }

  List<Measurement> loadMeasurements() {
    final raw = _prefs.getString(_measurementsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .cast<Map<String, Object?>>()
        .map(Measurement.fromJson)
        .toList();
  }

  Future<void> saveMeasurements(List<Measurement> items) async {
    await _prefs.setString(
      _measurementsKey,
      jsonEncode(items.map((m) => m.toJson()).toList()),
    );
    await _prefs.setInt(_versionKey, dataVersion);
  }

  List<LifeEvent> loadEvents() {
    final raw = _prefs.getString(_eventsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .cast<Map<String, Object?>>()
        .map(LifeEvent.fromJson)
        .toList();
  }

  Future<void> saveEvents(List<LifeEvent> items) async {
    await _prefs.setString(
      _eventsKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
    await _prefs.setInt(_versionKey, dataVersion);
  }

  AppSettings loadSettings() {
    final raw = _prefs.getString(_settingsKey);
    if (raw == null) return const AppSettings();
    return AppSettings.fromJson(
      (jsonDecode(raw) as Map).cast<String, Object?>(),
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
    await _prefs.setInt(_versionKey, dataVersion);
  }
}
