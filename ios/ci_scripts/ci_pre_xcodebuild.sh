#!/bin/bash

# Pre-Xcodebuild Script for Xcode Cloud
# This script ensures Flutter files are properly generated before building

set -e

echo "Pre-xcodebuild: Verifying Flutter environment..."

# Change to the project root
cd "$CI_PRIMARY_REPOSITORY_PATH"

# Ensure Flutter is in PATH
if ! command -v flutter &> /dev/null; then
    export PATH="$PATH:$HOME/flutter/bin"
fi

# Verify Generated.xcconfig exists
GENERATED_XCCONFIG="$CI_PRIMARY_REPOSITORY_PATH/ios/Flutter/Generated.xcconfig"
if [ ! -f "$GENERATED_XCCONFIG" ]; then
    echo "Generated.xcconfig not found. Regenerating Flutter iOS files..."
    flutter pub get
fi

# Verify all required Flutter files exist
echo "Verifying Flutter iOS files..."
FLUTTER_DIR="$CI_PRIMARY_REPOSITORY_PATH/ios/Flutter"
required_files=(
    "Generated.xcconfig"
    "AppFrameworkInfo.plist"
)

for file in "${required_files[@]}"; do
    if [ ! -f "$FLUTTER_DIR/$file" ]; then
        echo "Missing: $file. Regenerating..."
        flutter pub get
        break
    else
        echo "✓ Found: $file"
    fi
done

echo "Pre-xcodebuild verification complete!"
