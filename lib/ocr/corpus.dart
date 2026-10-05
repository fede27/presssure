import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'benchmark.dart';
import 'ocr_engine.dart';

/// Development builds only: keeps the photos read in the app, labelled with
/// the values the user confirmed, to grow the OCR test corpus. In release
/// builds photos are never kept.
///
/// Samples go to `ocr_corpus/app/` in the app's external files folder, the
/// same folder the benchmark reads (see `tool/ocr_bench/README.md`).
class CorpusRecorder {
  CorpusRecorder(this.folder);

  /// Null in release builds.
  static Future<CorpusRecorder?> open() async {
    if (!kDebugMode) return null;
    final external = await getExternalStorageDirectory();
    if (external == null) return null;
    return CorpusRecorder(Directory('${external.path}/ocr_corpus/app'));
  }

  final Directory folder;

  /// Copies [image] as a new sample, still without label; returns its name.
  Future<String> keep(OcrImage image) async {
    await folder.create(recursive: true);
    final name = 'app_${DateTime.now().millisecondsSinceEpoch}';
    await File(image.path).copy('${folder.path}/$name.jpg');
    return name;
  }

  /// Labels the sample: from now on it is part of the corpus.
  Future<void> label(String name, ExpectedReading expected) =>
      File('${folder.path}/$name.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert(expected.toJson()),
      );

  /// The reading was not saved: the photo has no reliable label.
  Future<void> drop(String name) async {
    for (final ext in ['jpg', 'json']) {
      final file = File('${folder.path}/$name.$ext');
      if (await file.exists()) await file.delete();
    }
  }
}
