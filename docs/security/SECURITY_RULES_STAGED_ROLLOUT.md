# Security Rules Staged Rollout Plan

Owner: Kristy Kelly  
Goal: move from permissive development rules to least-privilege production rules safely.

## Stage 0: Baseline Inventory (1-2 days)

- List all Firestore collections used by app features.
- List all Storage paths used by uploads and reads.
- Map each path/collection to authorized roles:
- owner user
- other authenticated users
- admins
- public (if any)

## Stage 1: Draft Hardened Rules (2-4 days)

- Remove broad wildcard write access.
- Restrict user profile write to owner/admin only.
- Restrict sensitive collections (payments, requests, moderation) to owner/admin/service roles.
- For Storage, require user ownership checks on write/delete.
- Keep explicit temporary exceptions documented with expiration dates.

## Stage 2: Test Environment Validation (2-5 days)

- Deploy hardened rules to test project.
- Run a route-by-route test matrix:
- signup/login
- profile update/upload
- capture upload/edit
- events/payments critical paths
- data-rights request submission
- Confirm no unauthorized read/write succeeds.
- Run automated staging script:
- `PROJECT_ID=wordnerd-artbeat DEPLOY=1 scripts/legal_staging_regression.sh`
- Optional full admin lifecycle validation:
- `PROJECT_ID=wordnerd-artbeat ADMIN_ID_TOKEN=<staging_admin_token> scripts/legal_staging_regression.sh`

## Stage 3: Canary Production Rollout (1-2 days)

- Deploy rules in low-risk window.
- Enable high-cardinality logging for denied requests.
- Watch errors for 24-48 hours.
- Maintain rollback rule set ready.
- Follow runbook:
- `docs/security/LEGAL_PRODUCTION_CANARY_ROLLOUT_RUNBOOK.md`
- Deploy helper:
- `PROJECT_ID=<prod-project-id> ./scripts/legal_canary_deploy.sh`

## Stage 4: Full Enforcement

- Remove temporary bypasses.
- Document final policy and ownership matrix.
- Lock change process: security review required for rules edits.

## Stage 5: Ongoing Governance

- Weekly review of denied-request logs.
- Monthly least-privilege review.
- Quarterly audit of new collections/paths.

## Immediate High-Risk Targets

- `storage.rules`: remove top-level permissive `match /{allPaths=**} allow read, write`.
- `firestore.rules`: remove broad authenticated create/update/delete for financial and commission collections unless ownership-checked.
- Ensure user data-rights request collections are explicitly writable by the requesting authenticated user and readable by admin only.

## Validation Script

- Script path: `scripts/legal_staging_regression.sh`
- What it validates:
- local regression tests for key legal-adjacent flows
- storage owner-write and cross-user deny behavior
- user privilege-escalation blocking (`userType=admin`)
- data-rights pending request creation
- optional admin completion path through callable deletion workflow

## CI Automation

- Workflow: `.github/workflows/legal_staging_regression.yml`
- Required secrets:
- `STAGING_ADMIN_EMAIL`
- `STAGING_ADMIN_PASSWORD`
