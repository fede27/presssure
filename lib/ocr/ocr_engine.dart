/// The swappable part of reading the display: an OCR engine turns a photo
/// into pieces of text with their position. Which number is the systolic,
/// the diastolic or the pulse is decided afterwards by `ReadingParser`, the
/// same for every engine.
library;

/// A photo of the display, as an encoded image file (JPEG or PNG).
class OcrImage {
  const OcrImage(this.path);

  final String path;

  @override
  String toString() => 'OcrImage($path)';
}

/// Axis-aligned box in image pixels, origin at the top left.
class OcrBox {
  const OcrBox(this.left, this.top, this.width, this.height);

  final double left;
  final double top;
  final double width;
  final double height;

  double get right => left + width;
  double get bottom => top + height;
  double get centerX => left + width / 2;
  double get centerY => top + height / 2;

  /// Height shared with [other], as a share of the shorter of the two.
  double verticalOverlap(OcrBox other) {
    final shared =
        (bottom < other.bottom ? bottom : other.bottom) -
        (top > other.top ? top : other.top);
    final shorter = height < other.height ? height : other.height;
    return shorter <= 0 ? 0 : (shared / shorter).clamp(0, 1).toDouble();
  }

  OcrBox union(OcrBox other) {
    final l = left < other.left ? left : other.left;
    final t = top < other.top ? top : other.top;
    final r = right > other.right ? right : other.right;
    final b = bottom > other.bottom ? bottom : other.bottom;
    return OcrBox(l, t, r - l, b - t);
  }

  /// The slice from [from] to [to] (0..1) of the width, e.g. one word of a
  /// line when the engine gives only the line box.
  OcrBox horizontalSlice(double from, double to) =>
      OcrBox(left + width * from, top, width * (to - from), height);

  List<double> toJson() => [left, top, width, height];

  factory OcrBox.fromJson(List<Object?> json) => OcrBox(
    (json[0]! as num).toDouble(),
    (json[1]! as num).toDouble(),
    (json[2]! as num).toDouble(),
    (json[3]! as num).toDouble(),
  );

  @override
  String toString() => 'OcrBox($left, $top, $width × $height)';
}

/// A piece of text found in the photo: usually a word or a number.
class OcrToken {
  const OcrToken(this.text, this.box, {this.confidence});

  final String text;
  final OcrBox box;

  /// 0..1, when the engine gives one.
  final double? confidence;

  Map<String, Object?> toJson() => {
    'text': text,
    'box': box.toJson(),
    if (confidence != null) 'confidence': confidence,
  };

  factory OcrToken.fromJson(Map<String, Object?> json) => OcrToken(
    json['text']! as String,
    OcrBox.fromJson((json['box']! as List).cast()),
    confidence: (json['confidence'] as num?)?.toDouble(),
  );

  @override
  String toString() => 'OcrToken("$text", $box, $confidence)';
}

/// Everything an engine found in one photo. Serializable, so that the
/// output of a real engine on the phone can be recorded once and replayed
/// in the parser tests on the computer.
class OcrResult {
  const OcrResult({required this.engine, required this.tokens});

  /// [OcrEngine.id] of the engine that produced it.
  final String engine;
  final List<OcrToken> tokens;

  Map<String, Object?> toJson() => {
    'engine': engine,
    'tokens': tokens.map((t) => t.toJson()).toList(),
  };

  factory OcrResult.fromJson(Map<String, Object?> json) => OcrResult(
    engine: json['engine']! as String,
    tokens: (json['tokens']! as List)
        .map((t) => OcrToken.fromJson((t as Map).cast()))
        .toList(),
  );
}

/// An OCR engine: ML Kit, Tesseract, a custom neural network...
abstract interface class OcrEngine {
  /// Short stable name, e.g. "mlkit"; used in recordings and reports.
  String get id;

  Future<OcrResult> recognize(OcrImage image);

  /// Frees native resources.
  Future<void> dispose();
}
