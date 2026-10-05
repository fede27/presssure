// How the "sure" threshold trades checks for silent errors, on the
// recordings of an engine: for each threshold, values that would show as
// sure and right, sure and wrong (silent errors), and to check.
//
//   dart run tool/ocr_train/calibrate.dart [engine]
import 'dart:convert';
import 'dart:io';

import 'package:presssure/ocr/benchmark.dart';
import 'package:presssure/ocr/reading_parser.dart';

void main(List<String> args) {
  final engine = args.isEmpty ? 'seg7' : args.first;
  final values = <(double, bool)>[]; // confidence, right
  final files = Directory('test/ocr/recordings/$engine')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'));
  for (final file in files) {
    final r = Recording.fromJson(
      (jsonDecode(file.readAsStringSync()) as Map).cast(),
    );
    final read = const ReadingParser().parse(r.ocr);
    if (read == null) continue;
    for (final (got, want) in [
      (read.systolic, r.expected.systolic),
      (read.diastolic, r.expected.diastolic),
      (read.pulse, r.expected.pulse),
    ]) {
      if (got == null || want == null) continue;
      values.add((got.confidence, got.value == want));
    }
  }
  final wrong = values.where((v) => !v.$2).map((v) => v.$1).toList()..sort();
  stdout.writeln('${values.length} values read, ${wrong.length} wrong');
  stdout.writeln(
    'confidence of the wrong ones: '
    '${wrong.map((c) => c.toStringAsFixed(2)).join(', ')}',
  );
  stdout.writeln('\nthreshold  sure+right  silent  to check');
  for (final t in [0.5, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9]) {
    final sure = values.where((v) => v.$1 >= t);
    stdout.writeln(
      '${t.toStringAsFixed(2).padLeft(9)}'
      '${'${sure.where((v) => v.$2).length}'.padLeft(12)}'
      '${'${sure.where((v) => !v.$2).length}'.padLeft(8)}'
      '${'${values.length - sure.length}'.padLeft(10)}',
    );
  }
}
