#!/bin/bash

set -euo pipefail

readonly SEARCH_ROOTS=(
  "lib/src/routing"
  "packages/artbeat_capture/lib/src/screens"
  "packages/artbeat_capture/lib/src/widgets"
)

echo "Checking provider-owned CaptureService usage in UI and routing layers..."

matches="$(
  rg -n "CaptureService\\(" "${SEARCH_ROOTS[@]}" --glob '!**/build/**' || true
)"

if [[ -n "${matches}" ]]; then
  echo "Direct CaptureService construction is not allowed in UI/routing layers."
  echo "Use the app-owned Provider instance instead."
  echo ""
  echo "${matches}"
  exit 1
fi

echo "Provider-owned CaptureService check passed."
