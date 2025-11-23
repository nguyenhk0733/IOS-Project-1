PYTHON ?= python3
APP_MODULE ?= api.api_server:app
PORT ?= 8000
IMAGE_NAME ?= plant-disease-api
INPUT ?=
OUTPUT ?=
PLANT ?=

.PHONY: install serve docker-build docker-run batch-predict

install:
	$(PYTHON) -m pip install --upgrade pip
	$(PYTHON) -m pip install -r requirements.txt

serve:
	uvicorn $(APP_MODULE) --host 0.0.0.0 --port $(PORT)

docker-build:
	docker build -t $(IMAGE_NAME) .

docker-run:
	docker run --rm -p $(PORT):8000 -e PORT=8000 $(IMAGE_NAME)

batch-predict:
	@if [ -z "$(INPUT)" ] || [ -z "$(OUTPUT)" ]; then \
		echo "Usage: make batch-predict INPUT=/path/to/images OUTPUT=predictions.csv [PLANT=Apple]"; \
		exit 1; \
	fi
	$(PYTHON) src/python/batch_predict.py $(INPUT) --output $(OUTPUT) $(if $(PLANT),--plant $(PLANT),)
