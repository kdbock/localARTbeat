# Investor Audit: Risk Profile

## Investor View

**Current rating:** high-medium risk  
**Assessment:** The largest risks are secrets/config hygiene, payment/config drift, and operational coupling in sensitive runtime paths.

## Code Reviewed

- `.gitignore`
- tracked files via `git ls-files`
- `packages/artbeat_core/lib/src/utils/env_loader.dart`
- `packages/artbeat_core/lib/src/services/unified_payment_service.dart`
- `packages/artbeat_core/lib/src/services/purchase_verification_service.dart`
- `packages/artbeat_ads/lib/src/services/local_ad_iap_service.dart`
- `packages/artbeat_sponsorships/lib/src/services/sponsorship_checkout_service.dart`

## Findings

### 1. Sensitive config hygiene is below industry standard

Tracked files currently include:

- `.env.production`
- `debug.keystore`
- `packages/artbeat_core/lib/firebase_options.dart`

That is already weaker than a typical hardened mobile repo.

### 2. Environment loading includes a hardcoded live publishable payment key

`packages/artbeat_core/lib/src/utils/env_loader.dart` sets a default `STRIPE_PUBLISHABLE_KEY` in code when configuration is missing. Even though a publishable key is not a secret in the same way as a secret key, hardcoding live billing configuration into app code is poor operational hygiene and increases environment drift risk.

### 3. Payment endpoints are hardcoded into the client

`packages/artbeat_core/lib/src/services/unified_payment_service.dart` and `packages/artbeat_core/lib/src/services/purchase_verification_service.dart` hardcode Cloud Function base URLs and function endpoints directly in the client. That makes environment promotion, staging isolation, and incident response harder.

### 4. Purchase handling is not visibly end-to-end verified at the ad service layer

`packages/artbeat_ads/lib/src/services/local_ad_iap_service.dart` completes the store purchase flow and returns purchase metadata, but the service does not itself enforce server verification before commercial activation. Even if verification exists elsewhere, that responsibility is not obvious at the boundary where revenue is created.

### 5. Sponsorship plan fallback behavior increases drift risk

`packages/artbeat_sponsorships/lib/src/services/sponsorship_checkout_service.dart` supports fallback placeholder-like plan mappings in non-release mode. That is useful for local development, but it raises the chance of environment mismatch and incomplete pre-release validation if not tightly controlled.

## Recommended Action Checklist

- [ ] Remove tracked production-like env files and keystores from version control, then rotate or re-issue anything that should not remain trusted.
- [ ] Remove hardcoded live Stripe configuration defaults from client code and require explicit environment injection for every environment.
- [ ] Move Cloud Function base URLs and payment endpoint configuration behind environment-based service discovery.
- [ ] Add a release gate that fails if payment config falls back to placeholder or development values.
- [ ] Enforce server-side purchase verification before any paid entitlement or ad activation is recorded as live.
- [ ] Add audit logs for ad purchases, sponsorship creation, refunds, entitlement activation, and admin approval actions.
- [ ] Add secret scanning and config policy checks that fail CI when protected files are tracked or unsafe defaults are committed.
- [ ] Create a payment and configuration incident runbook covering key rotation, endpoint rollback, and compromised-environment response.
