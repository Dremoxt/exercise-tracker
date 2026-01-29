#!/bin/bash

# Build script for Exercise Tracker PWA - QA Environment (UI Testing Only)
# Usage: ./scripts/build_qa.sh
#
# No Firebase credentials needed - this build is for local UI testing only.
# Cloud sync features will be disabled.

set -e

echo "=========================================="
echo "  Building QA Environment (UI Only)"
echo "  Firebase: DISABLED"
echo "  Storage: Local only"
echo "=========================================="
echo ""

flutter build web --release --dart-define=ENV=qa

echo ""
echo "=========================================="
echo "  QA Build Complete!"
echo "  Output: build/web/"
echo "=========================================="
echo ""
echo "To test locally:"
echo "  cd build/web && python3 -m http.server 8080"
echo "  Then open: http://localhost:8080"
echo ""
echo "Note: Cloud sync is disabled in QA mode."
echo "      Data is stored locally only."
