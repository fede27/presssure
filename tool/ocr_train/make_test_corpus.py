"""Copies test images, with their expected reading, into the benchmark
corpus (ocr_corpus/roboflow_test/), to compare the engine on the phone with
detect.py on the computer on the same photos.

    .venv/Scripts/python make_test_corpus.py [how many]
"""

import json
import shutil
import sys
from pathlib import Path

from detect import DATA, expected_reading

CORPUS = Path(__file__).parent.parent.parent / "ocr_corpus" / "roboflow_test"


def main(count=40):
    CORPUS.mkdir(parents=True, exist_ok=True)
    written = 0
    for image in sorted((DATA / "test" / "images").glob("*.jpg")):
        if written >= int(count):
            break
        expected = expected_reading(DATA / "test" / "labels" / (image.stem + ".txt"))
        if expected is None:
            continue
        expected["notes"] = "roboflow test"
        shutil.copy(image, CORPUS / image.name)
        (CORPUS / (image.stem + ".json")).write_text(json.dumps(expected))
        written += 1
    print(f"{written} photos in {CORPUS}")


if __name__ == "__main__":
    main(*sys.argv[1:])
