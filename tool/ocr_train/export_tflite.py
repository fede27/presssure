"""Exports the trained detector for the app: .pt -> ONNX -> TFLite.

Ultralytics exports TFLite only on Linux and macOS; on Windows the ONNX
model is converted with onnx2tf (what Ultralytics uses inside). The TFLite
model is checked against the ONNX one on a few test images, then copied to
assets/models/seg7.tflite.

    .venv/Scripts/python export_tflite.py work/runs/seg7/weights/best.pt [imgsz]
"""

import shutil
import sys
from pathlib import Path

import cv2
import numpy as np
import onnx2tf
import onnxruntime as ort
from ai_edge_litert.interpreter import Interpreter
from ultralytics import YOLO

HERE = Path(__file__).parent
ASSET = HERE.parent.parent / "assets" / "models" / "seg7.tflite"


def model_input(path, size):
    """As the app does it (lib/ocr/seg7_model.dart): grayscale, stretched,
    0..1, three equal channels."""
    gray = cv2.imread(str(path), cv2.IMREAD_GRAYSCALE)
    square = cv2.resize(gray, (size, size), interpolation=cv2.INTER_LINEAR)
    x = square.astype(np.float32) / 255.0
    return np.repeat(x[:, :, None], 3, axis=2)[None]  # 1, s, s, 3


def main(weights, imgsz=416):
    imgsz = int(imgsz)
    weights = Path(weights)
    onnx_path = Path(
        YOLO(str(weights)).export(format="onnx", imgsz=imgsz, simplify=True, opset=17)
    )
    out = weights.parent / "tflite"
    onnx2tf.convert(
        input_onnx_file_path=str(onnx_path),
        output_folder_path=str(out),
        non_verbose=True,
    )
    # The float16 variant does not run in LiteRT (float16 activations).
    tflite = out / f"{onnx_path.stem}_float32.tflite"

    # Same answers as the ONNX model, on real test photos.
    session = ort.InferenceSession(str(onnx_path))
    interpreter = Interpreter(model_path=str(tflite))
    interpreter.allocate_tensors()
    inp = interpreter.get_input_details()[0]
    outp = interpreter.get_output_details()[0]
    print("tflite input", inp["shape"], "output", outp["shape"])
    images = sorted((HERE / "work" / "upright" / "test" / "images").glob("*.jpg"))[:5]
    worst = 0.0
    for image in images:
        x = model_input(image, imgsz)
        onnx_out = session.run(None, {session.get_inputs()[0].name: x.transpose(0, 3, 1, 2)})[0]
        interpreter.set_tensor(inp["index"], x)
        interpreter.invoke()
        tfl_out = interpreter.get_tensor(outp["index"])
        if tfl_out.shape != onnx_out.shape:
            tfl_out = tfl_out.transpose(0, 2, 1)
        scores = slice(4, None)
        worst = max(worst, float(np.abs(tfl_out[:, scores] - onnx_out[:, scores]).max()))
    print(f"largest score difference TFLite vs ONNX: {worst:.5f}")
    if worst > 0.01:
        sys.exit("The TFLite model does not match: not copied.")

    ASSET.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy(tflite, ASSET)
    print(f"copied to {ASSET} ({ASSET.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main(*sys.argv[1:])
