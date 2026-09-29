import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'services/reminders.dart';
import 'services/repository.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState(
    repository: await Repository.open(),
    reminders: LocalNotificationReminderService(),
  );
  runApp(PressSureApp(state: state));
  unawaited(state.startReminders());
}
