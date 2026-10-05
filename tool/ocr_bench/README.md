# OCR benchmark

Measures how well each OCR engine reads blood pressure displays, on the
phone, over a corpus of labelled photos.

## The corpus

`ocr_corpus/` at the project root (not in git: they are real readings).
Any subfolder; each photo (`.jpg`, `.jpeg`, `.png`) has a label next to it
with the same name:

```
ocr_corpus/
  omron/
    001.jpg
    001.json   {"sys": 124, "dia": 77, "pulse": 68, "notes": "riflesso"}
  app/         photos labelled in "PressSure dev" (see below)
```

`pulse` can be left out when the display has none. `notes` describes the
conditions (`riflesso`, `buio`, `storta`, `lontana`...) and shows up in the
report.

Photos are prepared as in the app's "Da galleria": upright, at most 1600 px.
Photos taken in the app are already cut to the frame.

### Collecting photos with the app

The development build ("PressSure dev", `com.fscarel.presssure.debug`, next
to the real app and with its own data) keeps every photo it reads: when the
values are saved, the photo is labelled with them, so check them against the
display. Photos not saved, or saved as the average of two readings, are
dropped. Release builds never keep photos.

```
flutter run -d <phone>
```

`run.ps1` brings these photos into `ocr_corpus/app/`.

## Running it

```
powershell -ExecutionPolicy Bypass -File tool\ocr_bench\run.ps1
```

The phone must be connected with USB debugging authorized. The script:

1. builds and installs "PressSure dev" (never the real app);
2. copies the photos labelled on the phone into `ocr_corpus/app/`;
3. copies the corpus into "PressSure dev";
4. runs `integration_test/ocr_benchmark_test.dart` there;
5. brings back `ocr_results/<engine>/report.md` (and `report.json`);
6. copies the raw engine output to `test/ocr/recordings/<engine>/`.

To try it before having photos, `dart run tool/ocr_bench/make_smoke_sample.dart`
writes one printed (not LCD) sample.

**Never run `flutter test integration_test/...` by hand without
`--no-uninstall`:** by default Flutter uninstalls the app at the end, and
with a stale build it can pick the wrong one (it once removed the real app).

## Reading the report

For each value: *sure and right*, *to check but right*, *to check and wrong*
(the user corrects it), *missing* (the user copies it), and **silent error**:
wrong but shown as sure. Silent errors are the only ones a user may save
without noticing; the goal is zero.

## Replaying on the computer

`test/ocr/recordings_test.dart` replays the recordings with the current
parser: change `lib/ocr/reading_parser.dart`, run `flutter test`, and see
the effect on real engine output in seconds. The test fails on any silent
error.

The recordings hold the values of the photos (not the photos) and stay out
of git (`.gitignore`): on a fresh clone the replay is skipped until a
benchmark run, or `tool/ocr_train/replay.dart`, writes them again.

## Adding an engine

There is none at the moment: ML Kit was tried and dropped, it misreads
seven-segment digits (163 as 153, a known issue for years). Implement
`OcrEngine` (`lib/ocr/ocr_engine.dart`) and add it to `engines` in
`integration_test/ocr_benchmark_test.dart`.
