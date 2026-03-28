#!/bin/bash

# ArtBeat Build Script with Secure Configuration
# This script helps build the app with proper environment variables

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${GREEN}ℹ️  $1${NC}"
}

# Check if .env exists
if [ ! -f ".env" ]; then
    print_error ".env file not found!"
    print_info "Please create .env with your API keys:"
    echo ""
    echo "  cp .env.example .env"
    echo ""
    exit 1
fi

# Load environment variables
print_info "Loading environment variables from .env..."
set -a
source .env
set +a

# Validate required variables
if [ -z "$GOOGLE_MAPS_API_KEY" ]; then
    print_error "GOOGLE_MAPS_API_KEY not set in .env"
    exit 1
fi

if [ -z "$STRIPE_PUBLISHABLE_KEY" ]; then
    print_error "STRIPE_PUBLISHABLE_KEY not set in .env"
    exit 1
fi

# Set default environment if not specified
if [ -z "$ENVIRONMENT" ]; then
    ENVIRONMENT="development"
    print_warning "ENVIRONMENT not set, defaulting to development"
fi

# Validate Stripe key matches environment
if [[ "$ENVIRONMENT" == "production" && "$STRIPE_PUBLISHABLE_KEY" == pk_test_* ]]; then
    print_error "Cannot use test Stripe key in production environment!"
    exit 1
fi

if [[ "$ENVIRONMENT" == "development" && "$STRIPE_PUBLISHABLE_KEY" == pk_live_* ]]; then
    print_warning "Using live Stripe key in development environment!"
    read -p "Are you sure? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        exit 1
    fi
fi

# Determine build type
BUILD_TYPE="${1:-run}"

RELEASE_BUILD=false
case "$BUILD_TYPE" in
    build-apk|build-appbundle|build-ios|build-ipa)
        RELEASE_BUILD=true
        ;;
esac

# Production releases must use a dedicated release Stripe key source.
if [[ "$RELEASE_BUILD" == true && "$ENVIRONMENT" == "production" ]]; then
    if [ -z "$RELEASE_STRIPE_PUBLISHABLE_KEY" ]; then
        print_error "RELEASE_STRIPE_PUBLISHABLE_KEY must be provided outside .env for production release builds"
        print_info "Example:"
        echo "  RELEASE_STRIPE_PUBLISHABLE_KEY=pk_live_... $0 $BUILD_TYPE"
        exit 1
    fi

    STRIPE_PUBLISHABLE_KEY="$RELEASE_STRIPE_PUBLISHABLE_KEY"
fi

print_success "Configuration validated"
echo ""
echo "  Environment: $ENVIRONMENT"
echo "  Google Maps Key: ${GOOGLE_MAPS_API_KEY:0:10}...${GOOGLE_MAPS_API_KEY: -4}"
echo "  Stripe Key: ${STRIPE_PUBLISHABLE_KEY:0:12}...${STRIPE_PUBLISHABLE_KEY: -4}"
echo ""

print_info "Running release payment/config gate..."
bash tools/architecture/check_release_payment_config.sh
print_success "Release payment/config gate passed"

print_info "Running release monetization prerequisite gate..."
bash tools/architecture/check_release_monetization_prereqs.sh
print_success "Release monetization prerequisite gate passed"

# Build Flutter command with dart-defines
DART_DEFINES=(
    "--dart-define=GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY"
    "--dart-define=STRIPE_PUBLISHABLE_KEY=$STRIPE_PUBLISHABLE_KEY"
    "--dart-define=ENVIRONMENT=$ENVIRONMENT"
    "--dart-define=FIREBASE_REGION=$FIREBASE_REGION"
    "--dart-define=FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID"
    "--dart-define=FIREBASE_FUNCTIONS_BASE_URL=$FIREBASE_FUNCTIONS_BASE_URL"
    "--dart-define=API_BASE_URL=$API_BASE_URL"
)

# Execute build command
case "$BUILD_TYPE" in
    run)
        print_info "Running app in development mode..."
        flutter run "${DART_DEFINES[@]}"
        ;;
    
    build-apk)
        print_info "Building Android APK..."
        flutter build apk "${DART_DEFINES[@]}" --release
        print_success "APK built successfully!"
        ;;
    
    build-appbundle)
        print_info "Building Android App Bundle..."
        flutter build appbundle "${DART_DEFINES[@]}" --release
        print_success "App Bundle built successfully!"
        ;;
    
    build-ios)
        print_info "Building iOS app..."
        flutter build ios "${DART_DEFINES[@]}" --release
        print_success "iOS app built successfully!"
        ;;
    
    build-ipa)
        print_info "Building iOS IPA..."
        flutter build ipa "${DART_DEFINES[@]}" --release
        print_success "IPA built successfully!"
        ;;
    
    *)
        print_error "Unknown build type: $BUILD_TYPE"
        echo ""
        echo "Usage: $0 [build-type]"
        echo ""
        echo "Available build types:"
        echo "  run              - Run in development mode (default)"
        echo "  build-apk        - Build Android APK"
        echo "  build-appbundle  - Build Android App Bundle"
        echo "  build-ios        - Build iOS app"
        echo "  build-ipa        - Build iOS IPA"
        exit 1
        ;;
esac
