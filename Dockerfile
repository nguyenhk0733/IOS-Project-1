# Lightweight image to serve the FastAPI prediction service
FROM python:3.10-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app

WORKDIR /app

# System deps for opencv
RUN apt-get update \ 
    && apt-get install -y --no-install-recommends libgl1 \ 
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY api ./api
COPY src ./src
COPY models ./models
COPY data ./data

EXPOSE 8000

CMD ["uvicorn", "api.api_server:app", "--host", "0.0.0.0", "--port", "8000"]
