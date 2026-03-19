# ARTbeat Artist Package

`artbeat_artist` provides artist profile, subscription, gallery collaboration, visibility insights, and earnings/payout functionality for the ARTbeat app.

## Current Package Surface

- Version: `1.0.1`
- Dart: `>=3.10.7 <4.0.0`
- Flutter: `>=3.38.7`
- Entrypoint: `lib/artbeat_artist.dart`

Exports include:
- Artist models (subscriptions, earnings, payouts, invitations, followers)
- Artist screens (profile, onboarding, gallery/event hubs, earnings hubs)
- Artist services (profile/subscription/earnings/gallery/event + integration)
- Artist widgets bundle (`src/widgets/widgets.dart`)

## Structure

```
packages/artbeat_artist/
├── lib/
│   ├── artbeat_artist.dart
│   ├── src/models/     (11 files)
│   ├── src/services/   (18 files)
│   ├── src/screens/    (26 files)
│   ├── src/widgets/    (10 files)
│   ├── src/utils/      (4 files)
│   └── src/routes.dart
└── test/
    ├── models/
    ├── services/
    └── utils/
```

## Core Models

- `SubscriptionModel`
- `EarningsModel` / `EarningsTransaction`
- `PayoutModel` / `PayoutAccountModel`
- `GalleryInvitationModel`
- `TopFollowerModel`

## Core Services

- `ArtistProfileService`
- `SubscriptionService`
- `EarningsService`
- `GalleryInvitationService`
- `EventServiceAdapter`
- `SubscriptionPlanValidator`
- `FilterService`, `VisibilityService`, `IntegrationService`

## Routes

Defined in `src/routes.dart`:

- `/artist/onboarding`
- `/artist/profile`
- `/artist/hub`
- `/artist/subscription`
- `/artist/visibility`
- `/artist/commissions`
- `/artist/events`

Route ownership note:

- the host app now resolves `artistArtwork` to
  `artbeat_artwork`'s `ArtistArtworkManagementScreen`
- `artbeat_artist` no longer exports a duplicate `MyArtworkScreen`

## Testing

This package now has baseline tests for:
- input validation contracts
- subscription plan validator rules
- subscription lifecycle helpers
- earnings calculations
- payout display/status behavior
- top follower model mapping/copy behavior

Run from `packages/artbeat_artist`:

```bash
flutter test
flutter analyze
```
