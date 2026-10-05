// Writes a synthetic display photo to ocr_corpus/smoke/, to check that the
// benchmark runs end to end before real photos are available:
//
//   dart run tool/ocr_bench/make_smoke_sample.dart
//
// It is plain printed text, much easier than a real LCD: it says nothing
// about how good an engine is.
import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  final image = img.Image(width: 600, height: 800)
    ..clear(img.ColorRgb8(169, 182, 160)); // LCD green-grey
  final ink = img.ColorRgb8(31, 41, 30);
  img.drawString(image, 'SYS', font: img.arial24, x: 40, y: 120, color: ink);
  img.drawString(image, '124', font: img.arial48, x: 300, y: 100, color: ink);
  img.drawString(image, 'DIA', font: img.arial24, x: 40, y: 320, color: ink);
  img.drawString(image, '77', font: img.arial48, x: 330, y: 300, color: ink);
  img.drawString(image, 'PUL', font: img.arial24, x: 40, y: 520, color: ink);
  img.drawString(image, '68', font: img.arial24, x: 380, y: 520, color: ink);

  final folder = Directory('ocr_corpus/smoke')..createSync(recursive: true);
  File('${folder.path}/printed_124_77.png')
      .writeAsBytesSync(img.encodePng(image));
  File('${folder.path}/printed_124_77.json').writeAsStringSync(
    jsonEncode({'sys': 124, 'dia': 77, 'pulse': 68, 'notes': 'synthetic'}),
  );
  stdout.writeln('Written ${folder.path}/printed_124_77.png');
}
