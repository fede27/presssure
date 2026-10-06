// Screenshots for the Google Play listing, rendered from the app itself with
// the design's sample diary (test/helpers.dart): same data, same pictures,
// every time.
//
//   flutter test tool/store_screenshots/store_screenshots_test.dart
//
// Writes store_assets/screenshots/NN_name.png, 1080x1920 (9:16), without
// status bar, frames or captions. Not under test/, so `flutter test` alone
// does not rewrite them.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:presssure/ocr/reading_parser.dart';
import 'package:presssure/screens/achievements_screen.dart';
import 'package:presssure/screens/entry_screen.dart';
import 'package:presssure/screens/home_shell.dart';

import '../../test/helpers.dart';

const _outDir = 'store_assets/screenshots';

/// 1080x1920 on a 411x731 dp screen, a common phone size.
const _size = Size(1080, 1920);
const _ratio = 2.625;

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    await _loadFonts();
    Directory(_outDir).createSync(recursive: true);
  });

  // The last reading in evidence, with the buttons to add one.
  _screenshot('01_home', (tester) async {});

  // Just read from the photo: systolic and diastolic sure, the pulse to be
  // checked against the display ("04 · Controlla e salva").
  _screenshot(
    '02_ocr',
    includeToday: false,
    (tester) => _push(
      tester,
      const EntryScreen(
        scanned: ParsedReading(
          systolic: ReadValue(124, 0.97),
          diastolic: ReadValue(77, 0.95),
          pulse: ReadValue(68, 0.55),
        ),
      ),
    ),
  );

  _screenshot('03_grafico', (tester) => _tab(tester, HomeShell.trends));

  _screenshot('04_storico', (tester) => _tab(tester, HomeShell.diary));

  // Streak, record, jolly and badges.
  _screenshot(
    '05_promemoria',
    (tester) => _push(tester, const AchievementsScreen()),
  );

  _screenshot('06_condivisione', (tester) => _tab(tester, HomeShell.share));
}

/// Opens the app on the design's day (Sunday 27 September 2026, 07:50), in
/// Italian, with the design's readings and events, goes where [show] says
/// and saves the screen as `name.png`.
void _screenshot(
  String name,
  Future<void> Function(WidgetTester tester) show, {
  bool includeToday = true,
}) {
  testWidgets(name, (tester) async {
    // Tests draw shadows as solid black outlines unless told otherwise;
    // the setting must be back to its default when the test ends.
    debugDisableShadows = false;
    try {
      await pumpApp(
        tester,
        measurements: designReadings(includeToday: includeToday),
        events: designEvents(),
      );
      tester.view
        ..physicalSize = _size
        ..devicePixelRatio = _ratio;
      await tester.pumpAndSettle();
      await show(tester);
      await _save(tester, name);
    } finally {
      debugDisableShadows = true;
    }
  });
}

Future<void> _tab(WidgetTester tester, int index) async {
  HomeShell.select(tester.element(find.byType(NavigationBar)), index);
  await tester.pumpAndSettle();
}

Future<void> _push(WidgetTester tester, Widget screen) async {
  Navigator.of(tester.element(find.byType(HomeShell)))
      .push(MaterialPageRoute<void>(builder: (_) => screen));
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final image = await captureImage(
      find.byType(MaterialApp).evaluate().single,
    );
    expect((image.width, image.height), (1080, 1920));
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$_outDir/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}

/// Tests draw text with a placeholder font: load the app's fonts and the
/// Material icons from the Flutter SDK.
Future<void> _loadFonts() async {
  Future<void> load(String family, String path) async {
    final bytes = File(path).readAsBytesSync();
    await (FontLoader(
      family,
    )..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
  }

  await load('Manrope', 'assets/fonts/Manrope.ttf');
  await load('BricolageGrotesque', 'assets/fonts/BricolageGrotesque.ttf');
  await load('MaterialIcons', _materialIcons());
}

/// The test runner sits in `bin/cache/artifacts/engine/<platform>/` of the
/// Flutter SDK, the icons in `bin/cache/artifacts/material_fonts/`.
String _materialIcons() {
  final candidates = [
    if (Platform.environment['FLUTTER_ROOT'] case final root?)
      '$root/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
    File(Platform.resolvedExecutable).parent.parent.parent.uri
        .resolve('material_fonts/materialicons-regular.otf')
        .toFilePath(),
  ];
  return candidates.firstWhere(
    (p) => File(p).existsSync(),
    orElse: () => throw StateError('Material icons not found: $candidates'),
  );
}
