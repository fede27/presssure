// OCR benchmark on the phone: every engine on every photo of the corpus.
//
// Run it with tool/ocr_bench/run.ps1, which copies the corpus to the phone
// and brings back the report and the recordings; see
// tool/ocr_bench/README.md.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:presssure/ocr/benchmark.dart';
import 'package:presssure/ocr/ocr_engine.dart';
import 'package:presssure/ocr/photo_prep.dart';
import 'package:presssure/ocr/seg7_engine.dart';

/// The engines to compare: a new engine only needs a line here, as
/// 'name': Engine.new. ML Kit was tried and dropped: it misreads
/// seven-segment digits (163 as 153).
final Map<String, OcrEngine Function()> engines = {'seg7': Seg7Engine.new};

const _photoExtensions = ['.jpg', '.jpeg', '.png'];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('OCR benchmark', timeout: Timeout.none, (tester) async {
    if (engines.isEmpty) {
      debugPrint('No OCR engine to measure yet.');
      return;
    }
    // The corpus is copied into the app's private files by run.ps1 (files
    // pushed to the external folder are not readable by the app); the
    // results go to the external folder, where adb can fetch them.
    final corpus = Directory(
      '${(await getApplicationSupportDirectory()).path}/ocr_corpus',
    );
    final external = (await getExternalStorageDirectory())!;
    final results = Directory('${external.path}/ocr_results');
    final photos = await _photos(corpus);
    expect(
      photos,
      isNotEmpty,
      reason: 'No labelled photos in ${corpus.path}: see tool/ocr_bench.',
    );
    if (await results.exists()) await results.delete(recursive: true);

    final temp = await getTemporaryDirectory();
    for (final entry in engines.entries) {
      final engine = entry.value();
      final samples = <SampleResult>[];
      final recordings = Directory('${results.path}/${entry.key}/recordings');
      for (final photo in photos) {
        final sample = photo.path
            .substring(corpus.path.length + 1)
            .replaceAll(RegExp(r'\.[^.]+$'), '');
        final expected = ExpectedReading.fromJson(
          (jsonDecode(await _sidecar(photo).readAsString()) as Map).cast(),
        );
        // Same preparation as a photo from the gallery in the app.
        final prepared = File('${temp.path}/bench.jpg')
          ..writeAsBytesSync(prepareForOcr(await photo.readAsBytes()));

        final watch = Stopwatch()..start();
        final ocr = await engine.recognize(OcrImage(prepared.path));
        watch.stop();

        final recording = Recording(
          sample: sample,
          expected: expected,
          ocr: ocr,
          elapsedMs: watch.elapsedMilliseconds,
        );
        samples.add(SampleResult.parse(recording));
        final out = File('${recordings.path}/$sample.json');
        await out.parent.create(recursive: true);
        await out.writeAsString(
          const JsonEncoder.withIndent(' ').convert(recording.toJson()),
        );
      }
      await engine.dispose();

      final report = BenchmarkReport(entry.key, samples);
      final folder = '${results.path}/${entry.key}';
      await File('$folder/report.md').writeAsString(report.toMarkdown());
      await File('$folder/report.json').writeAsString(
        const JsonEncoder.withIndent(' ').convert(report.toJson()),
      );
      debugPrint(report.toMarkdown());
    }
  });
}

/// Photos with their `.json` label, in any subfolder, in a stable order.
Future<List<File>> _photos(Directory corpus) async {
  if (!await corpus.exists()) return [];
  final photos = <File>[];
  await for (final entity in corpus.list(recursive: true)) {
    if (entity is! File) continue;
    final lower = entity.path.toLowerCase();
    if (!_photoExtensions.any(lower.endsWith)) continue;
    if (await _sidecar(entity).exists()) photos.add(entity);
  }
  return photos..sort((a, b) => a.path.compareTo(b.path));
}

File _sidecar(File photo) =>
    File(photo.path.replaceAll(RegExp(r'\.[^.]+$'), '.json'));
