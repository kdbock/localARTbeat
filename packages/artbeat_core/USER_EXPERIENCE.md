# artbeat_core User Experience (Current Implementation)

This document reflects UX flows implemented inside `packages/artbeat_core` right now.

## UX boundary

`artbeat_core` provides shared UX building blocks and several concrete screens, but it is not the full app shell.

- It triggers named navigation (`Navigator.pushNamed`) from many widgets.
- The host app must register those routes.
- UX in this package is a combination of:
  - directly rendered core screens
  - route hand-offs to feature packages (`artbeat_art_walk`, `artbeat_events`, `artbeat_artist`, etc)

## Primary user journeys

### 1. App start to dashboard

Entry points:

- `SplashScreen`
- `AnimatedDashboardScreen`
- `ArtbeatDashboardScreen`

Flow:

1. User opens app.
2. Splash transitions to `AppRoutes.dashboard`.
3. Dashboard initializes `DashboardViewModel`.
4. Critical data (user, location, progress) loads first.
5. Feed/content sections load progressively in background.

User-visible behavior:

- Animated world-style backgrounds
- Drawer access
- Profile/settings shortcuts
- Error card + retry on data failures (`ArtbeatDashboardScreen`)

### 2. Global navigation experience

Main components:

- `ArtbeatDrawer`
- `EnhancedNavigationMenu`
- `QuickNavigationFAB`
- `EnhancedUniversalHeader`

Flow:

1. User opens drawer/menu.
2. Available actions are filtered by role (`user`, `artist`, `gallery`, `admin`, `moderator`).
3. `ArtbeatDrawer` checks route against `implementedRoutes` allowlist.
4. If allowed, navigates via `pushNamed`/`pushReplacementNamed`.
5. If not allowed, user gets "coming soon" dialog.

UX details implemented:

- Role-based sectioning and item visibility
- Main-route replacement behavior for major destinations (dashboard/browse/community/role dashboards)
- Navigation throttling via `CrashPreventionService.shouldAllowNavigation()`

### 3. Browse and discovery

Core screen:

- `FullBrowseScreen`

Typical user path:

1. User opens browse/search.
2. Sees grouped discovery sections (captures, art walks, artists, artwork).
3. Taps CTA/cards to route out to feature destinations such as:
   - `/capture/nearby`, `/capture/popular`, `/capture/my-captures`
   - `/art-walk/nearby`, `/art-walk/explore`, `/art-walk/create`
   - `/artist/featured`, `/community/artists`, `/artist/browse`
   - `/artwork/recent`, `/artwork/trending`, `/artwork/featured`

### 4. Dashboard content engagement

Core dashboard widgets route users into deeper modules:

- Artists section -> artist browse/search/profile routes
- Artwork section -> artwork browse/detail routes
- Events section -> events list/create/detail routes
- Community section -> feed/create/featured/trending routes
- Captures section -> capture browse/create/detail routes

This package focuses on presentation + routing handoff; the destination implementations are in sibling packages.

### 5. Artist onboarding

Core screens:

- `artist_onboarding/*`
- `ArtistOnboardingNavigator`

Step flow:

1. Welcome
2. Introduction
3. Story
4. Artwork upload
5. Featured artwork
6. Benefits
7. Tier selection
8. Completion

Completion actions route to:

- Artist dashboard
- Artist public profile
- Artwork upload

### 6. Subscription and purchase UX

Core screens:

- `SubscriptionPlansScreen`
- `SubscriptionPurchaseScreen`
- `SimpleSubscriptionPlansScreen`

Flow:

1. User opens plans (`/subscription/plans`).
2. Chooses tier + monthly/yearly cadence.
3. Proceeds to purchase screen.
4. Purchase action calls `InAppSubscriptionService.subscribeToTier(...)`.
5. Legal links available to terms/privacy routes.

### 7. Auth-required fallback

Core screen:

- `AuthRequiredScreen`

When unauthenticated users attempt protected flows, screen presents sign-in CTA and routes to `/auth`.

## Route contract used by core UX

### Route constants source

- `lib/src/routing/app_routes.dart` (`AppRoutes`)

### Important implementation detail

There is mixed usage today:

- Some call sites use `AppRoutes.*`
- Many call sites use raw route strings

This means UX reliability depends on host-app route aliases staying in sync.

### Known route mismatches/drift

The following route literals are used in core UX but are not standardized in `AppRoutes` naming:

- `/artist/signup`
- `/artwork/discovery`
- `/terms-of-service`
- `/privacy-policy`
- `/old-dashboard`
- `/following` vs `AppRoutes.profile/following` pattern
- `/auth/login` and `/auth/register` vs `AppRoutes.login`/`AppRoutes.register`

## Service-level UX enablers

These services directly shape UX behavior in this package:

- `DashboardViewModel`: staged loading, refresh, and dashboard state
- `OnboardingService`: first-run tours and completion flags
- `NavigationService`: global navigator key utility
- `SubscriptionService` + `InAppSubscriptionService`: tier state and purchase workflow
- `UserService`: user/profile retrieval and role-aware behavior
- `CrashPreventionService`: blocks rapid repeated navigation taps

## If you are updating UX

1. Prefer `AppRoutes` constants over raw strings.
2. Keep `ArtbeatDrawer` allowlist aligned with actual route registration.
3. Verify any newly introduced route in host app `MaterialApp` route table.
4. Update both this file and `README.md` when UX flow or route ownership changes.
