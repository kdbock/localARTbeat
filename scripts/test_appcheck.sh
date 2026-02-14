#!/bin/bash

echo "========================================"
echo "App Check Production Test Script"
echo "========================================"
echo ""

# Test 1: Build release version
echo "Test 1: Building release version..."
flutter build ios --release --no-codesign

if [ $? -eq 0 ]; then
    echo "✅ Release build successful"
else
    echo "❌ Release build failed"
    exit 1
fi

echo ""
echo "========================================"
echo "Next Steps:"
echo "========================================"
echo ""
echo "1. Run on device: flutter run --release"
echo "2. Check for these log messages:"
echo "   ✅ '🛡️ ACTIVATING APP CHECK IN PRODUCTION MODE'"
echo "   ✅ '🛡️ ✅ Production token fetch successful!'"
echo ""
echo "3. Open Xcode console and look for:"
echo "   ✅ '[AppCheckCore] Successfully obtained App Check token'"
echo ""
echo "4. Verify NO errors like:"
echo "   ❌ 'App attestation failed'"
echo "   ❌ 'Missing or insufficient permissions'"
echo ""
echo "5. In Firebase Console > App Check:"
echo "   - Check metrics to see token requests"
echo "   - Verify iOS app shows 'Active' status"
echo ""
