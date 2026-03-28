#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

files=(
  "packages/artbeat_artist/lib/src/screens/gallery_hub_screen.dart"
)

violations=()
pattern='FirebaseAuth\.instance|FirebaseFirestore\.instance|EarningsService\(|VisibilityService\(|ArtistFeatureService\(|GalleryHubReadService\('

for file in "${files[@]}"; do
  if grep -nE "$pattern" "$repo_root/$file" >/dev/null; then
    violations+=("$file")
  fi
done

if [ "${#violations[@]}" -gt 0 ]; then
  echo "Artist gallery UI boundary check failed."
  echo "These artist gallery surfaces must use app-owned services instead of local service construction or direct Firebase singletons:"
  printf ' - %s\n' "${violations[@]}"
  exit 1
fi

echo "Artist gallery UI boundary check passed."
