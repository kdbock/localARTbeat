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

#### P0 Manual Abuse Verification Runbook (Staging)
- Run date: `2026-04-08`
- Environment: `staging` (`wordnerd-artbeat`)
- Test identities:
  - `attackerUserId`: `TODO_FILL`
  - `victimUserId`: `TODO_FILL`
  - `attackerAuthToken`: `TODO_FILL`
  - `victimStripeCustomerId`: `TODO_FILL`
  - `victimSubscriptionId`: `TODO_FILL`
  - `victimPaymentMethodId`: `TODO_FILL`
  - `victimPaymentIntentId`: `TODO_FILL`

Expected result for each step: HTTP `403` or rules `PERMISSION_DENIED` with no victim-side state mutation.

1. Cross-user payment methods read abuse (`getPaymentMethods`)
```bash
curl -i -X POST \
  "https://us-central1-wordnerd-artbeat.cloudfunctions.net/getPaymentMethods" \
  -H "Authorization: Bearer TODO_ATTACKER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"customerId":"TODO_VICTIM_CUSTOMER_ID"}'
```

2. Cross-user subscription cancel abuse (`cancelSubscription`)
```bash
curl -i -X POST \
  "https://us-central1-wordnerd-artbeat.cloudfunctions.net/cancelSubscription" \
  -H "Authorization: Bearer TODO_ATTACKER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"subscriptionId":"TODO_VICTIM_SUBSCRIPTION_ID"}'
```

3. Cross-user refund abuse (`requestRefund`)
```bash
curl -i -X POST \
  "https://us-central1-wordnerd-artbeat.cloudfunctions.net/requestRefund" \
  -H "Authorization: Bearer TODO_ATTACKER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"paymentIntentId":"TODO_VICTIM_PAYMENT_INTENT_ID","reason":"fraudulent"}'
```

4. Cross-user payment method detach abuse (`detachPaymentMethod`)
```bash
curl -i -X POST \
  "https://us-central1-wordnerd-artbeat.cloudfunctions.net/detachPaymentMethod" \
  -H "Authorization: Bearer TODO_ATTACKER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"paymentMethodId":"TODO_VICTIM_PAYMENT_METHOD_ID"}'
```

Automation helper (recommended):
```bash
tools/security/run_p0_cross_account_abuse_checks.sh tools/security/p0-abuse-checks.env
```
Template env file:
- `tools/security/p0-abuse-checks.env.example`
Required env vars:
- `ATTACKER_TOKEN`
- `VICTIM_CUSTOMER_ID`
- `VICTIM_SUBSCRIPTION_ID`
- `VICTIM_PAYMENT_INTENT_ID`
- `VICTIM_PAYMENT_METHOD_ID`

5. Cross-user Firestore notification spoof abuse (emulator/rules harness)
```bash
cd functions && npm run test:rules
```

Current execution notes (2026-04-08):
- Attempted at `2026-04-08T20:19:15Z`.
- Initial blocker: shell runtime missing `node` on PATH.
- Re-run at `2026-04-08T20:21:00Z` with Node 20 path + emulator permissions succeeded:
  - Command: `cd functions && PATH=/opt/homebrew/opt/node@20/bin:$PATH npm run test:rules`
  - Result: `7/7 pass`, exit code `0`.
  - Abuse-path assertions observed `PERMISSION_DENIED` on denied cases (expected), including notification spoof paths.
- Re-run at `2026-04-08T20:29:28Z` under elevated terminal permissions (sandbox port/config limits) also succeeded:
  - Command: `cd functions && PATH=/opt/homebrew/opt/node@20/bin:$PATH npm run test:rules`
  - Result: `7/7 pass`, exit code `0`.
  - Confirms rules abuse harness remains green after latest hardening updates.
- Cross-account Cloud Functions abuse checks automation run attempted:
  - Command: `tools/security/run_p0_cross_account_abuse_checks.sh`
  - Result: blocked pending required credentials/env vars (listed above).
  - Note: script now exits non-zero when any endpoint does not return expected `403` (to support CI/manual gate use).

Evidence capture fields (fill per step):
- Step:
- Timestamp (UTC):
- Command:
- Response code / error:
- Victim state checked:
- Result: `PASS` / `FAIL`

#### Release Sign-Off Capture (Required)
- Security Owner: `TODO_FILL` | Date: `TODO_FILL` | Decision: `TODO_FILL`
- Product Owner: `TODO_FILL` | Date: `TODO_FILL` | Decision: `TODO_FILL`
- Legal/Compliance Owner: `TODO_FILL` | Date: `TODO_FILL` | Decision: `TODO_FILL`
- Residual Risk Accepted (if any): `TODO_FILL`
- Release Notes Link: `TODO_FILL`

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
- [x] Replace broad `any` pins with bounded versions where practical.
  - Evidence (2026-04-08):
    - Replaced first-party `any` constraints with bounded ranges across root and package `pubspec.yaml` files (left `third_party/pub_overrides/**` as vendor-managed).
    - Resolution verification passed:
      - `flutter pub get` success in root plus packages:
        - `artbeat_core`, `artbeat_auth`, `artbeat_art_walk`, `artbeat_profile`, `artbeat_community`, `artbeat_events`, `artbeat_artist`, `artbeat_capture`, `artbeat_messaging`, `artbeat_sponsorships`.
- [x] Eliminate high/critical dependency findings in immediate release path.
- [x] Add dependency drift checks in CI.
  - Evidence (2026-04-08):
    - Added `architecture_drift` job in `.github/workflows/tests.yml` running:
      - `python3 tools/architecture/check_sibling_dependency_drift.py`
      - `python3 tools/architecture/generate_package_dependency_inventory.py --check`
    - Local verification:
      - `Sibling dependency drift check passed.`
      - `Package dependency inventory is up to date.`

### P2.3 Observability and Failure Transparency
- [x] Replace silent catches in deferred startup with structured logs/telemetry.
  - Status: deferred startup silent catches replaced with structured `AppLogger.warning/error` diagnostics in `lib/src/bootstrap/deferred_startup.dart` (2026-04-08).
- [x] Keep graceful UX fallbacks but emit actionable diagnostics.
  - Status: sponsorship fallback paths now emit structured warnings while preserving UX fallback behavior:
    - `packages/artbeat_sponsorships/lib/src/widgets/sponsor_banner.dart`
    - `packages/artbeat_sponsorships/lib/src/widgets/sponsor_art_selection_widget.dart`
  - Status: events feed pagination fallback now emits structured warning diagnostics (no UX regression):
    - `packages/artbeat_events/lib/src/widgets/social_feed_widget.dart`
  - Status: splash startup fallbacks now emit structured warning diagnostics (no navigation behavior change):
    - `packages/artbeat_core/lib/src/screens/splash_screen.dart`
  - Status: user-service upload diagnostic fallback now emits structured warning diagnostics:
    - `packages/artbeat_core/lib/src/services/user_service.dart`
  - Status: App Check configuration/probe silent catches replaced with structured diagnostics:
    - `packages/artbeat_core/lib/src/firebase/secure_firebase_config.dart`
  - Status: messaging notification compatibility fallbacks now emit structured debug diagnostics:
    - `packages/artbeat_messaging/lib/src/services/notification_service.dart`

### P2.4 Focused Coverage Expansion
- [x] Add high-risk integration tests for package seams (payments, moderation, admin actions, data rights).
  - Evidence (2026-04-08):
    - Added `artbeat_ads` seam test for purchase-verification failure recovery flow:
      - `packages/artbeat_ads/test/src/services/local_ad_service_test.dart`
      - Verifies `createPurchasedAd` writes `localAdPurchaseRecoveries` fallback record with expected metadata/status.
    - Added `artbeat_ads` moderation/admin seam tests:
      - `packages/artbeat_ads/test/src/services/local_ad_service_test.dart`
      - Verifies `getAdsForReview` includes only pending/flagged ads.
      - Verifies `updateAdStatus` persists admin moderation metadata (`reviewedBy`, `reviewedAt`, `rejectionReason`).
    - Added `artbeat_sponsorships` seam test for active placement + radius targeting:
      - `packages/artbeat_sponsorships/test/sponsor_service_test.dart`
      - Verifies invalid placement rejection and in-radius/out-of-radius behavior for `getSponsorForPlacement`.
- [x] Add regression tests for policy-critical flows before release cut.
  - Evidence (2026-04-08):
    - Expanded `packages/artbeat_core/test/src/services/payment_policy_consistency_test.dart` with policy-boundary regression coverage:
      - payout modules (`artist`, `events`) remain Stripe-routed for all purchase types.
      - app-store-governed modules (`core`, `ads`, `messaging`, `capture`, `artWalk`, `profile`, `settings`) remain IAP-routed for all purchase types.
      - includes `requiresPayout` assertions to detect routing drift in payout handling.
    - Verification:
      - `flutter test packages/artbeat_core/test/src/services/payment_policy_consistency_test.dart` (`pass`).

### P2 Exit Criteria
- [x] Deployed code path is unambiguous.
- [x] Critical modules have deterministic dependency behavior.
- [x] Silent failure paths are observable.

---

## Phase 3 - Re-Review and Confidence Raise

### Re-Audit Delta
- [x] Re-run targeted security audit on payment/admin/rules surfaces.
  - Evidence (2026-04-08):
    - `flutter test test/admin_route_handler_guard_test.dart` -> pass (2/2).
    - `flutter test packages/artbeat_core/test/src/services/payment_policy_consistency_test.dart` -> pass.
    - `flutter test packages/artbeat_sponsorships/test/sponsor_service_test.dart` -> pass.
    - `flutter test packages/artbeat_ads/test/src/services/local_ad_service_test.dart` -> pass.
    - `python3 tools/architecture/check_sibling_dependency_drift.py` -> pass.
    - `python3 tools/architecture/generate_package_dependency_inventory.py --check` -> pass.
    - `cd functions && PATH=/opt/homebrew/opt/node@20/bin:$PATH npm run test:rules` -> pass (7/7).
- [x] Re-run legal/compliance evidence check against implemented controls.
  - Engineering reconciliation complete against checklist evidence for payment authz, rules tightening, consent/data-rights workflow wiring, and audit log minimization.
  - Remaining required human governance artifacts are tracked in "Release Sign-Off Capture (Required)".
- [x] Re-score release confidence using post-fix evidence.
  - Updated engineering confidence: `7.5/10` (as of 2026-04-08), blocked from `8/10+` by pending manual cross-account Cloud Functions abuse verification credentials and formal owner sign-offs.

### Release Gate
- [ ] No open P0 items.
- [ ] No unresolved high-severity security findings.
- [ ] Release QA checklist updated and signed.

---

## Suggested Execution Order by Team

### Backend/Functions
- [x] P0.1, P0.2 (functions side), P1.4

### Firebase Rules
- [x] P0.3, P1.1

### App Shell / Core
- [x] P1.2, P1.3, P2.3

### Release/QA
- [ ] P0/P1 test harness updates, Phase 3 re-review

---

## Tracking Fields (Optional)
- Owner:
- Branch/PR:
- Verification Evidence:
- Date Completed:
- Residual Risk Notes:
