#!/usr/bin/env bash

set -euo pipefail

PROJECT_ID="${PROJECT_ID:-}"

if [[ -z "${PROJECT_ID}" ]]; then
  echo "Missing PROJECT_ID."
  echo "Usage: PROJECT_ID=<firebase-project-id> ./scripts/legal_canary_deploy.sh"
  exit 1
fi

echo "== Legal Canary Deploy =="
echo "Project: ${PROJECT_ID}"

echo "Deploying Firestore + Storage rules and processDataDeletionRequest..."
firebase deploy \
  --project "${PROJECT_ID}" \
  --only firestore:rules,storage,functions:processDataDeletionRequest \
  --non-interactive

echo "Canary deploy completed."
echo "Next: run the verification section in docs/security/LEGAL_PRODUCTION_CANARY_ROLLOUT_RUNBOOK.md"
