# PressSure

Diario della pressione per Android: si fotografa il display del misuratore e
l'app scrive i valori. I dati restano sul telefono: niente account, niente
server.

## Build

Flutter (vedi `pubspec.yaml` e `pubspec.lock`).

```
flutter build apk --release
```

Le build beta per i tester si fanno con `--dart-define=BETA=true`
(`lib/config.dart`); quelle pubbliche non conservano foto.

### F-Droid

- Il runtime TensorFlow Lite è `de.schliweb:tensorflow-lite-fdroid`, compilato
  dal sorgente senza dipendenze proprietarie. Le AAR LiteRT di Google che
  `tflite_flutter` porterebbe con sé sono escluse in
  `android/build.gradle.kts`.
- Le schede dello store (testi, icona, screenshot) sono in
  `fastlane/metadata/android/`. Gli screenshot si rigenerano con
  `flutter test tool/store_screenshots/store_screenshots_test.dart`.

## Lettura del display

Un piccolo detector YOLO in TensorFlow Lite (`assets/models/seg7.tflite`)
trova le cifre del display. Addestramento ed esportazione sono in
`tool/ocr_train/` (vedi il README lì): il modello si può riprodurre dal
dataset pubblico e dagli script.

## Licenze

- **Codice**: GNU Affero General Public License v3.0 o successiva
  (AGPL-3.0-or-later), vedi `LICENSE`. Copyright © 2026 fede27.
- **Modello** `assets/models/seg7.tflite`: addestrato a partire dai pesi
  YOLO di [Ultralytics](https://www.ultralytics.com/license), AGPL-3.0.
- **Dataset di addestramento**:
  [Blood-Pressure-monitor-digit-reader](https://universe.roboflow.com/naphop/blood-pressure-monitor-digit-reader)
  di naphop (Roboflow Universe), CC BY 4.0.
- **Font** Manrope e Bricolage Grotesque: SIL Open Font License 1.1, vedi
  `assets/fonts/`.
