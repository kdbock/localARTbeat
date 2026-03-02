# TODO - Legal System Implementation Plan

Owner: Kristy Kelly  
Entity: Local ARTbeat, LLC  
Primary legal/support email: support@localartbeat.com

## Locked Decisions (Approved)

- [x] Arbitration + class action waiver language in ToS (where permitted).
- [x] 7-year retention for financial/legal records.
- [x] Account deletion timeline: 30 days primary + 60 days backup purge.
- [x] Refund baseline: no refunds except where required by law/platform policy.
- [x] Data-rights SLA: acknowledge in 72 hours, fulfill in 30 days.
- [x] Age baseline: 13+ globally; not directed to children under 13.
- [ ] School/student mode policy and consent flow definition (TBD).

## Completed (This Round)

- [x] Added centralized legal config (`LegalConfig`) with company/contact/version/SLA/retention values.
- [x] Added durable versioned consent recording on registration.
- [x] Added Legal Center screen (consent versions + acceptance timestamps).
- [x] Enforced one-time capture terms acceptance before upload submission.
- [x] Fixed profile legal menu to open proper Terms/Privacy + Legal Center.
- [x] Updated Terms and Privacy screens with approved legal decisions.
- [x] Normalized support email in help/legal/deletion surfaces.
- [x] Added `docs/security/LEGAL_INCIDENT_RESPONSE_PLAN.md`.
- [x] Added `docs/security/SECURITY_RULES_STAGED_ROLLOUT.md`.

## P0 - Must Do Next

- [x] Make data-rights requests functional end-to-end for non-admin users.
- [x] Add explicit Firestore rules for `dataRequests` / `dataExportRequests` / `dataDeletionRequests`.
- [x] Build admin queue UI for privacy requests with statuses and SLA timers.
- [x] Add request acknowledgment/fulfillment timestamps and audit trail.
- [x] Expand account deletion backend to cover declared user-data domains via admin deletion pipeline.
- [x] Verify deletion behavior matches published policy text in staging runtime (API-level lifecycle test + audit evidence).
- [x] Verify deletion behavior matches published policy text in app UX (manual UI QA pass; screenshot evidence captured).

## P1 - Security Hardening (Staged Rollout)

- [x] Stage 0 inventory for all Firestore collections and Storage paths.
- [x] Draft hardened rules for least privilege (remove broad authenticated write/read).
- [x] Deploy hardened rules to test project and run feature-focused regression checks.
- [x] Canary deploy to production with rollback plan.
- [ ] Remove temporary permissive exceptions after validation.

## Newly Implemented In Code (February 25, 2026)

- [x] Added SLA fields to `dataRequests` at creation (`slaAcknowledgementDueAt`, `slaCompletionDueAt`, SLA targets).
- [x] Upgraded admin data-requests queue with status actions, review notes, reviewer stamp, and SLA-overdue visibility.
- [x] Added callable Cloud Function `processDataDeletionRequest` for admin-run deletion pipeline + audit log.
- [x] Added `dataRequestAudit` collection support in Firestore rules (admin-only).
- [x] Hardened high-risk Firestore rule paths (`direct_commissions`, `artwork_sales`, `commission_requests`, `gift_purchases`, `artLocationClusters`, `sponsorships`, `chapter_analytics`).
- [x] Hardened Storage rules by removing broad development write/read paths and restricting debug/root paths to admin.

## Newly Implemented In Code (February 26, 2026 - Follow-up)

- [x] Aligned in-app account deletion UX copy with policy timelines and retention carve-outs (30-day primary deletion, 60-day backup purge, 7-year legal/financial retention where required).
- [x] Hardened chat media Storage rules: participant-only read/write, App Check-gated participant checks, required uploader/chat metadata on uploads, and uploader/admin-only deletes.
- [x] Continued Storage rules hardening by removing remaining temporary/permissive debug bypass behavior and requiring App Check-gated authorization for owner/admin writes across media paths.
- [x] Added purchase-flow inline legal disclosure for recurring billing and refund exceptions, with in-flow Terms/Privacy links.
- [x] Implemented first-use location safety disclosure flow and enforced it before location permission in primary Art Walk entry surfaces.

## Staging Validation Completed (February 26, 2026)

- [x] Deployed `firestore.rules`, `storage.rules`, and callable `processDataDeletionRequest` to `wordnerd-artbeat`.
- [x] Ran regression tests: `flutter test test/artist_features_test.dart test/art_walk_system_test.dart` (pass).
- [x] Ran live storage upload smoke tests for capture/ads/chat media/posts paths.
- [x] Ran live negative permission tests (cross-user writes denied on owner-scoped paths).
- [x] Validated admin deletion lifecycle with disposable accounts:
  pending -> in_review -> fulfilled.
- [x] Confirmed deletion evidence:
  request fulfilled, target user removed, `dataRequestAudit` record created.
- [x] Fixed and re-deployed privilege escalation risks discovered during validation:
  blocked self-assignment of privileged roles and restricted callable admin check to `userType == admin`.
- [x] Updated privacy policy security section to remove unverifiable 2FA/end-to-end encryption claims.
- [x] Added reusable staging validation script:
  `scripts/legal_staging_regression.sh`.
- [x] Final admin-token validation run succeeded end-to-end using a real Firebase ID token:
  local tests passed, rule checks passed, and callable returned `ok: true` with `fulfilled` deletion summary (`authDeleted: true`, retained collections explicitly listed, storage prefixes processed).
- [x] Executed production canary deploy helper against `wordnerd-artbeat`:
  `PROJECT_ID=wordnerd-artbeat ./scripts/legal_canary_deploy.sh` (rules + callable deploy succeeded).
- [x] Re-ran full live legal regression after canary deploy using admin email/password token resolution:
  all tests/rule checks passed and callable deletion lifecycle returned `ok: true`.
- [x] Exact post-deploy evidence run (2026-02-26 UTC):
  `data_request_created=jzyvWYISmQPIRx9DukPQ`,
  `self_promote_admin_http=403`,
  owner uploads `200`,
  cross-user uploads `403`,
  callable response `result.ok=true`,
  deletion summary `authDeleted=true`.
- [x] Recorded session status and blockers in:
  `docs/LEGAL_STAGING_UI_QA_SESSION_REPORT_2026-02-26.md`.
- [x] Implemented shared chat media lifecycle hardening:
  participant-aware message creation enforcement (`chats/{chatId}/messages`),
  uploader/chat/storage metadata on media messages,
  deletion pipeline chat-media cleanup/redaction.
- [x] Deployed updated `storage.rules`, `firestore.rules`, and `processDataDeletionRequest` after hardening.
- [x] Re-ran live legal regression with new chat checks:
  `chat_media_upload_http=200`,
  `chat_message_participant_create_http=200`,
  `chat_message_non_participant_create_http=403`.

## Next Steps (Execution Order)

- [x] Perform manual in-app staging QA for admin queue UI and deletion request handling using `docs/LEGAL_STAGING_MANUAL_QA_CHECKLIST.md` (completed with screenshot evidence).
- [x] Run policy claim review and edit legal text for any unverifiable security claims (2FA/encryption wording).
- [x] Execute collection/path inventory and map data paths to retention/deletion behavior (`docs/LEGAL_DATA_INVENTORY_MATRIX.md`).
- [x] Add CI workflow wiring for legal staging regression (`.github/workflows/legal_staging_regression.yml`).
- [x] Prepare production canary rollout artifacts (`docs/security/LEGAL_PRODUCTION_CANARY_ROLLOUT_RUNBOOK.md`, `scripts/legal_canary_deploy.sh`).
- [x] Add CI helper script for GitHub secret setup + workflow dispatch (`scripts/legal_ci_setup_and_run.sh`).
- [x] Finalize inventory matrix coverage for all collections/paths and shared media lifecycle guidance.
- [x] Configure CI secrets (`STAGING_ADMIN_EMAIL`, `STAGING_ADMIN_PASSWORD`, `STAGING_FIREBASE_API_KEY`, `STAGING_FIREBASE_STORAGE_BUCKET`) and validate manual workflow run in GitHub Actions.
- [ ] Complete production canary sign-off checklist in runbook (depends on manual in-app QA + CI workflow run evidence).
- [ ] Complete production canary sign-off checklist in runbook (engineering signed; waiting product/legal owner + support readiness + manual UI evidence).
- [ ] Run non-technical payment/refund QA checklist:
  `docs/LEGAL_PAYMENT_REFUND_QA_CHECKLIST.md`.

## CI Validation Evidence (February 26, 2026)

- [x] Workflow dispatched successfully:
  `legal_staging_regression.yml` run `22424833231`.
- [x] GitHub Actions result: `success` (job `legal-staging-regression`, ~2m22s).
- [x] Steps passed:
  checkout, Flutter setup, `pub get`, CI `.env` creation, config validation, legal regression script, artifact upload.

## P1 - Policy-to-Behavior Alignment

- [x] Add payment flow inline disclosure for refund exceptions.
- [x] Add location flow inline safety disclosure before first use.
- [ ] Add plain-language legal summaries in key consent surfaces.
- [ ] Add material-change re-consent trigger system (version bump workflow).

## P2 - Minors / School Readiness

- [ ] Define school/student mode legal model (district consent + guardian path).
- [ ] Define under-18 feature restrictions and moderation standards.
- [ ] Add age-gate and age-state handling for student experience.
- [ ] Define COPPA/FERPA review checklist for school deployments.

## P2 - Ops and Compliance

- [ ] Create legal risk register with severity, owner, due dates.
- [ ] Create monthly legal/compliance review routine.
- [ ] Add support response templates for privacy/payment/legal requests.
- [ ] Run tabletop test for incident response plan.

## Tracking Notes

- Canonical legal settings live in `packages/artbeat_core/lib/src/config/legal_config.dart`.
- Legal updates should be edited through centralized config + canonical legal screens, then synced to app-level duplicates if still present.
