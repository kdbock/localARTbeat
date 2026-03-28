#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

files=(
  "packages/artbeat_ads/lib/src/screens/my_ads_screen.dart"
  "packages/artbeat_ads/lib/src/screens/local_ads_list_screen.dart"
  "packages/artbeat_ads/lib/src/widgets/ad_native_card_widget.dart"
  "packages/artbeat_ads/lib/src/widgets/ad_grid_card_widget.dart"
  "packages/artbeat_ads/lib/src/widgets/ad_small_banner_widget.dart"
  "packages/artbeat_ads/lib/src/widgets/ad_cta_card_widget.dart"
  "packages/artbeat_ads/lib/src/widgets/ad_carousel_widget.dart"
  "packages/artbeat_ads/lib/src/widgets/ad_badge_widget.dart"
)

violations=()
pattern='FirebaseAuth\.instance|FirebaseFirestore\.instance|LocalAdService\(|AdReportService\('

for file in "${files[@]}"; do
  if grep -nE "$pattern" "$repo_root/$file" >/dev/null; then
    violations+=("$file")
  fi
done

if [ "${#violations[@]}" -gt 0 ]; then
  echo "Ads UI boundary check failed."
  echo "These ads screens/widgets must use app-owned services instead of direct Firebase singletons or local service construction:"
  printf ' - %s\n' "${violations[@]}"
  exit 1
fi

echo "Ads UI boundary check passed."
