#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

files=(
  "packages/artbeat_art_walk/lib/src/screens/discover_dashboard_screen.dart"
  "packages/artbeat_art_walk/lib/src/screens/art_walk_map_screen.dart"
  "packages/artbeat_art_walk/lib/src/widgets/art_walk_drawer.dart"
  "packages/artbeat_art_walk/lib/src/widgets/tour/discover_tour_overlay.dart"
)

violations=()
pattern='FirebaseAuth\.instance|FirebaseFirestore\.instance|UserService\(|ArtWalkCaptureReadService\(|OnboardingService\(|ArtistService\('

for file in "${files[@]}"; do
  if grep -nE "$pattern" "$repo_root/$file" >/dev/null; then
    violations+=("$file")
  fi
done

if [ "${#violations[@]}" -gt 0 ]; then
  echo "Art walk shell UI boundary check failed."
  echo "These art walk shell surfaces must use app-owned services instead of local service construction or direct Firebase singletons:"
  printf ' - %s\n' "${violations[@]}"
  exit 1
fi

echo "Art walk shell UI boundary check passed."
