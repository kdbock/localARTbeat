# ARTbeat Art Walk Package

`artbeat_art_walk` provides route creation, discovery, navigation, progress tracking, challenges, and achievement flows for the ARTbeat app.

## Current Status

- Package version: `0.0.2`
- SDK constraints: Dart `>=3.10.7 <4.0.0`, Flutter `>=3.38.7`
- Main entrypoint: `lib/artbeat_art_walk.dart`
- Exported surfaces:
  - `models`
  - `services`
  - `screens`
  - `widgets`
  - `utils`
  - route constants/config
  - `art_walk_design_system`

## Package Layout

```
packages/artbeat_art_walk/
├── lib/
│   ├── artbeat_art_walk.dart
│   ├── src/models/      (14 files)
│   ├── src/services/    (20 files)
│   ├── src/screens/     (18 files)
│   ├── src/widgets/     (42 files)
│   ├── src/routes/
│   ├── src/constants/
│   ├── src/theme/
│   └── src/utils/
└── test/
    ├── art_walk_service_test.dart
    ├── art_walk_progress_service_test.dart
    ├── art_walk_navigation_service_test.dart
    ├── art_walk_route_config_test.dart
    ├── art_walk_security_service_test.dart
    └── widgets/art_walk_core_widgets_test.dart
```

## Route Contracts

Defined in `src/constants/routes.dart` and wired in `src/routes/art_walk_route_config.dart`.

- `ArtWalkRoutes.map` -> `ArtWalkMapScreen`
- `ArtWalkRoutes.list` -> `ArtWalkListScreen`
- `ArtWalkRoutes.dashboard` -> `DiscoverDashboardScreen`
- `ArtWalkRoutes.questHistory` -> `QuestHistoryScreen`
- `ArtWalkRoutes.weeklyGoals` -> `WeeklyGoalsScreen`
- `ArtWalkRoutes.instantDiscovery` -> `InstantDiscoveryRadarScreen`
- Generated routes:
  - `detail`, `review`, `experience`, `create`, `edit`
  - `enhancedCreate`
  - `celebration` (with fallback if data missing)

`ArtWalkRoutes.enhancedExperience` is deprecated and currently aliases `experience`.

## Core Services In Use

- `ArtWalkService`: CRUD + discovery + comments + data retrieval
- `ArtWalkProgressService`: walk lifecycle (`start/pause/resume/complete/abandon`) and XP hooks
- `ArtWalkNavigationService`: route generation from directions payloads
- `ArtWalkSecurityService`: validation/sanitization, spam and rate-limit checks
- `RewardsService` and `AchievementService`: XP and achievement progression
- Additional surfaces: weekly goals, challenges, onboarding, haptics, clustering, instant discovery

## Development

From `packages/artbeat_art_walk`:

```bash
flutter test
flutter analyze
```

Run one test file:

```bash
flutter test test/art_walk_progress_service_test.dart
```

## Notes

- This package depends on multiple sibling ARTbeat packages via local `path` dependencies.
- Some screens/widgets are plugin-heavy (maps, geolocation, media); unit tests should prefer service contracts and lightweight widget behavior unless explicit integration setup is added.
