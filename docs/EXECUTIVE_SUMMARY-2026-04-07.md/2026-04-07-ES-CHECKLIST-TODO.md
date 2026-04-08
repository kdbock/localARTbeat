# 2026-04-07 ES Checklist TODO

Purpose: turn the audit into an execution checklist phased by risk so release confidence can be raised in a controlled, measurable way.

## Current Progress Snapshot (Updated 2026-04-08)
- Completed in `main`:
  - Payment/refund ownership authorization hardening in Cloud Functions.
  - Firestore rules tightening for user doc updates and notification creation.
  - Sensitive payment request log cleanup (removed raw headers/body logging).
  - Dependency risk reduction: removed `high` audit finding (`nodemailer` updated to `^8.0.5`).
  - Regression/unit tests added and passing.
- Latest verification evidence:
  - `functions`: `npm run lint` pass, `npm test` pass (24 tests), `npm run build` pass.
  - `firestore.rules`: compiled and deployed successfully to Firebase project `wordnerd-artbeat`.
  - `npm audit`: `0 high`, `0 critical` (19 low remain, primarily transitive Genkit/Google chain).
  - Admin role contract/backfill:
    - `npm test` pass (31 tests).
    - `npm run backfill:admin-user-type` dry run result: `scanned: 111`, `updated: 0`.
    - `npm run backfill:admin-user-type -- --apply` result: `scanned: 111`, `updated: 0`.
  - Firestore rules abuse tests:
    - `npm run test:rules` pass (7/7 via Firestore emulator).
    - Confirmed denied cross-user writes for user presence/engagement + notification spoof paths.
  - Storage rules:
    - `storage.rules` deployed successfully to `wordnerd-artbeat`.
    - `functions` checks pass: `npm test` (32/32), `npm run lint`, `npm run build`.
    - MIME validation updated to write-time `request.resource.contentType` on protected upload paths.
    - `npm run test:storage-rules` pass (storage+firestore emulators):
      - deny owner-boundary abuse case verified (`pass`).
      - allow-case MIME matrix tests currently `skipped` due Storage emulator App Check context limitation (`request.app` unavailable).
  - Admin route/client guard hardening:
    - `flutter test test/admin_route_handler_guard_test.dart` pass (2/2).
    - Unauthorized admin navigation now blocked at route-handler gate.

## Phase 0 - Production Blockers (P0)

### P0.1 Payment and Refund Authorization Boundaries
- [x] Enforce bearer auth + verified `auth.uid` on every payment/refund function path.
- [x] Add ownership checks for `customerId`, `subscriptionId`, `paymentIntentId`, `paymentMethodId` before Stripe operations.
- [x] Reject cross-user resource access with explicit 403.
- [x] Remove trust in client-supplied `userId` fields when they disagree with token identity.
- [ ] Add negative tests for cross-user attempts for:
  - [x] `createSubscription`
  - [x] `cancelSubscription`
  - [x] `changeSubscriptionTier`
  - [x] `requestRefund`
  - [x] `getPaymentMethods`
  - [x] `updateCustomer`
  - [x] `detachPaymentMethod`
  - [x] `createSetupIntent`

### P0.2 Role Model Consistency (AuthZ Contract)
- [x] Standardize one canonical admin role field (`userType` or `role`) across:
  - [x] Firestore rules
  - [x] Cloud Functions
  - [x] app-side admin checks/guards
- [x] Add migration script/backfill for existing user docs.
- [x] Add contract test: user marked admin in canonical field passes all admin gates; non-admin fails all.

### P0.3 Firestore Abuse Surface Tightening
- [x] Restrict notification creation under `users/{userId}/notifications` to owner/admin/trusted backend path.
- [x] Restrict presence/engagement stat updates to owner/admin only unless explicitly required.
- [x] Add rules tests proving unauthorized cross-user writes fail.

### P0 Exit Criteria (Must Pass)
- [x] All P0 tests green locally/CI.
- [ ] Manual verification: cross-account payment and notification abuse attempts are rejected.
- [ ] Security sign-off recorded in release notes.

---

## Phase 1 - High Priority Hardening (P1)

### P1.1 Storage Upload Validation Correctness
- [x] Replace write-time MIME checks to use `request.resource.contentType` in Storage rules.
- [ ] Add emulator tests for accepted/rejected MIME across artwork/video/audio/document uploads.
  - Status: deny-path coverage implemented and passing; allow-path MIME assertions blocked by current emulator App Check context.

### P1.2 Admin Route and Client Guard Hardening
- [x] Replace placeholder role logic in app guard helpers.
- [x] Enforce admin route guard at router layer before admin screen dispatch.
- [x] Add routing tests for unauthorized admin navigation.

### P1.3 Payment Policy Consolidation
- [x] Resolve conflicts between payment strategy services.
- [x] Define one source-of-truth policy table for IAP vs Stripe by product type.
- [x] Add unit tests that fail on contradictory mapping.

### P1.4 Data Rights Operational Reliability
- [x] Wire automated/operational trigger for deletion request processing.
- [x] Add monitoring for request SLA states (`pending`, `in_review`, `fulfilled`, `denied`).
- [x] Alert when SLA acknowledgment/completion windows are missed.

### P1 Exit Criteria
- [x] Storage rules tests and admin guard tests pass.
- [x] Payment policy matrix published and referenced by all payment modules.
- [x] Data-rights operational dashboard/alerting in place.

---

## Phase 2 - Stability and Maintainability (P2)

### P2.1 Cleanup and Deployment Clarity
- [x] Archive/remove stale/legacy function entrypoint variants not used by deploy path.
- [x] Document canonical Cloud Functions entrypoint and ownership.

### P2.2 Dependency Risk Reduction
- [ ] Replace broad `any` pins with bounded versions where practical.
- [x] Eliminate high/critical dependency findings in immediate release path.
- [ ] Add dependency drift checks in CI.

### P2.3 Observability and Failure Transparency
- [ ] Replace silent catches in deferred startup with structured logs/telemetry.
- [ ] Keep graceful UX fallbacks but emit actionable diagnostics.

### P2.4 Focused Coverage Expansion
- [ ] Add high-risk integration tests for package seams (payments, moderation, admin actions, data rights).
- [ ] Add regression tests for policy-critical flows before release cut.

### P2 Exit Criteria
- [ ] Deployed code path is unambiguous.
- [ ] Critical modules have deterministic dependency behavior.
- [ ] Silent failure paths are observable.

---

## Phase 3 - Re-Review and Confidence Raise

### Re-Audit Delta
- [ ] Re-run targeted security audit on payment/admin/rules surfaces.
- [ ] Re-run legal/compliance evidence check against implemented controls.
- [ ] Re-score release confidence using post-fix evidence.

### Release Gate
- [ ] No open P0 items.
- [ ] No unresolved high-severity security findings.
- [ ] Release QA checklist updated and signed.

---

## Suggested Execution Order by Team

### Backend/Functions
- [ ] P0.1, P0.2 (functions side), P1.4

### Firebase Rules
- [ ] P0.3, P1.1

### App Shell / Core
- [ ] P1.2, P1.3, P2.3

### Release/QA
- [ ] P0/P1 test harness updates, Phase 3 re-review

---

## Tracking Fields (Optional)
- Owner:
- Branch/PR:
- Verification Evidence:
- Date Completed:
- Residual Risk Notes:
