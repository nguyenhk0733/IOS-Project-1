# Models

Store serialized ML/DL artifacts in versioned subdirectories to track releases and
allow rollbacks.

## Layout

```
models/
└── v1/
    ├── trained_model.h5
    └── trained_model.keras
```

## Workflow

1. Export a new model to `models/<version>/` (for example `v2`).
2. Set the environment variable `MODEL_VERSION=<version>` in your deployment
   configuration to switch the runtime to the new artifact.
3. Keep previous versions to roll back quickly if needed.
