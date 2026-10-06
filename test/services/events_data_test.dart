import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:presssure/models/life_event.dart';
import 'package:presssure/models/settings.dart';
import 'package:presssure/services/backup.dart';
import 'package:presssure/services/data_format.dart';
import 'package:presssure/services/repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';

void main() {
  group('event', () {
    test('saved as JSON and read back', () {
      final e = designEvents()[1].copyWith(showInChart: false);
      final json = e.toJson();
      expect(json['day'], '2026-07-01');
      final back = LifeEvent.fromJson(jsonDecode(jsonEncode(json)));
      expect(back.day, DateTime(2026, 7, 1));
      expect(back.category, EventCategory.lifeWork);
      expect(back.title, e.title);
      expect(back.note, e.note);
      expect(back.showInChart, isFalse);
      expect(back.inReport, isTrue);
    });

    test('a kind unknown to this version becomes "other"', () {
      final e = LifeEvent.fromJson({
        'id': 'x',
        'day': '2026-07-01',
        'category': 'medicine',
        'title': 'x',
      });
      expect(e.category, EventCategory.other);
      expect(e.showInChart, isTrue);
    });
  });

  group('data version 2', () {
    test('version 1 data gets an empty list of events', () {
      final doc = migrateData({
        'measurements': <Object?>[],
        'settings': <String, Object?>{},
      }, 1);
      expect(doc['events'], isEmpty);
      expect(dataVersion, 2);
    });

    test('the phone storage of the previous version is upgraded', () async {
      SharedPreferences.setMockInitialValues({
        'measurements.v1': jsonEncode([designReadings().first.toJson()]),
        'settings.v1': jsonEncode(onboardedSettings.toJson()),
        'dataVersion': 1,
      });
      final repo = await Repository.open();
      expect(repo.storedVersion, 2);
      expect(repo.loadMeasurements(), hasLength(1));
      expect(repo.loadEvents(), isEmpty);

      await repo.saveEvents(designEvents());
      final reopened = await Repository.open();
      expect(reopened.loadEvents().map((e) => e.title), [
        'Meno sale a tavola',
        'Nuovo lavoro vicino a casa',
        'Camminata ogni giorno',
      ]);
    });

    test('a backup keeps the events', () {
      final backup = Backup(
        createdAt: designNow,
        measurements: designReadings(),
        events: designEvents(),
        settings: onboardedSettings.copyWith(eventsInChart: true),
      );
      final text = backup.encode();
      expect(jsonDecode(text)['version'], 2);
      final back = Backup.decode(text);
      expect(back.events.map((e) => e.id), ['e1', 'e2', 'e3']);
      expect(back.settings.eventsInChart, isTrue);
    });

    test('a version 1 backup restores with no events', () {
      final v1 = jsonEncode({
        'app': 'presssure',
        'version': 1,
        'createdAt': designNow.toIso8601String(),
        'measurements': [designReadings().first.toJson()],
        'settings': onboardedSettings.toJson(),
      });
      final back = Backup.decode(v1);
      expect(back.measurements, hasLength(1));
      expect(back.events, isEmpty);
    });

    test('an app at version 1 refuses a backup with events', () {
      final doc = jsonDecode(
        Backup(
          createdAt: designNow,
          measurements: const [],
          events: designEvents(),
          settings: onboardedSettings,
        ).encode(),
      );
      expect(
        () => migrateData(doc, doc['version'] as int, to: 1),
        throwsA(isA<DataTooNewException>()),
      );
    });
  });

  group('state', () {
    test('add, edit, delete and undo', () async {
      final state = await makeState();
      final e = designEvents()[1];
      await state.saveEvent(e);
      await state.saveEvent(designEvents()[0]);
      expect(state.events.map((x) => x.id), ['e1', 'e2']);

      await state.saveEvent(e.copyWith(title: 'Lavoro nuovo'));
      expect(state.events.last.title, 'Lavoro nuovo');

      final removed = await state.deleteEvent('e2');
      expect(state.events.map((x) => x.id), ['e1']);
      await state.saveEvent(removed!);
      expect(state.events.map((x) => x.id), ['e1', 'e2']);
    });

    test('the chart switch is off at first, then remembered', () async {
      final state = await makeState();
      expect(state.settings.eventsInChart, isFalse);
      await state.setEventsInChart(true);
      final repo = await Repository.open();
      expect(repo.loadSettings().eventsInChart, isTrue);
    });

    test('backup, restore and erase include the events', () async {
      final state = await makeState(events: designEvents());
      final backup = state.createBackup();
      expect(backup.events, hasLength(3));

      await state.deleteAllData();
      expect(state.events, isEmpty);

      await state.restoreBackup(Backup.decode(backup.encode()));
      expect(state.events, hasLength(3));
      expect(state.settings, isA<AppSettings>());
    });
  });
}
