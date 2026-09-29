import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/measurement.dart';
import '../models/settings.dart';

/// Stores the diary on the device as JSON in shared preferences.
class Repository {
  Repository(this._prefs);

  static Future<Repository> open() async =>
      Repository(await SharedPreferences.getInstance());

  static const _measurementsKey = 'measurements.v1';
  static const _settingsKey = 'settings.v1';

  final SharedPreferences _prefs;

  List<Measurement> loadMeasurements() {
    final raw = _prefs.getString(_measurementsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .cast<Map<String, Object?>>()
        .map(Measurement.fromJson)
        .toList();
  }

  Future<void> saveMeasurements(List<Measurement> items) => _prefs.setString(
    _measurementsKey,
    jsonEncode(items.map((m) => m.toJson()).toList()),
  );

  AppSettings loadSettings() {
    final raw = _prefs.getString(_settingsKey);
    if (raw == null) return const AppSettings();
    return AppSettings.fromJson(
      (jsonDecode(raw) as Map).cast<String, Object?>(),
    );
  }

  Future<void> saveSettings(AppSettings settings) =>
      _prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
}
