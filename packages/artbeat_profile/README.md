# artbeat_profile

User profile module for ARTbeat. This package provides profile screens, social connection workflows, profile activity/customization services, and profile-focused UI components.

## Public API

Entrypoint: `lib/artbeat_profile.dart`

- Models (barrel export)
  - `ProfileCustomizationModel`
  - `ProfileActivityModel`
  - `ProfileConnectionModel`
  - `ProfileAnalyticsModel`
  - `ProfileMentionModel`
  - badge/level model types from `src/models/`
- Services
  - `UserService`
  - `ProfileCustomizationService`
  - `ProfileActivityService`
  - `ProfileAnalyticsService`
  - `ProfileConnectionService`
- Screens (barrel + direct exports)
  - `MyProfileScreen`
  - `UserProfileScreen`
  - `ProfileViewScreen`
  - `EditProfileScreen`
  - `CreateProfileScreen`
  - `ProfileSettingsScreen`
  - `ProfileActivityScreen`
  - `ProfileAnalyticsScreen`
  - `ProfileConnectionsScreen`
  - `FollowersListScreen`
  - `FollowingListScreen`
  - `FollowedArtistsScreen`
  - `FavoritesScreen`
  - `FavoriteDetailScreen`
  - `AchievementsScreen`
  - additional profile sub-screens under `src/screens/`
- Widgets
  - reusable profile widgets under `widgets/widgets.dart` and `src/widgets/`

## Core Behavior

- Profile data is primarily read/written through Firestore-backed services.
- Social graph workflows (followers/following/mutual suggestions) are managed in `ProfileConnectionService`.
- Profile feed events and read-state tracking are managed in `ProfileActivityService`.
- Theme/layout/visibility customization is persisted through `ProfileCustomizationService`.

## Firestore Collections Used

Primary collections referenced in profile services:

- `users`
- `profile_customization`
- `profile_activities`
- `profile_connections`
- `followers`

## Testing

From repository root:

```bash
flutter test packages/artbeat_profile
flutter analyze packages/artbeat_profile
```
