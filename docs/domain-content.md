# Domain Content Pipeline (VN Recommendations)

This document explains how the Vietnamese plant-disease recommendations are
stored, converted to JSON, and consumed inside the iOS client.

## Source of truth
- Authoritative content lives in [`docs/recommendation_vi.py`](recommendation_vi.py).
- The file keeps rich Markdown blocks for every PlantVillage label plus reusable
  safety/IPM snippets.
- Keeping the rules inside `docs/` makes it easy for agronomists to edit without
  touching application code.

## Exporting to processed data
Use `src/python/export_recommendations.py` to build a normalized JSON payload:

```bash
python src/python/export_recommendations.py \
  --source docs/recommendation_vi.py \
  --output data/processed/recommendations_vi.json
```

The script:
- Loads the Python dictionary dynamically (no copy/paste required).
- Extracts crop/disease titles, deduplicates healthy/IPM/safety blocks.
- Writes `data/processed/recommendations_vi.json` with:
  - `metadata`: counts + file provenance.
  - `general_blocks`: shared Markdown snippets for healthy leaves, IPM, safety,
    resistance, and fallback text.
  - `recommendations`: array sorted by PlantVillage label including label, crop,
    disease, and the original Markdown instructions.
  - `quick_reference`: compact table rows for UI widgets.

## Using the JSON in iOS
1. Add `data/processed/recommendations_vi.json` to your Xcode project as a
   bundled resource (make sure “Target Membership” is checked).
2. Import `ios/DomainContent/RecommendationService.swift` into the app target.
3. Call `RecommendationService.shared.load()` once during app start to decode
   the JSON into strongly-typed models. The service exposes `payload`,
   `recommendation(for:)`, and helper functions for SwiftUI views.

## Updating the knowledge base
1. Edit `docs/recommendation_vi.py` (or ask the agronomy team to do so).
2. Run the export script to regenerate the processed JSON.
3. Commit both the script changes and the resulting JSON.
4. Re-build the iOS app; the service will automatically pick up the updated
   content because it only depends on the bundled JSON file.

Following this workflow keeps agronomy data versioned and reproducible, while
providing the iOS layer with a stable schema.
