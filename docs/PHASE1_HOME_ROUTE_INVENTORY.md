# Phase 1 Home Route Inventory and Ownership Map

Last updated: May 18, 2026

## Scope

Home-related route references focused on:
- `/dashboard` (canonical)
- `/old-dashboard` (legacy, debug-gated)
- Profile/Settings flows that return or route users back to home

## Route Reference Tagging

### Canonical Home Route: `/dashboard`

#### User-facing references
- `lib/src/routing/handlers/direct_route_handler.dart`
  - Owner: app shell routing (`artbeat` app)
  - Usage: canonical route resolution to `AnimatedDashboardScreen`
  - Tag: `user-facing`

- `lib/src/screens/user_onboarding_flow_screen.dart`
  - Owner: onboarding flow (`artbeat` app)
  - Usage: completion and skip both route to dashboard
  - Tag: `user-facing`

- `packages/artbeat_auth/lib/src/screens/login_screen.dart`
  - Owner: auth package (`artbeat_auth`)
  - Usage: successful auth routes to dashboard
  - Tag: `user-facing`

- `packages/artbeat_core/lib/src/screens/splash_screen.dart`
  - Owner: core startup UX (`artbeat_core`)
  - Usage: splash navigation target
  - Tag: `user-facing`

- `packages/artbeat_core/lib/src/widgets/artbeat_drawer_items.dart`
  - Owner: core navigation menu (`artbeat_core`)
  - Usage: dashboard menu item
  - Tag: `user-facing`

- `packages/artbeat_events/lib/src/widgets/events_drawer.dart`
  - Owner: events package (`artbeat_events`)
  - Usage: drawer item routes to dashboard
  - Tag: `user-facing`

- `packages/artbeat_capture/lib/src/widgets/capture_drawer.dart`
  - Owner: capture package (`artbeat_capture`)
  - Usage: drawer/main routes include dashboard
  - Tag: `user-facing`

- `packages/artbeat_art_walk/lib/src/widgets/art_walk_drawer.dart`
  - Owner: art walk package (`artbeat_art_walk`)
  - Usage: drawer route to dashboard
  - Tag: `user-facing`

- `packages/artbeat_profile/lib/src/screens/create_profile_screen.dart`
  - Owner: profile package (`artbeat_profile`)
  - Usage: post-create profile flow to dashboard
  - Tag: `user-facing`

- `packages/artbeat_core/lib/src/screens/artist_onboarding/welcome_screen.dart`
  - Owner: artist onboarding (`artbeat_core`)
  - Usage: onboarding exit to dashboard
  - Tag: `user-facing`

- `packages/artbeat_core/lib/src/widgets/main_layout.dart`
  - Owner: shared scaffold (`artbeat_core`)
  - Usage: fallback/home redirect target
  - Tag: `user-facing`

- `packages/artbeat_capture/lib/src/screens/enhanced_capture_dashboard_screen.dart`
  - Owner: capture feature (`artbeat_capture`)
  - Usage: return-to-home flow
  - Tag: `user-facing`

- `packages/artbeat_art_walk/lib/src/screens/discover_dashboard_screen.dart`
  - Owner: art walk feature (`artbeat_art_walk`)
  - Usage: return-to-home flow
  - Tag: `user-facing`

- `packages/artbeat_admin/lib/src/widgets/admin_drawer.dart`
  - Owner: admin package (`artbeat_admin`)
  - Usage: includes `/dashboard` route entry
  - Tag: `user-facing` (admin audience)

#### Internal/debug/support references
- `lib/src/services/navigation_service.dart`
  - Owner: app-level navigation utility
  - Usage: route existence checks, fallback handling, telemetry helper
  - Tag: `internal/support`

- `lib/src/routing/app_routes.dart` and `packages/artbeat_core/lib/src/routing/app_routes.dart`
  - Owner: route constants
  - Usage: route definitions
  - Tag: `internal/support`

- test files under `test/` and `packages/*/test/`
  - Owner: QA suites
  - Usage: assertions/mocks
  - Tag: `internal/test`

### Legacy Route: `/old-dashboard`

#### User-facing references
- None active in production user flows.

#### Internal/debug references
- `lib/src/routing/handlers/direct_route_handler.dart`
  - Owner: app shell routing (`artbeat` app)
  - Usage: legacy route, debug-gated (`kDebugMode`)
  - Tag: `internal/debug`

- tests asserting exclusion/behavior
  - `packages/artbeat_core/test/src/widgets/artbeat_drawer_items_test.dart`
  - `test/direct_route_handler_home_unification_test.dart`
  - Tag: `internal/test`

## Cross-Package Ownership Summary

- `artbeat` app shell (`lib/`): canonical route orchestration, route handlers, onboarding flow
- `artbeat_core`: splash/home scaffold, shared drawer/menu, shared route constants
- `artbeat_auth`: login success routing to home
- `artbeat_profile`: post-profile creation routing to home
- `artbeat_capture`: capture drawer and return-to-home transitions
- `artbeat_art_walk`: art-walk drawer and return-to-home transitions
- `artbeat_events`: events drawer home jump
- `artbeat_admin`: admin drawer includes global dashboard path

## Profile/Settings Back-to-Home Route Map

### Profile flows
- `/profile/create` completion:
  - Source: `packages/artbeat_profile/lib/src/screens/create_profile_screen.dart`
  - Home target: `/dashboard`
  - Consistency: `consistent`

- Profile menu/layout fallback:
  - Source: `packages/artbeat_core/lib/src/widgets/main_layout.dart`
  - Home target: `/dashboard`
  - Consistency: `consistent`

### Settings flows
- Main settings entry:
  - Source routes: `/settings`, `/settings/account`, `/settings/privacy`, etc.
  - Owner: `lib/src/routing/handlers/settings_route_handler.dart` and `artbeat_settings`
  - Home return behavior: via back navigation stack or explicit dashboard item in drawer
  - Consistency: `consistent with canonical home`

- Module settings headers (package-local menus):
  - Source: `packages/artbeat_settings/lib/src/widgets/settings_header.dart`
  - Behavior: route within settings namespace; dashboard return available via global nav shell/drawer
  - Consistency: `consistent`

## Conclusion

Remaining non-test Phase 1 closure items are satisfied:
- Route references are tagged by `user-facing` vs `internal/debug`.
- Cross-package ownership is identified for home-related routing.
- Profile/settings back-to-home consistency is mapped and aligned to canonical `/dashboard`.

## Drawer Home Verification (Phase 1 Final Check)

Verified canonical home target is `/dashboard` for user-facing drawer home entries:
- `packages/artbeat_core/lib/src/widgets/artbeat_drawer_items.dart` -> dashboard item route `/dashboard`
- `packages/artbeat_events/lib/src/widgets/events_drawer.dart` -> Home nav routes to `/dashboard`
- `packages/artbeat_capture/lib/src/widgets/capture_drawer.dart` -> Main Dashboard item uses `AppRoutes.dashboard`
- `packages/artbeat_art_walk/lib/src/widgets/art_walk_drawer.dart` -> dashboard route `/dashboard`
- `packages/artbeat_admin/lib/src/widgets/admin_drawer.dart` -> Home item route `/dashboard`

No drawer home entries were found targeting `/old-dashboard`.
