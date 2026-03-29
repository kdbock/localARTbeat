#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

files=(
  "packages/artbeat_artwork/lib/src/screens/artwork_detail_screen.dart"
  "packages/artbeat_artwork/lib/src/screens/artwork_purchase_screen.dart"
  "packages/artbeat_artwork/lib/src/screens/enhanced_artwork_upload_screen.dart"
  "packages/artbeat_artwork/lib/src/screens/artwork_upload_screen.dart"
  "packages/artbeat_artwork/lib/src/screens/artwork_browse_screen.dart"
  "packages/artbeat_artwork/lib/src/screens/artwork_edit_screen.dart"
  "packages/artbeat_artwork/lib/src/screens/artist_artwork_management_screen.dart"
  "packages/artbeat_artwork/lib/src/screens/artwork_discovery_screen.dart"
  "packages/artbeat_artwork/lib/src/screens/advanced_artwork_search_screen.dart"
  "packages/artbeat_artwork/lib/src/screens/written_content_detail_screen.dart"
  "packages/artbeat_artwork/lib/src/screens/written_content_upload_screen.dart"
  "packages/artbeat_artwork/lib/src/screens/video_content_upload_screen.dart"
  "packages/artbeat_artwork/lib/src/screens/written_content_discovery_screen.dart"
  "packages/artbeat_artwork/lib/src/screens/artwork_recent_screen.dart"
  "packages/artbeat_artwork/lib/src/screens/artwork_trending_screen.dart"
  "packages/artbeat_artwork/lib/src/screens/artwork_featured_screen.dart"
  "packages/artbeat_artwork/lib/src/screens/place_bid_modal.dart"
  "packages/artbeat_artwork/lib/src/screens/my_bids_screen.dart"
  "packages/artbeat_artwork/lib/src/screens/auction_management_modal.dart"
  "packages/artbeat_artwork/lib/src/screens/auction_setup_wizard_screen.dart"
  "packages/artbeat_artwork/lib/src/screens/auction_win_screen.dart"
  "packages/artbeat_artwork/lib/src/screens/curated_gallery_screen.dart"
  "packages/artbeat_artwork/lib/src/widgets/artwork_discovery_widget.dart"
  "packages/artbeat_artwork/lib/src/widgets/local_artwork_row_widget.dart"
  "packages/artbeat_artwork/lib/src/widgets/artwork_social_widget.dart"
)

violations=()
pattern='FirebaseAuth\.instance|FirebaseFirestore\.instance|ArtworkService\(|ArtworkRatingService\(|ArtworkCommentService\(|ChapterService\(|ArtworkDiscoveryService\(|ArtworkPaginationService\(|ArtworkLocalReadService\(|ArtistService\(|ArtworkVisibilityService\(|AuctionService\(|UnifiedPaymentService\(|UserService\(|CollectionService\(|SubscriptionService\(|EnhancedStorageService\(|ContentEngagementService\(|ChallengeService\('

for file in "${files[@]}"; do
  if grep -nE "$pattern" "$repo_root/$file" >/dev/null; then
    violations+=("$file")
  fi
done

if [ "${#violations[@]}" -gt 0 ]; then
  echo "Artwork UI boundary check failed."
  echo "These artwork screens and widgets must use app-owned services instead of local service construction or direct Firebase singletons:"
  printf ' - %s\n' "${violations[@]}"
  exit 1
fi

echo "Artwork UI boundary check passed."
