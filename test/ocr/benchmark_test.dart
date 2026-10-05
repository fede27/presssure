import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:presssure/ocr/benchmark.dart';
import 'package:presssure/ocr/ocr_engine.dart';

/// A display reading [sys]/[dia] with pulse [pulse], each with a confidence.
Recording rec(
  String sample,
  ExpectedReading expected, {
  required String sys,
  required String dia,
  String? pulse,
  double sysConf = 0.95,
  double diaConf = 0.95,
  double pulseConf = 0.95,
  int? ms,
}) => Recording(
  sample: sample,
  expected: expected,
  elapsedMs: ms,
  ocr: OcrResult(
    engine: 'test',
    tokens: [
      OcrToken(sys, const OcrBox(300, 150, 470, 260), confidence: sysConf),
      OcrToken(dia, const OcrBox(456, 480, 300, 250), confidence: diaConf),
      if (pulse != null)
        OcrToken(
          pulse,
          const OcrBox(600, 800, 144, 120),
          confidence: pulseConf,
        ),
    ],
  ),
);

const _design = ExpectedReading(124, 77, pulse: 68);

void main() {
  test('every outcome of a value', () {
    final perfect = SampleResult.parse(
      rec('a', _design, sys: '124', dia: '77', pulse: '68'),
    );
    expect(perfect.perfect, isTrue);
    expect(perfect.outcome(Field.systolic), FieldOutcome.sureRight);

    final toCheck = SampleResult.parse(
      rec('b', _design, sys: '124', dia: '77', pulse: '68', pulseConf: 0.4),
    );
    expect(toCheck.outcome(Field.pulse), FieldOutcome.unsureRight);
    expect((toCheck.perfect, toCheck.allRight), (false, true));

    final caught = SampleResult.parse(
      rec('c', _design, sys: '124', dia: '71', pulse: '68', diaConf: 0.4),
    );
    expect(caught.outcome(Field.diastolic), FieldOutcome.unsureWrong);
    expect(caught.hasSilentError, isFalse);

    final silent = SampleResult.parse(
      rec('d', _design, sys: '124', dia: '71', pulse: '68'),
    );
    expect(silent.outcome(Field.diastolic), FieldOutcome.silentError);
    expect(silent.hasSilentError, isTrue);

    final noPulse = SampleResult.parse(
      rec('e', _design, sys: '124', dia: '77'),
    );
    expect(noPulse.outcome(Field.pulse), FieldOutcome.missing);
  });

  test('a pulse not labelled is not judged', () {
    final r = SampleResult.parse(
      rec(
        'a',
        const ExpectedReading(124, 77),
        sys: '124',
        dia: '77',
        pulse: '68',
      ),
    );
    expect(r.outcome(Field.pulse), isNull);
    expect(r.perfect, isTrue);
  });

  test('nothing read', () {
    final r = SampleResult.parse(
      Recording(
        sample: 'x',
        expected: _design,
        ocr: const OcrResult(engine: 'test', tokens: []),
      ),
    );
    expect(r.notRead, isTrue);
    expect(r.outcome(Field.systolic), FieldOutcome.missing);
    expect(r.readText, '–');
  });

  test('report: totals, latency and the photos to look at', () {
    final report = BenchmarkReport('test', [
      SampleResult.parse(
        rec('ok', _design, sys: '124', dia: '77', pulse: '68', ms: 100),
      ),
      SampleResult.parse(
        rec(
          'check',
          _design,
          sys: '124',
          dia: '77',
          pulse: '68',
          pulseConf: 0.4,
          ms: 200,
        ),
      ),
      SampleResult.parse(
        rec('wrong', _design, sys: '124', dia: '71', pulse: '68', ms: 900),
      ),
    ]);
    expect(report.total, 3);
    expect(report.perfect, 1);
    expect(report.allRight, 2);
    expect(report.silentErrors, 1);
    expect(report.latency(0.5), 200);
    expect(report.latency(0.95), 900);
    expect(report.count(Field.diastolic, FieldOutcome.silentError), 1);

    final md = report.toMarkdown();
    expect(md, contains('| **Silent errors** | **1** | 33% |'));
    // Silent errors are listed first and in bold.
    expect(md.indexOf('**wrong**'), lessThan(md.indexOf('| check |')));
    expect(md, contains('124/71 (68)'));
    expect(md, contains('124/77 (68?)'));

    final json = report.toJson();
    expect(json['silentErrors'], 1);
    expect((json['fields'] as Map)['pulse'], containsPair('unsureRight', 1));
  });

  test('recordings and labels survive a JSON round trip', () {
    final r = rec(
      'photo/1',
      _design,
      sys: '124',
      dia: '77',
      pulse: '68',
      ms: 42,
    );
    final back = Recording.fromJson(
      (jsonDecode(jsonEncode(r.toJson())) as Map).cast(),
    );
    expect(back.sample, 'photo/1');
    expect(back.expected.toString(), '124/77 (68)');
    expect(back.elapsedMs, 42);
    expect(back.ocr.tokens.first.text, '124');

    const labelled = ExpectedReading(130, 85, notes: 'riflesso');
    expect(labelled.toJson(), {'sys': 130, 'dia': 85, 'notes': 'riflesso'});
    expect(ExpectedReading.fromJson(labelled.toJson()).notes, 'riflesso');
  });
}
