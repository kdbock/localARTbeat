#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

files=(
  "packages/artbeat_core/lib/src/screens/leaderboard_screen.dart"
  "packages/artbeat_core/lib/src/widgets/leaderboard_preview_widget.dart"
  "packages/artbeat_core/lib/src/widgets/content_engagement_bar.dart"
  "packages/artbeat_core/lib/src/widgets/artist_boost_widget.dart"
  "packages/artbeat_core/lib/src/widgets/artist_cta_widget.dart"
  "packages/artbeat_core/lib/src/widgets/dashboard/integrated_engagement_widget.dart"
  "packages/artbeat_core/lib/src/widgets/dashboard/dashboard_artwork_section.dart"
  "packages/artbeat_core/lib/src/widgets/dashboard/dashboard_artists_section.dart"
  "packages/artbeat_core/lib/src/widgets/dashboard/dashboard_community_section.dart"
)

violations=()
pattern='FirebaseAuth\.instance|FirebaseFirestore\.instance|LeaderboardService\(|UserProgressionService\(|DailyChallengeReadService\(|CommunityPostReadService\(|ContentEngagementService\(|ArtistService\(|ArtistBoostService\(|UserService\('

for file in "${files[@]}"; do
  if grep -nE "$pattern" "$repo_root/$file" >/dev/null; then
    violations+=("$file")
  fi
done

if [ "${#violations[@]}" -gt 0 ]; then
  echo "Core dashboard UI boundary check failed."
  echo "These core dashboard surfaces must use app-owned services instead of local service construction or direct Firebase singletons:"
  printf ' - %s\n' "${violations[@]}"
  exit 1
fi

echo "Core dashboard UI boundary check passed."
