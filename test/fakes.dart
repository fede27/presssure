import 'dart:io';

import 'package:flutter/material.dart';
import 'package:presssure/ocr/ocr_engine.dart';
import 'package:presssure/ocr/scan_log.dart';
import 'package:presssure/services/photo_source.dart';

/// Camera and gallery without hardware: every photo is a named file.
class FakePhotoSource implements PhotoSource {
  FakePhotoSource({
    this.failOpen = false,
    this.galleryPhoto,
    this.access = CameraAccess.granted,
    this.answer = CameraAccess.granted,
  });

  final bool failOpen;

  /// Permission now, and the answer to the dialog.
  CameraAccess access;
  CameraAccess answer;
  var requests = 0;
  var settingsOpened = 0;
  final OcrImage? galleryPhoto;
  var opens = 0;
  var torch = false;
  var _open = false;
  Rect? lastCrop;
  final discarded = <String>[];

  @override
  Future<CameraAccess> cameraAccess() async => access;

  @override
  Future<CameraAccess> requestCameraAccess() async {
    requests++;
    return access = answer;
  }

  @override
  Future<void> openCameraSettings() async => settingsOpened++;

  @override
  Future<void> open() async {
    if (failOpen) throw const PhotoSourceException('CameraAccessDenied');
    opens++;
    _open = true;
  }

  @override
  bool get isOpen => _open;

  @override
  double get previewAspect => 0.75;

  @override
  Widget buildPreview() =>
      const ColoredBox(key: Key('preview'), color: Colors.black);

  @override
  Future<void> setTorch(bool on) async => torch = on;

  @override
  Future<OcrImage> takePicture({Rect? crop}) async {
    lastCrop = crop;
    return const OcrImage('shot.jpg');
  }

  @override
  Future<OcrImage?> pickFromGallery() async => galleryPhoto;

  @override
  Future<void> discard(OcrImage image) async => discarded.add(image.path);

  @override
  Future<void> close() async => _open = false;
}

/// Kept readings in memory.
class FakeScanLog implements ScanLog {
  final photos = <String, String>{};
  final records = <String, LoggedScan>{};
  var exports = 0;

  @override
  Future<String> keep(OcrImage photo) async {
    final id = 'scan_${photos.length}';
    photos[id] = photo.path;
    return id;
  }

  @override
  Future<void> record(String id, LoggedScan scan) async => records[id] = scan;

  @override
  Future<int> count() async => photos.length;

  @override
  Future<File> export() async {
    exports++;
    return File('letture.zip');
  }

  @override
  Future<void> clear() async {
    photos.clear();
    records.clear();
  }
}
