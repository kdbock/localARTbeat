#!/usr/bin/env bash

# Canonical production build script for Android and iOS.
#
# Usage examples:
#   RELEASE_STRIPE_PUBLISHABLE_KEY=pk_live_... GOOGLE_MAPS_API_KEY=... ./scripts/build_secure.sh android
#   RELEASE_STRIPE_PUBLISHABLE_KEY=pk_live_... GOOGLE_MAPS_API_KEY=... ./scripts/build_secure.sh ios --clean
#   RELEASE_STRIPE_PUBLISHABLE_KEY=pk_live_... GOOGLE_MAPS_API_KEY=... ./scripts/build_secure.sh all
#   RELEASE_STRIPE_PUBLISHABLE_KEY=pk_live_... GOOGLE_MAPS_API_KEY=... ./scripts/build_secure.sh ios-ipa
#   RELEASE_STRIPE_PUBLISHABLE_KEY=pk_live_... GOOGLE_MAPS_API_KEY=... ./scripts/build_secure.sh all-ipa

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}OK: $1${NC}"
}

print_info() {
    echo -e "${YELLOW}INFO: $1${NC}"
}

usage() {
    cat <<EOF
Usage: ./scripts/build_secure.sh [android|ios|all|ios-ipa|all-ipa] [--clean] [--export-options-plist=path]

Options:
    android    Build Android release AAB.
    ios        Build iOS release (no codesign).
    all        Build both Android and iOS (default).
    ios-ipa    Build signed iOS IPA for Transporter/App Store Connect upload.
    all-ipa    Build Android AAB and signed iOS IPA.
    --clean    Run flutter clean before building.
    --export-options-plist=path
               Export options plist for IPA export (default: ios/export_options.plist).
    --no-pod-repo-update
               Skip pod repo update before iOS IPA build.

Required environment variables:
    GOOGLE_MAPS_API_KEY
    RELEASE_STRIPE_PUBLISHABLE_KEY (preferred) or STRIPE_PUBLISHABLE_KEY

Optional environment variables:
    ENVIRONMENT (defaults to production)
    FIREBASE_REGION
    FIREBASE_PROJECT_ID
    FIREBASE_FUNCTIONS_BASE_URL
    API_BASE_URL
EOF
}

if [[ ! -f "pubspec.yaml" ]]; then
    print_error "Run this script from the repository root."
    exit 1
fi

if ! command -v flutter >/dev/null 2>&1; then
    print_error "flutter is not installed or not on PATH."
    exit 1
fi

TARGET="all"
DO_CLEAN=false
EXPORT_OPTIONS_PLIST="ios/export_options.plist"
DO_POD_REPO_UPDATE=true

for arg in "$@"; do
    case "$arg" in
        android|ios|all|ios-ipa|all-ipa)
            TARGET="$arg"
            ;;
        --clean)
            DO_CLEAN=true
            ;;
        --export-options-plist=*)
            EXPORT_OPTIONS_PLIST="${arg#*=}"
            ;;
        --no-pod-repo-update)
            DO_POD_REPO_UPDATE=false
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            print_error "Unknown argument: $arg"
            usage
            exit 1
            ;;
    esac
done

ENVIRONMENT="${ENVIRONMENT:-production}"
if [[ "$ENVIRONMENT" != "production" ]]; then
    print_error "ENVIRONMENT must be production for this release script (current: $ENVIRONMENT)."
    exit 1
fi

# Fall back to .env when required values are not already exported.
if [[ ( -z "${GOOGLE_MAPS_API_KEY:-}" || ( -z "${RELEASE_STRIPE_PUBLISHABLE_KEY:-}" && -z "${STRIPE_PUBLISHABLE_KEY:-}" ) ) && -f ".env" ]]; then
    print_info "Loading missing build variables from .env..."
    set -a
    # shellcheck disable=SC1091
    source .env
    set +a
fi

GOOGLE_MAPS_API_KEY="${GOOGLE_MAPS_API_KEY:-}"
if [[ -z "$GOOGLE_MAPS_API_KEY" ]]; then
    print_error "GOOGLE_MAPS_API_KEY is required."
    exit 1
fi

STRIPE_KEY="${RELEASE_STRIPE_PUBLISHABLE_KEY:-${STRIPE_PUBLISHABLE_KEY:-}}"
if [[ -z "$STRIPE_KEY" ]]; then
    print_error "Set RELEASE_STRIPE_PUBLISHABLE_KEY (preferred) or STRIPE_PUBLISHABLE_KEY."
    exit 1
fi
if [[ "$STRIPE_KEY" != pk_live_* ]]; then
    print_error "Production release requires a live Stripe publishable key (pk_live_...)."
    exit 1
fi

if [[ "$DO_CLEAN" == true ]]; then
    print_info "Cleaning previous build artifacts..."
    flutter clean
fi

print_info "Fetching Flutter dependencies..."
flutter pub get

print_info "Running release payment/config gate..."
bash tools/architecture/check_release_payment_config.sh
print_success "Release payment/config gate passed"

print_info "Running release monetization prerequisite gate..."
bash tools/architecture/check_release_monetization_prereqs.sh
print_success "Release monetization prerequisite gate passed"

DART_DEFINES=(
    "--dart-define=GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY"
    "--dart-define=STRIPE_PUBLISHABLE_KEY=$STRIPE_KEY"
    "--dart-define=ENVIRONMENT=$ENVIRONMENT"
)

if [[ -n "${FIREBASE_REGION:-}" ]]; then
    DART_DEFINES+=("--dart-define=FIREBASE_REGION=$FIREBASE_REGION")
fi
if [[ -n "${FIREBASE_PROJECT_ID:-}" ]]; then
    DART_DEFINES+=("--dart-define=FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID")
fi
if [[ -n "${FIREBASE_FUNCTIONS_BASE_URL:-}" ]]; then
    DART_DEFINES+=("--dart-define=FIREBASE_FUNCTIONS_BASE_URL=$FIREBASE_FUNCTIONS_BASE_URL")
fi
if [[ -n "${API_BASE_URL:-}" ]]; then
    DART_DEFINES+=("--dart-define=API_BASE_URL=$API_BASE_URL")
fi

print_info "Build target: $TARGET"

if [[ "$TARGET" == "ios-ipa" || "$TARGET" == "all-ipa" ]]; then
    if [[ ! -f "$EXPORT_OPTIONS_PLIST" ]]; then
        print_error "Export options plist not found: $EXPORT_OPTIONS_PLIST"
        exit 1
    fi
fi

if [[ "$TARGET" == "android" || "$TARGET" == "all" || "$TARGET" == "all-ipa" ]]; then
    print_info "Building Android appbundle (release)..."
    flutter build appbundle --release "${DART_DEFINES[@]}"
    print_success "Android appbundle ready at build/app/outputs/bundle/release/app-release.aab"
fi

if [[ "$TARGET" == "ios" || "$TARGET" == "all" ]]; then
    print_info "Building iOS app (release, no codesign)..."
    flutter build ios --release --no-codesign "${DART_DEFINES[@]}"
    print_success "iOS app ready at build/ios/iphoneos/Runner.app"
fi

if [[ "$TARGET" == "ios-ipa" || "$TARGET" == "all-ipa" ]]; then
    if [[ "$DO_POD_REPO_UPDATE" == true ]]; then
        if command -v pod >/dev/null 2>&1; then
            print_info "Updating CocoaPods specs repo (pod repo update)..."
            (cd ios && pod repo update)
            print_success "CocoaPods specs repo updated"

            print_info "Refreshing iOS pods with latest specs (pod install --repo-update)..."
            (
                cd ios
                if ! pod install --repo-update; then
                    print_info "Pod install hit lockfile conflicts; running targeted pod updates..."
                    pod update \
                        Firebase/Auth \
                        Firebase/CoreOnly \
                        Firebase/Crashlytics \
                        Firebase/Firestore \
                        Firebase/Functions \
                        Firebase/Messaging \
                        Firebase/RemoteConfig \
                        Firebase/Storage \
                        FirebaseABTesting \
                        FirebaseAnalytics \
                        FirebaseAppCheck \
                        FirebaseAppCheckInterop \
                        FirebaseAuth \
                        FirebaseAuthInterop \
                        FirebaseCore \
                        FirebaseCoreExtension \
                        FirebaseCoreInternal \
                        FirebaseCrashlytics \
                        FirebaseFirestore \
                        FirebaseFirestoreInternal \
                        FirebaseFunctions \
                        FirebaseInstallations \
                        FirebaseMessaging \
                        FirebaseMessagingInterop \
                        FirebaseRemoteConfig \
                        FirebaseRemoteConfigInterop \
                        FirebaseSessions \
                        FirebaseSharedSwift \
                        FirebaseStorage \
                        cloud_firestore \
                        firebase_core \
                        firebase_app_check
                    pod install --repo-update
                fi
            )
            print_success "iOS pods and Podfile.lock refreshed"
        else
            print_error "CocoaPods is required for IPA builds but `pod` is not on PATH."
            exit 1
        fi
    fi

    print_info "Building signed iOS IPA (release)..."
    flutter build ipa --release --export-options-plist="$EXPORT_OPTIONS_PLIST" "${DART_DEFINES[@]}"
    print_success "iOS IPA ready at build/ios/ipa"
fi

print_success "Production build completed."
