"""Utility to export the Vietnamese recommendation knowledge base to JSON."""
from __future__ import annotations

import argparse
import importlib.util
import json
from pathlib import Path
from typing import Any, Dict, List

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SOURCE = ROOT / "docs" / "recommendation_vi.py"
DEFAULT_OUTPUT = ROOT / "data" / "processed" / "recommendations_vi.json"


def _load_module(path: Path):
    spec = importlib.util.spec_from_file_location("recommendation_vi", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to import module from {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _to_plain_title(first_line: str) -> Dict[str, str | None]:
    text = first_line.strip().strip("*").strip()
    crop = None
    disease = None
    if "–" in text:
        parts = [part.strip() for part in text.split("–", 1)]
        if len(parts) == 2:
            crop, disease = parts
    return {"title": text, "crop": crop, "disease": disease}


def build_payload(module) -> Dict[str, Any]:
    recommendations: List[Dict[str, Any]] = []
    for label, body in sorted(module.RECOMMENDATIONS.items()):
        lines = [line for line in body.strip().splitlines() if line.strip()]
        metadata = _to_plain_title(lines[0] if lines else "")
        recommendations.append(
            {
                "label": label,
                "title": metadata["title"],
                "crop": metadata["crop"],
                "disease": metadata["disease"],
                "markdown": body.strip(),
            }
        )

    payload = {
        "metadata": {
            "source": str(DEFAULT_SOURCE.relative_to(ROOT)),
            "total_labels": len(module.RECOMMENDATIONS),
            "quick_reference_rows": len(module.QUICK_REF),
        },
        "general_blocks": {
            "default_healthy": module.DEFAULT_HEALTHY.strip(),
            "ipm": module.IPM_BLOCK.strip(),
            "safety": module.SAFETY_MEDICAL.strip(),
            "resistance": module.RESISTANCE_NOTES.strip(),
            "fallback": module.FALLBACK.strip(),
        },
        "recommendations": recommendations,
        "quick_reference": module.QUICK_REF,
    }
    return payload


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--source",
        type=Path,
        default=DEFAULT_SOURCE,
        help="Path to docs/recommendation_vi.py",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT,
        help="Destination JSON path",
    )
    args = parser.parse_args()

    module = _load_module(args.source)
    payload = build_payload(module)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Wrote {args.output} ({payload['metadata']['total_labels']} labels)")


if __name__ == "__main__":
    main()
