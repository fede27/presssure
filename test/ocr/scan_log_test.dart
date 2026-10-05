import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presssure/models/measurement.dart';
import 'package:presssure/ocr/ocr_engine.dart';
import 'package:presssure/ocr/reading_parser.dart';
import 'package:presssure/ocr/scan_log.dart';

void main() {
  late Directory root;
  late FileScanLog log;

  setUp(() {
    root = Directory.systemTemp.createTempSync('scan_log_test');
    log = FileScanLog(
      Directory('${root.path}/kept'),
      exportFolder: Directory('${root.path}/cache'),
      limit: 3,
    );
  });

  tearDown(() => root.deleteSync(recursive: true));

  /// A photo as the camera leaves it, with [content] to tell them apart.
  OcrImage photo(String content) {
    final file = File('${root.path}/photo_$content.jpg')
      ..writeAsStringSync(content);
    return OcrImage(file.path);
  }

  LoggedScan scan(ScanOutcome outcome) => LoggedScan(
    takenAt: DateTime(2026, 10, 2, 8, 30),
    source: 'camera',
    outcome: outcome,
    ocr: const OcrResult(
      engine: 'mlkit',
      tokens: [OcrToken('153', OcrBox(0, 0, 90, 50), confidence: 0.6)],
    ),
    read: const ParsedReading(
      systolic: ReadValue(153, 0.6),
      diastolic: ReadValue(79, 0.9),
    ),
    saved: outcome == ScanOutcome.saved
        ? Measurement(
            id: 'm',
            takenAt: DateTime(2026, 10, 2, 8, 30),
            systolic: 163,
            diastolic: 79,
            pulse: 83,
          )
        : null,
  );

  test('keeps a copy: the original can be deleted', () async {
    final original = photo('a');
    final id = await log.keep(original);
    File(original.path).deleteSync();
    expect(await log.count(), 1);
    expect(File('${log.folder.path}/$id.jpg').readAsStringSync(), 'a');
  });

  test('only the last ones, the oldest dropped with their record', () async {
    final ids = <String>[];
    for (final c in ['1', '2', '3', '4', '5']) {
      final id = await log.keep(photo(c));
      await log.record(id, scan(ScanOutcome.notRead));
      ids.add(id);
    }
    expect(await log.count(), 3);
    final left = log.folder.listSync().map((f) => f.uri.pathSegments.last);
    expect(left, isNot(contains('${ids[0]}.jpg')));
    expect(left, isNot(contains('${ids[1]}.json')));
    expect(left, contains('${ids[4]}.json'));
  });

  test('the record: what was read, what was saved, how it ended', () async {
    final id = await log.keep(photo('x'));
    await log.record(id, scan(ScanOutcome.saved));
    final json = jsonDecode(
      File('${log.folder.path}/$id.json').readAsStringSync(),
    );
    expect(json['outcome'], 'saved');
    expect(json['engine'], 'mlkit');
    expect(json['read']['sys'], {'value': 153, 'confidence': 0.6});
    expect(json['read']['pulse'], isNull);
    expect(json['saved'], {
      'sys': 163,
      'dia': 79,
      'pulse': 83,
      'doubleReading': false,
    });
    expect(json['ocr']['tokens'][0]['text'], '153');
  });

  test('a record for a photo already dropped is ignored', () async {
    await log.record('scan_0', scan(ScanOutcome.retake));
    expect(await log.count(), 0);
  });

  test('export: one zip with photos, records and info', () async {
    final id = await log.keep(photo('p'));
    await log.record(id, scan(ScanOutcome.saved));
    await log.keep(photo('q')); // not recorded yet: the photo goes anyway

    final zip = await log.export();
    expect(zip.parent.path, log.exportFolder.path);
    expect(zip.path, endsWith('.zip'));
    final names = ZipDecoder()
        .decodeBytes(zip.readAsBytesSync())
        .files
        .map((f) => f.name)
        .toList();
    expect(names, contains('$id.jpg'));
    expect(names, contains('$id.json'));
    expect(names, contains('info.json'));
    expect(names.where((n) => n.endsWith('.jpg')), hasLength(2));
  });

  test('clear deletes everything', () async {
    await log.keep(photo('z'));
    await log.clear();
    expect(await log.count(), 0);
  });
}
