import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;

/// The part of the photo inside the on-screen frame, as fractions (0..1)
/// of the photo, with some [margin] around it so a display slightly out of
/// the frame is not cut.
///
/// The preview fills [viewport] like `BoxFit.cover`, keeping its
/// [previewAspect] (width / height, portrait); the photo has the same
/// aspect as the preview. [frame] is in viewport coordinates.
Rect cropForFrame({
  required Size viewport,
  required double previewAspect,
  required Rect frame,
  double margin = 0.08,
}) {
  // Size of the preview as drawn: covers the viewport, may overflow.
  var drawnW = viewport.width;
  var drawnH = drawnW / previewAspect;
  if (drawnH < viewport.height) {
    drawnH = viewport.height;
    drawnW = drawnH * previewAspect;
  }
  final dx = (drawnW - viewport.width) / 2;
  final dy = (drawnH - viewport.height) / 2;
  final grown = frame.inflate(margin * frame.shortestSide);
  return Rect.fromLTRB(
    ((grown.left + dx) / drawnW).clamp(0, 1),
    ((grown.top + dy) / drawnH).clamp(0, 1),
    ((grown.right + dx) / drawnW).clamp(0, 1),
    ((grown.bottom + dy) / drawnH).clamp(0, 1),
  );
}

/// Makes a photo ready for OCR: upright (EXIF orientation applied), cut to
/// [crop] (fractions of the photo) and at most [maxSide] pixels on the
/// longer side, as JPEG. Slow on big photos: run it in an isolate.
///
/// Throws [FormatException] when [encoded] is not an image.
Uint8List prepareForOcr(Uint8List encoded, {Rect? crop, int maxSide = 1600}) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(encoded);
  } catch (_) {
    decoded = null; // The decoders throw on some broken files.
  }
  if (decoded == null) throw const FormatException('not an image');
  var image = img.bakeOrientation(decoded);
  if (crop != null) {
    final x = (crop.left * image.width).round();
    final y = (crop.top * image.height).round();
    final w = (crop.width * image.width).round();
    final h = (crop.height * image.height).round();
    if (w > 0 && h > 0) {
      image = img.copyCrop(image, x: x, y: y, width: w, height: h);
    }
  }
  final longer = image.width > image.height ? image.width : image.height;
  if (longer > maxSide) {
    image = image.width >= image.height
        ? img.copyResize(image, width: maxSide)
        : img.copyResize(image, height: maxSide);
  }
  return img.encodeJpg(image, quality: 92);
}
