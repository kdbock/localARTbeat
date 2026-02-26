#!/usr/bin/env bash

set -euo pipefail

REPO="${REPO:-kdbock/localARTbeat}"
WORKFLOW_FILE="${WORKFLOW_FILE:-legal_staging_regression.yml}"
DEPLOY_FIRST="${DEPLOY_FIRST:-0}"
STAGING_ADMIN_EMAIL="${STAGING_ADMIN_EMAIL:-}"
STAGING_ADMIN_PASSWORD="${STAGING_ADMIN_PASSWORD:-}"

if ! command -v gh >/dev/null 2>&1; then
  echo "Missing gh CLI. Install with: brew install gh"
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "GitHub CLI is not authenticated."
  echo "Run: gh auth login"
  exit 1
fi

if [[ -z "${STAGING_ADMIN_EMAIL}" || -z "${STAGING_ADMIN_PASSWORD}" ]]; then
  echo "Missing secrets in environment."
  echo "Usage:"
  echo "  STAGING_ADMIN_EMAIL=<email> STAGING_ADMIN_PASSWORD=<password> ./scripts/legal_ci_setup_and_run.sh"
  exit 1
fi

echo "Setting repository secrets on ${REPO}..."
gh secret set STAGING_ADMIN_EMAIL -R "${REPO}" -b "${STAGING_ADMIN_EMAIL}"
gh secret set STAGING_ADMIN_PASSWORD -R "${REPO}" -b "${STAGING_ADMIN_PASSWORD}"

echo "Dispatching ${WORKFLOW_FILE} with deploy_first=${DEPLOY_FIRST}..."
gh workflow run "${WORKFLOW_FILE}" -R "${REPO}" -f deploy_first="${DEPLOY_FIRST}"

echo "Watching latest workflow run..."
gh run list -R "${REPO}" --workflow "${WORKFLOW_FILE}" --limit 1
gh run watch -R "${REPO}" "$(gh run list -R "${REPO}" --workflow "${WORKFLOW_FILE}" --limit 1 --json databaseId --jq '.[0].databaseId')"

echo "Done."
