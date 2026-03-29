#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

files=(
  "packages/artbeat_artist/lib/src/screens/verified_artist_screen.dart"
  "packages/artbeat_artist/lib/src/screens/featured_artist_screen.dart"
  "packages/artbeat_artist/lib/src/widgets/top_followers_widget.dart"
  "packages/artbeat_artist/lib/src/widgets/artist_social_stats_widget.dart"
)

violations=()
pattern='FirebaseAuth\.instance|FirebaseFirestore\.instance|SubscriptionService\('

for file in "${files[@]}"; do
  if grep -nE "$pattern" "$repo_root/$file" >/dev/null; then
    violations+=("$file")
  fi
done

if [ "${#violations[@]}" -gt 0 ]; then
  echo "Artist subscription UI boundary check failed."
  echo "These artist subscription/access surfaces must use app-owned services instead of direct Firebase singletons or local service construction:"
  printf ' - %s\n' "${violations[@]}"
  exit 1
fi

echo "Artist subscription UI boundary check passed."
