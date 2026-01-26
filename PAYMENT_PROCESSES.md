# ArtBeat Payment Processes Documentation

This document identifies all payment processes for each revenue stream within the ArtBeat application, consolidated under the `UnifiedPaymentService`.

## 1. Subscriptions
Handles recurring access to ArtBeat premium tiers (Starter, Creator, Business, Enterprise).

- **Revenue Stream**: `RevenueStream.subscription`
- **Modules**: `ArtbeatModule.core`
- **Payment Method**:
  - **IAP (In-App Purchase)**: Required for iOS/Android digital subscriptions.
  - **Stripe**: Used for web-based or specific direct billing scenarios.
- **Key Methods**:
  - `processSubscriptionPayment()`: Core routing for subscription processing.
  - `createSubscription()`: Creates a recurring Stripe subscription.
  - `cancelSubscription()`: Terminates an active subscription.
  - `changeSubscriptionTier()`: Handles upgrades/downgrades.
- **Frontend Integration**: `PaymentScreen` (artbeat_artist)

## 2. Boosts & Gifts
Allows users to send monetary support or digital perks to other users (e.g., fans boosting artists).

- **Revenue Stream**: `RevenueStream.boosts`
- **Modules**: `ArtbeatModule.messaging`
- **Payment Method**:
  - **IAP**: Used for "Digital Perks" (consumables).
  - **Stripe**: Used for monetary boosts that result in artist payouts.
- **Key Methods**:
  - `processBoostPayment()`: Handles both IAP and Stripe boost routing.
- **Frontend Integration**: Integrated into messaging and artist profile components.

## 3. Advertising
Handles payments for artists or businesses to promote content within the ArtBeat ecosystem.

- **Revenue Stream**: `RevenueStream.ads`
- **Modules**: `ArtbeatModule.ads`
- **Payment Method**: **Stripe only** (Apple forbids IAP for advertising services).
- **Key Methods**:
  - `processAdPayment()`: Processes ad campaign funding and targeting metadata.
- **Frontend Integration**: `AdsScreen` (artbeat_core/artbeat_ads).

## 4. Direct Commissions
A multi-step financial process for custom artist commissions involving deposits, milestones, and final payouts.

- **Revenue Stream**: `RevenueStream.commissions`
- **Modules**: `ArtbeatModule.artist`
- **Payment Method**: **Stripe only** (Service-based, involves complex payout logic).
- **Key Methods**:
  - `createCommissionPaymentIntent()`: Initializes a specific phase of commission payment.
  - `processCommissionDepositPayment()`: Processes the initial deposit (held in escrow).
  - `processCommissionMilestonePayment()`: Processes intermediate milestone payments.
  - `processCommissionFinalPayment()`: Processes the final balance.
  - `completeCommission()`: Releases held funds to the artist's available balance.
- **Frontend Integration**: `DirectCommissionService` & `StripeService` (artbeat_community).

## 5. Artwork Sales & Auctions
Handles the purchase of physical or digital artwork and auction wins.

- **Revenue Stream**: `RevenueStream.artwork`
- **Modules**: `ArtbeatModule.artist`, `ArtbeatModule.artwork`
- **Payment Method**: **Stripe only**.
- **Key Methods**:
  - `processArtworkSalePayment()`: Processes standard sales and auction completions.
- **Frontend Integration**:
  - `ArtworkPurchaseScreen` (Standard sales)
  - `AuctionWinScreen` (Auction fulfillment)
  - `WrittenContentDetailScreen` (Premium written content purchases)

## 6. Event Ticketing
Handles ticket sales for events hosted within the ArtBeat platform.

- **Revenue Stream**: N/A (Consolidated under `processEventTicketPayment`)
- **Modules**: `ArtbeatModule.events`
- **Payment Method**: **Stripe only**.
- **Key Methods**:
  - `processEventTicketPayment()`: Processes ticket quantity, types, and artist payouts.
- **Frontend Integration**: `TicketPurchaseSheet` (artbeat_events).

## 7. Artist Sponsorships
Recurring support similar to subscriptions but directed towards specific artists.

- **Revenue Stream**: N/A (Uses subscription-like architecture)
- **Modules**: `ArtbeatModule.artist`
- **Payment Method**: **Stripe only**.
- **Key Methods**:
  - `processSponsorshipPayment()`: Processes recurring artist support.
  - `pauseSubscription()` / `resumeSubscription()`: Lifecycle management for sponsorships.
- **Frontend Integration**: `SponsorshipReviewScreen` (artbeat_sponsorships).

## 8. Premium Feature Access (Digital Goods)
One-time purchases for premium app features.

- **Revenue Stream**: N/A
- **Modules**: `ArtbeatModule.capture`, `ArtbeatModule.artWalk`, `ArtbeatModule.profile`, `ArtbeatModule.settings`
- **Payment Method**: **IAP only** (Standard App Store requirement for digital features).
- **Key Methods**: Handled via `getPaymentMethod()` routing to IAP flow.

---
*Note: All Stripe processes utilize `StripeSafetyService` for risk assessment and `AppLogger` for financial telemetry.*
