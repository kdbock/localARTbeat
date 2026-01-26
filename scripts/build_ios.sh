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

# Build for iOS in release mode
echo "Building iOS app..."
flutter build ios --release --no-codesign

echo "========================================="
echo "iOS build complete!"
echo "Open the Xcode workspace to archive and distribute:"
echo "open ios/Runner.xcworkspace"
echo "========================================="
