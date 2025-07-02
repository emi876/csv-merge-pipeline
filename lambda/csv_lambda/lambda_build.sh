#!/bin/bash
set -euo pipefail

echo "Installing dependencies from requirements.txt..."
pip install -r $requirements_path -t .

echo "Build complete."
