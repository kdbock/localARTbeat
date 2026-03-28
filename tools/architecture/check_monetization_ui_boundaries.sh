#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

violations=()

check_file() {
  local file="$1"
  local pattern='FirebaseAuth\.instance|FirebaseFirestore\.instance|FirebaseStorage\.instance'

  if grep -nE "$pattern" "$repo_root/$file" >/dev/null; then
    violations+=("$file")
  fi
}

check_file "packages/artbeat_ads/lib/src/screens/create_local_ad_screen.dart"
check_file "packages/artbeat_sponsorships/lib/src/screens/sponsorships/sponsorship_review_screen.dart"

if [ "${#violations[@]}" -gt 0 ]; then
  echo "Monetization UI boundary check failed."
  echo "These paid submission screens must use app-owned services instead of direct Firebase singletons:"
  printf ' - %s\n' "${violations[@]}"
  exit 1
fi

echo "Monetization UI boundary check passed."
