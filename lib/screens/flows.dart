import 'package:flutter/material.dart';

import '../logic/bp_category.dart';
import '../models/measurement.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'celebrate_screen.dart';
import 'entry_screen.dart';
import 'high_reading_screen.dart';

/// New reading: entry form, then the celebration or the high-reading screen.
Future<void> openNewMeasurement(BuildContext context, {DateTime? day}) async {
  final outcome = await Navigator.of(context).push<SaveOutcome>(
    MaterialPageRoute(builder: (_) => EntryScreen(initialDay: day)),
  );
  if (outcome == null || !context.mounted) return;
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

/// Reading the values from a photo of the display (OCR) is not built yet:
/// every "Fotografa" button lands here.
void showScanPlaceholder(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: const Text(
          'La lettura dal display arriverà presto. Per ora inserisci i valori '
          'a mano.',
        ),
        action: SnackBarAction(
          label: 'A mano',
          onPressed: () => openNewMeasurement(context),
        ),
      ),
    );
}

/// Pops back to the main tabs.
void backToHome(BuildContext context) =>
    Navigator.of(context).popUntil((route) => route.isFirst);

/// Placeholder for features that need a server or are not built yet.
void showComingSoon(BuildContext context, String what) =>
    showSnack(context, '$what: in arrivo.');
