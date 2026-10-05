import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'config.dart';
import 'l10n/l10n.dart';
import 'ocr/corpus.dart';
import 'ocr/scan_log.dart';
import 'ocr/seg7_engine.dart';
import 'services/reminders.dart';
import 'services/repository.dart';
import 'state/app_state.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // Date names and patterns for every region, not only the app languages.
  await initializeDateFormatting();
  final locale = basicLocaleListResolution(
    binding.platformDispatcher.locales,
    AppLocalizations.supportedLocales,
  );
  final state = AppState(
    repository: await Repository.open(),
    reminders: LocalNotificationReminderService(),
    ocrEngine: Seg7Engine(),
    corpus: await CorpusRecorder.open(),
    scanLog: isBetaBuild ? await _scanLog() : null,
    locale: locale,
  );
  state.updateLocale(
    locale,
    dateLocaleFor(locale, binding.platformDispatcher.locales),
  );
  runApp(PressSureApp(state: state));
  unawaited(state.startReminders());
}

/// In the app's private files; the zip to send goes to the cache.
Future<ScanLog> _scanLog() async => FileScanLog(
  Directory('${(await getApplicationSupportDirectory()).path}/kept_scans'),
  exportFolder: await getTemporaryDirectory(),
);
