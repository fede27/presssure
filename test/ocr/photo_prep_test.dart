import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:presssure/ocr/photo_prep.dart';

Uint8List png(int width, int height) =>
    img.encodePng(img.Image(width: width, height: height));

img.Image decode(Uint8List bytes) => img.decodeImage(bytes)!;

void expectRect(Rect actual, Rect expected) {
  for (final (a, e) in [
    (actual.left, expected.left),
    (actual.top, expected.top),
    (actual.right, expected.right),
    (actual.bottom, expected.bottom),
  ]) {
    expect(a, closeTo(e, 1e-9), reason: '$actual vs $expected');
  }
}

void main() {
  group('crop for the frame', () {
    test('preview exactly as big as the viewport', () {
      final crop = cropForFrame(
        viewport: const Size(360, 480),
        previewAspect: 0.75,
        frame: const Rect.fromLTRB(90, 120, 270, 360),
        margin: 0,
      );
      expectRect(crop, const Rect.fromLTRB(0.25, 0.25, 0.75, 0.75));
    });

    test('preview taller than the viewport: cut at top and bottom', () {
      // Drawn 400 × 533.3, so 66.7 px hidden above the viewport.
      final crop = cropForFrame(
        viewport: const Size(400, 400),
        previewAspect: 0.75,
        frame: const Rect.fromLTRB(150, 150, 250, 250),
        margin: 0,
      );
      final drawnH = 400 / 0.75;
      final dy = (drawnH - 400) / 2;
      expectRect(
        crop,
        Rect.fromLTRB(0.375, (150 + dy) / drawnH, 0.625, (250 + dy) / drawnH),
      );
    });

    test('preview wider than the viewport: cut at the sides', () {
      // Drawn 600 × 800 in a 300 × 800 viewport.
      final crop = cropForFrame(
        viewport: const Size(300, 800),
        previewAspect: 0.75,
        frame: const Rect.fromLTRB(0, 0, 300, 800),
        margin: 0,
      );
      expectRect(crop, const Rect.fromLTRB(0.25, 0, 0.75, 1));
    });

    test('the margin grows the crop but stays inside the photo', () {
      final crop = cropForFrame(
        viewport: const Size(360, 480),
        previewAspect: 0.75,
        frame: const Rect.fromLTRB(0, 120, 180, 360),
        margin: 0.1,
      );
      expect(crop.left, 0);
      expect(crop.top, lessThan(0.25));
      expect(crop.right, greaterThan(0.5));
    });
  });

  group('prepare for OCR', () {
    test('cropped to the fractions given', () {
      final out = decode(
        prepareForOcr(
          png(400, 300),
          crop: const Rect.fromLTRB(0.25, 0.25, 0.75, 0.75),
        ),
      );
      expect((out.width, out.height), (200, 150));
    });

    test('the longer side is reduced, keeping the proportions', () {
      final wide = decode(prepareForOcr(png(2000, 500), maxSide: 1000));
      expect((wide.width, wide.height), (1000, 250));
      final tall = decode(prepareForOcr(png(300, 1200), maxSide: 600));
      expect((tall.width, tall.height), (150, 600));
    });

    test('small photos keep their size and become JPEG', () {
      final bytes = prepareForOcr(png(320, 240));
      expect(bytes.sublist(0, 2), [0xFF, 0xD8]); // JPEG signature
      expect(decode(bytes).width, 320);
    });

    test('not an image', () {
      expect(
        () => prepareForOcr(Uint8List.fromList([1, 2, 3])),
        throwsFormatException,
      );
    });
  });
}
