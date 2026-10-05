import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:presssure/ocr/ocr_engine.dart';
import 'package:presssure/ocr/reading_parser.dart';

/// A token of [text] at [left], [top] with digit height [h]; digits are
/// about 0.6 × h wide.
OcrToken tok(
  String text,
  double left,
  double top,
  double h, {
  double? confidence = 0.95,
}) => OcrToken(
  text,
  OcrBox(left, top, text.length * h * 0.6, h),
  confidence: confidence,
);

ParsedReading? parse(List<OcrToken> tokens) =>
    const ReadingParser().parse(OcrResult(engine: 'test', tokens: tokens));

/// Typical home monitor: systolic on top, diastolic below, same size; a
/// smaller pulse at the bottom right; labels, time and memory around.
List<OcrToken> classic({
  String sys = '124',
  String dia = '77',
  String? pulse = '68',
  double? confidence = 0.95,
}) => [
  tok('SYS', 40, 180, 40),
  tok('mmHg', 40, 230, 30),
  tok(sys, 300, 150, 260, confidence: confidence),
  tok('DIA', 40, 520, 40),
  tok(dia, 456, 480, 250, confidence: confidence),
  if (pulse != null) ...[
    tok('PUL/min', 40, 840, 30),
    tok(pulse, 600, 800, 120, confidence: confidence),
  ],
  tok('07:42', 60, 40, 60),
  tok('M', 900, 40, 50),
];

void expectReading(
  ParsedReading? r,
  int sys,
  int dia, {
  int? pulse,
  bool sure = true,
}) {
  expect(r, isNotNull);
  expect((r!.systolic.value, r.diastolic.value), (sys, dia));
  expect(r.pulse?.value, pulse);
  expect(r.systolic.isSure, sure, reason: 'systolic ${r.systolic}');
  expect(r.diastolic.isSure, sure, reason: 'diastolic ${r.diastolic}');
}

void main() {
  group('layouts', () {
    test('stacked: systolic, diastolic, smaller pulse', () {
      final r = parse(classic());
      expectReading(r, 124, 77, pulse: 68);
      expect(r!.pulse!.isSure, isTrue);
    });

    test('the order of the tokens from the engine does not matter', () {
      expectReading(parse(classic().reversed.toList()), 124, 77, pulse: 68);
    });

    test('side by side: systolic on the left', () {
      final r = parse([
        tok('135', 40, 200, 200),
        tok('85', 560, 205, 200),
        tok('72', 560, 500, 90),
      ]);
      expectReading(r, 135, 85, pulse: 72);
    });

    test('three numbers of the same size, one per row', () {
      final r = parse([
        tok('118', 100, 100, 200),
        tok('76', 220, 360, 200),
        tok('64', 220, 620, 200),
      ]);
      expectReading(r, 118, 76, pulse: 64);
    });

    test('pulse missing: a number was missed, the others are to check', () {
      expectReading(parse(classic(pulse: null)), 124, 77, sure: false);
    });

    test('systolic and diastolic on one line with a slash', () {
      final r = parse([tok('124/77', 50, 100, 120), tok('68', 50, 300, 60)]);
      expectReading(r, 124, 77, pulse: 68);
    });

    test('words and numbers in one token', () {
      final r = parse([
        const OcrToken('SYS 142', OcrBox(0, 0, 700, 200), confidence: 0.9),
        const OcrToken('DIA 91', OcrBox(0, 260, 600, 200), confidence: 0.9),
        const OcrToken('PUL 70', OcrBox(0, 520, 300, 100), confidence: 0.9),
      ]);
      expectReading(r, 142, 91, pulse: 70);
    });
  });

  group('noise is ignored', () {
    test('time, date, year, decimals and memory numbers', () {
      final r = parse([
        ...classic(),
        tok('9/27', 700, 40, 60),
        tok('2026', 700, 100, 40),
        tok('16.5', 700, 1000, 40),
        tok('M12', 900, 100, 50),
      ]);
      expectReading(r, 124, 77, pulse: 68);
    });

    test('numbers out of range are not a reading', () {
      expect(parse([tok('888', 0, 0, 200), tok('12', 0, 300, 200)]), isNull);
    });

    test('too little to read', () {
      expect(parse([]), isNull);
      expect(parse([tok('SYS', 0, 0, 40), tok('mmHg', 0, 60, 40)]), isNull);
      expect(parse([tok('124', 0, 0, 200)]), isNull);
    });

    test('a small pulse-like number above the systolic is not the pulse', () {
      final r = parse([
        tok('88', 700, 20, 60), // e.g. memory count, top right
        ...classic(pulse: null),
      ]);
      expectReading(r, 124, 77, sure: false);
    });
  });

  group('seven-segment lookalikes', () {
    test('letters read as digits give a value to check', () {
      final r = parse(classic(sys: 'l24', dia: '7O'));
      expectReading(r, 124, 70, pulse: 68, sure: false);
      expect(r!.pulse!.isSure, isTrue);
    });

    test('B for 8 and S for 5', () {
      final r = parse(classic(sys: '1B5', dia: '9S'));
      expectReading(r, 185, 95, pulse: 68, sure: false);
    });

    test('a word is not a number', () {
      expect(parse([tok('Il', 0, 0, 200), tok('SYS', 0, 300, 200)]), isNull);
    });
  });

  group('split numbers', () {
    test('a leading 1 separated by a gap is joined', () {
      final r = parse([
        tok('1', 300, 150, 260),
        tok('24', 300 + 156 + 40, 150, 260),
        tok('77', 456, 480, 250),
      ]);
      expectReading(r, 124, 77, sure: false);
    });

    test('numbers far apart on a row stay separate', () {
      final r = parse([tok('135', 40, 200, 200), tok('85', 700, 205, 200)]);
      expectReading(r, 135, 85, sure: false);
    });
  });

  group('confidence', () {
    test('low engine confidence is not sure', () {
      final r = parse(classic(confidence: 0.5));
      expectReading(r, 124, 77, pulse: 68, sure: false);
      expect(r!.pulse!.isSure, isFalse);
    });

    test('engines without confidence count as sure', () {
      expectReading(parse(classic(confidence: null)), 124, 77, pulse: 68);
    });

    test('implausible gap between systolic and diastolic', () {
      expectReading(
        parse(classic(sys: '84', dia: '80')),
        84,
        80,
        pulse: 68,
        sure: false,
      );
    });

    test('two candidates for the pulse of the same size', () {
      final r = parse([
        ...classic(pulse: null),
        tok('68', 600, 800, 120),
        tok('72', 100, 800, 120),
      ]);
      expect(r!.pulse!.isSure, isFalse);
    });
  });

  test('engine results survive a JSON round trip (recordings)', () {
    final result = OcrResult(engine: 'mlkit', tokens: classic());
    final back = OcrResult.fromJson(
      (jsonDecode(jsonEncode(result.toJson())) as Map).cast(),
    );
    expect(back.engine, 'mlkit');
    expect(back.tokens.length, result.tokens.length);
    expect(back.tokens[2].text, '124');
    expect(back.tokens[2].box.height, 260);
    expect(back.tokens[2].confidence, 0.95);
    expectReading(const ReadingParser().parse(back), 124, 77, pulse: 68);
  });
}
