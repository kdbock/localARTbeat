#!/usr/bin/env bash

# Single-command production release build:
# - Android App Bundle (.aab)
# - iOS signed IPA (.ipa)
#
# Usage:
#   RELEASE_STRIPE_PUBLISHABLE_KEY=pk_live_... GOOGLE_MAPS_API_KEY=... ./scripts/build_release_artifacts.sh
#   RELEASE_STRIPE_PUBLISHABLE_KEY=pk_live_... GOOGLE_MAPS_API_KEY=... ./scripts/build_release_artifacts.sh --clean
#   RELEASE_STRIPE_PUBLISHABLE_KEY=pk_live_... GOOGLE_MAPS_API_KEY=... ./scripts/build_release_artifacts.sh --export-options-plist=ios/export_options.plist

set -euo pipefail

if [[ ! -f "pubspec.yaml" ]]; then
  echo "ERROR: Run this script from the repository root." >&2
  exit 1
fi

if [[ ! -x "./scripts/build_secure.sh" ]]; then
  echo "ERROR: Missing executable script: ./scripts/build_secure.sh" >&2
  exit 1
fi

exec ./scripts/build_secure.sh all-ipa "$@"
