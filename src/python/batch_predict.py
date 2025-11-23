"""CLI tool for running batch predictions against the trained model.

Example usage:
    python src/python/batch_predict.py ./samples --output predictions.csv
    python src/python/batch_predict.py ./samples --output predictions.csv --plant Apple
"""
from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path
from typing import Iterable

from fastapi import HTTPException

REPO_ROOT = Path(__file__).resolve().parents[2]
if str(REPO_ROOT) not in sys.path:
    sys.path.append(str(REPO_ROOT))

from api.api_server import (  # noqa: E402
    PLANT_TO_CLASS_INDICES,
    load_model,
    preprocess_image,
    predict,
)


def iter_image_files(path: Path) -> Iterable[Path]:
    """Yield supported image files from a directory or the file itself."""

    if path.is_file():
        yield path
        return

    patterns = ("*.jpg", "*.jpeg", "*.png", "*.bmp", "*.gif", "*.webp")
    seen: set[Path] = set()
    for pattern in patterns:
        for file in path.glob(pattern):
            resolved = file.resolve()
            if resolved not in seen:
                seen.add(resolved)
                yield resolved


def score_image(image_path: Path, *, plant: str | None = None) -> dict:
    """Load an image and run prediction, returning a flattened payload."""

    contents = image_path.read_bytes()
    array = preprocess_image(contents)
    result = predict(array, plant=plant)

    probability = result.get("normalized_probability") or result.get("confidence")
    recommendation = result.get("recommendation_markdown")

    return {
        "filename": image_path.name,
        "plant": result.get("plant"),
        "disease": result.get("disease"),
        "probability": probability,
        "recommendation_markdown": recommendation,
        "error": None,
    }


def run_batch(input_path: Path, output_csv: Path, *, plant: str | None = None) -> None:
    """Score all images under ``input_path`` and persist results to CSV."""

    if plant and plant not in PLANT_TO_CLASS_INDICES:
        raise ValueError(f"Unknown plant '{plant}'. Valid options: {', '.join(sorted(PLANT_TO_CLASS_INDICES))}")

    if not input_path.exists():
        raise FileNotFoundError(f"Input path does not exist: {input_path}")

    model = load_model()
    _ = model  # Explicitly hold reference to keep cache warm during loop

    rows = []
    for image_file in iter_image_files(input_path):
        try:
            rows.append(score_image(image_file, plant=plant))
        except (HTTPException, Exception) as exc:  # noqa: BLE001
            rows.append(
                {
                    "filename": image_file.name,
                    "plant": plant,
                    "disease": None,
                    "probability": None,
                    "recommendation_markdown": None,
                    "error": str(exc),
                }
            )

    if not rows:
        raise ValueError(f"No supported images found under {input_path}")

    output_csv.parent.mkdir(parents=True, exist_ok=True)
    fieldnames = ["filename", "plant", "disease", "probability", "recommendation_markdown", "error"]
    with output_csv.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Batch inference against the plant disease model")
    parser.add_argument("input", type=Path, help="Path to a single image or a directory of images")
    parser.add_argument("--output", type=Path, required=True, help="Destination CSV file")
    parser.add_argument(
        "--plant",
        type=str,
        choices=sorted(PLANT_TO_CLASS_INDICES),
        help="Optional plant filter (same as API query parameter)",
    )

    args = parser.parse_args()
    run_batch(args.input, args.output, plant=args.plant)
