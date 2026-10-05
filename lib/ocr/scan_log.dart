import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';

import '../config.dart';
import '../models/measurement.dart';
import 'ocr_engine.dart';
import 'reading_parser.dart';

/// How a reading of the display ended.
enum ScanOutcome {
  /// The values were saved: what the user saved is the label of the photo.
  saved,

  /// The form was closed without saving ("Rifai").
  retake,

  /// The engine found no reading.
  notRead,

  /// No engine, or it failed.
  failed,
}

/// One reading of the display, as kept for analysis in beta builds.
class LoggedScan {
  const LoggedScan({
    required this.takenAt,
    required this.source,
    required this.outcome,
    this.ocr,
    this.read,
    this.saved,
  });

  final DateTime takenAt;

  /// `camera` or `gallery`.
  final String source;
  final ScanOutcome outcome;

  /// Raw engine output.
  final OcrResult? ocr;

  /// What the parser made of it.
  final ParsedReading? read;

  /// What the user saved, when [outcome] is [ScanOutcome.saved].
  final Measurement? saved;

  static Map<String, Object?>? _value(ReadValue? v) =>
      v == null ? null : {'value': v.value, 'confidence': v.confidence};

  Map<String, Object?> toJson() => {
    'takenAt': takenAt.toIso8601String(),
    'appVersion': appVersion,
    'source': source,
    'outcome': outcome.name,
    'engine': ocr?.engine,
    'read': read == null
        ? null
        : {
            'sys': _value(read!.systolic),
            'dia': _value(read!.diastolic),
            'pulse': _value(read!.pulse),
          },
    'saved': saved == null
        ? null
        : {
            'sys': saved!.systolic,
            'dia': saved!.diastolic,
            'pulse': saved!.pulse,
            // An average of two readings is not what the photo shows.
            'doubleReading': saved!.doubleReading,
          },
    'ocr': ocr?.toJson(),
  };
}

/// The last readings of the display kept in beta builds, with the tester's
/// consent, to be sent for analysis: photo plus [LoggedScan].
abstract interface class ScanLog {
  /// Copies the photo (the original is deleted as usual); returns its id.
  Future<String> keep(OcrImage photo);

  /// What happened to the reading kept as [id].
  Future<void> record(String id, LoggedScan scan);

  Future<int> count();

  /// Every kept reading in one zip file, ready to attach.
  Future<File> export();

  Future<void> clear();
}

/// [ScanLog] in a folder of the app: `<id>.jpg` and `<id>.json`, at most
/// [limit] readings, the oldest dropped first.
class FileScanLog implements ScanLog {
  FileScanLog(
    this.folder, {
    required this.exportFolder,
    this.limit = keptScans,
  });

  final Directory folder;

  /// Where the zip goes (the cache: the mail app can read it from there).
  final Directory exportFolder;
  final int limit;

  var _last = 0;

  /// Ids sort by time: milliseconds, never twice the same.
  String _newId() {
    var now = DateTime.now().millisecondsSinceEpoch;
    if (now <= _last) now = _last + 1;
    _last = now;
    return 'scan_$now';
  }

  Future<List<File>> _photos() async {
    if (!await folder.exists()) return [];
    final photos = await folder
        .list()
        .where((e) => e is File && e.path.endsWith('.jpg'))
        .cast<File>()
        .toList();
    return photos..sort((a, b) => a.path.compareTo(b.path));
  }

  File _json(File photo) =>
      File(photo.path.replaceFirst(RegExp(r'\.jpg$'), '.json'));

  @override
  Future<String> keep(OcrImage photo) async {
    await folder.create(recursive: true);
    final id = _newId();
    await File(photo.path).copy('${folder.path}/$id.jpg');
    final photos = await _photos();
    final extra = photos.length - limit;
    for (final old in photos.take(extra < 0 ? 0 : extra)) {
      await old.delete();
      final json = _json(old);
      if (await json.exists()) await json.delete();
    }
    return id;
  }

  @override
  Future<void> record(String id, LoggedScan scan) async {
    final photo = File('${folder.path}/$id.jpg');
    // Dropped meanwhile by newer readings.
    if (!await photo.exists()) return;
    await _json(
      photo,
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(scan.toJson()));
  }

  @override
  Future<int> count() async => (await _photos()).length;

  @override
  Future<File> export() async {
    final archive = Archive();
    for (final photo in await _photos()) {
      final name = photo.uri.pathSegments.last;
      archive.addFile(ArchiveFile.bytes(name, await photo.readAsBytes()));
      final json = _json(photo);
      if (await json.exists()) {
        archive.addFile(
          ArchiveFile.bytes(
            name.replaceFirst('.jpg', '.json'),
            await json.readAsBytes(),
          ),
        );
      }
    }
    archive.addFile(
      ArchiveFile.string(
        'info.json',
        jsonEncode({
          'app': 'presssure',
          'appVersion': appVersion,
          'exportedAt': DateTime.now().toIso8601String(),
        }),
      ),
    );
    await exportFolder.create(recursive: true);
    final stamp = DateTime.now().toIso8601String().substring(0, 16);
    final zip = File(
      '${exportFolder.path}/presssure_letture_${stamp.replaceAll(RegExp('[^0-9]'), '')}.zip',
    );
    await zip.writeAsBytes(ZipEncoder().encodeBytes(archive));
    return zip;
  }

  @override
  Future<void> clear() async {
    if (await folder.exists()) await folder.delete(recursive: true);
  }
}
