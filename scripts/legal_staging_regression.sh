#!/usr/bin/env bash

set -euo pipefail

PROJECT_ID="${PROJECT_ID:-wordnerd-artbeat}"
GOOGLE_SERVICES_PATH="${GOOGLE_SERVICES_PATH:-android/app/google-services.json}"

read_google_services_value() {
  local jq_expr="$1"
  if [[ -f "${GOOGLE_SERVICES_PATH}" ]]; then
    jq -r "${jq_expr} // empty" "${GOOGLE_SERVICES_PATH}"
  else
    echo ""
  fi
}

API_KEY="${API_KEY:-$(read_google_services_value '.client[0].api_key[0].current_key')}"
BUCKET="${BUCKET:-$(read_google_services_value '.project_info.storage_bucket')}"
BUCKET="${BUCKET:-${PROJECT_ID}.firebasestorage.app}"
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

fetch_firestore_doc() {
  local doc_name="$1"
  local token="$2"
  "$CURL" -sS \
    "https://firestore.googleapis.com/v1/${doc_name}" \
    -H "Authorization: Bearer ${token}"
}

print_request_diagnostics() {
  local request_json="$1"
  local status
  local reviewed_by
  local failed_at
  local error_code
  local error_message
  local review_notes

  status="$(json_field "${request_json}" '.fields.status.stringValue')"
  reviewed_by="$(json_field "${request_json}" '.fields.reviewedBy.stringValue')"
  failed_at="$(json_field "${request_json}" '.fields.processingFailedAt.timestampValue')"
  error_code="$(json_field "${request_json}" '.fields.processingError.mapValue.fields.code.stringValue')"
  error_message="$(json_field "${request_json}" '.fields.processingError.mapValue.fields.message.stringValue')"
  review_notes="$(json_field "${request_json}" '.fields.reviewNotes.stringValue')"

  echo "request_status=${status:-unknown}"
  echo "request_reviewed_by=${reviewed_by:--}"
  echo "request_failed_at=${failed_at:--}"
  echo "request_review_notes=${review_notes:--}"
  echo "request_processing_error_code=${error_code:--}"
  echo "request_processing_error_message=${error_message:--}"
}

echo "== Legal Staging Regression =="
echo "project: ${PROJECT_ID}"

if [[ -z "${API_KEY}" ]]; then
  echo "Missing API_KEY."
  echo "Set API_KEY explicitly or provide ${GOOGLE_SERVICES_PATH}."
  exit 1
fi

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
CHAT_ROOM="legal-smoke-room-${RAND}"
CHAT_PRIVATE_ROOM="legal-private-room-${RAND}"

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

upload_chat_code() {
  local token="$1"
  local path="$2"
  "$CURL" -sS -o /tmp/legal_upload_chat.json -w "%{http_code}" -X POST \
    "https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o?uploadType=media&name=${path}" \
    -H "Authorization: Bearer ${token}" \
    -H "Content-Type: application/octet-stream" \
    --data-binary "smoke-bytes"
}

echo "capture_owner_upload_http=$(upload_code "${U1_TOKEN}" "capture_images/${U1_ID}/smoke.txt") (expected 200)"
echo "ads_owner_upload_http=$(upload_code "${U1_TOKEN}" "ads/${U1_ID}/smoke.txt") (expected 200)"

# Create two chats to validate participant-aware media writes
"$CURL" -sS -X PATCH \
  "https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/chats/${CHAT_ROOM}?currentDocument.exists=false" \
  -H "Authorization: Bearer ${U1_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"fields\":{\"participantIds\":{\"arrayValue\":{\"values\":[{\"stringValue\":\"${U1_ID}\"},{\"stringValue\":\"${U2_ID}\"}]}},\"creatorId\":{\"stringValue\":\"${U1_ID}\"},\"createdAt\":{\"timestampValue\":\"${U1_NOW}\"},\"updatedAt\":{\"timestampValue\":\"${U1_NOW}\"}}}" >/dev/null

"$CURL" -sS -X PATCH \
  "https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/chats/${CHAT_PRIVATE_ROOM}?currentDocument.exists=false" \
  -H "Authorization: Bearer ${U1_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"fields\":{\"participantIds\":{\"arrayValue\":{\"values\":[{\"stringValue\":\"${U1_ID}\"}]}},\"creatorId\":{\"stringValue\":\"${U1_ID}\"},\"createdAt\":{\"timestampValue\":\"${U1_NOW}\"},\"updatedAt\":{\"timestampValue\":\"${U1_NOW}\"}}}" >/dev/null

echo "chat_media_upload_http=$(upload_chat_code "${U1_TOKEN}" "chat_media/${CHAT_ROOM}/smoke.txt") (expected 200)"

# Cross-user writes should be denied on owner-scoped paths
echo "capture_cross_user_upload_http=$(upload_code "${U2_TOKEN}" "capture_images/${U1_ID}/cross-user.txt") (expected 403)"
echo "ads_cross_user_upload_http=$(upload_code "${U2_TOKEN}" "ads/${U1_ID}/cross-user.txt") (expected 403)"
echo "chat_non_participant_upload_http=$(upload_chat_code "${U2_TOKEN}" "chat_media/${CHAT_PRIVATE_ROOM}/cross-user.txt") (expected 200)"

# Firestore participant authorization for chat messages (authoritative control)
MSG_PARTICIPANT_CODE="$("$CURL" -sS -o /tmp/legal_message_participant.json -w "%{http_code}" -X POST \
  "https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/chats/${CHAT_ROOM}/messages" \
  -H "Authorization: Bearer ${U1_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"fields\":{\"senderId\":{\"stringValue\":\"${U1_ID}\"},\"content\":{\"stringValue\":\"https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/chat_media%2F${CHAT_ROOM}%2Fsmoke.txt?alt=media\"},\"type\":{\"stringValue\":\"MessageType.image\"},\"storagePath\":{\"stringValue\":\"chat_media/${CHAT_ROOM}/smoke.txt\"},\"uploaderId\":{\"stringValue\":\"${U1_ID}\"},\"chatId\":{\"stringValue\":\"${CHAT_ROOM}\"},\"timestamp\":{\"timestampValue\":\"${U1_NOW}\"}}}")"
echo "chat_message_participant_create_http=${MSG_PARTICIPANT_CODE} (expected 200)"

MSG_NON_PARTICIPANT_CODE="$("$CURL" -sS -o /tmp/legal_message_non_participant.json -w "%{http_code}" -X POST \
  "https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/chats/${CHAT_PRIVATE_ROOM}/messages" \
  -H "Authorization: Bearer ${U2_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"fields\":{\"senderId\":{\"stringValue\":\"${U2_ID}\"},\"content\":{\"stringValue\":\"https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/chat_media%2F${CHAT_PRIVATE_ROOM}%2Fcross-user.txt?alt=media\"},\"type\":{\"stringValue\":\"MessageType.image\"},\"storagePath\":{\"stringValue\":\"chat_media/${CHAT_PRIVATE_ROOM}/cross-user.txt\"},\"uploaderId\":{\"stringValue\":\"${U2_ID}\"},\"chatId\":{\"stringValue\":\"${CHAT_PRIVATE_ROOM}\"},\"timestamp\":{\"timestampValue\":\"${U1_NOW}\"}}}")"
echo "chat_message_non_participant_create_http=${MSG_NON_PARTICIPANT_CODE} (expected 403)"

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
  REQUEST_DOC_AFTER_CALL="$(fetch_firestore_doc "${REQ_NAME}" "${ADMIN_ID_TOKEN}")"
  if [[ -n "${CALLABLE_ERR}" ]]; then
    echo "Callable failed: ${CALLABLE_RESP}"
    print_request_diagnostics "${REQUEST_DOC_AFTER_CALL}"
    exit 1
  fi
  echo "callable_response=${CALLABLE_RESP}"
  print_request_diagnostics "${REQUEST_DOC_AFTER_CALL}"
fi

echo "== Completed =="
