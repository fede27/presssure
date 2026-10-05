import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presssure/ocr/fake_ocr_engine.dart';
import 'package:presssure/ocr/ocr_engine.dart';
import 'package:presssure/ocr/scan_log.dart';
import 'package:presssure/screens/scan_screen.dart';
import 'package:presssure/state/app_state.dart';

import '../fakes.dart';
import '../helpers.dart';

/// 163/79 read as 153/79, as on the real display; pulse 83.
final _display = OcrResult(
  engine: 'mlkit',
  tokens: [
    const OcrToken('153', OcrBox(300, 150, 470, 260), confidence: 0.6),
    const OcrToken('79', OcrBox(456, 480, 300, 250), confidence: 0.95),
    const OcrToken('83', OcrBox(600, 800, 144, 120), confidence: 0.95),
  ],
);

const _unreadable = OcrResult(engine: 'mlkit', tokens: []);

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  late FakeScanLog log;
  late List<Email> sent;

  Future<AppState> start(
    WidgetTester tester, {
    bool beta = true,
    bool? keepScans,
    OcrResult? read,
    bool engine = true,
  }) async {
    log = FakeScanLog();
    sent = [];
    final camera = FakePhotoSource();
    return pumpApp(
      tester,
      measurements: designReadings(),
      settings: onboardedSettings.copyWith(keepScans: keepScans),
      ocrEngine: engine ? FakeOcrEngine(read ?? _display) : null,
      photoSource: () => camera,
      beta: beta,
      scanLog: log,
      sendEmail: (email) async => sent.add(email),
    );
  }

  Future<void> shoot(WidgetTester tester) async {
    final semantics = tester.ensureSemantics();
    await tap(tester, find.bySemanticsLabel('Scatta'));
    semantics.dispose();
  }

  testWidgets('asked once, before the first photo', (tester) async {
    final state = await start(tester);
    await tap(tester, find.text('Fotografa'));
    expect(find.text('Aiutami a migliorare la lettura'), findsOneWidget);
    expect(find.textContaining('federico.scarel@gmail.com'), findsOneWidget);
    await tap(tester, find.text('Sì, tieni le letture'));
    expect(state.keepsScans, isTrue);
    expect(find.byType(ScanScreen), findsOneWidget);

    await tap(tester, find.byTooltip('Chiudi'));
    await tap(tester, find.text('Fotografa'));
    expect(find.text('Aiutami a migliorare la lettura'), findsNothing);
  });

  testWidgets('"No": never asked again, nothing kept', (tester) async {
    final state = await start(tester);
    await tap(tester, find.text('Fotografa'));
    await tap(tester, find.text('No, grazie'));
    expect(state.settings.keepScans, isFalse);
    await shoot(tester);
    expect(log.photos, isEmpty);
    expect(find.textContaining('la foto non viene salvata'), findsOneWidget);
  });

  testWidgets('kept and saved: what was read and what was saved', (
    tester,
  ) async {
    await start(tester, keepScans: true);
    await tap(tester, find.text('Fotografa'));
    await shoot(tester);
    // The form says the truth about the photo.
    expect(find.textContaining('la foto resta sul telefono'), findsOneWidget);

    // The user corrects 153 into 163, as on the display.
    final sys = find.byType(TextField).first;
    await tester.enterText(sys, '163');
    await tap(tester, find.text('Salva misurazione'));

    final record = log.records.values.single;
    expect(record.outcome, ScanOutcome.saved);
    expect(record.source, 'camera');
    expect(record.read!.systolic.value, 153);
    expect(record.saved!.systolic, 163);
    expect(record.ocr!.engine, 'mlkit');
  });

  testWidgets('kept also when retaken or not read', (tester) async {
    await start(tester, keepScans: true);
    await tap(tester, find.text('Fotografa'));
    await shoot(tester);
    await tap(tester, find.text('Rifai'));
    expect(log.records.values.single.outcome, ScanOutcome.retake);
    expect(log.records.values.single.saved, isNull);
  });

  testWidgets('an unreadable photo is kept too', (tester) async {
    await start(tester, keepScans: true, read: _unreadable);
    await tap(tester, find.text('Fotografa'));
    await shoot(tester);
    expect(log.photos, hasLength(1));
    expect(log.records.values.single.outcome, ScanOutcome.notRead);
  });

  testWidgets('no engine: the photo kept, labelled with the copied values', (
    tester,
  ) async {
    await start(tester, keepScans: true, engine: false);
    await tap(tester, find.text('Fotografa'));
    await shoot(tester);
    expect(find.text('Copia i valori dal display'), findsOneWidget);
    expect(find.textContaining('la foto resta sul telefono'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '163');
    await tester.enterText(fields.at(1), '79');
    await tester.enterText(fields.at(2), '83');
    await tap(tester, find.text('Salva misurazione'));

    final record = log.records.values.single;
    expect(record.outcome, ScanOutcome.saved);
    expect(record.ocr, isNull);
    expect(record.read, isNull);
    expect((record.saved!.systolic, record.saved!.pulse), (163, 83));
  });

  testWidgets('public builds never ask and never keep', (tester) async {
    await start(tester, beta: false, keepScans: true);
    await tap(tester, find.text('Fotografa'));
    expect(find.text('Aiutami a migliorare la lettura'), findsNothing);
    await shoot(tester);
    expect(log.photos, isEmpty);
  });

  group('settings', () {
    Future<void> openSettings(WidgetTester tester) =>
        tap(tester, find.byTooltip('Impostazioni'));

    testWidgets('send: the mail to the developer with the zip', (tester) async {
      await start(tester, keepScans: true);
      await tap(tester, find.text('Fotografa'));
      await shoot(tester);
      await tap(tester, find.text('Rifai'));
      await tap(tester, find.byTooltip('Chiudi'));
      await openSettings(tester);

      expect(find.text('Programma beta'), findsOneWidget);
      expect(find.text('1 lettura tenuta'), findsOneWidget);
      await tap(tester, find.text('Invia per analisi'));
      final email = sent.single;
      expect(email.recipients, ['federico.scarel@gmail.com']);
      expect(email.attachmentPaths, ['letture.zip']);
      expect(email.subject, contains('letture del display'));
      expect(email.body, contains('1 lettura'));
    });

    testWidgets('turned off: the kept readings are deleted', (tester) async {
      final state = await start(tester, keepScans: true);
      await tap(tester, find.text('Fotografa'));
      await shoot(tester);
      await tap(tester, find.text('Rifai'));
      await tap(tester, find.byTooltip('Chiudi'));
      await openSettings(tester);

      await tap(tester, find.text('Aiutami a migliorare la lettura'));
      expect(state.keepsScans, isFalse);
      expect(log.photos, isEmpty);
      expect(find.text('Nessuna lettura tenuta'), findsOneWidget);
      expect(find.text('Letture tenute cancellate'), findsOneWidget);
    });

    testWidgets('nothing to send: the button is off', (tester) async {
      await start(tester, keepScans: true);
      await openSettings(tester);
      final button = tester.widget<ButtonStyleButton>(
        find.ancestor(
          of: find.text('Invia per analisi'),
          matching: find.bySubtype<ButtonStyleButton>(),
        ),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('public builds: no beta section', (tester) async {
      await start(tester, beta: false);
      await openSettings(tester);
      expect(find.text('Programma beta'), findsNothing);
    });
  });
}
