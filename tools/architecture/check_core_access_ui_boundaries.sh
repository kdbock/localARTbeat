#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

files=(
  "packages/artbeat_core/lib/src/screens/legal_center_screen.dart"
  "packages/artbeat_core/lib/src/screens/artist_onboarding/completion_screen.dart"
  "packages/artbeat_core/lib/src/screens/chapters/chapter_landing_screen.dart"
)

violations=()
pattern='FirebaseAuth\.instance|FirebaseFirestore\.instance|LegalConsentService\(|ChapterPartnerService\('

for file in "${files[@]}"; do
  if grep -nE "$pattern" "$repo_root/$file" >/dev/null; then
    violations+=("$file")
  fi
done

if [ "${#violations[@]}" -gt 0 ]; then
  echo "Core access UI boundary check failed."
  echo "These legal/onboarding/access surfaces must use app-owned services instead of local service construction or direct Firebase singletons:"
  printf ' - %s\n' "${violations[@]}"
  exit 1
fi

echo "Core access UI boundary check passed."
