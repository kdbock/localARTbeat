# artbeat_core

Core shared package for ARTbeat. It provides reusable UI, route constants, service singletons, models, and dashboard/onboarding flows used by feature packages.

## What this package currently contains

### Top-level structure

- `lib/artbeat_core.dart`: Main public entry point (exports routes, services, models, widgets, theme, utilities).
- `lib/widgets.dart`: Small focused widget export barrel.
- `lib/shared_widgets.dart`: Shared themed widget exports.
- `lib/src/routing/app_routes.dart`: Central route constants (`AppRoutes`).
- `lib/src/screens/`: Core screens (dashboard, onboarding, subscription, legal/help/search/browse/store).
- `lib/src/widgets/`: Shared UI building blocks (drawer, headers, cards, navigation, filters, dashboard sections).
- `lib/src/services/`: Core services (user, navigation, subscriptions, payments, engagement, onboarding, storage, etc).
- `lib/src/viewmodels/dashboard_view_model.dart`: Dashboard orchestration and data loading.
- `lib/src/models/`: Shared models and type definitions.
- `lib/src/theme/`: Color system, typography, themed components.
- `assets/translations/*.json`: i18n resources.

## Public API entry points

Use:

```dart
import 'package:artbeat_core/artbeat_core.dart';
```

Also available:

- `package:artbeat_core/widgets.dart`
- `package:artbeat_core/shared_widgets.dart`

`artbeat_core.dart` currently exports:

- Theme system: `ArtbeatTheme`, `ArtbeatColors`, `ArtbeatTypography`, themed components
- Routing: `AppRoutes`
- Services: `UserService`, `SubscriptionService`, `UnifiedPaymentService`, `InAppPurchase*`, `NavigationService`, `OnboardingService` (via direct service import in code), and more
- Models: barrel exports in `src/models/index.dart` + `src/models/types/index.dart`
- Screens: splash, dashboards, leaderboard/help, subscription screens, boosts/ads screens
- Widgets: drawer, buttons, cards, content engagement, filters, profile/header/navigation widgets
- Utilities: connectivity/date/env/auth/logger/location/image helpers

## Core runtime flows in this package

### Dashboard loading

`DashboardViewModel.initialize()`:

1. Loads current user (`UserService`).
2. Loads critical startup data (location + progress).
3. Marks view model initialized.
4. Starts non-blocking background loads (events, artwork, artists, achievements, captures, posts, challenge, activities).

Used by:

- `AnimatedDashboardScreen`
- `ArtbeatDashboardScreen` (`explore_dashboard_screen.dart`)

### Onboarding state

`OnboardingService` persists completion flags via `SharedPreferences`:

- App onboarding
- Capture/discover/explore/community/events onboarding flags

Used by dashboard screens to show/hide tour overlays.

### Artist onboarding flow

`ArtistOnboardingNavigator` defines 7 step routes:

- `/artist/onboarding/welcome`
- `/artist/onboarding/introduction`
- `/artist/onboarding/story`
- `/artist/onboarding/artwork`
- `/artist/onboarding/featured`
- `/artist/onboarding/benefits`
- `/artist/onboarding/selection`
- Completion: `/artist/onboarding/complete`

Completion screen routes to `artistDashboard`, `artistPublicProfile`, or `artworkUpload`.

### Subscription purchase flow

- `SubscriptionPlansScreen` -> select tier/billing cadence
- `SubscriptionPurchaseScreen` -> purchase confirmation + legal links
- `InAppSubscriptionService.subscribeToTier(...)` delegates to `InAppPurchaseService`

## Routing status (important)

### What exists in this package

- `AppRoutes` defines route constants only.
- Multiple widgets/screens call `Navigator.pushNamed(...)` directly.
- `ArtbeatDrawer` maintains an `implementedRoutes` allowlist before navigating.

### What this package does not do

- It does **not** register a global `routes`/`onGenerateRoute` map for `MaterialApp`.
- Host app must wire route names to actual screens across `artbeat_*` packages.

### Frequently invoked routes from `artbeat_core`

- Dashboard/search/profile: `/dashboard`, `/search`, `/profile`, `/profile/menu`
- Browse/discovery: `/browse`, `/artwork/browse`, `/artist/browse`, `/capture/browse`, `/art-walk/list`
- Engagement/community: `/community/feed`, `/community/create`, `/community/trending`, `/community/featured`
- Messaging/notifications: `/messaging`, `/notifications`
- Events: `/events`, `/events/discover`, `/events/create`
- Subscription/payments/store: `/subscription/plans`, `/payment/methods`, `/payment/screen`, `/store`
- Artist onboarding: `/artist/onboarding/*`

### Route drift to watch

Some routed literals used in UI do not have matching `AppRoutes` constants (or use alternate naming), for example:

- `/artist/signup`
- `/artwork/discovery`
- `/terms-of-service`
- `/privacy-policy`
- `/old-dashboard`
- `/following` (while `AppRoutes` has `/profile/following`)
- `/auth/login` and `/auth/register` (while `AppRoutes` has `/login` and `/register`)

If you standardize routing, convert these call sites to `AppRoutes` constants and align host-app route registration.

## Local development

```yaml
dependencies:
  artbeat_core:
    path: ../packages/artbeat_core
```

```bash
flutter pub get
flutter analyze
```

## Notes

- This package depends on many sibling modules (`artbeat_art_walk`, `artbeat_events`, `artbeat_artist`, etc); dashboard and route UX assumes those modules are present in the host app.
- `lib/src/view_models.dart` is currently empty.
