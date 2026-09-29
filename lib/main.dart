import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'l10n/l10n.dart';
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
    locale: locale,
  );
  state.updateLocale(
    locale,
    dateLocaleFor(locale, binding.platformDispatcher.locales),
  );
  runApp(PressSureApp(state: state));
  unawaited(state.startReminders());
}
