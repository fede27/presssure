import 'ocr_engine.dart';

/// Engine that returns prepared results: for tests, and to try the scan
/// flow without a camera.
class FakeOcrEngine implements OcrEngine {
  /// Always answers [result].
  FakeOcrEngine(OcrResult result) : _answer = ((_) => result);

  /// Answers per photo, e.g. from a map of recordings.
  FakeOcrEngine.using(OcrResult Function(OcrImage image) answer)
    : _answer = answer;

  final OcrResult Function(OcrImage image) _answer;

  /// Photos received, in order.
  final List<OcrImage> requests = [];

  @override
  String get id => 'fake';

  @override
  Future<OcrResult> recognize(OcrImage image) async {
    requests.add(image);
    return _answer(image);
  }

  @override
  Future<void> dispose() async {}
}
