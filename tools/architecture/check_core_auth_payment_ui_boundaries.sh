#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

files=(
  "packages/artbeat_core/lib/src/screens/splash_screen.dart"
  "packages/artbeat_core/lib/src/widgets/enhanced_navigation_menu.dart"
  "packages/artbeat_core/lib/src/screens/subscription_purchase_screen.dart"
)

violations=()
pattern='FirebaseAuth\.instance|InAppSubscriptionService\('

for file in "${files[@]}"; do
  if grep -nE "$pattern" "$repo_root/$file" >/dev/null; then
    violations+=("$file")
  fi
done

if [ "${#violations[@]}" -gt 0 ]; then
  echo "Core auth/payment UI boundary check failed."
  echo "These auth and payment surfaces must use app-owned services instead of direct Firebase singletons or local service construction:"
  printf ' - %s\n' "${violations[@]}"
  exit 1
fi

echo "Core auth/payment UI boundary check passed."
