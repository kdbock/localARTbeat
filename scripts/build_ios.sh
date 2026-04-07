#!/bin/bash

echo "========================================="
echo "ARTbeat iOS Build Script"
echo "========================================="

# Check if --clean flag is provided
CLEAN=false
for arg in "$@"; do
  if [ "$arg" == "--clean" ]; then
    CLEAN=true
    break
  fi
done

# Clean the build folder if requested
if [ "$CLEAN" == true ]; then
  echo "Cleaning build directory..."
  flutter clean
else
  echo "Skipping clean. Use --clean for a fresh build."
fi

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Load production environment variables
ENV_FILE=".env.production"
if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: $ENV_FILE not found. Cannot build release without environment configuration."
  exit 1
fi
echo "Loading environment from $ENV_FILE..."
set -a
source "$ENV_FILE"
set +a

# Validate required vars
for VAR in API_BASE_URL STRIPE_PUBLISHABLE_KEY FIREBASE_REGION FIREBASE_PROJECT_ID; do
  if [ -z "${!VAR}" ]; then
    echo "ERROR: $VAR is not set in $ENV_FILE"
    exit 1
  fi
done

# Build for iOS in release mode
echo "Building iOS app..."
flutter build ios --release --no-codesign \
  "--dart-define=API_BASE_URL=$API_BASE_URL" \
  "--dart-define=STRIPE_PUBLISHABLE_KEY=$STRIPE_PUBLISHABLE_KEY" \
  "--dart-define=FIREBASE_REGION=$FIREBASE_REGION" \
  "--dart-define=FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID" \
  "--dart-define=GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY" \
  "--dart-define=ENVIRONMENT=production"

echo "========================================="
echo "iOS build complete!"
echo "Open the Xcode workspace to archive and distribute:"
echo "open ios/Runner.xcworkspace"
echo "========================================="
