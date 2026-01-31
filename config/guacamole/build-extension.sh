#!/bin/bash
# Build the M2 Desktop branding extension JAR
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BRANDING_DIR="${SCRIPT_DIR}/branding"
OUTPUT_JAR="${SCRIPT_DIR}/m2-branding.jar"

cd "${BRANDING_DIR}"

# Create the JAR (which is just a ZIP file)
zip -r "${OUTPUT_JAR}" guac-manifest.json head.html styles.css scripts.js

echo "Built: ${OUTPUT_JAR}"
