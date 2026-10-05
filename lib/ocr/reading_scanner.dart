import 'ocr_engine.dart';
import 'reading_parser.dart';

/// What one photo gave: the raw engine output (kept for recordings and
/// diagnostics) and the reading, when one was found.
class ScanResult {
  const ScanResult({required this.raw, required this.reading});

  final OcrResult raw;
  final ParsedReading? reading;
}

/// Engine plus parser: the only entry point the app uses to read a photo,
/// whatever the engine.
class ReadingScanner {
  ReadingScanner(this.engine, {this.parser = const ReadingParser()});

  final OcrEngine engine;
  final ReadingParser parser;

  Future<ScanResult> scan(OcrImage image) async {
    final raw = await engine.recognize(image);
    return ScanResult(raw: raw, reading: parser.parse(raw));
  }
}
