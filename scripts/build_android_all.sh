#!/bin/bash

echo "========================================="
echo "ARTbeat Android Build Script"
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

# Build debug APK for testing
echo "Building debug APK..."
flutter build apk --debug

# Build release APK with minification disabled to avoid Stripe SDK issues
echo "Building release APK..."
flutter build apk --release

# Build app bundle for Play Store
echo "Building app bundle for Play Store..."
flutter build appbundle --release

echo "========================================="
echo "Build complete! Check the output files:"
echo "Debug APK: build/app/outputs/flutter-apk/app-debug.apk"
echo "Release APK: build/app/outputs/flutter-apk/app-release.apk"
echo "Bundle: build/app/outputs/bundle/release/app-release.aab"
echo "========================================="
