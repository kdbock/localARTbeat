# ARTbeat Artist - User Experience Guide

This guide reflects the current package behavior in `packages/artbeat_artist`.

## Primary User Journeys

1. Artist Onboarding
- User starts onboarding and profile setup.
- User selects subscription and profile visibility preferences.

2. Profile & Presence
- Artist updates public profile and social/professional metadata.
- Audience-facing profile screens expose stats, events, and artwork links.

3. Subscription & Access
- Subscription tier controls feature access and limits.
- Upgrade/downgrade paths gate analytics, events, and advanced features.

4. Earnings & Payouts
- Earnings hubs show source breakdowns and trends.
- Payout screens handle account setup and payout request flow.

5. Gallery/Event Collaboration
- Gallery invitation and hub screens support collaboration.
- Event creation and management surfaces support artist-led programming.

## UX-Sensitive Contracts

- Subscription lifecycle:
  - `active`, `inactive`, grace-period behavior
  - days-remaining logic on paid windows
- Plan validation:
  - tier hierarchy for upgrades/downgrades
  - feature access and limit checks
- Financial UX:
  - earnings source percentages and growth metrics
  - payout status helpers and account display masking

## Current Screen Surface

- Onboarding/profile: `ArtistOnboardScreen`, `ArtistProfileEditScreen`, `ArtistPublicProfileScreen`
- Hubs: `GalleryHubScreen`, `GalleryVisibilityHubScreen`, `AuctionHubScreen`
- Earnings: `ArtistEarningsHubScreen`, `ArtworkSalesHubScreen`, `PayoutRequestScreen`, `PayoutAccountsScreen`
- Events: `EventsScreen`, `EventCreationScreen`
- Discovery/listing: `ArtistBrowseScreen`, `FeaturedArtistScreen`

## Testing Focus (Current)

Implemented baseline tests cover:
- `InputValidator` behavior
- `SubscriptionPlanValidator` rule engine
- `SubscriptionModel` lifecycle helpers
- `EarningsModel` growth and breakdown calculations
- `PayoutModel` status flags and payout account display rules
- `TopFollowerModel` mapping/copy contracts

Recommended next wave:
1. Add widget tests for artist header/stat cards with test-localized strings.
2. Add service tests for gallery invitation and earnings service paths with mocked Firestore.
3. Add route-level navigation tests for onboarding/profile/earnings hub transitions.
