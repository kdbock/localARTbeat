#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

files=(
  "packages/artbeat_artist/lib/src/screens/visibility_insights_screen.dart"
  "packages/artbeat_artist/lib/src/screens/subscription_analytics_screen.dart"
  "packages/artbeat_artist/lib/src/screens/gallery_visibility_hub_screen.dart"
)

violations=()
pattern='FirebaseAuth\.instance|FirebaseFirestore\.instance|VisibilityService\(|SubscriptionService\(|UnifiedPaymentService\(|ArtworkService\('

for file in "${files[@]}"; do
  if grep -nE "$pattern" "$repo_root/$file" >/dev/null; then
    violations+=("$file")
  fi
done

if [ "${#violations[@]}" -gt 0 ]; then
  echo "Artist analytics UI boundary check failed."
  echo "These artist analytics screens must use app-owned services instead of direct Firebase singletons or local service construction:"
  printf ' - %s\n' "${violations[@]}"
  exit 1
fi

echo "Artist analytics UI boundary check passed."
