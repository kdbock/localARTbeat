#!/usr/bin/env bash

set -euo pipefail

PROJECT_ID="${PROJECT_ID:-wordnerd-artbeat}"
API_KEY="${API_KEY:-$(jq -r '.client[0].api_key[0].current_key' android/app/google-services.json)}"
BUCKET="${BUCKET:-$(jq -r '.project_info.storage_bucket' android/app/google-services.json)}"
ADMIN_ID_TOKEN="${ADMIN_ID_TOKEN:-}"
ADMIN_EMAIL="${ADMIN_EMAIL:-}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-}"
DEPLOY="${DEPLOY:-0}"

CURL="/usr/bin/curl"

now_ts() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

signup_user() {
  local email="$1"
  local pass="$2"
  "$CURL" -sS -X POST \
    "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${API_KEY}" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"${email}\",\"password\":\"${pass}\",\"returnSecureToken\":true}"
}

delete_user_by_token() {
  local token="$1"
  "$CURL" -sS -X POST \
    "https://identitytoolkit.googleapis.com/v1/accounts:delete?key=${API_KEY}" \
    -H "Content-Type: application/json" \
    -d "{\"idToken\":\"${token}\"}" >/dev/null || true
}

sign_in_user() {
  local email="$1"
  local pass="$2"
  "$CURL" -sS -X POST \
    "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"${email}\",\"password\":\"${pass}\",\"returnSecureToken\":true}"
}

json_field() {
  local json="$1"
  local path="$2"
  echo "${json}" | jq -r "${path} // empty"
}

echo "== Legal Staging Regression =="
echo "project: ${PROJECT_ID}"

if [[ "${DEPLOY}" == "1" ]]; then
  firebase deploy \
    --project "${PROJECT_ID}" \
    --only firestore:rules,storage,functions:processDataDeletionRequest \
    --non-interactive
fi

if [[ -z "${ADMIN_ID_TOKEN}" && -n "${ADMIN_EMAIL}" && -n "${ADMIN_PASSWORD}" ]]; then
  echo "== Resolving admin token from ADMIN_EMAIL/ADMIN_PASSWORD =="
  ADMIN_SIGNIN_JSON="$(sign_in_user "${ADMIN_EMAIL}" "${ADMIN_PASSWORD}")"
  ADMIN_ID_TOKEN="$(json_field "${ADMIN_SIGNIN_JSON}" '.idToken')"
  if [[ -z "${ADMIN_ID_TOKEN}" ]]; then
    echo "Failed to sign in admin user; check ADMIN_EMAIL/ADMIN_PASSWORD."
    echo "Response: ${ADMIN_SIGNIN_JSON}"
    exit 1
  fi
fi

if [[ -n "${ADMIN_ID_TOKEN}" && "${ADMIN_ID_TOKEN}" == "null" ]]; then
  echo "ADMIN_ID_TOKEN resolved to literal 'null'."
  echo "Generate a real Firebase ID token first."
  exit 1
fi

echo "== Running local regression tests =="
flutter test test/artist_features_test.dart test/art_walk_system_test.dart

echo "== Running live rule + workflow checks =="
RAND="$(date +%s)"
PASS="TempPass123!"
U1_EMAIL="legal-smoke-u1-${RAND}@localartbeat.com"
U2_EMAIL="legal-smoke-u2-${RAND}@localartbeat.com"

U1_SIGNUP="$(signup_user "${U1_EMAIL}" "${PASS}")"
U2_SIGNUP="$(signup_user "${U2_EMAIL}" "${PASS}")"
U1_ID="$(echo "${U1_SIGNUP}" | jq -r '.localId // empty')"
U1_TOKEN="$(echo "${U1_SIGNUP}" | jq -r '.idToken // empty')"
U2_ID="$(echo "${U2_SIGNUP}" | jq -r '.localId // empty')"
U2_TOKEN="$(echo "${U2_SIGNUP}" | jq -r '.idToken // empty')"

if [[ -z "${U1_ID}" || -z "${U1_TOKEN}" || -z "${U2_ID}" || -z "${U2_TOKEN}" ]]; then
  echo "Failed to create disposable users"
  exit 1
fi

cleanup() {
  delete_user_by_token "${U1_TOKEN}"
  delete_user_by_token "${U2_TOKEN}"
}
trap cleanup EXIT

U1_NOW="$(now_ts)"

# Create user docs
"$CURL" -sS -X PATCH \
  "https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/users/${U1_ID}?currentDocument.exists=false" \
  -H "Authorization: Bearer ${U1_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"fields\":{\"email\":{\"stringValue\":\"${U1_EMAIL}\"},\"userType\":{\"stringValue\":\"user\"},\"createdAt\":{\"timestampValue\":\"${U1_NOW}\"}}}" >/dev/null

"$CURL" -sS -X PATCH \
  "https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/users/${U2_ID}?currentDocument.exists=false" \
  -H "Authorization: Bearer ${U2_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"fields\":{\"email\":{\"stringValue\":\"${U2_EMAIL}\"},\"userType\":{\"stringValue\":\"user\"},\"createdAt\":{\"timestampValue\":\"${U1_NOW}\"}}}" >/dev/null

# Verify self-promotion is blocked
PROMOTE_CODE="$("$CURL" -sS -o /tmp/legal_promote.json -w "%{http_code}" -X PATCH \
  "https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/users/${U1_ID}?updateMask.fieldPaths=userType&updateMask.fieldPaths=updatedAt" \
  -H "Authorization: Bearer ${U1_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"fields\":{\"userType\":{\"stringValue\":\"admin\"},\"updatedAt\":{\"timestampValue\":\"${U1_NOW}\"}}}")"
echo "self_promote_admin_http=${PROMOTE_CODE} (expected 403)"

# Storage smoke (owner paths should allow)
upload_code() {
  local token="$1"
  local path="$2"
  "$CURL" -sS -o /tmp/legal_upload.json -w "%{http_code}" -X POST \
    "https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o?uploadType=media&name=${path}" \
    -H "Authorization: Bearer ${token}" \
    -H "Content-Type: application/octet-stream" \
    --data-binary "smoke-bytes"
}

echo "capture_owner_upload_http=$(upload_code "${U1_TOKEN}" "capture_images/${U1_ID}/smoke.txt") (expected 200)"
echo "ads_owner_upload_http=$(upload_code "${U1_TOKEN}" "ads/${U1_ID}/smoke.txt") (expected 200)"
echo "chat_media_upload_http=$(upload_code "${U1_TOKEN}" "chat_media/legal-smoke-room/smoke.txt") (expected 200)"

# Cross-user writes should be denied on owner-scoped paths
echo "capture_cross_user_upload_http=$(upload_code "${U2_TOKEN}" "capture_images/${U1_ID}/cross-user.txt") (expected 403)"
echo "ads_cross_user_upload_http=$(upload_code "${U2_TOKEN}" "ads/${U1_ID}/cross-user.txt") (expected 403)"

# Create deletion request (pending)
REQ_DOC="$("$CURL" -sS -X POST \
  "https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/dataRequests" \
  -H "Authorization: Bearer ${U1_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"fields\":{\"userId\":{\"stringValue\":\"${U1_ID}\"},\"requestType\":{\"stringValue\":\"deletion\"},\"type\":{\"stringValue\":\"deletion\"},\"status\":{\"stringValue\":\"pending\"},\"submittedVia\":{\"stringValue\":\"legal_staging_regression\"},\"requestedAt\":{\"timestampValue\":\"${U1_NOW}\"}}}")"
REQ_NAME="$(echo "${REQ_DOC}" | jq -r '.name // empty')"
REQ_ID="${REQ_NAME##*/}"
echo "data_request_created=${REQ_ID}"

if [[ -n "${ADMIN_ID_TOKEN}" ]]; then
  echo "== Running admin lifecycle completion with provided ADMIN_ID_TOKEN =="
  LOOKUP_RESP="$("$CURL" -sS -X POST \
    "https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=${API_KEY}" \
    -H "Content-Type: application/json" \
    -d "{\"idToken\":\"${ADMIN_ID_TOKEN}\"}")"
  LOOKUP_ERR="$(json_field "${LOOKUP_RESP}" '.error.message')"
  if [[ -n "${LOOKUP_ERR}" ]]; then
    echo "Admin token validation failed: ${LOOKUP_RESP}"
    exit 1
  fi

  "$CURL" -sS -X PATCH \
    "https://firestore.googleapis.com/v1/${REQ_NAME}?updateMask.fieldPaths=status&updateMask.fieldPaths=acknowledgedAt&updateMask.fieldPaths=updatedAt" \
    -H "Authorization: Bearer ${ADMIN_ID_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{\"fields\":{\"status\":{\"stringValue\":\"in_review\"},\"acknowledgedAt\":{\"timestampValue\":\"${U1_NOW}\"},\"updatedAt\":{\"timestampValue\":\"${U1_NOW}\"}}}" >/dev/null

  CALLABLE_RESP="$("$CURL" -sS -X POST \
    "https://us-central1-${PROJECT_ID}.cloudfunctions.net/processDataDeletionRequest" \
    -H "Authorization: Bearer ${ADMIN_ID_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{\"data\":{\"requestId\":\"${REQ_ID}\",\"userId\":\"${U1_ID}\",\"reviewNotes\":\"legal_staging_regression\"}}")"
  CALLABLE_ERR="$(json_field "${CALLABLE_RESP}" '.error.status')"
  if [[ -n "${CALLABLE_ERR}" ]]; then
    echo "Callable failed: ${CALLABLE_RESP}"
    exit 1
  fi
  echo "callable_response=${CALLABLE_RESP}"
fi

echo "== Completed =="
