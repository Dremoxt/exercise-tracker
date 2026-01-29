#!/bin/bash

# Build script for Exercise Tracker PWA - Production Environment
# Usage: ./scripts/build_web.sh
#
# Set production environment variables before running:
# source .env && ./scripts/build_web.sh

set -e

# Check required environment variables
required_vars=(
    "FIREBASE_API_KEY"
    "FIREBASE_AUTH_DOMAIN"
    "FIREBASE_PROJECT_ID"
    "FIREBASE_STORAGE_BUCKET"
    "FIREBASE_MESSAGING_SENDER_ID"
    "FIREBASE_APP_ID"
    "GOOGLE_WEB_CLIENT_ID"
)

missing_vars=()
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        missing_vars+=("$var")
    fi
done

if [ ${#missing_vars[@]} -ne 0 ]; then
    echo "Error: Missing required environment variables:"
    printf '  - %s\n' "${missing_vars[@]}"
    echo ""
    echo "Please set these variables or create a .env file."
    exit 1
fi

echo "=========================================="
echo "  Building PRODUCTION Environment"
echo "  Project: $FIREBASE_PROJECT_ID"
echo "=========================================="
echo ""

flutter build web --release \
    --dart-define=ENV=production \
    --dart-define=FIREBASE_API_KEY="$FIREBASE_API_KEY" \
    --dart-define=FIREBASE_AUTH_DOMAIN="$FIREBASE_AUTH_DOMAIN" \
    --dart-define=FIREBASE_PROJECT_ID="$FIREBASE_PROJECT_ID" \
    --dart-define=FIREBASE_STORAGE_BUCKET="$FIREBASE_STORAGE_BUCKET" \
    --dart-define=FIREBASE_MESSAGING_SENDER_ID="$FIREBASE_MESSAGING_SENDER_ID" \
    --dart-define=FIREBASE_APP_ID="$FIREBASE_APP_ID" \
    --dart-define=GOOGLE_WEB_CLIENT_ID="$GOOGLE_WEB_CLIENT_ID"

echo ""
echo "=========================================="
echo "  Production Build Complete!"
echo "  Output: build/web/"
echo "=========================================="
echo ""
echo "IMPORTANT: Deploy Firestore security rules first:"
echo "  firebase deploy --only firestore:rules"
echo ""
echo "Then deploy to hosting:"
echo "  firebase deploy --only hosting"
