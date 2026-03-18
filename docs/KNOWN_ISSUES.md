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
- Workaround: none documented beyond investigation and staged verification
- Target action: reproduce, isolate failing callable path, verify end-to-end in
  staging, then rerun manual QA

### Missing localization keys still appear at runtime

- Severity: medium
- Area: localization
- Evidence:
  - `assets/translations/missing_keys.md`
  - `docs/archive/manual_qa_result_2026-02-27.md`
- Known missing keys include:
  - `user_events_today_section`
  - `user_events_this_week_section`
  - runtime warnings also noted for auth/drawer keys during manual QA
- Impact: degraded non-English and fallback UX, runtime warning noise
- Workaround: English fallback may mask some issues
- Target action: standardize translation parity validation and close missing keys

### Package boundaries are highly coupled

- Severity: high
- Area: architecture
- Evidence:
  - `packages/artbeat_core/pubspec.yaml`
  - feature package manifests across `packages/`
- Impact: broad regression surface for small changes
- Workaround: limit cross-cutting refactors and prefer incremental changes
- Target action: enforce `DEPENDENCY_RULES.md` and reduce `artbeat_core`
  ownership over time

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
