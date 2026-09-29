import 'dart:async';

import 'package:intl/date_symbol_data_local.dart';

/// Loads date names and patterns for every locale before any test, as
/// `main()` does in the app.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await initializeDateFormatting();
  await testMain();
}
