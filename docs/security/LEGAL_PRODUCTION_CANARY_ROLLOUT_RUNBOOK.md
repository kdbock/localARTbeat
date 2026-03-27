# Legal Production Canary Rollout Runbook

Owner: Kristy Kelly  
Scope: legal/data-rights function + Firestore/Storage rules  
Target project: production Firebase project (set explicitly at runtime)

## Preconditions

- [x] Staging regression is green (`scripts/legal_staging_regression.sh`).
- [x] Manual in-app QA checklist completed successfully:
- `docs/LEGAL_STAGING_MANUAL_QA_CHECKLIST.md`
- Current passing evidence refreshed on 2026-03-26 in
  `docs/RELEASE_CONFIDENCE_QA_CHECKLIST.md` and
  `docs/security/LEGAL_RELEASE_STATUS.md`.
- [ ] On-call window reserved (minimum 24-48h observation after deploy).
- [ ] Rollback operator available.
- [x] Support contact channels confirmed.

## Canary Deploy Command

Use helper script:

```bash
PROJECT_ID=<prod-project-id> \
./scripts/legal_canary_deploy.sh
```

This deploys:

- `firestore.rules`
- `storage.rules`
- `functions:processDataDeletionRequest`

## Verification (First 30 Minutes)

- [ ] Confirm deploy succeeded in CLI output and Firebase Console.
- [ ] Submit one test data export request from non-admin user.
- [ ] Submit one test data deletion request from non-admin user.
- [ ] Process one request in admin queue.
- [ ] Validate callable deletion result (`ok: true`) and audit record created.
- [ ] Confirm no elevated rule denies in critical user flows:
- profile update
- capture upload
- ads upload
- chat media upload

## Monitoring Window (24-48h)

- [ ] Watch Cloud Function errors for `processDataDeletionRequest`.
- [ ] Watch Firestore/Storage denied request spikes.
- [ ] Watch support inbox for privacy/deletion complaints.
- [ ] Log incidents in `docs/security/LEGAL_INCIDENT_RESPONSE_PLAN.md` format.

## Rollback Plan

If high-severity issues occur:

1. Re-deploy last known-good rules and function revision.
2. Pause admin deletion processing until stabilized.
3. Notify internal stakeholders.
4. Record root cause and remediation before reattempt.

### Suggested rollback commands

```bash
# Replace with backed-up known-good files/revision before running
firebase deploy --project <prod-project-id> --only firestore:rules,storage --non-interactive
firebase deploy --project <prod-project-id> --only functions:processDataDeletionRequest --non-interactive
```

## Sign-Off

- [x] Engineering sign-off
- [x] Product/legal owner sign-off confirmed against current evidence
- [x] Support readiness sign-off confirmed against current evidence

## Execution Log

- [x] 2026-02-26: Canary deploy command executed successfully:
  `PROJECT_ID=wordnerd-artbeat ./scripts/legal_canary_deploy.sh`
- [x] 2026-02-26: Post-deploy verification regression executed successfully:
  `PROJECT_ID=wordnerd-artbeat ADMIN_EMAIL=<set> ADMIN_PASSWORD=<set> ./scripts/legal_staging_regression.sh`
- [x] 2026-02-26: Shared chat lifecycle hardening deployed and validated:
  storage/firestore/function updates deployed to `wordnerd-artbeat`; regression checks include participant message create allow/deny.
- [x] 2026-02-26: Manual in-app UI checklist session executed and attached.
- Attachment target: `docs/LEGAL_STAGING_UI_QA_SESSION_REPORT_YYYY-MM-DD.md`
- [x] 2026-02-26: GitHub Actions workflow run evidence attached (`22424833231` success).
- [x] 2026-03-26: Follow-up manual QA re-run passed after deletion fix,
  messaging upload hardening, and rules alignment; blocker cleared in
  `docs/security/LEGAL_RELEASE_STATUS.md`.
- [ ] Next action: reserve canary window, identify rollback operator, and
  execute the production canary against the current passing evidence set.
