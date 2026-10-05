# Seven-segment engine: training

The app's OCR engine (`lib/ocr/seg7_engine.dart`) is a small YOLO detector
that finds every digit (classes 0–9) and every whole number (class 10) on
a blood pressure monitor display. The digits are grouped into numbers by
`lib/ocr/digit_grouping.dart` and read by `lib/ocr/reading_parser.dart`.

## Data

[Blood-Pressure-monitor-digit-reader](https://universe.roboflow.com/naphop/blood-pressure-monitor-digit-reader)
by naphop on Roboflow Universe, **CC BY 4.0** (credited in the app, in
*Impostazioni › Avvertenza e fonti delle soglie*). Export "YOLOv8", unzipped
into `roboflow_dataset/` at the project root (not in git).

That export was augmented with flips and quarter turns while keeping the
labels: a flipped seven-segment 2 looks like a 5 and is still labelled 2.
`canonicalize.py` turns every image back upright (the orientation whose
labels read like a monitor) and drops the ambiguous ones.

The photos kept by beta testers and the ones labelled in "PressSure dev"
(`tool/ocr_bench`) are for testing only, never for training.

## Steps

Python 3.12; everything lives in `tool/ocr_train/.venv` and
`tool/ocr_train/work/` (not in git).

```
cd tool/ocr_train
python -m venv .venv
.venv\Scripts\python -m pip install ultralytics --index-url https://download.pytorch.org/whl/cpu --extra-index-url https://pypi.org/simple
.venv\Scripts\python -m pip install onnx2tf tensorflow tf_keras onnx_graphsurgeon sng4onnx ai-edge-litert onnxruntime opencv-python-headless

.venv\Scripts\python canonicalize.py ..\..\roboflow_dataset   # -> work/upright
.venv\Scripts\python train.py 50 416                          # hours on a CPU
.venv\Scripts\python detect.py work\runs\seg7\weights\best.pt test 416
cd ..\..
dart run tool/ocr_train/replay.dart tool/ocr_train/work/detections/best_test
cd tool\ocr_train
.venv\Scripts\python export_tflite.py work\runs\seg7\weights\best.pt 416
```

- `detect.py` writes the raw detections of the test images; `replay.dart`
  groups and parses them with the app's code, prints the report (silent
  errors first) and saves recordings in `test/ocr/recordings/seg7/`, which
  `flutter test` replays: parser and grouping changes are measured in
  seconds.
- `export_tflite.py` converts to TFLite (Ultralytics cannot on Windows),
  checks it gives the same scores as the trained model, and copies it to
  `assets/models/seg7.tflite`.
- Then `tool/ocr_bench/run.ps1` measures the engine on the phone, on real
  photos.

No flips in the training augmentation, and grayscale input: the app feeds
grayscale photos (`lib/ocr/seg7_model.dart`), stretched to the square.
