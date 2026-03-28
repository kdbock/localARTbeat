#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

files=(
  "packages/artbeat_community/lib/screens/create_art_post_screen.dart"
  "packages/artbeat_community/lib/screens/feed/create_post_screen.dart"
  "packages/artbeat_community/lib/screens/feed/create_group_post_screen.dart"
  "packages/artbeat_community/lib/screens/feed/group_feed_screen.dart"
  "packages/artbeat_community/lib/screens/feed/comments_screen.dart"
  "packages/artbeat_community/lib/screens/feed/artist_community_feed_screen.dart"
  "packages/artbeat_community/lib/screens/feed/trending_content_screen.dart"
  "packages/artbeat_community/lib/screens/art_community_hub.dart"
  "packages/artbeat_community/lib/screens/unified_community_hub.dart"
  "packages/artbeat_community/lib/screens/artist_feed_screen.dart"
  "packages/artbeat_community/lib/screens/posts/user_posts_screen.dart"
  "packages/artbeat_community/lib/screens/commissions/direct_commissions_screen.dart"
  "packages/artbeat_community/lib/screens/commissions/commission_hub_screen.dart"
  "packages/artbeat_community/lib/screens/commissions/commission_analytics_screen.dart"
  "packages/artbeat_community/lib/screens/commissions/commission_detail_screen.dart"
  "packages/artbeat_community/lib/screens/commissions/artist_commission_settings_screen.dart"
  "packages/artbeat_community/lib/screens/commissions/commission_setup_wizard_screen.dart"
  "packages/artbeat_community/lib/widgets/group_feed_widget.dart"
  "packages/artbeat_community/lib/widgets/post_detail_modal.dart"
  "packages/artbeat_community/lib/widgets/comments_modal.dart"
  "packages/artbeat_community/lib/widgets/enhanced_post_card.dart"
  "packages/artbeat_community/lib/widgets/community_drawer.dart"
  "packages/artbeat_community/lib/widgets/artist_list_widget.dart"
)

strict_constructor_files=(
  "packages/artbeat_community/lib/screens/unified_community_hub.dart"
  "packages/artbeat_community/lib/screens/artist_feed_screen.dart"
  "packages/artbeat_community/lib/screens/posts/user_posts_screen.dart"
  "packages/artbeat_community/lib/screens/commissions/direct_commissions_screen.dart"
  "packages/artbeat_community/lib/screens/commissions/commission_hub_screen.dart"
  "packages/artbeat_community/lib/screens/commissions/commission_analytics_screen.dart"
  "packages/artbeat_community/lib/screens/commissions/commission_detail_screen.dart"
  "packages/artbeat_community/lib/screens/commissions/artist_commission_settings_screen.dart"
  "packages/artbeat_community/lib/screens/commissions/commission_setup_wizard_screen.dart"
)

violations=()
singleton_pattern='FirebaseAuth\.instance|FirebaseFirestore\.instance'
constructor_pattern='ArtCommunityService\(|DirectCommissionService\(|StripeService\(|core\.EnhancedStorageService\('

is_strict_constructor_file() {
  local target="$1"
  for strict_file in "${strict_constructor_files[@]}"; do
    if [ "$strict_file" = "$target" ]; then
      return 0
    fi
  done
  return 1
}

for file in "${files[@]}"; do
  if grep -nE "$singleton_pattern" "$repo_root/$file" >/dev/null; then
    violations+=("$file")
    continue
  fi

  if is_strict_constructor_file "$file" &&
      grep -nE "$constructor_pattern" "$repo_root/$file" >/dev/null; then
    violations+=("$file")
  fi
done

if [ "${#violations[@]}" -gt 0 ]; then
  echo "Community UI boundary check failed."
  echo "These community screens must use app-owned services instead of direct Firebase singletons or local service construction:"
  printf ' - %s\n' "${violations[@]}"
  exit 1
fi

echo "Community UI boundary check passed."
