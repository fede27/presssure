import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presssure/models/measurement.dart';
import 'package:presssure/ocr/fake_ocr_engine.dart';
import 'package:presssure/ocr/ocr_engine.dart';
import 'package:presssure/screens/celebrate_screen.dart';
import 'package:presssure/screens/entry_screen.dart';
import 'package:presssure/screens/scan_screen.dart';
import 'package:presssure/services/photo_source.dart';
import 'package:presssure/state/app_state.dart';

import '../fakes.dart';
import '../helpers.dart';

/// 124/77 sure, pulse 68 blurry.
final _display = OcrResult(
  engine: 'fake',
  tokens: [
    const OcrToken('124', OcrBox(300, 150, 470, 260), confidence: 0.97),
    const OcrToken('77', OcrBox(456, 480, 300, 250), confidence: 0.95),
    const OcrToken('68', OcrBox(600, 800, 144, 120), confidence: 0.5),
  ],
);

const _unreadable = OcrResult(
  engine: 'fake',
  tokens: [OcrToken('SYS', OcrBox(0, 0, 100, 40))],
);

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder shutter() => find.bySemanticsLabel('Scatta');

void main() {
  late FakePhotoSource camera;

  Future<AppState> openCamera(
    WidgetTester tester, {
    OcrResult? read,
    FakePhotoSource? source,
    bool engine = true,
  }) async {
    camera = source ?? FakePhotoSource();
    final state = await pumpApp(
      tester,
      measurements: designReadings(),
      ocrEngine: engine ? FakeOcrEngine(read ?? _display) : null,
      photoSource: () => camera,
    );
    await tap(tester, find.text('Fotografa'));
    return state;
  }

  testWidgets('"Fotografa" opens the camera with the frame', (tester) async {
    await openCamera(tester);
    expect(find.byType(ScanScreen), findsOneWidget);
    expect(find.text('Fotografa il display'), findsOneWidget);
    expect(find.byKey(const Key('preview')), findsOneWidget);
    expect(find.text('Inquadra il display nella cornice'), findsOneWidget);
    expect(camera.isOpen, isTrue);
  });

  testWidgets('the photo is cut to the frame, read and deleted', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await openCamera(tester);
    await tap(tester, shutter());

    final crop = camera.lastCrop!;
    expect(crop.left, greaterThan(0));
    expect(crop.right, lessThan(1));
    expect(crop.top, greaterThan(0));
    expect(crop.bottom, lessThan(1));
    expect(camera.discarded, ['shot.jpg']);

    expect(find.byType(EntryScreen), findsOneWidget);
    expect(find.text('Letto dalla foto'), findsOneWidget);
    // The camera rests while the values are checked.
    expect(camera.isOpen, isFalse);
    semantics.dispose();
  });

  testWidgets('"Rifai" goes back to the camera, open again', (tester) async {
    final semantics = tester.ensureSemantics();
    await openCamera(tester);
    await tap(tester, shutter());
    await tap(tester, find.text('Rifai'));

    expect(find.byType(ScanScreen), findsOneWidget);
    expect(camera.isOpen, isTrue);
    expect(camera.opens, 2);
    semantics.dispose();
  });

  testWidgets('saved: celebrated, then home without the camera', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final state = await openCamera(tester);
    await tap(tester, shutter());
    await tap(tester, find.text('Salva misurazione'));

    expect(state.latest!.source, ReadingSource.photo);
    expect(find.byType(CelebrateScreen), findsOneWidget);
    await tap(tester, find.text('Fatto'));
    expect(find.byType(ScanScreen), findsNothing);
    expect(find.text('Oggi'), findsWidgets);
    semantics.dispose();
  });

  testWidgets('nothing read: the camera stays, the photo is deleted', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await openCamera(tester, read: _unreadable);
    await tap(tester, shutter());

    expect(find.byType(ScanScreen), findsOneWidget);
    expect(find.byType(EntryScreen), findsNothing);
    expect(
      find.textContaining('Non riesco a leggere i valori'),
      findsOneWidget,
    );
    expect(camera.discarded, ['shot.jpg']);
    expect(camera.isOpen, isTrue);
    semantics.dispose();
  });

  testWidgets('without an OCR engine: photo, then the values to copy', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final state = await openCamera(tester, engine: false);
    await tap(tester, shutter());
    expect(camera.discarded, ['shot.jpg']);
    expect(find.text('Copia i valori dal display'), findsOneWidget);
    expect(camera.isOpen, isFalse);

    final fields = find.descendant(
      of: find.byType(EntryScreen),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), '163');
    await tester.enterText(fields.at(1), '79');
    await tap(tester, find.text('Salva misurazione'));
    // Typed by the user: a manual reading, not one read from the photo.
    expect(state.latest!.systolic, 163);
    expect(state.latest!.source, ReadingSource.manual);
    semantics.dispose();
  });

  testWidgets('without an OCR engine "Rifai" goes back to the camera', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await openCamera(tester, engine: false);
    await tap(tester, shutter());
    await tap(tester, find.text('Rifai'));
    expect(find.byType(ScanScreen), findsOneWidget);
    expect(camera.isOpen, isTrue);
    semantics.dispose();
  });

  testWidgets('a photo from the gallery is read the same way', (tester) async {
    await openCamera(
      tester,
      source: FakePhotoSource(galleryPhoto: const OcrImage('gallery.jpg')),
    );
    await tap(tester, find.text('Da galleria'));
    expect(find.byType(EntryScreen), findsOneWidget);
    expect(camera.discarded, ['gallery.jpg']);
  });

  testWidgets('gallery cancelled: nothing happens', (tester) async {
    await openCamera(tester);
    await tap(tester, find.text('Da galleria'));
    expect(find.byType(ScanScreen), findsOneWidget);
    expect(camera.discarded, isEmpty);
  });

  testWidgets('"A mano" switches to the manual form', (tester) async {
    await openCamera(tester);
    await tap(tester, find.text('A mano'));
    expect(find.byType(ScanScreen), findsNothing);
    expect(find.byType(EntryScreen), findsOneWidget);
    expect(find.text('Letto dalla foto'), findsNothing);
    expect(find.text('Inserita a mano'), findsOneWidget);
  });

  testWidgets('the camera button of the manual form opens the camera', (
    tester,
  ) async {
    camera = FakePhotoSource();
    await pumpApp(
      tester,
      measurements: designReadings(),
      ocrEngine: FakeOcrEngine(_display),
      photoSource: () => camera,
    );
    await tap(tester, find.text('A mano'));
    await tap(tester, find.byTooltip('Fotografa il display'));
    expect(find.byType(EntryScreen), findsNothing);
    expect(find.byType(ScanScreen), findsOneWidget);
  });

  testWidgets('the light can be switched on and off', (tester) async {
    await openCamera(tester);
    await tap(tester, find.byTooltip('Luce'));
    expect(camera.torch, isTrue);
    await tap(tester, find.byTooltip('Luce'));
    expect(camera.torch, isFalse);
  });

  testWidgets('no camera: explained, the gallery still works', (tester) async {
    await openCamera(
      tester,
      source: FakePhotoSource(
        failOpen: true,
        galleryPhoto: const OcrImage('gallery.jpg'),
      ),
    );
    expect(
      find.textContaining('Non riesco ad aprire la fotocamera'),
      findsOneWidget,
    );
    expect(find.text('Riprova'), findsOneWidget);
    await tap(tester, find.text('Da galleria'));
    expect(find.byType(EntryScreen), findsOneWidget);
  });

  group('camera permission', () {
    Future<void> pauseAndResume(WidgetTester tester) async {
      for (final s in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(s);
      }
      await tester.pumpAndSettle();
    }

    testWidgets('asked once when never answered, then the camera opens', (
      tester,
    ) async {
      await openCamera(
        tester,
        source: FakePhotoSource(access: CameraAccess.denied),
      );
      expect(camera.requests, 1);
      expect(camera.isOpen, isTrue);
    });

    testWidgets('refused: never asked again on return (no loop)', (
      tester,
    ) async {
      await openCamera(
        tester,
        source: FakePhotoSource(
          access: CameraAccess.denied,
          answer: CameraAccess.denied,
        ),
      );
      expect(camera.requests, 1);
      expect(
        find.textContaining('ha bisogno della fotocamera'),
        findsOneWidget,
      );

      // The dialog pauses and resumes the app: that must not ask again.
      for (var i = 0; i < 5; i++) {
        await pauseAndResume(tester);
      }
      expect(camera.requests, 1);
      expect(camera.opens, 0);

      // Only the button asks again.
      await tap(tester, find.text('Consenti'));
      expect(camera.requests, 2);
    });

    testWidgets('blocked: the settings, and back the camera opens', (
      tester,
    ) async {
      await openCamera(
        tester,
        source: FakePhotoSource(access: CameraAccess.blocked),
      );
      expect(camera.requests, 0);
      expect(find.textContaining('è stato negato'), findsOneWidget);

      await tap(tester, find.text('Apri impostazioni'));
      expect(camera.settingsOpened, 1);

      // Allowed in the settings, then back in the app.
      camera.access = CameraAccess.granted;
      await pauseAndResume(tester);
      expect(camera.isOpen, isTrue);
      expect(find.byKey(const Key('preview')), findsOneWidget);
      expect(camera.requests, 0);
    });

    testWidgets('the camera is released in background and back on return', (
      tester,
    ) async {
      await openCamera(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(camera.isOpen, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(camera.isOpen, isTrue);
      expect(camera.opens, 2);
    });
  });
}
