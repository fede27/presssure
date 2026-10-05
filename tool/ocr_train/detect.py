"""Runs a trained detector on the test images and writes its raw output.

One JSON per image in work/detections/<name>/: the digit and number boxes
found (class, confidence, box in pixels) and the reading the image shows,
taken from its labels. The app's own Dart code then groups the digits and
parses the reading (tool/ocr_train/replay.dart), so the test measures
exactly what the app does.

    .venv/Scripts/python detect.py work/runs/seg7/weights/best.pt [split] [imgsz]

Works with .pt and .tflite weights (to check the exported model too).
"""

import json
import sys
from pathlib import Path

import cv2
from ultralytics import YOLO

HERE = Path(__file__).parent
DATA = HERE / "work" / "upright"
NUMBER = 10


def expected_reading(label_path):
    """Systolic, diastolic and pulse from the labels, as on the display."""
    labels = []
    for line in label_path.read_text().splitlines():
        p = line.split()
        if len(p) == 5:
            labels.append((int(p[0]), tuple(float(v) for v in p[1:])))
    digits = [(c, b) for c, b in labels if c != NUMBER]
    numbers = []
    for c, (x, y, w, h) in labels:
        if c != NUMBER:
            continue
        inside = sorted(
            (
                (db[0], dc)
                for dc, db in digits
                if abs(db[0] - x) <= w / 2 + 0.01 and abs(db[1] - y) <= h / 2 + 0.01
            )
        )
        if inside:
            numbers.append(("".join(str(dc) for _, dc in inside), (x, y, w, h)))
    # Reading order, as on the display: systolic first, then diastolic,
    # then pulse. Some monitors show the three numbers at the same size, so
    # the size alone does not tell them apart: among the big numbers (at
    # least 80% of the tallest) the top ones come first.
    if len(numbers) < 2:
        return None
    tallest = max(n[1][3] for n in numbers)
    big = sorted((n for n in numbers if n[1][3] >= 0.8 * tallest), key=lambda n: n[1][1])
    small = sorted((n for n in numbers if n[1][3] < 0.8 * tallest), key=lambda n: -n[1][3])
    ordered = big + small
    expected = {"sys": int(ordered[0][0]), "dia": int(ordered[1][0])}
    # Some labels are wrong (pulse 791, systolic below diastolic): no
    # reliable expectation, the image is left out.
    if not (60 <= expected["sys"] <= 260 and 30 <= expected["dia"] < expected["sys"]):
        return None
    if len(ordered) > 2 and 30 <= int(ordered[2][0]) <= 220:
        expected["pulse"] = int(ordered[2][0])
    return expected


def main(weights, split="test", imgsz=416):
    weights = Path(weights)
    model = YOLO(str(weights), task="detect")
    out = HERE / "work" / "detections" / f"{weights.stem}_{split}"
    out.mkdir(parents=True, exist_ok=True)
    images = sorted((DATA / split / "images").glob("*.jpg"))
    written = 0
    for image in images:
        expected = expected_reading(DATA / split / "labels" / (image.stem + ".txt"))
        if expected is None:
            continue
        # The app feeds grayscale photos.
        gray = cv2.cvtColor(cv2.imread(str(image)), cv2.COLOR_BGR2GRAY)
        bgr = cv2.cvtColor(gray, cv2.COLOR_GRAY2BGR)
        result = model.predict(
            bgr, imgsz=int(imgsz), conf=0.1, iou=0.5, verbose=False
        )[0]
        detections = [
            {
                "cls": int(c),
                "conf": round(float(p), 4),
                "box": [round(float(v), 1) for v in (x1, y1, x2 - x1, y2 - y1)],
            }
            for (x1, y1, x2, y2), c, p in zip(
                result.boxes.xyxy.tolist(),
                result.boxes.cls.tolist(),
                result.boxes.conf.tolist(),
            )
        ]
        (out / (image.stem + ".json")).write_text(
            json.dumps(
                {
                    "sample": f"roboflow_{split}/{image.stem}",
                    "expected": expected,
                    "detections": detections,
                    "elapsedMs": round(sum(result.speed.values())),
                }
            )
        )
        written += 1
    print(f"{written} images -> {out}")


if __name__ == "__main__":
    main(*sys.argv[1:])
