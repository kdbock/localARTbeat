#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FUNCTIONS_INDEX="$ROOT_DIR/functions/src/index.js"

failures=()

require_pattern() {
  local pattern="$1"
  local label="$2"
  if command -v rg >/dev/null 2>&1; then
    if ! rg -q "$pattern" "$FUNCTIONS_INDEX"; then
      failures+=("missing backend endpoint: $label")
    fi
    return
  fi

  if ! grep -Eq "$pattern" "$FUNCTIONS_INDEX"; then
    failures+=("missing backend endpoint: $label")
  fi
}

if [[ ! -f "$FUNCTIONS_INDEX" ]]; then
  echo "Release monetization prerequisite gate failed."
  echo " - missing functions entrypoint: $FUNCTIONS_INDEX"
  exit 1
fi

require_pattern 'exports\.validateAppleReceipt\s*=' 'validateAppleReceipt'
require_pattern 'exports\.verifyGooglePlayPurchase\s*=' 'verifyGooglePlayPurchase'
require_pattern 'exports\.activateIapSubscription\s*=' 'activateIapSubscription'
require_pattern 'exports\.cancelIapSubscription\s*=' 'cancelIapSubscription'
require_pattern 'exports\.createSubscription\s*=' 'createSubscription'
require_pattern 'exports\.cancelSubscription\s*=' 'cancelSubscription'
require_pattern 'exports\.processArtworkSalePayment\s*=' 'processArtworkSalePayment'
require_pattern 'exports\.processEventTicketPayment\s*=' 'processEventTicketPayment'
require_pattern 'exports\.processCommissionDepositPayment\s*=' 'processCommissionDepositPayment'
require_pattern 'exports\.processCommissionMilestonePayment\s*=' 'processCommissionMilestonePayment'
require_pattern 'exports\.processCommissionFinalPayment\s*=' 'processCommissionFinalPayment'
require_pattern 'exports\.completeCommission\s*=' 'completeCommission'

if ! (
  cd "$ROOT_DIR/functions" &&
  node -e "require.resolve('googleapis')"
) >/dev/null 2>&1; then
  failures+=("missing runtime module: googleapis must be resolvable in functions")
fi

if ! node --check "$FUNCTIONS_INDEX" >/dev/null 2>&1; then
  failures+=("invalid functions syntax: functions/src/index.js")
fi

if [[ ${#failures[@]} -gt 0 ]]; then
  echo "Release monetization prerequisite gate failed."
  printf ' - %s\n' "${failures[@]}"
  exit 1
fi

echo "Release monetization prerequisite gate passed."
