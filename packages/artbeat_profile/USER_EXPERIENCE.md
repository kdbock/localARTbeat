# artbeat_profile User Experience

This document reflects the current profile UX surface in `packages/artbeat_profile`.

## Primary Journeys

1. Create and edit profile
- Entry points: `CreateProfileScreen`, `EditProfileScreen`, `ProfileSettingsScreen`
- Users set profile identity data, media, preferences, and visibility-related options.

2. View profile surfaces
- Entry points: `MyProfileScreen`, `UserProfileScreen`, `ProfileViewScreen`
- Users view public profile details, engagement metrics, and profile content sections.

3. Social graph and connections
- Entry points: `FollowersListScreen`, `FollowingListScreen`, `ProfileConnectionsScreen`, `FollowedArtistsScreen`
- Users manage follow relationships and discover suggested/mutual connections.

4. Activity and analytics
- Entry points: `ProfileActivityScreen`, `ProfileAnalyticsScreen`
- Users view personal profile activity and insight-oriented stats.

5. Favorites and achievements
- Entry points: `FavoritesScreen`, `FavoriteDetailScreen`, `AchievementsScreen`
- Users track saved content and progression/badge-related profile experiences.

## UX Building Blocks

- Common profile widgets include:
  - `ProfileHeader`
  - `FollowButton`
  - `EnhancedStatsGrid`
  - `ProfileBadgeGrid`
  - level/xp widgets (`LevelBadge`, `XPProgressBar`, related components)
  - reusable form/display widgets under `src/widgets/`

## Experience Contracts

- Profile UI state depends on Firestore-backed services in this package.
- Follow/connection views depend on `followers` and `profile_connections` data.
- Activity feed and unread status rely on `profile_activities`.
