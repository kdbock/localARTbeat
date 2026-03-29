#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

files=(
  "packages/artbeat_core/lib/src/screens/artbeat_store.dart"
  "packages/artbeat_core/lib/src/screens/coupon_management_screen.dart"
  "packages/artbeat_core/lib/src/widgets/payment_analytics_dashboard.dart"
  "packages/artbeat_core/lib/src/widgets/usage_limits_widget.dart"
  "packages/artbeat_core/lib/src/widgets/featured_content_row_widget.dart"
  "packages/artbeat_core/lib/src/widgets/secure_network_image.dart"
  "packages/artbeat_core/lib/src/widgets/optimized_image.dart"
)

violations=()
pattern='FirebaseAuth\.instance|FirebaseFirestore\.instance|PaymentAnalyticsService\(|UsageTrackingService\(|CouponService\(|ImageManagementService\(|StorePreviewReadService\(|AuthService\('

for file in "${files[@]}"; do
  if grep -nE "$pattern" "$repo_root/$file" >/dev/null; then
    violations+=("$file")
  fi
done

if [ "${#violations[@]}" -gt 0 ]; then
  echo "Core commerce/media UI boundary check failed."
  echo "These commerce/media surfaces must use app-owned services instead of direct Firebase singletons or local service construction:"
  printf ' - %s\n' "${violations[@]}"
  exit 1
fi

echo "Core commerce/media UI boundary check passed."
