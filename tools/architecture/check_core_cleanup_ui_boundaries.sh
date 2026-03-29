#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

files=(
  "packages/artbeat_core/lib/src/screens/art_market_screen.dart"
  "packages/artbeat_core/lib/src/widgets/temp_capture_fix.dart"
  "packages/artbeat_core/lib/src/widgets/izzy_xp_fix.dart"
)

violations=()
pattern='FirebaseAuth\.instance|FirebaseFirestore\.instance|UserService\(|UserMaintenanceService\('

for file in "${files[@]}"; do
  if grep -nE "$pattern" "$repo_root/$file" >/dev/null; then
    violations+=("$file")
  fi
done

if [ "${#violations[@]}" -gt 0 ]; then
  echo "Core cleanup UI boundary check failed."
  echo "These cleanup surfaces must use app-owned services instead of local service construction or direct Firebase singletons:"
  printf ' - %s\n' "${violations[@]}"
  exit 1
fi

echo "Core cleanup UI boundary check passed."
