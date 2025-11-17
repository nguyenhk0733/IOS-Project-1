# Repository Structure

```
.
├── api/                # Backend/API entrypoints
├── app/                # Cross-platform app glue and shared assets
├── data/
│   ├── processed/      # Feature-ready datasets
│   └── raw/            # Source datasets (read-only)
├── docs/               # Documentation and architecture notes
├── ios/                # Native iOS application code
├── models/             # Serialized ML/DL artifacts
├── notebooks/          # Experimentation notebooks
├── src/
│   ├── index.ts        # TypeScript placeholder module
│   └── python/
│       └── preprocessing.py
```

Use this layout as the canonical reference when adding new files to the project.
