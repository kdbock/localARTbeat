# 2026-04-07 Executive Summary (Release Audit)

## Scope
Final pre-release audit of the ARTbeat production repository with emphasis on:
- correctness across all first-party packages
- backend authorization and data integrity
- legal/compliance implementation evidence
- maintainability and release-readiness

## Bottom Line
This audit identified multiple high-severity, fixable issues concentrated in payment authorization boundaries, role-model consistency, and cross-user write controls.

This is not a statement that the app is "bad" or "unshippable forever". It means the current build should be treated as a hardening release candidate: stabilize the P0/P1 controls first, then re-score confidence after verification.

## Confidence Framing
Current confidence is constrained by a small number of high-impact issues, not by broad codebase collapse.

Main confidence reducers:
1. backend payment/refund auth and ownership checks not consistently enforced
2. role field inconsistency (`userType` vs `role`) across rules and functions
3. broad Firestore write paths that allow abuse/tampering scenarios

Main confidence builders:
1. modular package architecture with clear domain boundaries
2. substantial service/test scaffolding across packages
3. legal-consent recording and data-request UX paths exist
4. static analysis baseline passed (`flutter analyze`)

## Priority Risk Summary

### P0 (Immediate Blockers)
1. Cloud Functions payment/refund ownership enforcement
2. Stripe customer/payment-method ownership validation
3. Firestore notification/presence/engagement write tightening
4. Role-model unification across app, rules, and functions

### P1 (Near-Term Hardening)
1. Storage MIME rule correctness (`request.resource.contentType`)
2. App-side admin route guard hardening
3. Payment strategy source-of-truth consolidation
4. Data-rights SLA operational automation/monitoring

### P2 (Stability and Maintainability)
1. Remove legacy/dead function entrypoint ambiguity
2. Reduce `any` dependency ranges
3. Replace silent failure handling with telemetry-backed degraded modes
4. Expand package-level regression coverage where risk is concentrated

## Detailed Findings Register (Full List)

### 1) Security/Privacy

#### S-01
- Severity: Critical
- What is wrong: payment/refund Cloud Functions do not consistently enforce auth + ownership checks
- Why it matters: enables potential cross-user subscription/refund manipulation
- Where it is:
  - `functions/src/index.js:3571`
  - `functions/src/index.js:3620`
  - `functions/src/index.js:3663`
  - `functions/src/index.js:4975`
  - reference secure pattern: `functions/src/index.js:2695`
- Exact fix recommendation:
  1. Verify bearer token on every endpoint.
  2. Resolve canonical user ID from token only.
  3. Enforce ownership mapping for subscription/customer/payment intent before Stripe mutations.
  4. Return `403` on ownership mismatch.
- Blocks production confidence: Yes

#### S-02
- Severity: Critical
- What is wrong: customer/payment-method endpoints authenticate caller but do not prove `customerId` ownership
- Why it matters: unauthorized card/payment method operations and data exposure
- Where it is:
  - `functions/src/index.js:3393`
  - `functions/src/index.js:3452`
  - `functions/src/index.js:3515`
- Exact fix recommendation:
  1. Read `users/{uid}.stripeCustomerId`.
  2. Reject requests where supplied `customerId` != stored customer.
  3. For detach/update, confirm payment method belongs to that customer.
- Blocks production confidence: Yes

#### S-03
- Severity: High
- What is wrong: Firestore allows broad notification creation to user subcollections
- Why it matters: spam/abuse path and trust erosion
- Where it is: `firestore.rules:168`
- Exact fix recommendation:
  1. Restrict create to owner/admin or backend-controlled write path.
  2. Add rules tests that cross-user writes fail.
- Blocks production confidence: Yes

#### S-04
- Severity: High
- What is wrong: broad cross-user presence/engagement updates allowed
- Why it matters: user-state tampering and analytics integrity issues
- Where it is:
  - `firestore.rules:67`
  - `firestore.rules:69`
- Exact fix recommendation:
  1. Enforce owner/admin-only updates.
  2. If non-owner writes are required, isolate into narrowly scoped backend function.
- Blocks production confidence: Yes

#### S-05
- Severity: High
- What is wrong: app-side auth role helpers are placeholders (`emailVerified` / always true)
- Why it matters: unsafe client authorization assumptions and UI exposure
- Where it is:
  - `lib/src/guards/auth_guard.dart:45`
  - `lib/src/guards/auth_guard.dart:55`
- Exact fix recommendation:
  1. Replace with claims/document-backed role resolver.
  2. Remove placeholder logic and add guard unit tests.
- Blocks production confidence: Yes

#### S-06
- Severity: Medium
- What is wrong: storage write MIME checks likely use wrong context (`resource.contentType`)
- Why it matters: upload validation may not enforce intended constraints
- Where it is:
  - `storage.rules:129`
  - `storage.rules:156`
  - `storage.rules:183`
- Exact fix recommendation:
  1. Use `request.resource.contentType` for incoming writes.
  2. Add storage emulator tests for allowed/denied MIME cases.
- Blocks production confidence: No (high priority hardening)

### 2) Legal/Compliance

#### L-01
- Severity: High
- What is wrong: role schema mismatch (`userType` in rules vs `role` in functions)
- Why it matters: admin authorization inconsistency and compliance control failure risk
- Where it is:
  - `firestore.rules:26`
  - `functions/src/index.js:5925`
- Exact fix recommendation:
  1. Standardize one canonical role field.
  2. Migrate existing docs.
  3. Update all checks and add contract tests.
- Blocks production confidence: Yes

#### L-02
- Severity: High
- What is wrong: privacy policy/SLA claims depend on manual-admin deletion execution path
- Why it matters: potential SLA breaches for data-rights handling
- Where it is:
  - `lib/src/screens/privacy_policy_screen.dart`
  - `packages/artbeat_settings/lib/src/services/integrated_settings_service.dart:646`
  - `functions/src/index.js:6312`
- Exact fix recommendation:
  1. Add operational automation/alerts for request lifecycle.
  2. Track acknowledgment and completion SLA with dashboard alerts.
- Blocks production confidence: Yes

#### L-03
- Severity: Medium
- What is wrong: under-18 restrictions are present in policy text but technical enforcement is not clearly evidenced
- Why it matters: child-safety/store-policy risk if controls are expected
- Where it is:
  - `lib/src/screens/terms_of_service_screen.dart`
  - `lib/src/screens/privacy_policy_screen.dart`
- Exact fix recommendation:
  1. Add age-gate and enforce feature gating for minors where policy says restrictions apply.
- Blocks production confidence: No (jurisdiction/policy dependent)

### 3) App Logic/Functionality

#### A-01
- Severity: High
- What is wrong: admin routes dispatch without explicit admin gate at router layer
- Why it matters: unauthorized users may reach admin UI paths
- Where it is: `lib/src/routing/handlers/admin_route_handler.dart:10`
- Exact fix recommendation:
  1. Add centralized admin route guard before handler dispatch.
  2. Route unauthorized users to safe fallback.
- Blocks production confidence: Yes

#### A-02
- Severity: Medium
- What is wrong: deferred startup swallows failures silently
- Why it matters: degraded behavior becomes hard to diagnose
- Where it is:
  - `lib/src/bootstrap/deferred_startup.dart:52`
  - `lib/src/bootstrap/deferred_startup.dart:65`
  - `lib/src/bootstrap/deferred_startup.dart:74`
- Exact fix recommendation:
  1. Replace silent catches with structured logging + telemetry.
  2. Surface degraded state where user-impacting.
- Blocks production confidence: No

#### A-03
- Severity: Medium
- What is wrong: permission service requests broad permissions at startup; essential status hardcoded true
- Why it matters: user trust friction and unclear permission health state
- Where it is:
  - `lib/src/services/app_permission_service.dart:19`
  - `lib/src/services/app_permission_service.dart:116`
- Exact fix recommendation:
  1. Request permissions just-in-time by feature.
  2. Compute `hasEssentialPermissions` from real statuses.
- Blocks production confidence: No

### 4) Package Integration

#### P-01
- Severity: Medium
- What is wrong: conflicting payment strategy logic across services
- Why it matters: inconsistent billing behavior and policy drift risk
- Where it is:
  - `packages/artbeat_core/lib/src/services/payment_strategy_service.dart:75`
  - `packages/artbeat_core/lib/src/services/unified_payment_service.dart:435`
- Exact fix recommendation:
  1. Define one policy source of truth.
  2. Make all payment routing read from that source.
  3. Add policy-consistency tests.
- Blocks production confidence: No (important)

#### P-02
- Severity: Low
- What is wrong: legacy/backup function variants add ambiguity
- Why it matters: wrong-file edits and operational mistakes
- Where it is:
  - `functions/index.js`
  - `functions/stripe.js`
  - `functions/src/index_v2.js`
  - backup files
- Exact fix recommendation:
  1. Archive or remove non-deployed variants.
  2. Document canonical deploy entrypoint.
- Blocks production confidence: No

### 5) UI/UX and Accessibility

#### U-01
- Severity: Medium
- What is wrong: sponsor banner suppresses errors silently
- Why it matters: missing sponsor content without operator signal
- Where it is: `packages/artbeat_sponsorships/lib/src/widgets/sponsor_banner.dart:87`
- Exact fix recommendation:
  1. Keep graceful fallback UI.
  2. Emit telemetry event on exception path.
- Blocks production confidence: No

#### U-02
- Severity: Medium
- What is wrong: broad startup permission prompts degrade experience
- Why it matters: lower acceptance rates and trust
- Where it is: `lib/src/services/app_permission_service.dart:19`
- Exact fix recommendation:
  1. move prompts to contextual flows with rationale copy
- Blocks production confidence: No

### 6) Performance

#### PF-01
- Severity: Medium
- What is wrong: verbose logging of headers/body in payment paths
- Why it matters: noisy logs and possible sensitive metadata exposure
- Where it is:
  - `functions/src/index.js:2691`
  - `functions/src/index.js:3398`
  - `functions/src/index.js:3457`
  - `functions/src/index.js:3520`
- Exact fix recommendation:
  1. remove raw payload/header logs in production
  2. add redaction and sampling
- Blocks production confidence: No

### 7) Testing

#### T-01
- Severity: Critical
- What is wrong: no first-party backend auth/ownership test suite evident for payment endpoints
- Why it matters: regression risk on financial security boundaries
- Where it is: `functions/` test coverage gap
- Exact fix recommendation:
  1. add emulator/integration tests for positive + cross-user negative cases on all payment endpoints
- Blocks production confidence: Yes

#### T-02
- Severity: High
- What is wrong: missing explicit Firestore rules tests for broad write surfaces
- Why it matters: unauthorized write regressions can recur undetected
- Where it is: `firestore.rules`
- Exact fix recommendation:
  1. add rules tests for notifications, presence, engagement, admin-only collections
- Blocks production confidence: Yes

#### T-03
- Severity: High
- What is wrong: missing storage rule tests for MIME/path enforcement
- Why it matters: upload safety constraints may drift
- Where it is: `storage.rules`
- Exact fix recommendation:
  1. add storage emulator tests per media type/path
- Blocks production confidence: Yes

#### T-04
- Severity: Medium
- What is wrong: missing end-to-end data-rights lifecycle tests
- Why it matters: legal process reliability is not continuously validated
- Where it is: settings request path + deletion pipeline
- Exact fix recommendation:
  1. add E2E tests from request creation to fulfilled/denied and SLA timestamps
- Blocks production confidence: No

### 8) Release/DevOps/Configuration

#### R-01
- Severity: Medium
- What is wrong: broad `any` dependency constraints in multiple packages
- Why it matters: non-deterministic dependency behavior and drift
- Where it is: multiple package `pubspec.yaml` files
- Exact fix recommendation:
  1. replace `any` with bounded versions
  2. enforce dependency policy checks in CI
- Blocks production confidence: No

#### R-02
- Severity: Medium
- What is wrong: active deploy surface includes overlapping legacy patterns
- Why it matters: operational confusion during hotfixes
- Where it is: `functions/` structure and historical variants
- Exact fix recommendation:
  1. simplify deployment source map and codify in docs + CI checks
- Blocks production confidence: No

## Package Inventory (Reference)
- `artbeat_core`
- `artbeat_auth`
- `artbeat_profile`
- `artbeat_artist`
- `artbeat_artwork`
- `artbeat_capture`
- `artbeat_community`
- `artbeat_art_walk`
- `artbeat_events`
- `artbeat_messaging`
- `artbeat_ads`
- `artbeat_settings`
- `artbeat_sponsorships`
- `artbeat_admin`

Dependency graph reference:
- `docs/PACKAGE_DEPENDENCY_INVENTORY.md`

## Execution Artifact
Implementation sequencing and checkboxes are tracked in:
- `docs/EXECUTIVE_SUMMARY-2026-04-07.md/2026-04-07-ES-CHECKLIST-TODO.md`

## What Must Be True Before Final Release Approval
1. All P0 fixes are merged and validated with tests.
2. Payment endpoints reject cross-user resource manipulation.
3. Admin authorization uses one canonical role model everywhere.
4. Firestore abuse paths are covered by rules tests.
5. Re-audit delta confirms no new high-severity regressions.
