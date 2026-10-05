import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'digit_grouping.dart';
import 'ocr_engine.dart';

/// Input and output of the seven-segment detector (a YOLO model trained by
/// tool/ocr_train): plain Dart, so it is tested on the computer.

/// What the model gets: the photo in grayscale, stretched to a square of
/// [size] pixels, as floats 0..1 in three equal channels (NHWC).
class ModelInput {
  const ModelInput(this.pixels, this.width, this.height);

  final Float32List pixels;

  /// Size of the original photo, to map the boxes back onto it.
  final int width;
  final int height;
}

/// [encoded] is a JPEG or PNG. Throws [FormatException] if it is not.
ModelInput modelInput(Uint8List encoded, int size) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(encoded);
  } catch (_) {
    decoded = null;
  }
  if (decoded == null) throw const FormatException('not an image');
  final gray = img.grayscale(img.bakeOrientation(decoded));
  final square = img.copyResize(
    gray,
    width: size,
    height: size,
    interpolation: img.Interpolation.linear,
  );
  final pixels = Float32List(size * size * 3);
  var i = 0;
  for (final p in square) {
    final v = p.luminanceNormalized.toDouble();
    pixels[i++] = v;
    pixels[i++] = v;
    pixels[i++] = v;
  }
  return ModelInput(pixels, decoded.width, decoded.height);
}

/// Boxes from the raw YOLO output: [classes] scores per candidate after
/// the 4 box values (centre x, centre y, width, height in input pixels),
/// laid out as `[1, 4 + classes, candidates]` or transposed. Candidates
/// under [minConfidence] are dropped, then overlapping boxes (non-maximum
/// suppression): digits whatever their class, numbers among themselves.
/// Boxes come back in the pixels of the original photo.
List<Detection> decodeYolo(
  Float32List output,
  List<int> shape, {
  required int inputSize,
  required int imageWidth,
  required int imageHeight,
  int classes = 11,
  double minConfidence = 0.25,
  double maxOverlap = 0.5,
}) {
  final rows = 4 + classes;
  final channelsFirst = shape.length == 3 && shape[1] == rows;
  final count = channelsFirst ? shape[2] : shape[1];
  double at(int row, int candidate) => channelsFirst
      ? output[row * count + candidate]
      : output[candidate * rows + row];

  final sx = imageWidth / inputSize;
  final sy = imageHeight / inputSize;
  final found = <Detection>[];
  for (var c = 0; c < count; c++) {
    var best = 0;
    var score = at(4, c);
    for (var k = 1; k < classes; k++) {
      final s = at(4 + k, c);
      if (s > score) {
        score = s;
        best = k;
      }
    }
    if (score < minConfidence) continue;
    // Some exports give the box in 0..1 instead of input pixels.
    var scale = 1.0;
    if (at(2, c) <= 1.5 && at(3, c) <= 1.5) scale = inputSize.toDouble();
    final w = at(2, c) * scale;
    final h = at(3, c) * scale;
    final x = at(0, c) * scale - w / 2;
    final y = at(1, c) * scale - h / 2;
    found.add(Detection(best, score, OcrBox(x * sx, y * sy, w * sx, h * sy)));
  }

  found.sort((a, b) => b.confidence.compareTo(a.confidence));
  final kept = <Detection>[];
  for (final d in found) {
    final clash = kept.any(
      (k) => k.isDigit == d.isDigit && _iou(k.box, d.box) > maxOverlap,
    );
    if (!clash) kept.add(d);
  }
  return kept;
}

double _iou(OcrBox a, OcrBox b) {
  final w =
      (a.right < b.right ? a.right : b.right) -
      (a.left > b.left ? a.left : b.left);
  final h =
      (a.bottom < b.bottom ? a.bottom : b.bottom) -
      (a.top > b.top ? a.top : b.top);
  if (w <= 0 || h <= 0) return 0;
  final inter = w * h;
  return inter / (a.width * a.height + b.width * b.height - inter);
}
