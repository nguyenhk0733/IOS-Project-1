# User Guide

This guide explains how to set up the environment, download the plant disease dataset, and run the project assets.

## Prerequisites
- **Hardware**: macOS machine capable of running Xcode 15+ simulators (8 GB RAM minimum recommended) for the iOS app; 10 GB free disk space for dataset storage and preprocessing outputs.
- **Software**:
  - Xcode 15 or newer with command line tools.
  - Python 3.10+ with `pip` and a virtual environment tool (e.g., `venv`).
  - (Optional) Kaggle CLI for dataset download.

## Installation
1. Clone the repository and install Python dependencies:
   ```bash
   git clone <repo-url>
   cd IOS-Project-1
   python -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt
   ```
2. For iOS development, open the workspace in Xcode:
   ```bash
   open ios/IOS-Project-1.xcodeproj
   ```
3. Confirm data folders are present (`data/raw/`, `data/processed/`).

## Dataset notes (New Plant Diseases Dataset)
- Source: Kaggle — https://www.kaggle.com/datasets/vipoooool/new-plant-diseases-dataset
- Size: ~3.5 GB of training and validation images across multiple crop disease classes.
- Suggested layout:
  - Place the downloaded archive inside `data/raw/` and extract it there. Keep the original archive as read-only.
  - Use `notebooks/` or `src/python/preprocessing.py` to clean/resize images, then export results to `data/processed/`.
- Download via Kaggle CLI (requires a Kaggle API token placed in `~/.kaggle/kaggle.json`):
  ```bash
  kaggle datasets download -d vipoooool/new-plant-diseases-dataset -p data/raw
  unzip data/raw/new-plant-diseases-dataset.zip -d data/raw
  ```

## Running notebooks and scripts
- Launch notebooks for exploratory analysis:
  ```bash
  jupyter notebook notebooks/
  ```
- Run preprocessing to generate cleaned outputs:
  ```bash
  python src/python/preprocessing.py --input data/raw --output data/processed
  ```

## iOS app quick start
- With the dataset processed, update any local file references (if needed) in the iOS project under `ios/`.
- In Xcode, select a simulator/device and press **Cmd + R** to build and run.
- Use **Cmd + U** to execute unit tests once they are added.
