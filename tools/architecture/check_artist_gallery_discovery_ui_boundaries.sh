#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

files=(
  "packages/artbeat_artist/lib/src/screens/gallery_artists_management_screen.dart"
  "packages/artbeat_artist/lib/src/screens/artist_list_screen.dart"
  "packages/artbeat_artist/lib/src/widgets/local_artists_row_widget.dart"
  "packages/artbeat_artist/lib/src/widgets/local_galleries_widget.dart"
  "packages/artbeat_artist/lib/src/widgets/upcoming_events_row_widget.dart"
)

violations=()
pattern='FirebaseAuth\.instance|FirebaseFirestore\.instance|ArtistProfileService\(|ArtistGalleryDiscoveryReadService\(|EventService\('

for file in "${files[@]}"; do
  if grep -nE "$pattern" "$repo_root/$file" >/dev/null; then
    violations+=("$file")
  fi
done

if [ "${#violations[@]}" -gt 0 ]; then
  echo "Artist gallery/discovery UI boundary check failed."
  echo "These artist gallery/discovery surfaces must use app-owned services instead of local service construction or direct Firebase singletons:"
  printf ' - %s\n' "${violations[@]}"
  exit 1
fi

echo "Artist gallery/discovery UI boundary check passed."
