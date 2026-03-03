# ARTbeat Artwork Package

`artbeat_artwork` is the artwork domain package for browse/discovery, upload/edit flows, auctions, comments/ratings, collections, and artwork analytics.

## Current Package Surface

- Version: `0.0.2`
- Dart: `>=3.10.7 <4.0.0`
- Flutter: `>=3.38.7`
- Entrypoint: `lib/artbeat_artwork.dart`

Exports:
- `src/models/models.dart`
- `src/services/services.dart`
- `src/screens/screens.dart`
- `src/widgets/widgets.dart`

## Structure

```
packages/artbeat_artwork/
├── lib/
│   ├── artbeat_artwork.dart
│   ├── src/models/      (6 files)
│   ├── src/services/    (17 files)
│   ├── src/screens/     (25 files)
│   ├── src/widgets/     (9 files; 7 exported)
│   └── theme/
└── test/
    ├── models/
    ├── services/
    └── widgets/
```

## Key Models

- `ArtworkModel`
- `ArtworkRatingModel` + `ArtworkRatingStats`
- `CommentModel`
- `CollectionModel`
- `AuctionBidModel` / `AuctionResultModel` / `AuctionStatus`

## Key Services

- `ArtworkService`
- `ArtworkDiscoveryService`
- `EnhancedArtworkSearchService`
- `ArtworkPaginationService`
- `ArtworkAnalyticsService` + `AdvancedArtworkAnalyticsService`
- `ArtworkCommentService` / `ArtworkRatingService`
- `CollectionService`
- `AuctionService`
- `ImageModerationService` + `EnhancedModerationService`

## Screens (Exported)

Includes browse/detail/upload/edit/purchase flows, discovery/search flows, management flows, and auction screens:

- `ArtworkBrowseScreen`, `ArtworkDetailScreen`, `ArtworkUploadScreen`, `ArtworkEditScreen`
- `ArtworkDiscoveryScreen`, `AdvancedArtworkSearchScreen`, `CuratedGalleryScreen`
- `ArtworkFeaturedScreen`, `ArtworkRecentScreen`, `ArtworkTrendingScreen`
- `ArtistArtworkManagementScreen`, `PortfolioManagementScreen`
- `PlaceBidModal`, `MyBidsScreen`, `AuctionWinScreen`, `AuctionManagementModal`, `AuctionSetupWizardScreen`
- plus written-content screens and upload choice screen

## Widgets (Exported)

- `ArtworkHeader`
- `ArtworkGridWidget`
- `ArtworkDiscoveryWidget`
- `ArtworkSocialWidget`
- `ArtworkModerationStatusChip`
- `LocalArtworkRowWidget`
- `BookCard`

## Testing

Baseline tests in this package now cover:
- model behavior (`ArtworkModel`, `ArtworkRatingStats`, `AuctionStatus`)
- pagination state contract (`PaginationState.copyWith`)
- widget behavior (`ArtworkModerationStatusChip`)

Run from `packages/artbeat_artwork`:

```bash
flutter test
flutter analyze
```
