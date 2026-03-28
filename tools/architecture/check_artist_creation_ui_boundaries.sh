#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

files=(
  "packages/artbeat_artist/lib/src/screens/auction_hub_screen.dart"
  "packages/artbeat_artist/lib/src/screens/artist_journey_screen.dart"
  "packages/artbeat_artist/lib/src/screens/event_creation_screen.dart"
  "packages/artbeat_artist/lib/src/screens/events_screen.dart"
)

violations=()
pattern='FirebaseAuth\.instance|FirebaseFirestore\.instance|SubscriptionService\(|ArtworkService\(|ArtistAuctionReadService\(|EventServiceAdapter\('

for file in "${files[@]}"; do
  if grep -nE "$pattern" "$repo_root/$file" >/dev/null; then
    violations+=("$file")
  fi
done

if [ "${#violations[@]}" -gt 0 ]; then
  echo "Artist creation UI boundary check failed."
  echo "These artist creation surfaces must use app-owned services instead of local service construction or direct Firebase singletons:"
  printf ' - %s\n' "${violations[@]}"
  exit 1
fi

echo "Artist creation UI boundary check passed."
