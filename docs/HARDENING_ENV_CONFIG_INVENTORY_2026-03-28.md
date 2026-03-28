# Env And Config Inventory: March 28, 2026

## Purpose

Document the current environment-dependent runtime inputs, where they are consumed, and the first concrete hardening risks found in code.

This is the first output of the hardening sprint and should drive the next Stripe/defaults and endpoint work.

## Current Sources Of Truth

### Runtime env loader
- Primary loader: [env_loader.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_core/lib/src/utils/env_loader.dart)
- Secondary config wrapper: [config_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_core/lib/src/services/config_service.dart)
- Build-time config wrapper: [app_config.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/config/app_config.dart)

### Startup use
- App startup reads env through [main.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/main.dart)
- Stripe startup behavior is now expected to use the explicit `STRIPE_PUBLISHABLE_KEY` contract and reject placeholder keys

## Explicit Environment Contract

The current hardening direction is to treat the following values as the explicit
release-critical config contract:

- `STRIPE_PUBLISHABLE_KEY`
- `FIREBASE_FUNCTIONS_BASE_URL`
- `FIREBASE_REGION`
- `FIREBASE_PROJECT_ID`
- `API_BASE_URL`

Contract rules:
- release builds must provide all five explicitly
- non-release builds may still run with warnings while hardening is in progress, but should not silently rely on fake production-like defaults
- backend payment and verification traffic must not depend on guessed production targets

Environment expectations:
- local development:
  - may use local `.env`
  - must use Stripe test keys only
  - may run with warnings in non-release mode while still avoiding fake production-like defaults
- CI/staging:
  - should inject the full five-key contract explicitly
  - should point `FIREBASE_FUNCTIONS_BASE_URL` and `API_BASE_URL` at the intended non-production backend
  - must not rely on guessed backend targets or placeholder Stripe IDs
- production release:
  - must inject the full five-key contract explicitly
  - must use a live `STRIPE_PUBLISHABLE_KEY`
  - must pass both release gates before build or upload
  - must not treat local `.env` as the release source of truth

## Environment-Dependent Inputs Found

### From `EnvLoader`
- `API_BASE_URL`
- `STRIPE_PUBLISHABLE_KEY`
- `FIREBASE_REGION`
- `FIREBASE_FUNCTIONS_BASE_URL`
- `GOOGLE_MAPS_API_KEY`
- `FIREBASE_API_KEY`
- `FIREBASE_APP_ID`
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_STORAGE_BUCKET`
- `APPLE_TEAM_ID`
- `FIREBASE_APP_CHECK_DEBUG_TOKEN` via `ConfigService`

### From `AppConfig`
- `GOOGLE_MAPS_API_KEY`
- `STRIPE_PUBLISHABLE_KEY`
- `FIREBASE_REGION`
- `API_BASE_URL`
- `ENVIRONMENT`

### Sponsorship-specific Stripe config
From [sponsorship_checkout_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_sponsorships/lib/src/services/sponsorship_checkout_service.dart):
- `STRIPE_PRODUCT_SPONSORSHIP_ART_WALK`
- `STRIPE_PRODUCT_SPONSORSHIP_CAPTURE`
- `STRIPE_PRODUCT_SPONSORSHIP_DISCOVERY`
- `STRIPE_PRICE_SPONSORSHIP_ART_WALK_MONTHLY`
- `STRIPE_PRICE_SPONSORSHIP_CAPTURE_MONTHLY`
- `STRIPE_PRICE_SPONSORSHIP_DISCOVERY_MONTHLY`

### Core subscription Stripe config
From [unified_payment_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_core/lib/src/services/unified_payment_service.dart):
- `STRIPE_PRICE_SUBSCRIPTION_STARTER_MONTHLY`
- `STRIPE_PRICE_SUBSCRIPTION_CREATOR_MONTHLY`
- `STRIPE_PRICE_SUBSCRIPTION_BUSINESS_MONTHLY`
- `STRIPE_PRICE_SUBSCRIPTION_ENTERPRISE_MONTHLY`

## Consumers Identified

### Stripe startup and safety
- [main.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/main.dart)
- [unified_payment_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_core/lib/src/services/unified_payment_service.dart)

### Endpoint and Cloud Function targeting
- [env_loader.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_core/lib/src/utils/env_loader.dart)
- [unified_payment_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_core/lib/src/services/unified_payment_service.dart)
- [purchase_verification_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_core/lib/src/services/purchase_verification_service.dart)

Environment-to-endpoint mapping:
- `FIREBASE_FUNCTIONS_BASE_URL` is the sole authority for payment and verification Cloud Function traffic
- `API_BASE_URL` is the explicit base for non-Functions API traffic
- `FIREBASE_REGION` and `FIREBASE_PROJECT_ID` identify the intended environment and support runtime/build consistency, but they should not be used to guess payment or verification endpoints
- no release-critical payment flow should infer production routing from fallback region/project defaults

### Validation helpers
- [env_validator.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_core/lib/src/utils/env_validator.dart)
- [app_config.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/config/app_config.dart)

## Confirmed Risks

### 1. Silent defaults still exist for release-critical values
In [env_loader.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_core/lib/src/utils/env_loader.dart):
- `API_BASE_URL` defaults to `https://api.artbeat.app`
- `FIREBASE_REGION` defaults to `us-central1`
- `FIREBASE_PROJECT_ID` defaults to `wordnerd-artbeat`

Why this matters:
- release/runtime behavior can look configured even when environment injection is incomplete
- backend targeting can be inferred instead of explicitly chosen

### 2. Config initialization can fail open
In [config_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_core/lib/src/services/config_service.dart):
- config init errors are logged
- app initialization continues
- service marks itself initialized even after load failure

Why this matters:
- failure to load release-critical config can degrade into ambiguous runtime behavior rather than a controlled stop

### 3. Cloud Function base URL was previously inferred
In [env_loader.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_core/lib/src/utils/env_loader.dart):
- `cloudFunctionsBaseUrl` is now expected to come from explicit `FIREBASE_FUNCTIONS_BASE_URL`

Why this matters:
- payment and verification traffic should not target a guessed backend when the environment contract is incomplete

### 4. Stripe startup currently warns and continues
In [main.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/main.dart):
- missing `STRIPE_PUBLISHABLE_KEY` only logs a warning during deferred init
- no release-safe stop or degraded-mode policy is enforced there

Why this matters:
- release credibility is weakened if payment config can be absent without a deterministic failure mode

### 5. Split Stripe price sources existed across subscriptions and sponsorships
In [unified_payment_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_core/lib/src/services/unified_payment_service.dart) and [subscription_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_core/lib/src/services/subscription_service.dart):
- core subscription pricing previously used hardcoded Stripe price IDs
- sponsorship pricing already preferred env-driven IDs

Why this matters:
- monetization configuration is split between environment-driven and code-hardcoded sources
- this weakens the “single source of truth” story for release and environment management

### 6. Sponsorships previously used fallback behavior in non-release
In [sponsorship_checkout_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_sponsorships/lib/src/services/sponsorship_checkout_service.dart):
- env-driven Stripe IDs are preferred
- non-release builds previously could still use internal fallback plans

Why this matters:
- even non-release fallback plan IDs create another configuration path that weakens auditability

## Purchase Verification Boundary Notes

### Positive finding
In [purchase_verification_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_core/lib/src/services/purchase_verification_service.dart):
- store purchase verification is explicitly routed through Cloud Functions
- client-side secret handling is not present in this service

### Remaining concern
- the verification service still relies on `EnvLoader().cloudFunctionsBaseUrl`
- verification safety therefore still depends on `FIREBASE_FUNCTIONS_BASE_URL` being explicitly injected and release-gated

## Immediate Next Hardening Tasks

1. Define a single environment contract for:
   - `STRIPE_PUBLISHABLE_KEY`
   - `FIREBASE_FUNCTIONS_BASE_URL`
   - `FIREBASE_REGION`
   - `FIREBASE_PROJECT_ID`
   - `API_BASE_URL`
2. Enforce explicit `FIREBASE_FUNCTIONS_BASE_URL` for payment and verification traffic.
3. Remove hardcoded subscription Stripe IDs in [unified_payment_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_core/lib/src/services/unified_payment_service.dart) and [subscription_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_core/lib/src/services/subscription_service.dart).
4. Remove non-release sponsorship fallback plan IDs in [sponsorship_checkout_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_sponsorships/lib/src/services/sponsorship_checkout_service.dart).
5. Define a release gate that blocks release when Stripe key, Stripe price IDs, or backend function targeting is ambiguous.

## Hardening Progress After The Stripe/Endpoint Pass

- `UnifiedPaymentService` now requires a real `STRIPE_PUBLISHABLE_KEY` instead of tolerating placeholder values in runtime initialization.
- Subscription price IDs are now environment-owned through:
  - `STRIPE_PRICE_SUBSCRIPTION_STARTER_MONTHLY`
  - `STRIPE_PRICE_SUBSCRIPTION_CREATOR_MONTHLY`
  - `STRIPE_PRICE_SUBSCRIPTION_BUSINESS_MONTHLY`
  - `STRIPE_PRICE_SUBSCRIPTION_ENTERPRISE_MONTHLY`
- Sponsorship plan resolution remains environment-owned only through:
  - `STRIPE_PRODUCT_SPONSORSHIP_ART_WALK`
  - `STRIPE_PRODUCT_SPONSORSHIP_CAPTURE`
  - `STRIPE_PRODUCT_SPONSORSHIP_DISCOVERY`
  - `STRIPE_PRICE_SPONSORSHIP_ART_WALK_MONTHLY`
  - `STRIPE_PRICE_SPONSORSHIP_CAPTURE_MONTHLY`
  - `STRIPE_PRICE_SPONSORSHIP_DISCOVERY_MONTHLY`
- `.env.example` now reflects both the subscription and sponsorship Stripe ID contract so the repo advertises the same source of truth as the code.
- Cloud Function targeting in payment and verification flows is now expected to use explicit `FIREBASE_FUNCTIONS_BASE_URL` only, with no inferred backend target.

## Working Conclusion

The next hardening work should stay focused on config ownership and endpoint determinism first. The codebase is already cleaner architecturally, but release/payment confidence is still limited by silent defaults, inferred backend targets, and split Stripe configuration sources.

## Release Gate Progress

The first operational release gate now exists in
[check_release_payment_config.sh](/Volumes/ExternalDrive/DevProjects/artbeat/tools/architecture/check_release_payment_config.sh).

Current gate coverage:
- missing required payment/config env keys
- placeholder Stripe publishable key values
- placeholder subscription Stripe price IDs
- placeholder sponsorship Stripe product and price IDs
- invalid or trailing-slash `FIREBASE_FUNCTIONS_BASE_URL`
- invalid `API_BASE_URL`
- production use of a Stripe test publishable key

Current limitation:
- this gate enforces config integrity, not purchase-boundary integrity
- entitlement and payout finalization still need separate hardening based on
  [HARDENING_PURCHASE_VERIFICATION_BOUNDARIES_2026-03-28.md](/Volumes/ExternalDrive/DevProjects/artbeat/docs/HARDENING_PURCHASE_VERIFICATION_BOUNDARIES_2026-03-28.md)

The release gate now has a second enforced layer in
[check_release_monetization_prereqs.sh](/Volumes/ExternalDrive/DevProjects/artbeat/tools/architecture/check_release_monetization_prereqs.sh).

Current monetization prerequisite coverage:
- backend export exists for `validateAppleReceipt`
- backend export exists for `verifyGooglePlayPurchase`
- backend export exists for `activateIapSubscription`
- backend export exists for `cancelIapSubscription`
- backend export exists for Stripe subscription creation and cancellation
- backend export exists for artwork, event-ticket, and commission payment completion paths
- `functions/src/index.js` passes Node syntax check
- `googleapis` must be resolvable in the Functions runtime environment
