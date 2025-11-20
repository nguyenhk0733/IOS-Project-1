# API Layer

Backend or serverless endpoints that serve the mobile applications belong here.
Document any new service contracts in this file or link to the relevant spec in `docs/`.

## `/predict` response fields

The `/predict` endpoint now returns Markdown guidance for the predicted label
when `data/processed/recommendations_vi.json` is available in the deployment
artifact. The `recommendation_markdown` key contains the disease-specific
guidance; if no exact match is found the API falls back to the general
recommendation block.
