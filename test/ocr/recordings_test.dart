// Replays on the computer what the engines read on the phone (recorded by
// the OCR benchmark, see tool/ocr_bench/README.md): parser changes are
// measured on real engine output in seconds, without the phone.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:presssure/ocr/benchmark.dart';

/// One folder per engine, one JSON per photo.
final _root = Directory('test/ocr/recordings');

Map<String, List<Recording>> _load() {
  final byEngine = <String, List<Recording>>{};
  if (!_root.existsSync()) return byEngine;
  for (final dir in _root.listSync().whereType<Directory>()) {
    final engine = dir.uri.pathSegments.where((s) => s.isNotEmpty).last;
    final files =
        dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    byEngine[engine] = [
      for (final f in files)
        Recording.fromJson((jsonDecode(f.readAsStringSync()) as Map).cast()),
    ];
  }
  return byEngine;
}

void main() {
  final recordings = _load();

  test(
    'no recordings yet',
    () {},
    skip: recordings.isEmpty ? false : 'recordings found',
  );

  for (final MapEntry(key: engine, value: list) in recordings.entries) {
    group(engine, () {
      final report = BenchmarkReport(engine, [
        for (final r in list) SampleResult.parse(r),
      ]);
      final limits = _limits[engine];

      test('report', () {
        // ignore: avoid_print
        print(report.toMarkdown());
      });

      // A value shown as sure must be right, otherwise the user saves a
      // wrong reading without noticing. The goal is none; the limit is
      // what the engine does today, so any change that adds one fails.
      test('silent errors do not grow', () {
        final silent = report.samples
            .where((s) => s.hasSilentError)
            .map(
              (s) => '${s.recording.sample}: ${s.expected} read ${s.readText}',
            )
            .toList();
        expect(
          silent.length,
          lessThanOrEqualTo(limits?.silentErrors ?? 0),
          reason: silent.join('\n'),
        );
      });

      test('photos read right do not drop', () {
        expect(report.allRight, greaterThanOrEqualTo(limits?.allRight ?? 0));
      });
    });
  }
}

/// What each engine achieves today on its recordings: raise [allRight] and
/// lower [silentErrors] when an improvement allows it, never the other way.
const _limits = {
  'mlkit': (silentErrors: 0, allRight: 1),
  'seg7': (silentErrors: 2, allRight: 152),
  'seg7_phone': (silentErrors: 1, allRight: 35),
};
