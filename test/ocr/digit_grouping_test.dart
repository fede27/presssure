import 'package:flutter_test/flutter_test.dart';
import 'package:presssure/ocr/digit_grouping.dart';
import 'package:presssure/ocr/ocr_engine.dart';
import 'package:presssure/ocr/reading_parser.dart';

/// A digit [d] of height [h] at [left], [top]; "1" is narrow.
Detection digit(
  int d,
  double left,
  double top, {
  double h = 100,
  double conf = 0.95,
}) => Detection(d, conf, OcrBox(left, top, d == 1 ? 0.25 * h : 0.55 * h, h));

Detection number(
  double left,
  double top,
  double w,
  double h, {
  double conf = 0.9,
}) => Detection(numberClass, conf, OcrBox(left, top, w, h));

/// 163 / 79 / 83 laid out like a monitor, digits about 0.65 h apart.
List<Detection> display({bool missingOne = false}) => [
  number(100, 100, 200, 100),
  if (!missingOne) digit(1, 120, 100),
  digit(6, 165, 100),
  digit(3, 230, 100),
  number(165, 230, 135, 100),
  digit(7, 165, 230),
  digit(9, 230, 230),
  number(200, 360, 75, 50),
  digit(8, 205, 360, h: 50),
  digit(3, 240, 360, h: 50),
];

ParsedReading? parse(List<OcrToken> tokens) =>
    const ReadingParser().parse(OcrResult(engine: 'seg7', tokens: tokens));

void main() {
  test('digits inside each number box, left to right', () {
    final tokens = groupDigits(display());
    expect(tokens.map((t) => t.text), ['163', '79', '83']);
    expect(tokens.first.confidence, 0.95);
    final r = parse(tokens)!;
    expect(
      (r.systolic.value, r.diastolic.value, r.pulse!.value),
      (163, 79, 83),
    );
    expect(r.systolic.isSure, isTrue);
  });

  test('the order of the detections does not matter', () {
    final tokens = groupDigits(display().reversed.toList());
    expect(tokens.map((t) => t.text).toSet(), {'163', '79', '83'});
  });

  test('a missed leading 1: the number is not sure', () {
    final tokens = groupDigits(display(missingOne: true));
    final sys = tokens.firstWhere((t) => t.text == '63');
    expect(sys.confidence, missingDigitConfidence);
    // 63 over 79 is no reading: the parser does not make one up.
    final r = parse(tokens);
    expect(r == null || !r.systolic.isSure, isTrue);
  });

  test('the confidence of a number is the lowest of its digits', () {
    final tokens = groupDigits([
      number(0, 0, 200, 100),
      digit(1, 20, 0),
      digit(2, 65, 0, conf: 0.4),
      digit(4, 130, 0),
    ]);
    expect(tokens.single.text, '124');
    expect(tokens.single.confidence, 0.4);
  });

  test('without number boxes, neighbours on the same row are joined', () {
    final tokens = groupDigits([
      digit(1, 20, 0),
      digit(2, 65, 0),
      digit(4, 130, 0),
      digit(7, 20, 150),
      digit(7, 85, 150),
      // Far on the right: another number.
      digit(5, 400, 0),
      digit(5, 465, 0),
    ]);
    expect(tokens.map((t) => t.text).toSet(), {'124', '77', '55'});
  });

  test('the same digit found twice counts once', () {
    final tokens = groupDigits([
      number(0, 0, 140, 100),
      digit(7, 10, 0, conf: 0.9),
      digit(1, 12, 2, conf: 0.3),
      digit(9, 75, 0),
    ]);
    expect(tokens.single.text, '79');
  });

  test('detections survive a JSON round trip', () {
    final d = digit(8, 10, 20, conf: 0.77);
    final back = Detection.fromJson(d.toJson());
    expect((back.cls, back.confidence, back.box.left), (8, 0.77, 10));
  });
}
