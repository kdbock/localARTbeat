#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

files=(
  "packages/artbeat_profile/lib/src/screens/profile_view_screen.dart"
  "packages/artbeat_profile/lib/src/screens/profile_connections_screen.dart"
  "packages/artbeat_profile/lib/src/screens/profile_analytics_screen.dart"
  "packages/artbeat_profile/lib/src/screens/profile_activity_screen.dart"
  "packages/artbeat_profile/lib/src/screens/achievements_screen.dart"
  "packages/artbeat_profile/lib/src/screens/following_list_screen.dart"
  "packages/artbeat_profile/lib/src/screens/favorite_detail_screen.dart"
  "packages/artbeat_profile/lib/src/screens/edit_profile_screen.dart"
  "packages/artbeat_profile/lib/src/screens/create_profile_screen.dart"
  "packages/artbeat_profile/lib/src/screens/favorites_screen.dart"
  "packages/artbeat_profile/lib/src/screens/followed_artists_screen.dart"
  "packages/artbeat_profile/lib/src/screens/followers_list_screen.dart"
  "packages/artbeat_profile/lib/src/screens/profile_menu_screen.dart"
  "packages/artbeat_profile/lib/src/widgets/progress_tab.dart"
)

violations=()
pattern='FirebaseAuth\.instance|FirebaseFirestore\.instance|ProfileConnectionService\(|ProfileAnalyticsService\(|ProfileActivityService\(|ProfileAchievementReadService\(|ProfileRewardsService\(|ProfileChallengeService\(|AchievementService\(|UserService\('

for file in "${files[@]}"; do
  if grep -nE "$pattern" "$repo_root/$file" >/dev/null; then
    violations+=("$file")
  fi
done

if [ "${#violations[@]}" -gt 0 ]; then
  echo "Profile UI boundary check failed."
  echo "These profile screens must use app-owned services instead of direct Firebase singletons:"
  printf ' - %s\n' "${violations[@]}"
  exit 1
fi

echo "Profile UI boundary check passed."
