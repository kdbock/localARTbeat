#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

files=(
  "packages/artbeat_art_walk/lib/src/screens/enhanced_art_walk_experience_screen.dart"
  "packages/artbeat_art_walk/lib/src/screens/enhanced_art_walk_create_screen.dart"
  "packages/artbeat_art_walk/lib/src/screens/art_walk_celebration_screen.dart"
  "packages/artbeat_art_walk/lib/src/widgets/discovery_capture_modal.dart"
  "packages/artbeat_art_walk/lib/src/widgets/social_activity_feed.dart"
  "packages/artbeat_art_walk/lib/src/widgets/art_walk_comment_section.dart"
  "packages/artbeat_art_walk/lib/src/widgets/instant_discovery_radar.dart"
  "packages/artbeat_art_walk/lib/src/widgets/local_art_walk_preview_widget.dart"
  "packages/artbeat_art_walk/lib/src/widgets/progress_cards.dart"
)

violations=()
pattern='FirebaseAuth\.instance|FirebaseFirestore\.instance|ArtWalkDistanceUnitService\(|ArtWalkCaptureReadService\(|InstantDiscoveryService\(|SocialService\(|ArtWalkService\(|UserService\(|ArtWalkPreviewReadService\('

for file in "${files[@]}"; do
  if grep -nE "$pattern" "$repo_root/$file" >/dev/null; then
    violations+=("$file")
  fi
done

if [ "${#violations[@]}" -gt 0 ]; then
  echo "Art walk experience UI boundary check failed."
  echo "These art walk experience surfaces must use app-owned services instead of local service construction or direct Firebase singletons:"
  printf ' - %s\n' "${violations[@]}"
  exit 1
fi

echo "Art walk experience UI boundary check passed."
