#!/usr/bin/env bash

set -euo pipefail

# Optional env file support:
#   tools/security/run_p0_cross_account_abuse_checks.sh
#   tools/security/run_p0_cross_account_abuse_checks.sh path/to/envfile
ENV_FILE="${1:-}"
if [[ -n "${ENV_FILE}" ]]; then
  if [[ ! -f "${ENV_FILE}" ]]; then
    echo "Env file not found: ${ENV_FILE}"
    exit 2
  fi
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
fi

BASE_URL="${FUNCTIONS_BASE_URL:-https://us-central1-wordnerd-artbeat.cloudfunctions.net}"
ATTACKER_TOKEN="${ATTACKER_TOKEN:-}"
VICTIM_CUSTOMER_ID="${VICTIM_CUSTOMER_ID:-}"
VICTIM_SUBSCRIPTION_ID="${VICTIM_SUBSCRIPTION_ID:-}"
VICTIM_PAYMENT_INTENT_ID="${VICTIM_PAYMENT_INTENT_ID:-}"
VICTIM_PAYMENT_METHOD_ID="${VICTIM_PAYMENT_METHOD_ID:-}"

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DIR="artifacts/p0-abuse-checks"
OUT_FILE="${OUT_DIR}/${STAMP}.log"

mkdir -p "${OUT_DIR}"
failures=0

missing=()
[[ -z "${ATTACKER_TOKEN}" ]] && missing+=("ATTACKER_TOKEN")
[[ -z "${VICTIM_CUSTOMER_ID}" ]] && missing+=("VICTIM_CUSTOMER_ID")
[[ -z "${VICTIM_SUBSCRIPTION_ID}" ]] && missing+=("VICTIM_SUBSCRIPTION_ID")
[[ -z "${VICTIM_PAYMENT_INTENT_ID}" ]] && missing+=("VICTIM_PAYMENT_INTENT_ID")
[[ -z "${VICTIM_PAYMENT_METHOD_ID}" ]] && missing+=("VICTIM_PAYMENT_METHOD_ID")

if (( ${#missing[@]} > 0 )); then
  {
    echo "P0 cross-account abuse checks could not run."
    echo "Missing required environment variables:"
    for v in "${missing[@]}"; do
      echo "- ${v}"
    done
  } | tee "${OUT_FILE}"
  exit 2
fi

run_check() {
  local name="$1"
  local endpoint="$2"
  local payload="$3"
  local expected_status="$4"

  local tmp_file
  tmp_file="$(mktemp)"

  local status
  status="$(
    curl -sS -o "${tmp_file}" -w "%{http_code}" \
      -X POST "${BASE_URL}/${endpoint}" \
      -H "Authorization: Bearer ${ATTACKER_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "${payload}"
  )"

  {
    echo "=== ${name} ==="
    echo "timestamp_utc: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "endpoint: ${BASE_URL}/${endpoint}"
    echo "expected_status: ${expected_status}"
    echo "actual_status: ${status}"
    echo "payload: ${payload}"
    echo "response_body:"
    cat "${tmp_file}"
    echo
  } | tee -a "${OUT_FILE}"

  if [[ "${status}" != "${expected_status}" ]]; then
    {
      echo "result: FAIL"
      echo "reason: expected ${expected_status}, got ${status}"
      echo
    } | tee -a "${OUT_FILE}"
    failures=$((failures + 1))
  else
    echo "result: PASS" | tee -a "${OUT_FILE}"
    echo | tee -a "${OUT_FILE}"
  fi

  rm -f "${tmp_file}"
}

run_check \
  "cross_user_getPaymentMethods" \
  "getPaymentMethods" \
  "{\"customerId\":\"${VICTIM_CUSTOMER_ID}\"}" \
  "403"

run_check \
  "cross_user_cancelSubscription" \
  "cancelSubscription" \
  "{\"subscriptionId\":\"${VICTIM_SUBSCRIPTION_ID}\"}" \
  "403"

run_check \
  "cross_user_requestRefund" \
  "requestRefund" \
  "{\"paymentIntentId\":\"${VICTIM_PAYMENT_INTENT_ID}\",\"reason\":\"fraudulent\"}" \
  "403"

run_check \
  "cross_user_detachPaymentMethod" \
  "detachPaymentMethod" \
  "{\"paymentMethodId\":\"${VICTIM_PAYMENT_METHOD_ID}\"}" \
  "403"

if (( failures > 0 )); then
  echo "Completed with ${failures} failure(s). Evidence log: ${OUT_FILE}" | tee -a "${OUT_FILE}"
  exit 1
fi

echo "Completed P0 cross-account abuse checks with all expected denials. Evidence log: ${OUT_FILE}" | tee -a "${OUT_FILE}"
