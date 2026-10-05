"""Trains the seven-segment digit detector on the upright dataset.

A small YOLO detector finds every digit (classes 0-9) and every whole
number (class 10) on the display. Images are grayscale, as the app feeds
them. No flips in the augmentation: a flipped seven-segment 2 is a 5.

    .venv/Scripts/python train.py [epochs] [image size] [model]

The best weights end up in work/runs/seg7/weights/best.pt.
"""

import sys
from pathlib import Path

from ultralytics import YOLO

HERE = Path(__file__).parent
DATA = HERE / "work" / "upright"
NAMES = [str(d) for d in range(10)] + ["number"]


def write_data_yaml():
    path = DATA / "data.yaml"
    names = "\n".join(f"  {i}: '{n}'" for i, n in enumerate(NAMES))
    path.write_text(
        f"path: {DATA.as_posix()}\n"
        "train: train/images\nval: valid/images\ntest: test/images\n"
        f"names:\n{names}\n"
    )
    return path


def main(epochs=60, imgsz=416, model="yolo11n.pt"):
    data = write_data_yaml()
    YOLO(model).train(
        data=str(data),
        epochs=int(epochs),
        imgsz=int(imgsz),
        batch=16,
        device="cpu",
        workers=4,
        project=str(HERE / "work" / "runs"),
        name="seg7",
        exist_ok=True,
        patience=15,
        # Seven-segment digits change meaning when flipped.
        fliplr=0.0,
        flipud=0.0,
        degrees=8.0,
        # Grayscale input: no hue or saturation to vary.
        hsv_h=0.0,
        hsv_s=0.0,
        hsv_v=0.4,
        translate=0.1,
        scale=0.4,
        mosaic=1.0,
        close_mosaic=10,
        plots=True,
    )


if __name__ == "__main__":
    main(*sys.argv[1:])
