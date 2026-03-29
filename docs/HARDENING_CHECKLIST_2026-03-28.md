# Hardening Checklist: March 28, 2026

## Goal

Raise investor and release confidence by reducing real config, payment, and deployment risk before any router/bootstrap cleanup work.

This checklist is the next priority after the UI/provider-boundary sweep.

## Status

- UI/provider-boundary pass is complete for:
  - `artbeat_admin`
  - `artbeat_core`
  - `artbeat_artist`
  - `artbeat_artwork`
  - `artbeat_events`
  - `artbeat_profile`
- Hardening sprint: complete
- Env/config inventory: complete
- Stripe defaults and endpoint discovery audit: complete
- Stripe and endpoint hardening pass: complete
- Purchase verification boundary mapping: complete
- Release payment/config gate: complete
- IAP/boost/commission verification hardening pass: complete
- Release-doc/runbook pass: complete
- Final monetization consistency audit: complete

## Workstreams

### 1. Env And Config Ownership
- [x] Inventory all environment-dependent inputs used by client code, services, and Cloud Function callers.
- [x] Identify every place where release-critical config can silently fall back to unsafe or ambiguous defaults.
- [x] Define one source of truth for each required runtime value by environment.
- [x] Separate local/dev/test/staging/release expectations explicitly in docs and code paths.
- [x] Confirm that release builds fail closed when required config is missing.

Target outputs:
- one config inventory
- one documented environment contract
- one short list of unsafe defaults removed or blocked

### 2. Stripe Defaults And Missing-Key Behavior
- [x] Identify all Stripe publishable key and payment endpoint configuration paths in client code.
- [x] Remove or block any hardcoded live-like defaults that can mask misconfiguration.
- [x] Confirm how release mode behaves when Stripe keys are missing or malformed.
- [x] Add explicit release-safe behavior for missing payment config.
- [x] Document expected per-environment Stripe setup and failure mode.

Target outputs:
- no ambiguous Stripe key fallback path
- explicit release failure behavior
- documented Stripe config contract

### 3. Endpoint And Cloud Function Discovery
- [x] Inventory Cloud Function and endpoint resolution logic used by payments and other critical flows.
- [x] Verify which endpoints are hardcoded, inferred, or environment-derived.
- [x] Remove unclear discovery paths where the runtime target cannot be proven from config.
- [x] Document the mapping between app environment and backend endpoint/function base.
- [x] Add checks or assertions where endpoint resolution is currently implicit.

Target outputs:
- endpoint inventory
- explicit environment-to-endpoint mapping
- reduced hidden routing behavior

### 4. Purchase Verification Boundaries
- [x] Trace all paid entitlement and monetization flows end to end.
- [x] Identify any places where client success is treated as final success without server-side verification.
- [x] Define the boundary where verification must happen before entitlement, activation, or payout-side state changes.
- [x] Check ads, sponsorships, subscriptions, boosts, artwork purchases, and ticket-related payments.
- [x] Document which flows are already safe and which still need boundary hardening.

Target outputs:
- monetization flow map
- verified list of safe vs unsafe purchase paths
- concrete hardening task list for weak verification boundaries

### 5. Release-Gate Checks
- [x] Define the minimum config and verification conditions required for a release build.
- [x] Add checks that fail release preparation when risky config states are present.
- [x] Decide which checks belong in code, scripts, CI, or release docs.
- [x] Ensure the release gate covers env/config, Stripe, endpoint mapping, and purchase verification prerequisites.
- [x] Update release documentation so the gate is operational, not aspirational.

Target outputs:
- explicit release gate
- automatable checks where practical
- updated release/runbook documentation

## Suggested Execution Order

1. Env and config inventory
2. Stripe default and missing-key review
3. Endpoint / Cloud Function discovery audit
4. Purchase verification boundary mapping
5. Release-gate implementation and documentation

## Current Evidence

- Initial hardening inventory documented in:
  - [HARDENING_ENV_CONFIG_INVENTORY_2026-03-28.md](/Volumes/ExternalDrive/DevProjects/artbeat/docs/HARDENING_ENV_CONFIG_INVENTORY_2026-03-28.md)
- Purchase verification boundary mapping documented in:
  - [HARDENING_PURCHASE_VERIFICATION_BOUNDARIES_2026-03-28.md](/Volumes/ExternalDrive/DevProjects/artbeat/docs/HARDENING_PURCHASE_VERIFICATION_BOUNDARIES_2026-03-28.md)
- Confirmed early risks from code inspection:
  - `EnvLoader` previously applied silent defaults for `API_BASE_URL`, `FIREBASE_REGION`, and `FIREBASE_PROJECT_ID`
  - `ConfigService.initialize()` previously allowed startup to continue after config init failure
  - payment and verification traffic now rely on explicit `FIREBASE_FUNCTIONS_BASE_URL`
  - subscription and sponsorship Stripe IDs now resolve from env contract keys instead of split hardcoded sources
  - IAP subscriptions now activate through a backend endpoint after receipt verification
  - Android now has a backend Google Play verification endpoint instead of a missing verification target
  - boost effect application now relies on the server-side `applyBoostMomentum` trigger instead of client-side effect writes
  - commission payout-adjacent status changes no longer flip to completed on the client before backend success
  - the first operational release gate now exists in [check_release_payment_config.sh](/Volumes/ExternalDrive/DevProjects/artbeat/tools/architecture/check_release_payment_config.sh)
  - the release gate now also verifies backend monetization prerequisites in [check_release_monetization_prereqs.sh](/Volumes/ExternalDrive/DevProjects/artbeat/tools/architecture/check_release_monetization_prereqs.sh)
  - release-facing docs now explicitly require both gates in [RELEASE_CHECKLIST.md](/Volumes/ExternalDrive/DevProjects/artbeat/docs/RELEASE_CHECKLIST.md), [PRE_SUBMISSION_REMAINING_WORK.md](/Volumes/ExternalDrive/DevProjects/artbeat/docs/PRE_SUBMISSION_REMAINING_WORK.md), and [README.md](/Volumes/ExternalDrive/DevProjects/artbeat/README.md)
  - both release gates are now CI-enforced in [comprehensive_tests.yml](/Volumes/ExternalDrive/DevProjects/artbeat/.github/workflows/comprehensive_tests.yml) through the `Release Hardening Gates` job
  - final monetization audit confirms the main active paid paths are backend-owned for final activation or payout release:
    - IAP activation and cancellation go through backend endpoints
    - boost effect finalization is backend-triggered after verified completion
    - sponsorships, artwork sales, and ticketing treat backend processing as authority
    - commission completion and payout release are backend-owned
  - the last paid-subscription blocker in [subscription_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_core/lib/src/services/subscription_service.dart) was hardened by disabling the legacy client-owned paid Stripe activation path
  - the only remaining local tier write in that service is the documented non-payment exception for full-discount coupon activation, which does not represent a paid monetization finalization path

## Done Definition

This sprint is done when:
- release-critical config ownership is explicit
- unsafe fallback behavior is removed or blocked
- payment and endpoint behavior is understandable by inspection
- purchase verification boundaries are documented and defensible
- release gates exist for the highest-risk failure modes
- no remaining client-owned final monetization state transitions exist outside documented exceptions

Current assessment:
- this done definition is now met for the March 28 hardening scope

## Not In Scope Yet

- router splitting
- bootstrap decomposition
- broader architectural refactors not directly tied to release/config/payment risk
- another package sweep unless a hardening task depends on it
