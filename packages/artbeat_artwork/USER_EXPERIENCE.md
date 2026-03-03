# ARTbeat Artwork - User Experience Guide

This guide reflects current package behavior in `packages/artbeat_artwork`.

## Primary User Flows

1. Discovery
- Users browse featured/recent/trending artwork feeds.
- Users open detail screens and move to artist and related artwork surfaces.

2. Search
- Users run advanced search (query + medium/style/price/location/sort filters).
- Users can revisit saved searches where enabled by service wiring.

3. Artwork Management
- Artists upload, edit, and manage artwork entries.
- Portfolio and artist-management screens support list/grid management actions.

4. Engagement
- Users rate and comment on artworks.
- Social actions and engagement metrics are surfaced through artwork widgets/services.

5. Commerce/Auction
- Direct purchase flow is supported by artwork purchase screens.
- Auction flow includes bid placement, auction management, and win surfaces.

## UX-Critical Contracts

- `ArtworkModerationStatus` drives moderation badges and messaging:
  - `pending`, `approved`, `rejected`, `flagged`, `underReview`
- `ArtworkModel` carries content metadata, sale state, moderation fields, and optional auction fields.
- `ArtworkRatingStats` is the aggregate source for rating summaries and star distributions.
- Pagination state contract (`PaginationState`) drives loading/has-more behavior in scroll feeds.

## Screen Surface Areas

- Browse/discovery: `ArtworkBrowseScreen`, `ArtworkDiscoveryScreen`, `ArtworkFeaturedScreen`, `ArtworkRecentScreen`, `ArtworkTrendingScreen`
- Detail/purchase: `ArtworkDetailScreen`, `ArtworkPurchaseScreen`
- Creation/management: `ArtworkUploadScreen`, `EnhancedArtworkUploadScreen`, `ArtworkEditScreen`, `ArtistArtworkManagementScreen`, `PortfolioManagementScreen`
- Search/curation: `AdvancedArtworkSearchScreen`, `CuratedGalleryScreen`
- Auctions: `PlaceBidModal`, `MyBidsScreen`, `AuctionWinScreen`, `AuctionManagementModal`, `AuctionSetupWizardScreen`
- Written content: upload/detail/discovery screens plus upload choice surface

## Testing Focus (Current)

Implemented baseline tests cover:
- Model contracts and enum behavior
- Rating aggregate math
- Pagination state copy behavior
- Moderation chip rendering behavior

Recommended next wave:
1. Add `ArtworkGridWidget` interaction tests (tap/edit/delete/auction callbacks).
2. Add service tests with mocked Firestore query paths for search/discovery ranking and fallback behavior.
3. Add screen tests for loading/error empty states on key browse/detail flows.
