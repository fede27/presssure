import 'package:flutter/material.dart';

import '../config.dart';
import '../l10n/l10n.dart';
import '../logic/bp_category.dart';
import '../models/measurement.dart';
import '../ocr/ocr_engine.dart';
import '../ocr/reading_scanner.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'celebrate_screen.dart';
import 'entry_screen.dart';
import 'high_reading_screen.dart';
import 'scan_screen.dart';

/// New reading: entry form, then the celebration or the high-reading screen.
/// The camera button of the form switches to [openCamera].
Future<void> openNewMeasurement(BuildContext context, {DateTime? day}) async {
  final result = await Navigator.of(context).push<Object>(
    MaterialPageRoute(builder: (_) => EntryScreen(initialDay: day)),
  );
  if (!context.mounted) return;
  if (result == EntryScreen.useCamera) return openCamera(context);
  await _afterSave(context, result as SaveOutcome?);
}

/// "Fotografa": the camera, then the values to check. "A mano" there
/// switches to the manual form.
Future<void> openCamera(BuildContext context) async {
  await _askKeepScans(context);
  if (!context.mounted) return;
  final exit = await Navigator.of(context)
      .push<ScanExit>(MaterialPageRoute(builder: (_) => const ScanScreen()));
  if (exit == ScanExit.manual && context.mounted) {
    await openNewMeasurement(context);
  }
}

/// Beta builds ask once, before the first photo, whether the readings may
/// be kept for analysis. The answer can be changed in the settings.
Future<void> _askKeepScans(BuildContext context) async {
  final state = AppScope.read(context);
  if (!state.beta || state.scanLog == null) return;
  if (state.settings.keepScans != null) return;
  final l = context.l10n;
  final keep = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(l.keepScansTitle),
      content: Text(l.keepScansBody(keptScans, feedbackEmail)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.keepScansNo),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l.keepScansYes),
        ),
      ],
    ),
  );
  await state.setKeepScans(keep ?? false);
}

/// How a scan ended, for the camera screen.
enum ScanEnd {
  /// Nothing usable was read (the user was told): try again.
  notRead,

  /// The form was closed without saving ("Rifai").
  retake,

  /// The reading was saved.
  saved,
}

/// Reads the display in [image]; the values open in "Controlla e salva" to
/// be checked, nothing is saved without the user. Without an OCR engine the
/// form opens empty, to copy the values from the display.
Future<ScanEnd> openScannedMeasurement(
  BuildContext context,
  OcrImage image,
) async {
  if (AppScope.read(context).scanner == null) return openPhotoForm(context);
  final result = await scanPhoto(context, image);
  if (result == null || !context.mounted) return ScanEnd.notRead;
  return openScanResult(context, result);
}

/// Runs the OCR engine on [image]; null (and the user told) when it fails.
Future<ScanResult?> scanPhoto(BuildContext context, OcrImage image) async {
  final l = context.l10n;
  try {
    return await AppScope.read(context).scanner!.scan(image);
  } catch (e) {
    if (context.mounted) showSnack(context, l.errorGeneric('$e'));
    return null;
  }
}

/// No OCR engine: the photo was taken (and, in beta builds, kept), the
/// user copies the values from the display.
Future<ScanEnd> openPhotoForm(
  BuildContext context, {
  void Function(Measurement saved)? onSaved,
}) async {
  final outcome = await Navigator.of(context).push<Object>(
    MaterialPageRoute(builder: (_) => const EntryScreen(fromPhoto: true)),
  );
  if (outcome is! SaveOutcome) return ScanEnd.retake;
  onSaved?.call(outcome.measurement);
  if (context.mounted) await _afterSave(context, outcome);
  return ScanEnd.saved;
}

/// The form pre-filled with what was read, or a message if nothing was.
///
/// [onSaved] receives the reading as saved, i.e. as checked by the user.
Future<ScanEnd> openScanResult(
  BuildContext context,
  ScanResult result, {
  void Function(Measurement saved)? onSaved,
}) async {
  final l = context.l10n;
  final reading = result.reading;
  if (reading == null) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l.scanNothingRead)));
    return ScanEnd.notRead;
  }
  final outcome = await Navigator.of(context).push<Object>(
    MaterialPageRoute(builder: (_) => EntryScreen(scanned: reading)),
  );
  if (outcome is! SaveOutcome) return ScanEnd.retake;
  onSaved?.call(outcome.measurement);
  if (context.mounted) await _afterSave(context, outcome);
  return ScanEnd.saved;
}

/// The celebration, or the calm screen for a high reading.
Future<void> _afterSave(BuildContext context, SaveOutcome? outcome) async {
  if (outcome == null) return;
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => outcome.category == BpCategory.high
          ? HighReadingScreen(outcome: outcome)
          : CelebrateScreen(outcome: outcome),
    ),
  );
}

Future<void> openEditMeasurement(BuildContext context, Measurement m) {
  return Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => EntryScreen(existing: m)));
}

/// Pops back to the main tabs.
void backToHome(BuildContext context) =>
    Navigator.of(context).popUntil((route) => route.isFirst);

/// Placeholder for features that need a server or are not built yet.
void showComingSoon(BuildContext context, String what) =>
    showSnack(context, context.l10n.comingSoon(what));
