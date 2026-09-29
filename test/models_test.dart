import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:presssure/models/measurement.dart';
import 'package:presssure/models/settings.dart';

import 'helpers.dart';

void main() {
  test('Measurement survives a JSON round trip', () {
    final m = Measurement(
      id: 'abc',
      takenAt: DateTime(2026, 9, 27, 7, 42),
      systolic: 124,
      diastolic: 77,
      pulse: 68,
      arm: Arm.right,
      posture: Posture.lying,
      note: 'Dormito poco',
      source: ReadingSource.photo,
      doubleReading: true,
    );
    final back = Measurement.fromJson(
      (jsonDecode(jsonEncode(m.toJson())) as Map).cast<String, Object?>(),
    );
    expect(back.id, 'abc');
    expect(back.takenAt, m.takenAt);
    expect(back.systolic, 124);
    expect(back.diastolic, 77);
    expect(back.pulse, 68);
    expect(back.arm, Arm.right);
    expect(back.posture, Posture.lying);
    expect(back.note, 'Dormito poco');
    expect(back.source, ReadingSource.photo);
    expect(back.doubleReading, isTrue);
  });

  test('Measurement.copyWith can clear the pulse', () {
    final m = reading(DateTime(2026), 120, 80, pulse: 70);
    expect(m.copyWith(pulse: () => null).pulse, isNull);
    expect(m.copyWith(systolic: 130).pulse, 70);
  });

  test('AppSettings survive a JSON round trip', () {
    final s = AppSettings(
      onboarded: true,
      frequency: Frequency.fewTimesWeek,
      weekdays: const {DateTime.monday, DateTime.thursday},
      reminderHour: 21,
      reminderMinute: 15,
      remindNextDay: false,
      monthlySummary: false,
      thresholds: const Thresholds(highSystolic: 140, highDiastolic: 90),
      anchor: DateTime(2026, 9, 1),
      profile: const ReportProfile(name: 'Mario Rossi'),
      shares: [DateTime(2026, 6, 14)],
    );
    final back = AppSettings.fromJson(
      (jsonDecode(jsonEncode(s.toJson())) as Map).cast<String, Object?>(),
    );
    expect(back.onboarded, isTrue);
    expect(back.frequency, Frequency.fewTimesWeek);
    expect(back.weekdays, {DateTime.monday, DateTime.thursday});
    expect(back.reminderHour, 21);
    expect(back.reminderMinute, 15);
    expect(back.remindNextDay, isFalse);
    expect(back.monthlySummary, isFalse);
    expect(back.thresholds.highSystolic, 140);
    expect(back.thresholds.elevatedSystolic, 120);
    expect(back.anchor, DateTime(2026, 9, 1));
    expect(back.profile.name, 'Mario Rossi');
    expect(back.shares, [DateTime(2026, 6, 14)]);
  });

  test('defaults: weekly on Sunday at 8, ESC 2024', () {
    final s = AppSettings.fromJson(const {});
    expect(s.onboarded, isFalse);
    expect(s.frequency, Frequency.weekly);
    expect(s.weekdays, {DateTime.sunday});
    expect(s.reminderHour, 8);
    expect(s.thresholds.isEsc2024, isTrue);
  });
}
