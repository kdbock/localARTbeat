# Legal Release Status

## Purpose

Track the current release-gate status for legal/data-rights rollout work in one
place so the team does not need to reconstruct status from archived notes.

## Current Status

- Automated staging regression: pass
- Engineering deploy verification: pass
- GitHub Actions legal staging workflow validation: pass
- Credentialed staging deletion repro: pass
- Manual in-app QA: pass on 2026-03-26
- Product/legal owner approval: captured on 2026-03-26
- Support readiness approval: captured on 2026-03-26 for the current
  owner-operated support path and runbooks
- Production canary sign-off: blocked pending explicit canary scheduling

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
- production canary still remains blocked until current product/legal +
  support approvals are captured and a canary window is scheduled

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

- production canary execution against the current passing evidence

## What "Non-Engineering Sign-Off" Means

In this repo, "non-engineering sign-off" means two specific approvals:

1. Product/legal owner sign-off
   Meaning: the person responsible for privacy/legal product risk agrees that
   the current deletion/data-rights behavior and evidence are acceptable for
   release.
2. Support readiness sign-off
   Meaning: support has the current runbook, knows what changed, knows how to
   identify a deletion/data-rights problem, and knows where escalation paths
   and evidence live.

This is not a hidden technical task. It is a release-approval step for the
people who handle legal/product acceptance and user support.

## Current Diagnostic Path

- `functions/src/index.js` now writes failed deletion processing back to the
  request document with `status`, `processingFailedAt`, and `processingError`
- `packages/artbeat_admin/lib/src/screens/admin_data_requests_screen.dart` now
  exposes `failed` requests plus the recorded error details in the admin UI
- `scripts/legal_staging_regression.sh` now fetches the request document after
  callable execution and prints the resulting status and processing error fields

## Required Next Actions

1. Record that manual in-app QA passed on 2026-03-26 against the fixed staging
   deletion flow.
2. Reconfirm that the admin queue UI behaved correctly with the fixed callable.
3. Keep the owner-approved policy set and incident/runbook docs in sync with any
   future product changes.
4. Schedule the production canary window.
5. Only then reopen production canary rollout.

## Release Rule

Do not treat the legal/data-rights rollout as release-ready until:

- staging deletion fulfillment is verified
- manual QA is current
- product/legal owner approval is captured
- support readiness approval is captured
