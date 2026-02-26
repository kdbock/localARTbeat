#!/usr/bin/env bash

set -euo pipefail

REPO="${REPO:-kdbock/localARTbeat}"
WORKFLOW_FILE="${WORKFLOW_FILE:-legal_staging_regression.yml}"
DEPLOY_FIRST="${DEPLOY_FIRST:-0}"
STAGING_ADMIN_EMAIL="${STAGING_ADMIN_EMAIL:-}"
STAGING_ADMIN_PASSWORD="${STAGING_ADMIN_PASSWORD:-}"
STAGING_FIREBASE_API_KEY="${STAGING_FIREBASE_API_KEY:-}"
STAGING_FIREBASE_STORAGE_BUCKET="${STAGING_FIREBASE_STORAGE_BUCKET:-}"

if ! command -v gh >/dev/null 2>&1; then
  echo "Missing gh CLI. Install with: brew install gh"
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "GitHub CLI is not authenticated."
  echo "Run: gh auth login"
  exit 1
fi

if [[ -z "${STAGING_ADMIN_EMAIL}" || -z "${STAGING_ADMIN_PASSWORD}" || -z "${STAGING_FIREBASE_API_KEY}" ]]; then
  echo "Missing secrets in environment."
  echo "Usage:"
  echo "  STAGING_ADMIN_EMAIL=<email> STAGING_ADMIN_PASSWORD=<password> STAGING_FIREBASE_API_KEY=<apiKey> [STAGING_FIREBASE_STORAGE_BUCKET=<bucket>] ./scripts/legal_ci_setup_and_run.sh"
  exit 1
fi

echo "Setting repository secrets on ${REPO}..."
gh secret set STAGING_ADMIN_EMAIL -R "${REPO}" -b "${STAGING_ADMIN_EMAIL}"
gh secret set STAGING_ADMIN_PASSWORD -R "${REPO}" -b "${STAGING_ADMIN_PASSWORD}"
gh secret set STAGING_FIREBASE_API_KEY -R "${REPO}" -b "${STAGING_FIREBASE_API_KEY}"
if [[ -n "${STAGING_FIREBASE_STORAGE_BUCKET}" ]]; then
  gh secret set STAGING_FIREBASE_STORAGE_BUCKET -R "${REPO}" -b "${STAGING_FIREBASE_STORAGE_BUCKET}"
fi

echo "Dispatching ${WORKFLOW_FILE} with deploy_first=${DEPLOY_FIRST}..."
gh workflow run "${WORKFLOW_FILE}" -R "${REPO}" -f deploy_first="${DEPLOY_FIRST}"

echo "Watching latest workflow run..."
gh run list -R "${REPO}" --workflow "${WORKFLOW_FILE}" --limit 1
gh run watch -R "${REPO}" "$(gh run list -R "${REPO}" --workflow "${WORKFLOW_FILE}" --limit 1 --json databaseId --jq '.[0].databaseId')"

echo "Done."
