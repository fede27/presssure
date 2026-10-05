import 'ocr_engine.dart';
import 'reading_parser.dart';

/// What a photo of the test corpus shows, from its `.json` sidecar:
/// `{"sys": 124, "dia": 77, "pulse": 68, "notes": "riflesso"}`.
/// `pulse` may be missing when the display has none or it was not checked.
class ExpectedReading {
  const ExpectedReading(
    this.systolic,
    this.diastolic, {
    this.pulse,
    this.notes,
  });

  final int systolic;
  final int diastolic;
  final int? pulse;

  /// Conditions of the photo, e.g. "riflesso", "buio", "storta".
  final String? notes;

  Map<String, Object?> toJson() => {
    'sys': systolic,
    'dia': diastolic,
    if (pulse != null) 'pulse': pulse,
    if (notes != null && notes!.isNotEmpty) 'notes': notes,
  };

  factory ExpectedReading.fromJson(Map<String, Object?> json) =>
      ExpectedReading(
        json['sys']! as int,
        json['dia']! as int,
        pulse: json['pulse'] as int?,
        notes: json['notes'] as String?,
      );

  @override
  String toString() =>
      '$systolic/$diastolic${pulse == null ? '' : ' ($pulse)'}';
}

/// One engine run on one photo of the corpus: replayable on the computer.
class Recording {
  const Recording({
    required this.sample,
    required this.expected,
    required this.ocr,
    this.elapsedMs,
  });

  /// Path of the photo in the corpus, without extension.
  final String sample;
  final ExpectedReading expected;
  final OcrResult ocr;
  final int? elapsedMs;

  Map<String, Object?> toJson() => {
    'sample': sample,
    'expected': expected.toJson(),
    'ocr': ocr.toJson(),
    if (elapsedMs != null) 'elapsedMs': elapsedMs,
  };

  factory Recording.fromJson(Map<String, Object?> json) => Recording(
    sample: json['sample']! as String,
    expected: ExpectedReading.fromJson((json['expected']! as Map).cast()),
    ocr: OcrResult.fromJson((json['ocr']! as Map).cast()),
    elapsedMs: json['elapsedMs'] as int?,
  );
}

enum Field { systolic, diastolic, pulse }

/// How one value came out, from best to worst.
enum FieldOutcome {
  /// Right and shown as sure.
  sureRight,

  /// Right, but the user is asked to check it.
  unsureRight,

  /// Wrong, but marked to check: the user will notice.
  unsureWrong,

  /// Not read: the user copies it.
  missing,

  /// Wrong and shown as sure: the only error the user may not notice.
  silentError,
}

/// One photo, parsed and compared with what it shows.
class SampleResult {
  SampleResult(this.recording, this.reading);

  factory SampleResult.parse(
    Recording recording, {
    ReadingParser parser = const ReadingParser(),
  }) => SampleResult(recording, parser.parse(recording.ocr));

  final Recording recording;
  final ParsedReading? reading;

  ExpectedReading get expected => recording.expected;

  /// Null for a pulse the photo was not labelled with.
  FieldOutcome? outcome(Field field) {
    final want = switch (field) {
      Field.systolic => expected.systolic,
      Field.diastolic => expected.diastolic,
      Field.pulse => expected.pulse,
    };
    if (want == null) return null;
    final got = switch (field) {
      Field.systolic => reading?.systolic,
      Field.diastolic => reading?.diastolic,
      Field.pulse => reading?.pulse,
    };
    if (got == null) return FieldOutcome.missing;
    if (got.value == want) {
      return got.isSure ? FieldOutcome.sureRight : FieldOutcome.unsureRight;
    }
    return got.isSure ? FieldOutcome.silentError : FieldOutcome.unsureWrong;
  }

  Iterable<FieldOutcome> get _outcomes =>
      Field.values.map(outcome).whereType<FieldOutcome>();

  bool get notRead => reading == null;

  /// Every labelled value right (sure or not).
  bool get allRight => _outcomes.every(
    (o) => o == FieldOutcome.sureRight || o == FieldOutcome.unsureRight,
  );

  /// Every labelled value right and sure: nothing for the user to do.
  bool get perfect => _outcomes.every((o) => o == FieldOutcome.sureRight);

  bool get hasSilentError => _outcomes.contains(FieldOutcome.silentError);

  String get readText {
    final r = reading;
    if (r == null) return '–';
    String v(ReadValue? x) =>
        x == null ? '–' : '${x.value}${x.isSure ? '' : '?'}';
    return '${v(r.systolic)}/${v(r.diastolic)} (${v(r.pulse)})';
  }
}

/// Summary of an engine on the whole corpus.
class BenchmarkReport {
  BenchmarkReport(this.engine, this.samples);

  final String engine;
  final List<SampleResult> samples;

  int get total => samples.length;
  int get perfect => samples.where((s) => s.perfect).length;
  int get allRight => samples.where((s) => s.allRight).length;
  int get notRead => samples.where((s) => s.notRead).length;
  int get silentErrors => samples.where((s) => s.hasSilentError).length;

  int count(Field field, FieldOutcome outcome) =>
      samples.where((s) => s.outcome(field) == outcome).length;

  /// Milliseconds of the engine at the given [percentile] (0..1).
  int? latency(double percentile) {
    final times =
        samples.map((s) => s.recording.elapsedMs).whereType<int>().toList()
          ..sort();
    if (times.isEmpty) return null;
    final i = ((times.length - 1) * percentile).round();
    return times[i];
  }

  static String _percent(int part, int whole) =>
      whole == 0 ? '–' : '${(100 * part / whole).toStringAsFixed(0)}%';

  Map<String, Object?> toJson() => {
    'engine': engine,
    'total': total,
    'perfect': perfect,
    'allRight': allRight,
    'notRead': notRead,
    'silentErrors': silentErrors,
    'latencyP50Ms': latency(0.5),
    'latencyP95Ms': latency(0.95),
    'fields': {
      for (final f in Field.values)
        f.name: {for (final o in FieldOutcome.values) o.name: count(f, o)},
    },
  };

  /// Readable report: summary, per field, and every photo not perfect.
  String toMarkdown() {
    final b = StringBuffer()
      ..writeln('# OCR benchmark · $engine')
      ..writeln()
      ..writeln('| | Photos | Share |')
      ..writeln('|---|---:|---:|')
      ..writeln('| Total | $total | |')
      ..writeln(
        '| Perfect (all right and sure) | $perfect | ${_percent(perfect, total)} |',
      )
      ..writeln(
        '| All right (some to check) | $allRight | ${_percent(allRight, total)} |',
      )
      ..writeln('| Not read | $notRead | ${_percent(notRead, total)} |')
      ..writeln(
        '| **Silent errors** | **$silentErrors** | ${_percent(silentErrors, total)} |',
      )
      ..writeln()
      ..writeln(
        'Engine time: median ${latency(0.5) ?? '–'} ms, 95th percentile ${latency(0.95) ?? '–'} ms.',
      )
      ..writeln()
      ..writeln(
        '| Field | Sure, right | To check, right | To check, wrong | Missing | Silent error |',
      )
      ..writeln('|---|---:|---:|---:|---:|---:|');
    for (final f in Field.values) {
      b.writeln(
        '| ${f.name} | ${FieldOutcome.values.map((o) => count(f, o)).join(' | ')} |',
      );
    }
    final failures = samples.where((s) => !s.perfect).toList();
    if (failures.isNotEmpty) {
      b
        ..writeln()
        ..writeln('## Photos not perfect')
        ..writeln()
        ..writeln('`?` = shown as "to check". Silent errors first.')
        ..writeln()
        ..writeln('| Photo | Expected | Read | Notes |')
        ..writeln('|---|---|---|---|');
      failures.sort(
        (a, b) => (b.hasSilentError ? 1 : 0) - (a.hasSilentError ? 1 : 0),
      );
      for (final s in failures) {
        b.writeln(
          '| ${s.hasSilentError ? '**${s.recording.sample}**' : s.recording.sample} '
          '| ${s.expected} | ${s.readText} | ${s.expected.notes ?? ''} |',
        );
      }
    }
    return b.toString();
  }
}
