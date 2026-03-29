# Purchase Verification Boundaries: March 28, 2026

## Purpose

Document where monetization flows are already backend-authoritative, where the
client still mutates entitlement or payout-adjacent state after payment
success, and what must be hardened next.

This is the verification-boundary companion to
[HARDENING_ENV_CONFIG_INVENTORY_2026-03-28.md](/Volumes/ExternalDrive/DevProjects/artbeat/docs/HARDENING_ENV_CONFIG_INVENTORY_2026-03-28.md).

## Boundary Rule

For paid flows, the authoritative state transition must happen only after one
of these is true:

- the app store purchase is verified server-side
- the backend payment function confirms Stripe payment and finalizes the
  transaction

The client may collect intent data and present payment UI, but it must not be
the final authority for:

- subscription activation
- paid entitlement activation
- payout release
- commission status changes tied to funds movement
- ticket confirmation for paid tickets

## Flow Map

### 1. IAP subscriptions

Primary code:
- [in_app_purchase_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_core/lib/src/services/in_app_purchase_service.dart)
- [purchase_verification_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_core/lib/src/services/purchase_verification_service.dart)
- [in_app_purchase_manager.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_core/lib/src/services/in_app_purchase_manager.dart)

Observed flow:
1. Store purchase completes in the client.
2. `PurchaseVerificationService` verifies the receipt/token through Cloud Functions.
3. After verification succeeds, the client writes `subscriptions` and `users.subscriptionStatus` directly in Firestore.
4. `InAppPurchaseManager` also updates user subscription tier state locally.

Assessment:
- verification exists
- improved, but still not fully done

Reason:
- server verification is present, but the client remains the authority that
  activates subscription records and user subscription state

Required hardening:
- move post-verification subscription activation to a backend-authoritative path
- reduce duplicate client-side subscription state mutation after verification

Progress:
- the client now calls backend `activateIapSubscription` after successful
  receipt verification instead of writing subscription entitlement state
  directly in Dart
- Android now has a backend `verifyGooglePlayPurchase` endpoint instead of
  relying on a missing verification target
- remaining risk is legacy/duplicate subscription mutation paths elsewhere in
  core subscription services

Legacy path audit:
- [subscription_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_core/lib/src/services/subscription_service.dart)
  still contains local profile-tier sync helpers after Stripe/manual flows
- those paths no longer own IAP activation, but they should be treated as
  profile synchronization helpers, not the source of truth for paid access
- [in_app_subscription_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_core/lib/src/services/in_app_subscription_service.dart)
  now routes IAP cancellation through backend `cancelIapSubscription`
  instead of writing cancellation state locally in Dart

### 2. Sponsorship subscriptions

Primary code:
- [sponsorship_checkout_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_sponsorships/lib/src/services/sponsorship_checkout_service.dart)
- [unified_payment_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_core/lib/src/services/unified_payment_service.dart)

Observed flow:
1. Client resolves env-owned Stripe plan IDs.
2. Client sets up payment method and payment sheet.
3. Backend `createSubscription` function is called through authenticated payment service.
4. Subscription result comes back from backend.

Assessment:
- stronger boundary

Reason:
- the Stripe subscription creation and first-invoice handling are backend-driven
- the client does not create sponsorship entitlement records locally

Remaining concern:
- final entitlement source should be documented clearly on the backend side

### 3. Boost purchases

Primary code:
- [in_app_purchase_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_core/lib/src/services/in_app_purchase_service.dart)
- [in_app_purchase_manager.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_core/lib/src/services/in_app_purchase_manager.dart)
- [artist_boost_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_core/lib/src/services/artist_boost_service.dart)

Observed flow:
1. IAP purchase is verified through Cloud Functions.
2. The client emits a completed purchase event.
3. The client then completes boost effects locally by writing `boosts`,
   updating momentum, and creating artist features.

Assessment:
- improved

Reason:
- store verification exists
- boost effect application still happens from client callbacks after verification

Required hardening:
- move boost effect application behind a backend-authoritative post-verification
  path, or add a dedicated trusted boundary before artist features are granted

Progress:
- the client now records only the verified completed boost event
- momentum, features, and notifications are expected to come from the existing
  backend `applyBoostMomentum` trigger

### 4. Artwork sales and auction payments

Primary code:
- [artwork_purchase_screen.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_artwork/lib/src/screens/artwork_purchase_screen.dart)
- [auction_win_screen.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_artwork/lib/src/screens/auction_win_screen.dart)
- [unified_payment_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_core/lib/src/services/unified_payment_service.dart)

Observed flow:
1. Client creates Stripe payment intent.
2. Client presents Stripe payment sheet.
3. Client calls backend `processArtworkSalePayment`.
4. Success is taken from backend processing response, not from payment sheet alone.

Assessment:
- stronger boundary

Reason:
- the client does not treat Stripe sheet success as final sale completion
- backend processing is the post-payment authority

Remaining concern:
- backend-side sale finalization and payout release should be documented as the
  authoritative ownership point

### 5. Event ticketing

Primary code:
- [ticket_purchase_sheet.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_events/lib/src/widgets/ticket_purchase_sheet.dart)
- [event_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_events/lib/src/services/event_service.dart)
- [unified_payment_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_core/lib/src/services/unified_payment_service.dart)

Observed flow:
- Free tickets:
  1. client calls `purchaseTickets`
  2. client writes purchase record and attendee state directly
- Paid tickets:
  1. client creates payment intent
  2. client presents payment sheet
  3. client calls backend `processEventTicketPayment`
  4. success depends on backend response, not payment sheet alone

Assessment:
- paid tickets: stronger boundary
- free tickets: acceptable as non-payment flow

Remaining concern:
- document that only backend-confirmed ticket processing is authoritative for
  paid ticket fulfillment

### 6. Direct commissions

Primary code:
- [stripe_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_community/lib/services/stripe_service.dart)
- [direct_commission_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_community/lib/services/direct_commission_service.dart)
- [unified_payment_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_core/lib/src/services/unified_payment_service.dart)

Observed flow:
- Deposit and final payment service methods call backend payment functions first,
  but then still update commission status locally in some cases.
- `DirectCommissionService.completeCommission()` updates
  `direct_commissions.status = completed` before calling backend
  `completeCommission`, which is the funds-release path.

Assessment:
- improved, but still worth a follow-up review

Reason:
- commission lifecycle state and payout-side fulfillment are not fully aligned
- client can mark the commission complete before backend fund release succeeds

Required hardening:
- move commission completion and payout-release state transition behind one
  backend-authoritative operation
- remove client-first status mutation for payout-adjacent commission states

Progress:
- client-first completion/status writes were removed from the commission payment
  services in this hardening pass
- backend `completeCommission` is now the authority for payout-side completion

## Safe Vs Weak Summary

### Stronger patterns already present
- app store verification is routed through Cloud Functions
- sponsorship Stripe subscriptions are backend-created
- artwork sales use backend processing after Stripe sheet confirmation
- paid event ticket sales use backend processing after Stripe sheet confirmation

### Weak patterns still present
- IAP subscription activation is still client-written after verification
- boost effect activation is still client-driven after verification
- commission completion and some commission status transitions are still
  client-written around payout-side actions

## Priority Hardening Tasks

1. Move IAP subscription entitlement activation to a backend-authoritative
   post-verification path.
2. Move boost effect activation off the client callback path.
3. Make commission completion and payout release a single backend-owned state
   transition.
4. Document the backend authority point for sponsorship, artwork sale, and paid
   ticket fulfillment.

## Working Conclusion

The repo is no longer weak on config ownership alone. The next real investor
risk is that some monetization flows are verified securely but still finalized
by the client. The critical pattern to eliminate next is
"server verification succeeded, then client writes the final paid state."

## Final Audit Addendum

A final consistency scan after the hardening passes confirmed:

- IAP subscription activation is backend-owned through `activateIapSubscription`.
- IAP cancellation is backend-owned through `cancelIapSubscription`.
- Boost effect finalization relies on backend-owned `applyBoostMomentum`.
- Sponsorship, artwork sale, and ticket-sale success depends on backend
  processing rather than client-only success handling.
- Commission completion and payout release are backend-owned through
  `completeCommission`.

The legacy paid-subscription blocker in
[subscription_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_core/lib/src/services/subscription_service.dart)
has now been hardened by fail-closing the old paid Stripe helper path instead
of allowing it to write final tier state locally.

The remaining local tier write in that service is the documented non-payment
exception for full-discount coupon activation. It is not a paid monetization
finalization path.
