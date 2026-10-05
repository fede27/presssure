import 'ocr_engine.dart';

/// One box found by the seven-segment detector: a digit (class 0-9) or a
/// whole number (class [numberClass]), with the model's confidence.
class Detection {
  const Detection(this.cls, this.confidence, this.box);

  final int cls;
  final double confidence;
  final OcrBox box;

  bool get isDigit => cls >= 0 && cls <= 9;

  Map<String, Object?> toJson() => {
    'cls': cls,
    'conf': confidence,
    'box': box.toJson(),
  };

  factory Detection.fromJson(Map<String, Object?> json) => Detection(
    json['cls']! as int,
    (json['conf']! as num).toDouble(),
    OcrBox.fromJson((json['box']! as List).cast()),
  );

  @override
  String toString() => 'Detection($cls, $confidence, $box)';
}

/// The detector's class for a box around a whole number.
const numberClass = 10;

/// Confidence of a number with fewer digits than its box has room for:
/// a digit was probably missed (a faint leading "1" makes 163 into 63).
const missingDigitConfidence = 0.5;

/// Turns digit boxes into number tokens for `ReadingParser`.
///
/// Digits inside a number box form that number, left to right; digits
/// outside any number box are joined with their neighbours on the same
/// row. The confidence of a number is the lowest of its digits.
List<OcrToken> groupDigits(List<Detection> detections) {
  final digits = _dedup(detections.where((d) => d.isDigit).toList());
  final numbers = detections.where((d) => d.cls == numberClass).toList()
    ..sort((a, b) => b.confidence.compareTo(a.confidence));

  final used = <Detection>{};
  final tokens = <OcrToken>[];
  for (final number in numbers) {
    final area = _grow(number.box, 0.1);
    final inside = digits
        .where((d) => !used.contains(d) && _contains(area, d.box))
        .toList();
    if (inside.isEmpty) continue;
    used.addAll(inside);
    tokens.add(_token(inside, number.box));
  }

  // Digits the detector did not put in a number box.
  final rest = digits.where((d) => !used.contains(d)).toList()
    ..sort((a, b) => a.box.left.compareTo(b.box.left));
  final groups = <List<Detection>>[];
  for (final d in rest) {
    final group = groups.where((g) => _follows(g.last, d)).firstOrNull;
    if (group == null) {
      groups.add([d]);
    } else {
      group.add(d);
    }
  }
  for (final g in groups) {
    tokens.add(_token(g, null));
  }
  return tokens;
}

/// The same digit found twice (overlapping boxes): the surer one stays.
List<Detection> _dedup(List<Detection> digits) {
  final sorted = [...digits]
    ..sort((a, b) => b.confidence.compareTo(a.confidence));
  final kept = <Detection>[];
  for (final d in sorted) {
    if (kept.every((k) => _overlap(k.box, d.box) < 0.6)) kept.add(d);
  }
  return kept;
}

OcrToken _token(List<Detection> digits, OcrBox? numberBox) {
  digits.sort((a, b) => a.box.centerX.compareTo(b.box.centerX));
  final box =
      numberBox ?? digits.map((d) => d.box).reduce((a, b) => a.union(b));
  var confidence = digits
      .map((d) => d.confidence)
      .reduce((a, b) => a < b ? a : b);
  if (numberBox != null && _roomFor(numberBox, digits) > digits.length) {
    confidence = confidence < missingDigitConfidence
        ? confidence
        : missingDigitConfidence;
  }
  return OcrToken(
    digits.map((d) => '${d.cls}').join(),
    box,
    confidence: confidence,
  );
}

/// How many digits fit in [numberBox], judging from the width of the
/// digits found ("1" is narrow on a seven-segment display: not used).
int _roomFor(OcrBox numberBox, List<Detection> digits) {
  final wide = digits.where((d) => d.cls != 1).map((d) => d.box.width).toList()
    ..sort();
  if (wide.isEmpty) return digits.length;
  final width = wide[wide.length ~/ 2];
  // Digits plus the gap between them: about 1.2 digit widths each.
  return ((numberBox.width + 0.2 * width) / (1.2 * width)).floor();
}

/// [b] continues the number ending with [a]: same row and size, close by.
bool _follows(Detection a, Detection b) {
  final h = (a.box.height + b.box.height) / 2;
  final ratio = a.box.height < b.box.height
      ? a.box.height / b.box.height
      : b.box.height / a.box.height;
  final gap = b.box.left - a.box.right;
  return ratio >= 0.7 &&
      a.box.verticalOverlap(b.box) >= 0.6 &&
      gap > -0.2 * h &&
      gap < 0.8 * h;
}

OcrBox _grow(OcrBox b, double share) => OcrBox(
  b.left - b.width * share,
  b.top - b.height * share,
  b.width * (1 + 2 * share),
  b.height * (1 + 2 * share),
);

bool _contains(OcrBox area, OcrBox box) =>
    box.centerX >= area.left &&
    box.centerX <= area.right &&
    box.centerY >= area.top &&
    box.centerY <= area.bottom;

/// Shared area as a share of the smaller box: a narrow "1" found inside a
/// "7" is the same digit read twice.
double _overlap(OcrBox a, OcrBox b) {
  final w =
      (a.right < b.right ? a.right : b.right) -
      (a.left > b.left ? a.left : b.left);
  final h =
      (a.bottom < b.bottom ? a.bottom : b.bottom) -
      (a.top > b.top ? a.top : b.top);
  if (w <= 0 || h <= 0) return 0;
  final smaller = a.width * a.height < b.width * b.height
      ? a.width * a.height
      : b.width * b.height;
  return w * h / smaller;
}
