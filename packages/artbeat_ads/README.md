# ARTbeat Ads Package

The `artbeat_ads` package powers ARTbeat's simplified local ad system.

It is built for:
- local businesses
- local artists
- local event organizers

The current product model is intentionally small:
- `Banner Ad`
- `Inline Ad`

Both are monthly paid products. Both require store checkout first, then admin review before they go live.

## Current Product Model

### Ad Types

- `Banner Ad`
  - section-break placement
  - lower-priced monthly option
  - best for broad local visibility

- `Inline Ad`
  - feed/native placement
  - higher-tier monthly option
  - best for community, artist, and artwork browsing surfaces

### Live Placements

The launch flow only sells placements that are currently live in the app:
- `Community feed`
- `Artists and artwork`
- `Events`

Older internal placement enums still exist for compatibility, but `Home` and `Featured` are not in launch rotation.

## Purchase Flow

The current ad flow is:
1. User creates an ad.
2. User selects ad type and placement.
3. User uploads images.
4. Store checkout opens for the monthly subscription.
5. The purchase is verified server-side.
6. After successful verification, the ad is created in Firestore as `pendingReview`.
7. Admin approves or rejects the ad.
8. Approved ads become visible in their selected placement.

Important:
- payment happens before the ad enters review
- approval still controls visibility
- `My Ads` shows pending items clearly

## Product IDs

The active monthly subscription product IDs are:

```text
artbeat_ad_banner_monthly
artbeat_ad_inline_monthly
```

These must match App Store Connect and Google Play Console exactly.

## Core Models

```dart
LocalAd
LocalAdZone
LocalAdSize
LocalAdStatus
AdPricingMatrix
```

### LocalAd

`LocalAd` stores:
- user-owned ad content
- selected placement
- size
- review state
- expiry date
- subscription/payment metadata

The model now also stores:
- `subscriptionProductId`
- `purchaseId`
- `transactionId`
- `monthlyPrice`
- `currencyCode`
- `autoRenewing`
- `purchaseFollowUpStatus`
- `purchaseFollowUpNotes`

## Services

### `LocalAdService`

Primary Firestore service for:
- creating ads
- loading ads by placement
- loading current user's ads
- updating status
- searching active ads

### `LocalAdIapService`

Ad-specific store billing service for:
- loading the two monthly products
- starting checkout
- waiting for store confirmation
- returning purchase metadata and verification payload only after success

## Storage / Media

Ad images are uploaded to:

```text
ads/<userId>/<timestamp>_<index>.jpg
```

This matches the current Firebase Storage rules.

## Firestore Shape

### `localAds/{adId}`

```javascript
{
  userId: string,
  title: string,
  description: string,
  imageUrl?: string,
  imageUrls?: string[],
  contactInfo?: string,
  websiteUrl?: string,
  zone: number,
  size: number,
  createdAt: Timestamp,
  expiresAt: Timestamp,
  status: number,
  reportCount: number,
  reviewedAt?: Timestamp,
  reviewedBy?: string,
  rejectionReason?: string,
  subscriptionProductId?: string,
  purchaseId?: string,
  transactionId?: string,
  monthlyPrice?: number,
  currencyCode?: string,
  autoRenewing: boolean,
  purchaseFollowUpStatus?: string,
  purchaseFollowUpNotes?: string
}
```

## UI Surfaces

### Merchant Screens

- `CreateLocalAdScreen`
- `MyAdsScreen`
- `LocalAdsListScreen`

### Display Widgets

- `AdSmallBannerWidget`
- `AdNativeCardWidget`
- `AdGridCardWidget`
- `AdCtaCardWidget`

## Admin Workflow

Ads are moderated through the admin ad management flow.

Current moderation language is aligned to:
- submitted
- needs review
- approve & publish
- reject

## Launch Notes

The current ads system is optimized for a near-term launch:
- two products only
- monthly only
- no user-facing stats product
- no old campaign matrix
- no consumable ad packs

If ARTbeat later expands this system, do it intentionally. Do not reintroduce the old six-SKU consumable design by accident.
