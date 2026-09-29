import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presssure/app.dart';
import 'package:presssure/l10n/l10n.dart';
import 'package:presssure/models/measurement.dart';
import 'package:presssure/models/settings.dart';
import 'package:presssure/services/reminders.dart';
import 'package:presssure/services/repository.dart';
import 'package:presssure/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sunday 27 September 2026, 07:50: the day of the design mockups.
final designNow = DateTime(2026, 9, 27, 7, 50);

var _ids = 0;

Measurement reading(
  DateTime at,
  int sys,
  int dia, {
  int? pulse,
  String note = '',
  ReadingSource source = ReadingSource.manual,
}) => Measurement(
  id: 'm${_ids++}',
  takenAt: at,
  systolic: sys,
  diastolic: dia,
  pulse: pulse,
  note: note,
  source: source,
);

/// The weekly readings of the design ("08 · PDF esportato"): every Sunday
/// from 5 April to 20 September 2026, except 9 and 16 August.
List<Measurement> designReadings({bool includeToday = false}) {
  const rows = [
    (4, 5, '08:10', 142, 90, 75, ''),
    (4, 12, '08:25', 142, 90, 71, ''),
    (4, 19, '09:05', 139, 90, 72, ''),
    (4, 26, '08:15', 145, 88, 68, ''),
    (5, 3, '07:50', 138, 92, 72, ''),
    (5, 10, '08:40', 137, 93, 76, ''),
    (5, 17, '08:05', 144, 91, 66, ''),
    (5, 24, '09:20', 137, 90, 65, ''),
    (5, 31, '08:30', 139, 88, 64, ''),
    (6, 7, '08:00', 142, 90, 74, 'Iniziata la nuova terapia'),
    (6, 14, '08:45', 141, 90, 70, ''),
    (6, 21, '07:55', 140, 87, 67, ''),
    (6, 28, '08:20', 142, 90, 74, ''),
    (7, 5, '08:35', 138, 84, 67, ''),
    (7, 12, '09:10', 132, 82, 73, ''),
    (7, 19, '08:15', 131, 85, 69, ''),
    (7, 26, '08:05', 135, 84, 64, ''),
    (8, 2, '08:50', 126, 83, 70, ''),
    (8, 23, '08:30', 125, 80, 76, ''),
    (8, 30, '09:00', 132, 79, 67, 'Caffè poco prima'),
    (9, 6, '08:10', 125, 78, 74, ''),
    (9, 13, '08:20', 126, 81, 69, 'Dormito poco'),
    (9, 20, '08:05', 126, 82, 66, ''),
  ];
  final list = [
    for (final (month, day, time, sys, dia, pulse, note) in rows)
      reading(
        DateTime(
          2026,
          month,
          day,
          int.parse(time.substring(0, 2)),
          int.parse(time.substring(3)),
        ),
        sys,
        dia,
        pulse: pulse,
        note: note,
      ),
  ];
  if (includeToday) {
    list.add(reading(DateTime(2026, 9, 27, 7, 42), 124, 77, pulse: 68));
  }
  return list;
}

const onboardedSettings = AppSettings(onboarded: true);

/// Italian texts and dates, as most tests expect.
final itL10n = lookupAppLocalizations(const Locale('it'));
final itDates = Dates('it');
final enL10n = lookupAppLocalizations(const Locale('en'));
final enDates = Dates('en_US');

/// Prepares shared preferences with the given data and returns the state.
Future<AppState> makeState({
  List<Measurement> measurements = const [],
  AppSettings settings = onboardedSettings,
  DateTime? now,
  ReminderService? reminders,
  Locale locale = const Locale('it'),
}) async {
  SharedPreferences.setMockInitialValues({
    'measurements.v1': jsonEncode(measurements.map((m) => m.toJson()).toList()),
    'settings.v1': jsonEncode(settings.toJson()),
  });
  final clock = now ?? designNow;
  return AppState(
    repository: await Repository.open(),
    reminders: reminders ?? NoopReminderService(),
    clock: () => clock,
    locale: locale,
  );
}

/// Pumps the whole app on a tall phone-sized screen, with the phone set to
/// [locale] (Italian by default).
Future<AppState> pumpApp(
  WidgetTester tester, {
  List<Measurement> measurements = const [],
  AppSettings settings = onboardedSettings,
  DateTime? now,
  Locale locale = const Locale('it', 'IT'),
}) async {
  tester.view.physicalSize = const Size(1170, 6000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  final state = await makeState(
    measurements: measurements,
    settings: settings,
    now: now,
  );
  await tester.pumpWidget(PressSureApp(state: state));
  await tester.pumpAndSettle();
  return state;
}
