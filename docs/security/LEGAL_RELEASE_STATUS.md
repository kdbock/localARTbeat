# Legal Release Status

## Purpose

Track the current release-gate status for legal/data-rights rollout work in one
place so the team does not need to reconstruct status from archived notes.

## Current Status

- Automated staging regression: pass
- Engineering deploy verification: pass
- GitHub Actions legal staging workflow validation: pass
- Credentialed staging deletion repro: pass
- Manual in-app QA: stale fail from 2026-02-27; rerun required
- Production canary sign-off: blocked pending fresh QA and non-engineering sign-off

## Evidence

- `docs/archive/2026-02-26_legal_security_recap.md`
- `docs/archive/manual_qa_result_2026-02-27.md`
- `docs/security/LEGAL_PRODUCTION_CANARY_ROLLOUT_RUNBOOK.md`
- `docs/security/LEGAL_INCIDENT_RESPONSE_PLAN.md`

## Blocking Issue

Previous blocker:

- admin deletion request fulfillment failed during manual QA on 2026-02-27 with
  `[firebase_functions/internal] INTERNAL`

Impact:

- the concrete callable failure has been reproduced and fixed
- staging deletion workflow is now verified end-to-end
- production canary still remains blocked until fresh manual QA and current
  product/legal + support sign-off are captured

## What Is Verified

- staging rules and deletion-function rollout completed
- automated regression completed successfully
- CI workflow for legal staging regression validated
- local staging regression re-run from this machine on 2026-03-19 passed all
  non-admin rule and storage/chat checks
- local staging regression on 2026-03-19 created fresh deletion requests for
  follow-up admin processing
- data-rights request creation succeeded in manual QA
- function-side failure diagnostics are implemented
- admin UI now exposes failed deletion requests and processing errors
- staging regression script now prints request status and processing error fields
- a fresh staging deploy of `functions:processDataDeletionRequest` was started
  from this machine on 2026-03-18
- the root cause was identified: `deletionSummary.pipelineSteps` used
  `FieldValue.serverTimestamp()` inside array items, which Firestore rejects
- `processDataDeletionRequest` was patched and redeployed to staging on
  2026-03-19
- a credentialed staging repro passed on 2026-03-19 with request
  `fq0DXnJ0QxWIc8phFPk3` returning `result.ok=true` and request status
  `fulfilled`

## What Is Not Verified Yet

- fresh product/legal owner sign-off against current evidence
- fresh support readiness sign-off against current evidence
- fresh manual in-app QA evidence after the 2026-03-19 fix
- production canary execution against current evidence

## Current Diagnostic Path

- `functions/src/index.js` now writes failed deletion processing back to the
  request document with `status`, `processingFailedAt`, and `processingError`
- `packages/artbeat_admin/lib/src/screens/admin_data_requests_screen.dart` now
  exposes `failed` requests plus the recorded error details in the admin UI
- `scripts/legal_staging_regression.sh` now fetches the request document after
  callable execution and prints the resulting status and processing error fields

## Required Next Actions

1. Re-run manual in-app QA and capture fresh evidence against the fixed staging
   deletion flow.
2. Confirm the admin queue UI also behaves correctly with the fixed callable,
   not just the scripted path.
3. Reconfirm product/legal owner sign-off and support readiness sign-off.
4. Only then reopen production canary rollout.

## Release Rule

Do not treat the legal/data-rights rollout as release-ready while the deletion
fulfillment path remains unverified in staging.
