import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presssure/models/measurement.dart';
import 'package:presssure/ocr/fake_ocr_engine.dart';
import 'package:presssure/ocr/ocr_engine.dart';
import 'package:presssure/screens/celebrate_screen.dart';
import 'package:presssure/screens/entry_screen.dart';
import 'package:presssure/screens/flows.dart';
import 'package:presssure/screens/today_screen.dart';

import '../helpers.dart';

/// The display of the design: 124/77 read well, the pulse 68 blurry.
final _display = OcrResult(
  engine: 'fake',
  tokens: [
    const OcrToken('SYS', OcrBox(40, 180, 120, 40), confidence: 0.9),
    const OcrToken('124', OcrBox(300, 150, 470, 260), confidence: 0.97),
    const OcrToken('77', OcrBox(456, 480, 300, 250), confidence: 0.95),
    const OcrToken('68', OcrBox(600, 800, 144, 120), confidence: 0.5),
  ],
);

const _photo = OcrImage('display.jpg');

/// Starts a scan of [_photo] from the home screen, as the camera will.
Future<void> scanFromHome(WidgetTester tester) async {
  final context = tester.element(find.byType(TodayScreen));
  // Not awaited: the flow ends only when the pushed screens are closed.
  openScannedMeasurement(context, _photo);
  await tester.pumpAndSettle();
}

String fieldText(WidgetTester tester, int index) => tester
    .widget<TextField>(
      find
          .descendant(
            of: find.byType(EntryScreen),
            matching: find.byType(TextField),
          )
          .at(index),
    )
    .controller!
    .text;

void main() {
  testWidgets('read values open pre-filled, sure or to check', (tester) async {
    final engine = FakeOcrEngine(_display);
    await pumpApp(tester, measurements: designReadings(), ocrEngine: engine);

    await scanFromHome(tester);
    expect(engine.requests.single.path, 'display.jpg');
    expect(find.byType(EntryScreen), findsOneWidget);
    expect(find.text('Letto dalla foto'), findsOneWidget);
    expect(find.textContaining('la foto non viene salvata'), findsOneWidget);
    expect((fieldText(tester, 0), fieldText(tester, 1)), ('124', '77'));
    expect(fieldText(tester, 2), '68');
    expect(find.text('Letto con sicurezza'), findsNWidgets(2));
    expect(find.textContaining('Cifra poco nitida'), findsOneWidget);
  });

  testWidgets('a corrected value is no longer marked', (tester) async {
    await pumpApp(
      tester,
      measurements: designReadings(),
      ocrEngine: FakeOcrEngine(_display),
    );
    await scanFromHome(tester);

    final pulse = find
        .descendant(
          of: find.byType(EntryScreen),
          matching: find.byType(TextField),
        )
        .at(2);
    await tester.enterText(pulse, '66');
    await tester.pump();
    expect(find.textContaining('Cifra poco nitida'), findsNothing);
    expect(find.text('Letto con sicurezza'), findsNWidgets(2));
  });

  testWidgets('saved as a photo reading, then celebrated', (tester) async {
    final state = await pumpApp(
      tester,
      measurements: designReadings(),
      ocrEngine: FakeOcrEngine(_display),
    );
    await scanFromHome(tester);

    await tester.tap(find.text('Salva misurazione'));
    await tester.pumpAndSettle();
    final saved = state.latest!;
    expect((saved.systolic, saved.diastolic, saved.pulse), (124, 77, 68));
    expect(saved.source, ReadingSource.photo);
    expect(find.byType(CelebrateScreen), findsOneWidget);
  });

  testWidgets('"Rifai" goes back without saving', (tester) async {
    final state = await pumpApp(
      tester,
      measurements: designReadings(),
      ocrEngine: FakeOcrEngine(_display),
    );
    await scanFromHome(tester);

    await tester.tap(find.text('Rifai'));
    await tester.pumpAndSettle();
    expect(find.byType(EntryScreen), findsNothing);
    expect(state.measurements, hasLength(23));
  });

  testWidgets('a value not found is left empty, to copy', (tester) async {
    await pumpApp(
      tester,
      measurements: designReadings(),
      ocrEngine: FakeOcrEngine(
        OcrResult(engine: 'fake', tokens: _display.tokens.take(3).toList()),
      ),
    );
    await scanFromHome(tester);
    expect(fieldText(tester, 2), '');
    expect(find.textContaining('Non trovato nella foto'), findsOneWidget);
  });

  testWidgets('nothing read: the user is told, no form', (tester) async {
    await pumpApp(
      tester,
      measurements: designReadings(),
      ocrEngine: FakeOcrEngine(
        const OcrResult(
          engine: 'fake',
          tokens: [OcrToken('SYS', OcrBox(0, 0, 100, 40))],
        ),
      ),
    );
    await scanFromHome(tester);
    expect(find.byType(EntryScreen), findsNothing);
    expect(
      find.textContaining('Non riesco a leggere i valori'),
      findsOneWidget,
    );
  });

  testWidgets('without an engine the values are copied from the display', (
    tester,
  ) async {
    await pumpApp(tester, measurements: designReadings());
    await scanFromHome(tester);
    expect(find.byType(EntryScreen), findsOneWidget);
    expect(find.text('Copia i valori dal display'), findsOneWidget);
    expect((fieldText(tester, 0), fieldText(tester, 1)), ('', ''));
    expect(find.text('Letto con sicurezza'), findsNothing);
  });
}
