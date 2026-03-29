#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENV_FILE="${1:-$ROOT_DIR/.env}"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

required_keys=(
  API_BASE_URL
  FIREBASE_FUNCTIONS_BASE_URL
  FIREBASE_REGION
  FIREBASE_PROJECT_ID
  STRIPE_PUBLISHABLE_KEY
  STRIPE_PRICE_SUBSCRIPTION_STARTER_MONTHLY
  STRIPE_PRICE_SUBSCRIPTION_CREATOR_MONTHLY
  STRIPE_PRICE_SUBSCRIPTION_BUSINESS_MONTHLY
  STRIPE_PRICE_SUBSCRIPTION_ENTERPRISE_MONTHLY
  STRIPE_PRODUCT_SPONSORSHIP_ART_WALK
  STRIPE_PRODUCT_SPONSORSHIP_CAPTURE
  STRIPE_PRODUCT_SPONSORSHIP_DISCOVERY
  STRIPE_PRICE_SPONSORSHIP_ART_WALK_MONTHLY
  STRIPE_PRICE_SPONSORSHIP_CAPTURE_MONTHLY
  STRIPE_PRICE_SPONSORSHIP_DISCOVERY_MONTHLY
)

failures=()

trimmed_value() {
  local key="$1"
  local value="${!key-}"
  printf '%s' "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

is_placeholder() {
  local value="$1"
  [[ -z "$value" ]] && return 0
  [[ "$value" == *XXXXXXXX* ]] && return 0
  [[ "$value" == your_* ]] && return 0
  [[ "$value" == pk_test_your_* ]] && return 0
  [[ "$value" == pk_live_your_* ]] && return 0
  [[ "$value" == prod_sponsorship_* ]] && return 0
  [[ "$value" == price_sponsorship_* ]] && return 0
  [[ "$value" == price_*_2025 ]] && return 0
  [[ "$value" == price_*_2026 ]] && return 0
  return 1
}

for key in "${required_keys[@]}"; do
  value="$(trimmed_value "$key")"
  if [[ -z "$value" ]]; then
    failures+=("missing: $key")
    continue
  fi
  if is_placeholder "$value"; then
    failures+=("placeholder: $key=$value")
  fi
done

api_base_url="$(trimmed_value API_BASE_URL)"
functions_url="$(trimmed_value FIREBASE_FUNCTIONS_BASE_URL)"
stripe_key="$(trimmed_value STRIPE_PUBLISHABLE_KEY)"
environment="${ENVIRONMENT:-}"

if [[ -n "$api_base_url" && ! "$api_base_url" =~ ^https?://[^[:space:]]+$ ]]; then
  failures+=("invalid API_BASE_URL: must be an absolute http(s) URL")
fi

if [[ -n "$functions_url" && ! "$functions_url" =~ ^https?://[^[:space:]]+$ ]]; then
  failures+=("invalid FIREBASE_FUNCTIONS_BASE_URL: must be an absolute http(s) URL")
fi

if [[ -n "$functions_url" && "$functions_url" == */ ]]; then
  failures+=("invalid FIREBASE_FUNCTIONS_BASE_URL: trailing slash is not allowed")
fi

if [[ -n "$environment" && "$environment" == "production" && "$stripe_key" == pk_test_* ]]; then
  failures+=("invalid STRIPE_PUBLISHABLE_KEY: production must not use a test key")
fi

if [[ ${#failures[@]} -gt 0 ]]; then
  echo "Release payment/config gate failed."
  printf ' - %s\n' "${failures[@]}"
  exit 1
fi

echo "Release payment/config gate passed."
