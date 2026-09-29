import 'package:flutter_test/flutter_test.dart';
import 'package:presssure/models/settings.dart';
import 'package:presssure/services/backup.dart';

import '../helpers.dart';

void main() {
  test('a backup brings back readings and settings', () {
    final readings = designReadings(includeToday: true);
    final backup = Backup(
      createdAt: DateTime(2026, 9, 27, 9),
      measurements: readings,
      settings: onboardedSettings.copyWith(
        frequency: Frequency.fewTimesWeek,
        weekdays: {DateTime.monday, DateTime.thursday},
        thresholds: const Thresholds(highSystolic: 140, highDiastolic: 90),
      ),
    );

    final back = Backup.decode(backup.encode());
    expect(back.createdAt, DateTime(2026, 9, 27, 9));
    expect(back.measurements, hasLength(readings.length));
    final last = back.measurements.last;
    expect((last.systolic, last.diastolic, last.pulse), (124, 77, 68));
    expect(back.measurements[9].note, 'Iniziata la nuova terapia');
    expect(back.settings.frequency, Frequency.fewTimesWeek);
    expect(back.settings.weekdays, {DateTime.monday, DateTime.thursday});
    expect(back.settings.thresholds.highSystolic, 140);
  });

  test('other files are refused', () {
    for (final text in [
      'not json',
      '[]',
      '{"app": "other", "version": 1}',
      '{"app": "presssure", "version": 1, "createdAt": "2026-09-27"}',
      '{"app": "presssure", "version": 1, "createdAt": "2026-09-27", '
          '"measurements": [{"id": 1}], "settings": {}}',
    ]) {
      expect(() => Backup.decode(text), throwsFormatException, reason: text);
    }
  });

  test('restoring replaces the diary and keeps the app set up', () async {
    final state = await makeState(measurements: designReadings());
    final backup = Backup(
      createdAt: DateTime(2026, 8, 1, 10),
      measurements: [reading(DateTime(2026, 7, 5, 8), 130, 85)],
      settings: const AppSettings(onboarded: false, reminderHour: 20),
    );
    await state.restoreBackup(backup);
    expect(state.measurements, hasLength(1));
    expect(state.settings.onboarded, isTrue);
    expect(state.settings.reminderHour, 20);
    expect(state.settings.lastBackup, DateTime(2026, 8, 1, 10));
  });

  test('a saved backup moves the reminder on', () async {
    final state = await makeState(measurements: designReadings());
    final backup = state.createBackup();
    expect(backup.measurements, hasLength(23));
    await state.recordBackup(backup.createdAt);
    expect(state.settings.lastBackup, designNow);
  });

  test('deleting everything leaves an empty, new app', () async {
    final state = await makeState(measurements: designReadings());
    await state.deleteAllData();
    expect(state.measurements, isEmpty);
    expect(state.settings.onboarded, isFalse);
  });
}
