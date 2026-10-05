"""Undoes the flips and quarter turns of the Roboflow export.

The export (Blood-Pressure-monitor-digit-reader v13, CC BY 4.0) was
augmented with horizontal/vertical flips and 90-degree rotations, but kept
the labels: a horizontally flipped seven-segment "2" looks exactly like a
"5" and is still labelled "2". Trained as is, a model would learn exactly
the confusions to avoid.

For each image, the 8 flips/rotations are tried on the labels and the one
whose numbers read like a blood pressure monitor wins (tall digits, wide
numbers, systolic on top and bigger than the diastolic, plausible values,
pulse smallest and lowest). The image is turned back to that orientation.
Ambiguous images are dropped.

Output: work/upright/{train,valid,test}/{images,labels} in YOLO format,
classes 0-9 = digits, 10 = whole number.

    .venv/Scripts/python canonicalize.py ../../roboflow_dataset
"""

import json
import random
import sys
from pathlib import Path

import cv2
import numpy as np

# Roboflow class index -> our class: digits keep their value, "10" (a box
# around a whole number) becomes 10.
ROBOFLOW_NAMES = ["0", "1", "10", "2", "3", "4", "5", "6", "7", "8", "9"]
NUMBER = 10
TO_OURS = [10 if n == "10" else int(n) for n in ROBOFLOW_NAMES]

# The 8 orientations: rotate k quarter turns clockwise, then maybe flip.
ORIENTATIONS = [(k, flip) for k in range(4) for flip in (False, True)]


def transform_box(box, k, flip):
    """Maps a normalized (cx, cy, w, h) box through rotation and flip."""
    x, y, w, h = box
    for _ in range(k):  # 90 degrees clockwise: (x, y) -> (1 - y, x)
        x, y, w, h = 1 - y, x, h, w
    if flip:
        x = 1 - x
    return x, y, w, h


def transform_image(img, k, flip):
    for _ in range(k):
        img = cv2.rotate(img, cv2.ROTATE_90_CLOCKWISE)
    if flip:
        img = cv2.flip(img, 1)
    return img


def read_numbers(labels):
    """Numbers as (value_text, box) from the digits inside each number box."""
    digits = [(c, b) for c, b in labels if c != NUMBER]
    numbers = []
    for c, (x, y, w, h) in labels:
        if c != NUMBER:
            continue
        inside = [
            (dc, db)
            for dc, db in digits
            if abs(db[0] - x) <= w / 2 + 0.01 and abs(db[1] - y) <= h / 2 + 0.01
        ]
        if not inside:
            continue
        inside.sort(key=lambda d: d[1][0])
        numbers.append(("".join(str(dc) for dc, _ in inside), (x, y, w, h)))
    return numbers


def score(labels):
    """How much the labels look like an upright monitor display."""
    s = 0.0
    digits = [b for c, b in labels if c != NUMBER]
    if digits:
        tall = sum(1 for _, _, w, h in digits if h > w) / len(digits)
        s += 4 * (tall - 0.5)
    numbers = read_numbers(labels)
    if not numbers:
        return s
    for text, (_, _, w, h) in numbers:
        if len(text) > 1:
            s += 1 if w > h else -1
        if len(text) > 1 and text[0] == "0":
            s -= 3
    # Systolic and diastolic: the two biggest numbers, systolic on top.
    big = sorted(numbers, key=lambda n: -n[1][3])[:2]
    if len(big) == 2:
        top, bottom = sorted(big, key=lambda n: n[1][1])
        sys_v, dia_v = int(top[0]), int(bottom[0])
        if 70 <= sys_v <= 250:
            s += 3
        if len(top[0]) == 3 and top[0][0] in "12":
            s += 1
        if 40 <= dia_v <= 140:
            s += 3
        if sys_v > dia_v:
            s += 2
            if 15 <= sys_v - dia_v <= 100:
                s += 1
        # Pulse: smaller, below the systolic.
        rest = [n for n in numbers if n not in big]
        if rest:
            pulse = max(rest, key=lambda n: n[1][3])
            if 40 <= int(pulse[0]) <= 150:
                s += 1
            if pulse[1][1] > top[1][1]:
                s += 1
    return s


def load_labels(path):
    labels = []
    for line in path.read_text().splitlines():
        parts = line.split()
        if len(parts) != 5:
            continue
        c = TO_OURS[int(parts[0])]
        labels.append((c, tuple(float(v) for v in parts[1:])))
    return labels


def main(dataset, out=Path(__file__).parent / "work" / "upright"):
    dataset = Path(dataset)
    stats = {}
    kept_examples = []
    for split in ("train", "valid", "test"):
        images_out = out / split / "images"
        labels_out = out / split / "labels"
        images_out.mkdir(parents=True, exist_ok=True)
        labels_out.mkdir(parents=True, exist_ok=True)
        counts = {"kept": 0, "ambiguous": 0, "no_numbers": 0, "turned": 0}
        for label_path in sorted((dataset / split / "labels").glob("*.txt")):
            labels = load_labels(label_path)
            if not any(c == NUMBER for c, _ in labels):
                counts["no_numbers"] += 1
                continue
            ranked = sorted(
                (
                    (score([(c, transform_box(b, k, f)) for c, b in labels]), k, f)
                    for k, f in ORIENTATIONS
                ),
                reverse=True,
            )
            best, runner_up = ranked[0], ranked[1]
            if best[0] - runner_up[0] < 2:
                counts["ambiguous"] += 1
                continue
            _, k, flip = best
            image_path = dataset / split / "images" / (label_path.stem + ".jpg")
            img = cv2.imread(str(image_path))
            if img is None:
                continue
            cv2.imwrite(
                str(images_out / image_path.name), transform_image(img, k, flip)
            )
            lines = [
                "%d %.6f %.6f %.6f %.6f" % (c, *transform_box(b, k, flip))
                for c, b in labels
            ]
            (labels_out / label_path.name).write_text("\n".join(lines) + "\n")
            counts["kept"] += 1
            if k or flip:
                counts["turned"] += 1
            if split == "train":
                kept_examples.append(images_out / image_path.name)
        stats[split] = counts
        print(split, counts)
    (out / "stats.json").write_text(json.dumps(stats, indent=2))
    _montage(kept_examples, out / "montage.jpg")


def _montage(paths, target, n=12):
    """A few results with their labels, to check by eye."""
    random.seed(1)
    tiles = []
    for p in random.sample(paths, min(n, len(paths))):
        img = cv2.imread(str(p))
        h, w = img.shape[:2]
        label = p.parent.parent / "labels" / (p.stem + ".txt")
        for c, (x, y, bw, bh) in load_labels_ours(label):
            p1 = (int((x - bw / 2) * w), int((y - bh / 2) * h))
            p2 = (int((x + bw / 2) * w), int((y + bh / 2) * h))
            if c == NUMBER:
                cv2.rectangle(img, p1, p2, (0, 0, 255), 2)
            else:
                cv2.rectangle(img, p1, p2, (0, 200, 0), 1)
                cv2.putText(img, str(c), (p1[0], p1[1] - 3),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 0, 0), 2)
        tiles.append(cv2.resize(img, (320, 320)))
    while len(tiles) % 4:
        tiles.append(np.zeros_like(tiles[0]))
    rows = [np.hstack(tiles[i:i + 4]) for i in range(0, len(tiles), 4)]
    cv2.imwrite(str(target), np.vstack(rows))


def load_labels_ours(path):
    return [
        (int(p[0]), tuple(float(v) for v in p[1:]))
        for p in (line.split() for line in path.read_text().splitlines())
        if len(p) == 5
    ]


if __name__ == "__main__":
    main(sys.argv[1])
