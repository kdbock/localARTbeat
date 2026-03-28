#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

files=(
  "packages/artbeat_core/lib/src/screens/boosts/artist_boosts_screen.dart"
  "packages/artbeat_core/lib/src/widgets/commission_artists_preview.dart"
  "packages/artbeat_core/lib/src/widgets/feedback_form.dart"
)

violations=()
pattern='FirebaseAuth\.instance|FirebaseFirestore\.instance|UserService\(|ArtistBoostService\(|CommissionArtistPreviewService\(|FeedbackService\('

for file in "${files[@]}"; do
  if grep -nE "$pattern" "$repo_root/$file" >/dev/null; then
    violations+=("$file")
  fi
done

if [ "${#violations[@]}" -gt 0 ]; then
  echo "Core feature-access UI boundary check failed."
  echo "These feature-access surfaces must use app-owned services instead of local service construction or direct Firebase singletons:"
  printf ' - %s\n' "${violations[@]}"
  exit 1
fi

echo "Core feature-access UI boundary check passed."
