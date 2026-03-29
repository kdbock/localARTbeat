#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

files=(
  "packages/artbeat_artist/lib/src/screens/artist_public_profile_screen.dart"
  "packages/artbeat_artist/lib/src/screens/artist_profile_edit_screen.dart"
  "packages/artbeat_artist/lib/src/screens/artist_onboard_screen.dart"
  "packages/artbeat_artist/lib/src/screens/artist_browse_screen.dart"
)

violations=()
pattern='FirebaseAuth\.instance|FirebaseFirestore\.instance|SubscriptionService\(|ArtistProfileService\(|EnhancedStorageService\(|ArtworkService\(|VisibilityService\(|DirectCommissionService\(|ArtistBoostService\(|UserService\('

for file in "${files[@]}"; do
  if grep -nE "$pattern" "$repo_root/$file" >/dev/null; then
    violations+=("$file")
  fi
done

if [ "${#violations[@]}" -gt 0 ]; then
  echo "Artist profile UI boundary check failed."
  echo "These artist profile/public-facing screens must use app-owned services instead of direct Firebase singletons or local service construction:"
  printf ' - %s\n' "${violations[@]}"
  exit 1
fi

echo "Artist profile UI boundary check passed."
