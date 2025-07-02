#!/bin/bash
set -euo pipefail

echo "Creating build directory..."
mkdir -p build

echo "Installing dependencies from requirements.txt..."
pip install -r requirements.txt -t build/

echo "Copying Lambda source files..."
cp lambda_function.py __init__.py build/

echo "Zipping build artifacts..."
cd build
zip -r ../lambda_function.zip .
cd ..

echo "Build complete."

