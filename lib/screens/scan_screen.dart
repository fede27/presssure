import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/measurement.dart';
import '../ocr/benchmark.dart';
import '../ocr/corpus.dart';
import '../ocr/ocr_engine.dart';
import '../ocr/photo_prep.dart';
import '../ocr/reading_scanner.dart';
import '../ocr/scan_log.dart';
import '../services/photo_source.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'flows.dart';

/// How the camera screen was left, when not simply closed.
enum ScanExit {
  /// "A mano": the caller opens the manual form.
  manual,
}

/// Colors of the dark camera screen.
abstract final class _Dark {
  static const background = Color(0xFF0E1113);
  static const surface = Color(0xFF1E2427);
  static const viewport = Color(0xFF23282B);
  static const text = Color(0xFFE8ECEE);
  static const hint = Color(0xFFC9D0D4);
  static const accent = Color(0xFF6FE3CC);
}

/// "03 · Scansione del display": the camera with a frame for the display.
/// The photo is cut to the frame, read, and deleted; the values open in
/// "Controlla e salva", whose "Rifai" comes back here.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  /// The frame for the display, centered in a viewport of [size]: a bit
  /// taller than wide, like most monitors.
  static Rect frameIn(Size size) {
    var width = size.width * 0.62;
    if (width * 1.1 > size.height * 0.7) width = size.height * 0.7 / 1.1;
    return Rect.fromCenter(
      center: size.center(Offset.zero),
      width: width,
      height: width * 1.1,
    );
  }

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  late final PhotoSource _source = AppScope.read(context).newPhotoSource();
  var _ready = false;
  Object? _error;
  var _torch = false;
  var _busy = false;
  var _opening = false;

  /// A form is open on top: the camera stays off.
  var _away = false;

  /// Last laid-out viewport, to map the frame onto the photo.
  Size? _viewport;

  /// Null until checked.
  CameraAccess? _access;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _open(ask: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _source.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The camera is released in background and taken again on return, also
    // after the permission was granted in the settings. Never asking here:
    // the permission dialog itself pauses and resumes the app, and a refused
    // permission answers at once, so asking on resume would loop.
    if (state == AppLifecycleState.inactive && _ready) {
      _close();
    } else if (state == AppLifecycleState.resumed && !_away && !_ready) {
      _open(ask: false);
    }
  }

  /// Opens the camera if allowed; with [ask], shows the permission dialog
  /// when it was never answered.
  Future<void> _open({required bool ask}) async {
    if (_opening) return;
    _opening = true;
    if (_error != null) setState(() => _error = null);
    try {
      var access = await _source.cameraAccess();
      if (access == CameraAccess.denied && ask) {
        access = await _source.requestCameraAccess();
      }
      if (!mounted) return;
      setState(() => _access = access);
      if (access != CameraAccess.granted) return;
      await _source.open();
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      _opening = false;
    }
  }

  Future<void> _close() async {
    if (mounted) {
      setState(() {
        _ready = false;
        _torch = false;
      });
    }
    await _source.close();
  }

  Future<void> _toggleTorch() async {
    try {
      await _source.setTorch(!_torch);
      setState(() => _torch = !_torch);
    } catch (_) {
      // No light on this camera: the button just does nothing.
    }
  }

  Future<void> _shoot() {
    final viewport = _viewport;
    return _read(
      () => _source.takePicture(
        crop: viewport == null
            ? null
            : cropForFrame(
                viewport: viewport,
                previewAspect: _source.previewAspect,
                frame: ScanScreen.frameIn(viewport),
              ),
      ),
      source: 'camera',
    );
  }

  Future<void> _read(
    Future<OcrImage?> Function() getPhoto, {
    required String source,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    final state = AppScope.read(context);
    final corpus = state.corpus;
    // Beta builds, with the tester's consent: every reading is kept, also
    // the unreadable ones, the most useful to improve the engine.
    final log = state.keepsScans ? state.scanLog : null;
    final takenAt = state.now();
    OcrImage? image;
    ScanResult? result;
    String? sample;
    String? kept;

    Future<void> logAs(ScanOutcome outcome, {Measurement? saved}) async {
      if (kept == null) return;
      await log!.record(
        kept,
        LoggedScan(
          takenAt: takenAt,
          source: source,
          outcome: outcome,
          ocr: result?.raw,
          read: result?.reading,
          saved: saved,
        ),
      );
    }

    final engine = state.scanner != null;
    try {
      image = await getPhoto();
      if (image == null || !mounted) return;
      kept = await log?.keep(image);
      if (!mounted) return;
      if (engine) result = await scanPhoto(context, image);
      // Development builds keep the photo, to be labelled once saved.
      if (!engine || result?.reading != null) {
        sample = await corpus?.keep(image);
      }
    } catch (e) {
      await logAs(ScanOutcome.failed);
      if (mounted) showSnack(context, context.l10n.errorGeneric('$e'));
      return;
    } finally {
      // The photo itself is never kept (copies above, when allowed).
      if (image != null) await _source.discard(image);
      if (mounted) setState(() => _busy = false);
    }
    if (engine && result == null) return logAs(ScanOutcome.failed);
    if (engine && result!.reading == null) await logAs(ScanOutcome.notRead);
    if (!mounted) return;

    // The camera rests while the values are checked (or copied).
    final opensForm = !engine || result!.reading != null;
    if (opensForm) {
      _away = true;
      await _close();
    }
    if (!mounted) return;
    Measurement? saved;
    void onSaved(Measurement m) {
      saved = m;
      // Now, not after the celebration: the app may be closed there.
      unawaited(logAs(ScanOutcome.saved, saved: m));
    }

    final end = engine
        ? await openScanResult(context, result!, onSaved: onSaved)
        : await openPhotoForm(context, onSaved: onSaved);
    if (opensForm && saved == null) await logAs(ScanOutcome.retake);
    if (sample != null) await _labelSample(corpus!, sample, saved);
    _away = false;
    if (!mounted) return;
    if (end == ScanEnd.saved) {
      // "Fatto" already went home; back from the celebration lands here.
      if (ModalRoute.of(context)?.isCurrent ?? false) {
        Navigator.of(context).pop();
      }
    } else if (opensForm) {
      await _open(ask: false); // "Rifai"
    }
  }

  /// The values confirmed by the user label the photo; an average of two
  /// readings, or nothing saved, is no label for it.
  Future<void> _labelSample(
    CorpusRecorder corpus,
    String sample,
    Measurement? saved,
  ) async {
    if (saved == null || saved.doubleReading) return corpus.drop(sample);
    await corpus.label(
      sample,
      ExpectedReading(saved.systolic, saved.diastolic, pulse: saved.pulse),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: _Dark.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Row(
                children: [
                  _CircleButton(
                    icon: Icons.close_rounded,
                    tooltip: l.close,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        l.scanTitle,
                        textAlign: TextAlign.center,
                        style: AppText.body(
                          17,
                          weight: FontWeight.w800,
                          color: _Dark.text,
                        ),
                      ),
                    ),
                  ),
                  _CircleButton(
                    icon: _torch
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    tooltip: l.scanFlash,
                    selected: _torch,
                    onPressed: _ready ? _toggleTorch : null,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: ColoredBox(
                    color: _Dark.viewport,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final viewport = constraints.biggest;
                        _viewport = viewport;
                        return _viewfinder(l, viewport);
                      },
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SideAction(
                    icon: Icons.photo_library_outlined,
                    label: l.scanFromGallery,
                    onPressed: _busy
                        ? null
                        : () =>
                              _read(_source.pickFromGallery, source: 'gallery'),
                  ),
                  _Shutter(
                    label: l.scanShutter,
                    busy: _busy,
                    onPressed: _ready && !_busy ? _shoot : null,
                  ),
                  _SideAction(
                    icon: Icons.edit_outlined,
                    label: l.byHand,
                    onPressed: _busy
                        ? null
                        : () => Navigator.of(context).pop(ScanExit.manual),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _viewfinder(AppLocalizations l, Size viewport) {
    final hintStyle = AppText.body(
      12,
      weight: FontWeight.w600,
      color: _Dark.hint,
    );
    final access = _access;
    if (_error != null ||
        access == CameraAccess.denied ||
        access == CameraAccess.blocked) {
      final (message, action, onPressed) = _error != null
          ? (l.scanCameraError, l.scanRetry, () => _open(ask: true))
          : access == CameraAccess.blocked
          ? (
              l.scanCameraBlocked,
              l.scanOpenSettings,
              _source.openCameraSettings,
            )
          : (l.scanCameraNeeded, l.scanAllow, () => _open(ask: true));
      return Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              size: 40,
              color: _Dark.hint,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.body(14, height: 1.4, color: _Dark.text),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: _Dark.accent,
                foregroundColor: _Dark.background,
              ),
              child: Text(action),
            ),
          ],
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_ready)
          FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: 1000 * _source.previewAspect,
              height: 1000,
              child: _source.buildPreview(),
            ),
          )
        else
          const Center(child: CircularProgressIndicator(color: _Dark.accent)),
        IgnorePointer(
          child: CustomPaint(
            painter: _FramePainter(ScanScreen.frameIn(viewport)),
          ),
        ),
        Positioned(
          top: 14,
          left: 16,
          right: 16,
          child: Center(
            child: Semantics(
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _Dark.background,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: _Dark.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _busy && AppScope.of(context).scanner != null
                            ? l.scanReading
                            : l.scanFrameHint,
                        style: AppText.body(
                          13,
                          weight: FontWeight.w700,
                          color: _Dark.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 14,
          left: 16,
          right: 16,
          child: Text(
            l.scanGlareHint,
            textAlign: TextAlign.center,
            style: hintStyle,
          ),
        ),
      ],
    );
  }
}

/// Corner brackets around the frame, as in the design.
class _FramePainter extends CustomPainter {
  _FramePainter(this.frame);

  final Rect frame;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _Dark.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final arm = frame.shortestSide * 0.12;
    final f = frame;
    final path = Path()
      ..moveTo(f.left, f.top + arm)
      ..lineTo(f.left, f.top)
      ..lineTo(f.left + arm, f.top)
      ..moveTo(f.right - arm, f.top)
      ..lineTo(f.right, f.top)
      ..lineTo(f.right, f.top + arm)
      ..moveTo(f.right, f.bottom - arm)
      ..lineTo(f.right, f.bottom)
      ..lineTo(f.right - arm, f.bottom)
      ..moveTo(f.left + arm, f.bottom)
      ..lineTo(f.left, f.bottom)
      ..lineTo(f.left, f.bottom - arm);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_FramePainter old) => old.frame != frame;
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      isSelected: selected,
      style: IconButton.styleFrom(
        fixedSize: const Size(48, 48),
        backgroundColor: selected ? _Dark.accent : _Dark.surface,
        foregroundColor: selected ? _Dark.background : _Dark.text,
        disabledBackgroundColor: _Dark.surface,
        disabledForegroundColor: _Dark.hint.withValues(alpha: 0.4),
      ),
      icon: Icon(icon, size: 22),
    );
  }
}

class _SideAction extends StatelessWidget {
  const _SideAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: _Dark.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: _Dark.text),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppText.body(
                  12,
                  weight: FontWeight.w700,
                  color: _Dark.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Shutter extends StatelessWidget {
  const _Shutter({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 80,
          height: 80,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _Dark.text, width: 4),
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: onPressed == null && !busy ? _Dark.surface : _Dark.accent,
            ),
            child: busy
                ? const Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: _Dark.background,
                    ),
                  )
                : const Icon(
                    Icons.photo_camera_rounded,
                    size: 28,
                    color: _Dark.background,
                  ),
          ),
        ),
      ),
    );
  }
}
