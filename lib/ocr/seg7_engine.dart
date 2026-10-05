import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:tflite_flutter/tflite_flutter.dart';

import 'digit_grouping.dart';
import 'ocr_engine.dart';
import 'seg7_model.dart';

/// Our own engine for seven-segment displays: a small YOLO detector trained
/// on photos of blood pressure monitors (tool/ocr_train), run on the phone
/// with LiteRT. It finds every digit and every number; the digits are
/// grouped into numbers by [groupDigits].
///
/// The model was trained on the "Blood-Pressure-monitor-digit-reader"
/// dataset by naphop on Roboflow Universe (CC BY 4.0).
class Seg7Engine implements OcrEngine {
  Seg7Engine({this.asset = 'assets/models/seg7.tflite'});

  final String asset;
  Interpreter? _interpreter;
  IsolateInterpreter? _isolate;

  @override
  String get id => 'seg7';

  Future<IsolateInterpreter> _load() async {
    if (_isolate != null) return _isolate!;
    final interpreter = await Interpreter.fromAsset(
      asset,
      options: InterpreterOptions()..threads = 4,
    );
    _interpreter = interpreter;
    return _isolate = await IsolateInterpreter.create(
      address: interpreter.address,
    );
  }

  @override
  Future<OcrResult> recognize(OcrImage image) async {
    final runner = await _load();
    final interpreter = _interpreter!;
    final inputShape = interpreter.getInputTensor(0).shape; // [1, s, s, 3]
    final size = inputShape[1];
    final outputShape = interpreter.getOutputTensor(0).shape;

    final bytes = await File(image.path).readAsBytes();
    final input = await Isolate.run(() => modelInput(bytes, size));
    final output = Uint8List(outputShape.reduce((a, b) => a * b) * 4);
    await runner.run(input.pixels.buffer.asUint8List(), output);

    final detections = decodeYolo(
      output.buffer.asFloat32List(),
      outputShape,
      inputSize: size,
      imageWidth: input.width,
      imageHeight: input.height,
    );
    return OcrResult(engine: id, tokens: groupDigits(detections));
  }

  @override
  Future<void> dispose() async {
    await _isolate?.close();
    _interpreter?.close();
    _isolate = null;
    _interpreter = null;
  }
}
