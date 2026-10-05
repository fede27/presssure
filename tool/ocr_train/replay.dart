// Turns the detector output written by detect.py into recordings, with the
// app's own grouping (lib/ocr/digit_grouping.dart), and prints the
// benchmark report. The recordings go to test/ocr/recordings/<engine>/,
// where `flutter test` replays them through the parser.
//
//   dart run tool/ocr_train/replay.dart tool/ocr_train/work/detections/best_test [engine]
import 'dart:convert';
import 'dart:io';

import 'package:presssure/ocr/benchmark.dart';
import 'package:presssure/ocr/digit_grouping.dart';
import 'package:presssure/ocr/ocr_engine.dart';

void main(List<String> args) {
  final folder = Directory(args[0]);
  final engine = args.length > 1 ? args[1] : 'seg7';
  final out = Directory('test/ocr/recordings/$engine');
  if (out.existsSync()) out.deleteSync(recursive: true);

  final samples = <SampleResult>[];
  final files =
      folder
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in files) {
    final json = (jsonDecode(file.readAsStringSync()) as Map)
        .cast<String, Object?>();
    final detections = [
      for (final d in json['detections']! as List)
        Detection.fromJson((d as Map).cast()),
    ];
    final recording = Recording(
      sample: json['sample']! as String,
      expected: ExpectedReading.fromJson((json['expected']! as Map).cast()),
      ocr: OcrResult(engine: engine, tokens: groupDigits(detections)),
      elapsedMs: json['elapsedMs'] as int?,
    );
    samples.add(SampleResult.parse(recording));
    File('${out.path}/${recording.sample}.json')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(
        const JsonEncoder.withIndent(' ').convert(recording.toJson()),
      );
  }
  stdout.writeln(BenchmarkReport(engine, samples).toMarkdown());
}
