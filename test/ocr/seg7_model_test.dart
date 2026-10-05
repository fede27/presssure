import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:presssure/ocr/digit_grouping.dart';
import 'package:presssure/ocr/seg7_model.dart';

const _classes = 11;
const _rows = 4 + _classes;

/// A raw output `[1, 15, n]` with the given candidates: box in input
/// pixels and the score of one class.
Float32List output(List<(double, double, double, double, int, double)> cands) {
  final n = cands.length;
  final out = Float32List(_rows * n);
  for (var c = 0; c < n; c++) {
    final (x, y, w, h, cls, score) = cands[c];
    out[0 * n + c] = x;
    out[1 * n + c] = y;
    out[2 * n + c] = w;
    out[3 * n + c] = h;
    out[(4 + cls) * n + c] = score;
  }
  return out;
}

/// The same, laid out `[1, n, 15]`.
Float32List transposed(Float32List channelsFirst, int n) {
  final out = Float32List(channelsFirst.length);
  for (var r = 0; r < _rows; r++) {
    for (var c = 0; c < n; c++) {
      out[c * _rows + r] = channelsFirst[r * n + c];
    }
  }
  return out;
}

void main() {
  group('decode', () {
    final cands = [
      (100.0, 50.0, 40.0, 80.0, 7, 0.9), // a 7
      (104.0, 52.0, 38.0, 78.0, 1, 0.6), // the same digit read as 1
      (300.0, 60.0, 200.0, 90.0, numberClass, 0.8), // a number around it
      (200.0, 200.0, 40.0, 80.0, 3, 0.1), // too weak
    ];

    test('boxes back on the photo, weak and duplicate ones dropped', () {
      final d = decodeYolo(
        output(cands),
        [1, _rows, cands.length],
        inputSize: 400,
        imageWidth: 800,
        imageHeight: 1200,
      );
      expect(d.map((x) => x.cls), [7, numberClass]);
      final seven = d.first;
      expect(seven.confidence, closeTo(0.9, 1e-6));
      // Centre 100,50 size 40x80 in a 400 input, photo 800x1200.
      expect(seven.box.left, closeTo((100 - 20) * 2, 1e-3));
      expect(seven.box.top, closeTo((50 - 40) * 3, 1e-3));
      expect(seven.box.width, closeTo(80, 1e-3));
      expect(seven.box.height, closeTo(240, 1e-3));
    });

    test('a number overlapping a digit is kept: they are different things', () {
      final d = decodeYolo(
        output([
          (100.0, 50.0, 40.0, 80.0, 2, 0.9),
          (100.0, 50.0, 44.0, 82.0, numberClass, 0.7),
        ]),
        [1, _rows, 2],
        inputSize: 400,
        imageWidth: 400,
        imageHeight: 400,
      );
      expect(d.map((x) => x.cls), [2, numberClass]);
    });

    test('transposed output, same result', () {
      final channelsFirst = output(cands);
      final a = decodeYolo(
        channelsFirst,
        [1, _rows, cands.length],
        inputSize: 400,
        imageWidth: 400,
        imageHeight: 400,
      );
      final b = decodeYolo(
        transposed(channelsFirst, cands.length),
        [1, cands.length, _rows],
        inputSize: 400,
        imageWidth: 400,
        imageHeight: 400,
      );
      expect(
        b.map((x) => (x.cls, x.box.left)),
        a.map((x) => (x.cls, x.box.left)),
      );
    });

    test('boxes given as 0..1 are scaled to the input', () {
      final d = decodeYolo(
        output([(0.25, 0.125, 0.1, 0.2, 5, 0.9)]),
        [1, _rows, 1],
        inputSize: 400,
        imageWidth: 400,
        imageHeight: 400,
      );
      expect(d.single.box.left, closeTo(100 - 20, 1e-3));
      expect(d.single.box.height, closeTo(80, 1e-3));
    });
  });

  group('input', () {
    test('grayscale, stretched to the square, 0..1 in three channels', () {
      final photo = img.Image(width: 300, height: 100)
        ..clear(img.ColorRgb8(255, 255, 255));
      img.fillRect(
        photo,
        x1: 0,
        y1: 0,
        x2: 149,
        y2: 99,
        color: img.ColorRgb8(0, 0, 0),
      );
      final input = modelInput(img.encodePng(photo), 32);
      expect((input.width, input.height), (300, 100));
      expect(input.pixels.length, 32 * 32 * 3);
      // Left half black, right half white, each pixel in R, G and B.
      expect(input.pixels[0], closeTo(0, 0.05));
      expect(input.pixels[1], input.pixels[0]);
      final lastPixel = (32 * 32 - 1) * 3;
      expect(input.pixels[lastPixel], closeTo(1, 0.05));
    });

    test('not an image', () {
      expect(
        () => modelInput(Uint8List.fromList([1, 2, 3]), 32),
        throwsFormatException,
      );
    });
  });
}
