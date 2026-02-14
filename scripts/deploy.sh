#!/bin/bash

# ARTbeat App - Deployment Script
# This script automates the build process for both Android and iOS

set -e

echo "🚀 ARTbeat App Deployment Script"
echo "=================================="

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: pubspec.yaml not found. Please run this script from the project root."
    exit 1
fi

# Function to print colored output
print_step() {
    echo -e "\n✅ $1"
}

print_error() {
    echo -e "\n❌ Error: $1"
}

print_warning() {
    echo -e "\n⚠️  Warning: $1"
}

# Get current version from pubspec.yaml
CURRENT_VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //' | tr -d ' ')
echo "📱 Current App Version: $CURRENT_VERSION"

# Clean project
print_step "Cleaning Flutter project..."
flutter clean

# Get dependencies
print_step "Getting Flutter dependencies..."
flutter pub get

# Check for lint issues
print_step "Running Flutter analyze..."
if ! flutter analyze; then
    print_warning "Lint issues found. Consider fixing them before deployment."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Build Android
echo -e "\n🤖 ANDROID BUILD"
echo "=================="

print_step "Building Android App Bundle (AAB)..."
if flutter build appbundle --release; then
    print_step "Android AAB built successfully!"
    AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
    AAB_SIZE=$(du -h "$AAB_PATH" | cut -f1)
    echo "   📁 Location: $AAB_PATH"
    echo "   📏 Size: $AAB_SIZE"
else
    print_error "Android AAB build failed!"
    exit 1
fi

print_step "Building Android APK..."
if flutter build apk --release; then
    print_step "Android APK built successfully!"
    APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
    echo "   📁 Location: $APK_PATH"
    echo "   📏 Size: $APK_SIZE"
else
    print_error "Android APK build failed!"
    exit 1
fi

# Build iOS
echo -e "\n🍎 iOS BUILD"
echo "============="

print_step "Building iOS release..."
if flutter build ios --release --no-codesign; then
    print_step "iOS build completed successfully!"
    echo "   📁 Location: build/ios/iphoneos/Runner.app"
    echo "   ⚠️  Note: You'll need to archive and sign in Xcode for distribution"
else
    print_error "iOS build failed!"
    exit 1
fi

# Summary
echo -e "\n🎉 BUILD SUMMARY"
echo "================="
echo "✅ Android AAB: $AAB_PATH ($AAB_SIZE)"
echo "✅ Android APK: $APK_PATH ($APK_SIZE)"
echo "✅ iOS App: build/ios/iphoneos/Runner.app"
echo ""
echo "📋 NEXT STEPS:"
echo "=============="
echo "For Android:"
echo "  1. Upload AAB to Google Play Console"
echo "  2. Set up internal/closed testing"
echo "  3. Add test users and publish"
echo ""
echo "For iOS:"
echo "  1. Open ios/Runner.xcworkspace in Xcode"
echo "  2. Archive the project (Product → Archive)"
echo "  3. Distribute to App Store Connect"
echo "  4. Set up TestFlight testing"
echo ""
echo "🔗 Useful Links:"
echo "  • Google Play Console: https://play.google.com/console"
echo "  • App Store Connect: https://appstoreconnect.apple.com"
echo "  • Deployment Guide: ./DEPLOYMENT_GUIDE.md"
echo ""
echo "🎊 Builds completed successfully! Ready for testing."
