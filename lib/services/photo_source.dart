import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../ocr/ocr_engine.dart';
import '../ocr/photo_prep.dart';

/// The camera could not be opened (no camera, permission denied...).
class PhotoSourceException implements Exception {
  const PhotoSourceException(this.code);

  final String code;

  @override
  String toString() => 'PhotoSourceException($code)';
}

/// Whether the app may use the camera.
enum CameraAccess {
  granted,

  /// Not granted yet: asking shows the system dialog.
  denied,

  /// Refused for good: only the app settings can change it.
  blocked,
}

/// Where the photo of the display comes from: the camera with its preview,
/// or the gallery. Photos come back ready for OCR and are never kept:
/// [discard] deletes them once read.
abstract interface class PhotoSource {
  /// Checks the camera permission without asking.
  Future<CameraAccess> cameraAccess();

  /// Shows the system dialog (once per call).
  Future<CameraAccess> requestCameraAccess();

  /// The app page of the phone settings, to allow a blocked camera.
  Future<void> openCameraSettings();

  /// Starts the camera, once access is granted; throws
  /// [PhotoSourceException] when unavailable.
  Future<void> open();

  bool get isOpen;

  /// Width / height of the preview held upright. Valid once open.
  double get previewAspect;

  /// The live preview. Valid once open.
  Widget buildPreview();

  /// Continuous light, to read displays in the dark.
  Future<void> setTorch(bool on);

  /// Takes a photo and keeps only [crop] (fractions of the photo).
  Future<OcrImage> takePicture({Rect? crop});

  /// A photo chosen from the gallery, or null if the user cancels.
  Future<OcrImage?> pickFromGallery();

  Future<void> discard(OcrImage image);

  /// Frees the camera; [open] can be called again.
  Future<void> close();
}

/// The back camera through the `camera` plugin.
class CameraPhotoSource implements PhotoSource {
  CameraController? _controller;

  static CameraAccess _access(PermissionStatus status) => switch (status) {
    PermissionStatus.granted ||
    PermissionStatus.limited => CameraAccess.granted,
    PermissionStatus.permanentlyDenied ||
    PermissionStatus.restricted => CameraAccess.blocked,
    _ => CameraAccess.denied,
  };

  @override
  Future<CameraAccess> cameraAccess() async =>
      _access(await Permission.camera.status);

  @override
  Future<CameraAccess> requestCameraAccess() async =>
      _access(await Permission.camera.request());

  @override
  Future<void> openCameraSettings() => openAppSettings();

  @override
  bool get isOpen => _controller?.value.isInitialized ?? false;

  @override
  double get previewAspect => 1 / _controller!.value.aspectRatio;

  @override
  Future<void> open() async {
    if (isOpen) return;
    final List<CameraDescription> cameras;
    try {
      cameras = await availableCameras();
    } on CameraException catch (e) {
      throw PhotoSourceException(e.code);
    }
    final camera =
        cameras
            .where((c) => c.lensDirection == CameraLensDirection.back)
            .firstOrNull ??
        cameras.firstOrNull;
    if (camera == null) throw const PhotoSourceException('noCamera');
    final controller = CameraController(
      camera,
      ResolutionPreset.veryHigh,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    try {
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
    } on CameraException catch (e) {
      await controller.dispose();
      throw PhotoSourceException(e.code);
    }
    _controller = controller;
  }

  @override
  Widget buildPreview() => CameraPreview(_controller!);

  @override
  Future<void> setTorch(bool on) async =>
      _controller?.setFlashMode(on ? FlashMode.torch : FlashMode.off);

  @override
  Future<OcrImage> takePicture({Rect? crop}) async {
    final shot = await _controller!.takePicture();
    try {
      return await _prepare(await shot.readAsBytes(), crop);
    } finally {
      await _delete(shot.path);
    }
  }

  @override
  Future<OcrImage?> pickFromGallery() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return null;
    return _prepare(await file.readAsBytes(), null);
  }

  @override
  Future<void> discard(OcrImage image) => _delete(image.path);

  @override
  Future<void> close() async {
    final controller = _controller;
    _controller = null;
    await controller?.dispose();
  }

  /// Upright, cropped and resized off the UI thread, into the app cache.
  static Future<OcrImage> _prepare(Uint8List bytes, Rect? crop) async {
    final jpeg = await Isolate.run(() => prepareForOcr(bytes, crop: crop));
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/ocr_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(jpeg);
    return OcrImage(file.path);
  }

  static Future<void> _delete(String path) async {
    try {
      await File(path).delete();
    } on FileSystemException {
      // Already gone.
    }
  }
}
