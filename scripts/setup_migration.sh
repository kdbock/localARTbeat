#!/bin/bash

# Firestore Schema Migration Helper
# This script helps you run the migration using Firebase CLI authentication

echo "============================================================"
echo "Firestore Schema Migration: Supporters → Boosters"
echo "Setup Helper"
echo "============================================================"
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found"
    echo ""
    echo "Please install Firebase CLI:"
    echo "  npm install -g firebase-tools"
    echo ""
    exit 1
fi

echo "✓ Firebase CLI found"

# Check if logged in
if ! firebase projects:list &> /dev/null; then
    echo "❌ Not logged in to Firebase"
    echo ""
    echo "Please log in:"
    echo "  firebase login"
    echo ""
    exit 1
fi

echo "✓ Firebase authenticated"

# Get current project
PROJECT_ID=$(firebase use | grep "Active Project" | awk '{print $4}' | tr -d '()')

if [ -z "$PROJECT_ID" ]; then
    echo "❌ No Firebase project selected"
    echo ""
    echo "Please select a project:"
    echo "  firebase use <project-id>"
    echo ""
    exit 1
fi

echo "✓ Project: $PROJECT_ID"
echo ""

# Ask user which method they prefer
echo "Choose migration method:"
echo "  1) Download service account key (recommended for production)"
echo "  2) Use Firebase CLI authentication (quick test)"
echo "  3) Use Firebase Emulator (safest test)"
echo ""
read -p "Enter choice (1-3): " choice

case $choice in
    1)
        echo ""
        echo "📥 Service Account Key Setup"
        echo "-----------------------------------------------------------"
        echo "1. Open: https://console.firebase.google.com/project/$PROJECT_ID/settings/serviceaccounts/adminsdk"
        echo "2. Click 'Generate New Private Key'"
        echo "3. Save the downloaded file as: service-account-key.json"
        echo "4. Move it to: $(pwd)"
        echo ""
        echo "Press Enter when ready to continue..."
        read
        
        if [ -f "service-account-key.json" ]; then
            echo "✓ Service account key found"
            echo ""
            echo "Running migration (DRY RUN)..."
            node scripts/migrate_boosters_schema.js --dry-run
        else
            echo "❌ service-account-key.json not found"
            exit 1
        fi
        ;;
    
    2)
        echo ""
        echo "🔐 Using Firebase CLI Authentication"
        echo "-----------------------------------------------------------"
        echo "This method uses your current Firebase login."
        echo ""
        
        # Try to get access token
        TOKEN=$(firebase login:ci --no-localhost 2>&1 | grep -o '1//.*' | head -1)
        
        if [ -n "$TOKEN" ]; then
            echo "✓ Access token obtained"
            export GOOGLE_APPLICATION_CREDENTIALS=""
            export FIREBASE_TOKEN="$TOKEN"
        fi
        
        echo ""
        echo "Running migration (DRY RUN)..."
        node scripts/migrate_boosters_schema.js --dry-run
        ;;
    
    3)
        echo ""
        echo "🧪 Using Firebase Emulator"
        echo "-----------------------------------------------------------"
        echo "This will test the migration on local emulator data."
        echo ""
        echo "Starting emulator..."
        
        # Start emulator in background
        firebase emulators:start --only firestore &
        EMULATOR_PID=$!
        
        # Wait for emulator to start
        sleep 5
        
        echo ""
        echo "Running migration (DRY RUN)..."
        FIRESTORE_EMULATOR_HOST="localhost:8080" node scripts/migrate_boosters_schema.js --dry-run
        
        # Stop emulator
        kill $EMULATOR_PID 2>/dev/null
        echo ""
        echo "Emulator stopped"
        ;;
    
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "============================================================"
echo "Next Steps:"
echo "============================================================"
echo ""
echo "If dry run looks good:"
echo "  node scripts/migrate_boosters_schema.js"
echo ""
echo "Or run this script again without --dry-run option"
