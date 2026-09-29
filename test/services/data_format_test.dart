import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:presssure/models/measurement.dart';
import 'package:presssure/models/settings.dart';
import 'package:presssure/services/backup.dart';
import 'package:presssure/services/data_format.dart';
import 'package:presssure/services/repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('migrations', () {
    // A pretend future: v2 renames "sys"/"dia", v3 adds a settings flag.
    final steps = <int, DataMigration>{
      1: (doc) => {
        ...doc,
        'measurements': [
          for (final m in doc['measurements']! as List)
            {
              ...(m as Map).cast<String, Object?>(),
              'systolic': m['sys'],
              'diastolic': m['dia'],
            }..removeWhere((k, _) => k == 'sys' || k == 'dia'),
        ],
      },
      2: (doc) => {
        ...doc,
        'settings': {...(doc['settings']! as Map), 'v3': true},
      },
    };
    final v1 = <String, Object?>{
      'measurements': [
        {'id': 'a', 'sys': 120, 'dia': 80},
      ],
      'settings': <String, Object?>{},
    };

    test('run one step at a time up to the current version', () {
      final doc = migrateData(v1, 1, to: 3, migrations: steps);
      final m = (doc['measurements']! as List).single as Map;
      expect(m['systolic'], 120);
      expect(m.containsKey('sys'), isFalse);
      expect((doc['settings']! as Map)['v3'], isTrue);

      final fromV2 = migrateData(steps[1]!(v1), 2, to: 3, migrations: steps);
      expect(fromV2, doc);
    });

    test('same version: unchanged; newer: refused', () {
      expect(migrateData(v1, 3, to: 3, migrations: steps), same(v1));
      expect(
        () => migrateData(v1, 4, to: 3, migrations: steps),
        throwsA(isA<DataTooNewException>()),
      );
    });

    test('every version before the current one has its step', () {
      for (var v = 1; v < dataVersion; v++) {
        expect(dataMigrations.containsKey(v), isTrue, reason: 'v$v');
      }
    });
  });

  test('values unknown to this version fall back to defaults', () {
    final m = Measurement.fromJson({
      'id': 'x',
      'takenAt': '2026-09-27T08:00:00.000',
      'sys': 120,
      'dia': 80,
      'posture': 'kneeling',
      'source': 'bluetooth',
      'newField': {'anything': 1},
    });
    expect(m.posture, Posture.sitting);
    expect(m.source, ReadingSource.manual);

    final s = AppSettings.fromJson({'frequency': 'hourly', 'newFlag': true});
    expect(s.frequency, Frequency.weekly);
  });

  test('a backup from a newer app is refused as such', () {
    final text = jsonEncode({
      'app': 'presssure',
      'version': dataVersion + 1,
      'createdAt': '2026-09-27T09:00:00.000',
      'measurements': [],
      'settings': {},
    });
    expect(() => Backup.decode(text), throwsA(isA<DataTooNewException>()));
  });

  test('backups carry the current data version', () {
    final text = Backup(
      createdAt: DateTime(2026, 9, 27),
      measurements: const [],
      settings: const AppSettings(),
    ).encode();
    expect((jsonDecode(text) as Map)['version'], dataVersion);
  });

  test('storage from before versioning is read and marked', () async {
    SharedPreferences.setMockInitialValues({
      'measurements.v1': jsonEncode([
        {
          'id': 'a',
          'takenAt': '2026-09-27T08:00:00.000',
          'sys': 120,
          'dia': 80,
        },
      ]),
      'settings.v1': jsonEncode({'onboarded': true}),
    });
    final repository = await Repository.open();
    expect(repository.storedVersion, dataVersion);
    expect(repository.loadMeasurements().single.systolic, 120);
    expect(repository.loadSettings().onboarded, isTrue);
  });
}
