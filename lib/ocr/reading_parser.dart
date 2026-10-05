import 'ocr_engine.dart';

/// A value read from the photo, with how much to trust it.
class ReadValue {
  const ReadValue(this.value, this.confidence);

  final int value;

  /// 0..1: the engine's confidence, lowered when the parser had to guess.
  final double confidence;

  /// Sure enough to be shown as "Letto con sicurezza"; otherwise the user
  /// is asked to compare it with the display.
  bool get isSure => confidence >= ReadingParser.sureThreshold;

  @override
  String toString() => '$value (${confidence.toStringAsFixed(2)})';
}

/// Systolic, diastolic and (when found) pulse read from a photo.
class ParsedReading {
  const ParsedReading({
    required this.systolic,
    required this.diastolic,
    this.pulse,
  });

  final ReadValue systolic;
  final ReadValue diastolic;
  final ReadValue? pulse;

  @override
  String toString() => 'ParsedReading($systolic / $diastolic, pulse $pulse)';
}

/// A number found on the display, before deciding what it is.
class _Candidate {
  _Candidate(this.digits, this.box, this.confidence, {this.guessed = false});

  final String digits;
  final OcrBox box;
  final double confidence;

  /// Letters were read as digits ("l24").
  final bool guessed;

  int get value => int.parse(digits);
  double get height => box.height;

  @override
  String toString() => '_Candidate($digits, $box)';
}

/// Turns what an OCR engine found into a blood pressure reading.
///
/// Engine-independent: it knows how home monitors lay out their display.
/// The two biggest numbers are systolic and diastolic (top one first, or
/// left one when side by side), a smaller one is the pulse. Labels, time,
/// date and decimals are ignored, and letters that look like digits on a
/// seven-segment display are read as digits, with a lower confidence.
class ReadingParser {
  const ReadingParser();

  /// Confidence from which a value counts as sure.
  static const sureThreshold = 0.8;

  /// Confidence given to values the parser had to guess.
  static const guessedConfidence = 0.6;

  static const systolicRange = (min: 60, max: 260);
  static const diastolicRange = (min: 30, max: 160);
  static const pulseRange = (min: 30, max: 220);

  /// Words printed next to the numbers, removed before reading them.
  static final _labels = RegExp(
    r'mmhg|kpa|bpm|/min|pulse|puls|pul|sys|dia|mem|avg|am|pm',
    caseSensitive: false,
  );

  /// Characters an engine may return for a seven-segment digit.
  static const _lookalikes = {
    'O': '0', 'o': '0', 'D': '0', 'Q': '0', //
    'I': '1', 'l': '1', '|': '1', 'i': '1', '!': '1', //
    'Z': '2', 'z': '2', //
    'S': '5', 's': '5', //
    'b': '6', 'G': '6', //
    'B': '8', //
    'g': '9', 'q': '9',
  };

  ParsedReading? parse(OcrResult result) {
    final candidates = _join(result.tokens.expand(_candidatesOf).toList())
        .where((c) => c.digits.length >= 2 && c.digits.length <= 3)
        .where((c) => c.value >= pulseRange.min && c.value <= systolicRange.max)
        .toList();
    if (candidates.length < 2) return null;

    final pairs = _pairs(candidates);
    if (pairs.isEmpty) return null;
    // Among the most prominent pairs the display order decides: with three
    // numbers of the same size, systolic and diastolic come first.
    final prominent =
        pairs.where((p) => p.score >= 0.85 * pairs.first.score).toList()
          ..sort((x, y) {
            if (!identical(x.sys, y.sys)) return _before(x.sys, y.sys) ? -1 : 1;
            if (!identical(x.dia, y.dia)) return _before(x.dia, y.dia) ? -1 : 1;
            return 0;
          });
    final best = prominent.first;
    var sysConfidence = _confidenceOf(best.sys);
    var diaConfidence = _confidenceOf(best.dia);

    // Pulse pressure (the difference) outside what is plausible.
    final gap = best.sys.value - best.dia.value;
    if (gap < 10 || gap > 150) {
      sysConfidence = _atMost(sysConfidence, guessedConfidence);
      diaConfidence = _atMost(diaConfidence, guessedConfidence);
    }

    // Monitors show three numbers. With only two, one was missed and the
    // two found may not be systolic and diastolic: a missed systolic turns
    // diastolic and pulse into a plausible 81/70.
    final pulse = _pulse(candidates, best);
    if (pulse == null) {
      sysConfidence = _atMost(sysConfidence, guessedConfidence);
      diaConfidence = _atMost(diaConfidence, guessedConfidence);
    }

    return ParsedReading(
      systolic: ReadValue(best.sys.value, sysConfidence),
      diastolic: ReadValue(best.dia.value, diaConfidence),
      pulse: pulse,
    );
  }

  /// Numbers in a token: labels removed, lookalike letters mapped.
  Iterable<_Candidate> _candidatesOf(OcrToken token) sync* {
    final confidence = token.confidence ?? 1;
    final text = token.text.trim();
    if (text.isEmpty) return;
    final words = text.split(RegExp(r'\s+'));
    var offset = 0;
    for (final word in words) {
      final start = text.indexOf(word, offset);
      offset = start + word.length;
      final box = words.length == 1
          ? token.box
          : token.box.horizontalSlice(
              start / text.length,
              (start + word.length) / text.length,
            );
      yield* _candidatesOfWord(word, box, confidence);
    }
  }

  Iterable<_Candidate> _candidatesOfWord(
    String word,
    OcrBox box,
    double confidence,
  ) sync* {
    // Times (07:42) and decimals (16.5 kPa, 36,6 °C) are never a reading.
    if (word.contains(RegExp(r'[:.,]'))) return;
    final cleaned = word.replaceAll(_labels, '');
    if (cleaned.isEmpty) return;

    // "124/77" on one line; any other slash is a date.
    final slash = RegExp(r'^(\d{2,3})/(\d{2,3})$').firstMatch(cleaned);
    if (slash != null) {
      final split = slash.group(1)!.length / cleaned.length;
      yield _Candidate(
        slash.group(1)!,
        box.horizontalSlice(0, split),
        confidence,
      );
      yield _Candidate(
        slash.group(2)!,
        box.horizontalSlice(split + 1 / cleaned.length, 1),
        confidence,
      );
      return;
    }
    if (cleaned.contains('/')) return;

    // Only words with at least one real digit: "SYS" or "Il" are not numbers.
    if (!cleaned.contains(RegExp(r'\d'))) return;
    var guessed = false;
    final digits = StringBuffer();
    for (final ch in cleaned.split('')) {
      if (RegExp(r'\d').hasMatch(ch)) {
        digits.write(ch);
      } else if (_lookalikes.containsKey(ch)) {
        digits.write(_lookalikes[ch]);
        guessed = true;
      } else {
        return; // Other letters: a word, not a number.
      }
    }
    yield _Candidate(digits.toString(), box, confidence, guessed: guessed);
  }

  /// Joins pieces of one number split by the engine, e.g. "1" and "24"
  /// when the gap between segments looks like a space.
  List<_Candidate> _join(List<_Candidate> candidates) {
    final sorted = [...candidates]
      ..sort((a, b) => a.box.left.compareTo(b.box.left));
    final result = <_Candidate>[];
    for (final c in sorted) {
      final i = result.indexWhere((prev) => _adjacent(prev, c));
      if (i < 0) {
        result.add(c);
        continue;
      }
      final prev = result[i];
      result[i] = _Candidate(
        prev.digits + c.digits,
        prev.box.union(c.box),
        prev.confidence < c.confidence ? prev.confidence : c.confidence,
        guessed: prev.guessed || c.guessed,
      );
    }
    return result;
  }

  bool _adjacent(_Candidate a, _Candidate b) {
    if (a.digits.length + b.digits.length > 3) return false;
    final ratio = a.height < b.height
        ? a.height / b.height
        : b.height / a.height;
    if (ratio < 0.8 || a.box.verticalOverlap(b.box) < 0.7) return false;
    final gap = b.box.left - a.box.right;
    final avg = (a.height + b.height) / 2;
    return gap > -0.1 * avg && gap < 0.35 * avg;
  }

  /// Whether [a] comes before [b] reading the display: side by side on
  /// the same row, left first; otherwise top first.
  bool _before(_Candidate a, _Candidate b) {
    if (a.box.verticalOverlap(b.box) > 0.5) return a.box.left < b.box.left;
    return a.box.centerY < b.box.centerY;
  }

  /// Plausible systolic/diastolic pairs, the most prominent first.
  List<({_Candidate sys, _Candidate dia, double score})> _pairs(
    List<_Candidate> candidates,
  ) {
    final bySize = [...candidates]
      ..sort((a, b) => b.height.compareTo(a.height));
    final top = bySize.take(4).toList();
    final pairs = <({_Candidate sys, _Candidate dia, double score})>[];
    for (final a in top) {
      for (final b in top) {
        if (identical(a, b) || !_before(a, b)) continue;
        if (a.value < systolicRange.min || a.value > systolicRange.max) {
          continue;
        }
        if (b.value < diastolicRange.min || b.value > diastolicRange.max) {
          continue;
        }
        if (a.value <= b.value) continue;
        final ratio = a.height < b.height
            ? a.height / b.height
            : b.height / a.height;
        if (ratio < 0.6) continue;
        pairs.add((sys: a, dia: b, score: a.height + b.height));
      }
    }
    pairs.sort((x, y) => y.score.compareTo(x.score));
    return pairs;
  }

  /// The biggest remaining number in the pulse range, if any: usually
  /// smaller than the other two, below them or on their right.
  ReadValue? _pulse(
    List<_Candidate> candidates,
    ({_Candidate sys, _Candidate dia, double score}) pair,
  ) {
    final options =
        candidates
            .where((c) => !identical(c, pair.sys) && !identical(c, pair.dia))
            .where(
              (c) => c.value >= pulseRange.min && c.value <= pulseRange.max,
            )
            .where((c) => !_before(c, pair.sys))
            .where(
              (c) =>
                  c.height >= 0.25 * pair.sys.height &&
                  // Some monitors show the pulse even bigger than the rest.
                  c.height <= 1.5 * pair.sys.height,
            )
            .toList()
          ..sort((a, b) => b.height.compareTo(a.height));
    if (options.isEmpty) return null;
    final pulse = options.first;
    var confidence = _confidenceOf(pulse);
    // Two numbers of the same size could both be the pulse.
    if (options.length > 1 && options[1].height >= 0.9 * pulse.height) {
      confidence = _atMost(confidence, guessedConfidence);
    }
    return ReadValue(pulse.value, confidence);
  }

  double _confidenceOf(_Candidate c) =>
      c.guessed ? _atMost(c.confidence, guessedConfidence) : c.confidence;

  static double _atMost(double value, double max) => value < max ? value : max;
}
