# ARTbeat Known Issues

## Purpose

Keep visible issues in one place with impact, workaround, and target action.

## Open Issues

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

## Recently Cleared

### Admin deletion fulfillment blocker cleared on 2026-03-26

- Area: legal / settings / backend
- Evidence:
  - `docs/archive/manual_qa_result_2026-02-27.md`
  - `docs/security/LEGAL_RELEASE_STATUS.md`
  - `docs/RELEASE_CONFIDENCE_QA_CHECKLIST.md`
- Resolution:
  - the original callable failure was fixed on 2026-03-19
  - fresh manual QA passed on 2026-03-26
  - admin data-rights deletion handling is now working in the current verified
    flow
- Remaining caution:
  - this no longer belongs in Open Issues
  - production canary still depends on product/legal approval, support
    readiness approval, and canary scheduling

### Release-confidence manual QA blocker cleared on 2026-03-26

- Area: account / monetization / capture / messaging / legal
- Evidence:
  - `docs/RELEASE_CONFIDENCE_QA_CHECKLIST.md`
- Resolution:
  - targeted release-confidence QA completed successfully
  - messaging media upload reliability required a foundation fix:
    shared Firebase Storage upload hardening plus chat Storage rule alignment
    and redeploy
- Follow-through:
  - if a new release-critical regression appears, add it back under Open Issues
    as a concrete blocker rather than restoring the generic QA-needed item

## Issue Rules

- Add new issues when they affect shipping confidence, production stability, or
  developer reliability.
- Remove issues only when fixed and verified.
- If an issue changes release risk, reflect it in `WORK_QUEUE.md`.
