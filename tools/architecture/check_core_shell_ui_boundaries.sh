#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

files=(
  "packages/artbeat_core/lib/src/widgets/artbeat_drawer.dart"
  "packages/artbeat_core/lib/src/widgets/enhanced_universal_header.dart"
  "packages/artbeat_core/lib/src/widgets/enhanced_profile_menu.dart"
  "packages/artbeat_core/lib/src/widgets/developer_menu.dart"
  "packages/artbeat_core/lib/src/widgets/tour/dashboard_tour_overlay.dart"
  "packages/artbeat_core/lib/src/widgets/tour/events_tour_overlay.dart"
  "packages/artbeat_core/lib/src/widgets/dashboard/art_walk_hero_section.dart"
  "packages/artbeat_core/lib/src/widgets/user_experience_card.dart"
  "packages/artbeat_core/lib/src/screens/dashboard/animated_dashboard_screen.dart"
  "packages/artbeat_core/lib/src/screens/dashboard/explore_dashboard_screen.dart"
)

violations=()
pattern='FirebaseAuth\.instance|FirebaseFirestore\.instance|UserService\(|UserProgressionService\(|LeaderboardService\(|OnboardingService\(|PublicArtReadService\('

for file in "${files[@]}"; do
  if grep -nE "$pattern" "$repo_root/$file" >/dev/null; then
    violations+=("$file")
  fi
done

if [ "${#violations[@]}" -gt 0 ]; then
  echo "Core shell UI boundary check failed."
  echo "These core dashboard/navigation shell files must use app-owned services instead of direct Firebase singletons or local service construction:"
  printf ' - %s\n' "${violations[@]}"
  exit 1
fi

echo "Core shell UI boundary check passed."
