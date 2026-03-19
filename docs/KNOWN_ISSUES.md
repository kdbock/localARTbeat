# ARTbeat Known Issues

## Purpose

Keep visible issues in one place with impact, workaround, and target action.

## Open Issues

### Admin deletion request fulfillment can fail

- Severity: high
- Area: legal / settings / backend
- Evidence: `docs/archive/manual_qa_result_2026-02-27.md`
- Symptom: admin queue deletion fulfillment returned
  `[firebase_functions/internal] INTERNAL`
- Impact: blocks confidence in deletion workflow and canary sign-off
- Workaround: use the updated admin queue UI and
  `scripts/legal_staging_regression.sh` to inspect `processingError` and
  `processingFailedAt` once a credentialed staging repro is run; non-admin
  staging smoke checks were revalidated locally on 2026-03-19
- Target action: fixed in staging on 2026-03-19 by removing
  `FieldValue.serverTimestamp()` values from `deletionSummary.pipelineSteps`
  array items; rerun manual QA and keep this issue open only if the admin UI
  still fails against the fixed callable

### Package boundaries are highly coupled

- Severity: high
- Area: architecture
- Evidence:
  - `packages/artbeat_core/pubspec.yaml`
  - feature package manifests across `packages/`
- Impact: broader regression surface than necessary still exists in some
  feature areas
- Workaround: limit cross-cutting refactors and prefer incremental changes
- Target action: keep enforcing `DEPENDENCY_RULES.md` and reduce the remaining
  feature-to-feature coupling clusters over time

### Repo contains mixed source and local/generated artifacts

- Severity: medium
- Area: repo hygiene
- Evidence:
  - root logs and local files
  - committed package-local build/tooling residue
- Impact: harder navigation, higher accidental-change risk, noisier reviews
- Workaround: careful manual review before commits
- Target action: perform controlled cleanup and strengthen `.gitignore`

## Issue Rules

- Add new issues when they affect shipping confidence, production stability, or
  developer reliability.
- Remove issues only when fixed and verified.
- If an issue changes release risk, reflect it in `WORK_QUEUE.md`.
