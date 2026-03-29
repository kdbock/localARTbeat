#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

files=(
  "packages/artbeat_artist/lib/src/screens/payment_screen.dart"
  "packages/artbeat_artist/lib/src/screens/payment_methods_screen.dart"
  "packages/artbeat_artist/lib/src/screens/refund_request_screen.dart"
  "packages/artbeat_artist/lib/src/screens/earnings/artist_earnings_hub.dart"
  "packages/artbeat_artist/lib/src/screens/earnings/payout_request_screen.dart"
  "packages/artbeat_artist/lib/src/screens/earnings/payout_accounts_screen.dart"
  "packages/artbeat_artist/lib/src/screens/earnings/artwork_sales_hub.dart"
)

violations=()
pattern='FirebaseAuth\.instance|FirebaseFirestore\.instance|UnifiedPaymentService\(|EarningsService\(|ArtistBoostService\(|UserService\('

for file in "${files[@]}"; do
  if grep -nE "$pattern" "$repo_root/$file" >/dev/null; then
    violations+=("$file")
  fi
done

if [ "${#violations[@]}" -gt 0 ]; then
  echo "Artist monetization UI boundary check failed."
  echo "These artist monetization screens must use app-owned services instead of direct Firebase singletons or local service construction:"
  printf ' - %s\n' "${violations[@]}"
  exit 1
fi

echo "Artist monetization UI boundary check passed."
