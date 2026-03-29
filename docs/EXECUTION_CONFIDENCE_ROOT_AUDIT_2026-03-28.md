# Execution-Confidence Root Audit: March 28, 2026

## Purpose

Document the next root-level execution-confidence risks after the March 28
hardening sprint so the next phase can start from concrete composition debt
instead of another broad package sweep.

## Scope Reviewed

- [app_providers.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/src/app_providers.dart)
- [main.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/main.dart)
- [app.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/app.dart)
- [app_router.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/src/routing/app_router.dart)
- [app_routes.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/src/routing/app_routes.dart)

## File Size / Composition Signals

- [app_providers.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/src/app_providers.dart):
  521 lines
- [main.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/main.dart):
  459 lines
- [app.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/app.dart):
  55 lines
- [app_router.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/src/routing/app_router.dart):
  1303 lines
- [app_routes.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/src/routing/app_routes.dart):
  18 lines

Provider root counts in
[app_providers.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/src/app_providers.dart):

- `Provider<...>`: 118
- `ChangeNotifierProvider<...>`: 18
- `ProxyProvider...`: 2
- `ChangeNotifierProxyProvider...`: 1

That is not just "a lot of providers". It means the app-level composition root
is still acting as a single global assembly file for almost every subsystem.

## Findings

### 1. `app_providers.dart` was an oversized global composition root

Evidence:
- one root list currently owns provider registration across admin, artwork,
  art walk, artist, ads, profile, events, messaging, sponsorships, capture,
  payments, and dashboard view models
- package-specific services are mixed together with app-wide core services and
  feature-specific read services
- the file carries both simple service registration and composed graph wiring
  like `AdminPaymentOperationsService` and `DashboardViewModel`

Why this matters:
- ownership is hard to reason about
- provider graph changes become high-blast-radius edits
- it is difficult to tell which provider groups are startup-critical versus
  feature-local

Current status:
- first pass complete
- [app_providers.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/src/app_providers.dart)
  is now a small aggregator over grouped provider modules under
  `lib/src/providers/`
- provider ownership is now separated into domain-oriented modules instead of
  one 500-line root list

### 2. There is still duplicate ownership shape at the provider root

Notable examples in
[app_providers.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/src/app_providers.dart):

- `core.SubscriptionService`
- `core.InAppSubscriptionService`
- `artist.SubscriptionService`
- `ArtworkService` from `artbeat_artwork`
- `artist.ArtworkService`
- `events.EventService`
- `artist.EventServiceAdapter`
- `core.UserService`
- `core_auth.AuthService`

This is not automatically wrong, but right now it is under-explained and
co-located in one root list with no visible grouping contract. That weakens
confidence because overlapping service domains look interchangeable from the
composition root even when they are not.

Current status:
- first overlap-consolidation pass complete
- `artist.SubscriptionService` is now provider-owned with explicit
  `AuthService` / `UserService` injection from the app root instead of hidden
  fallback construction
- `artist.EventServiceAdapter` is now provider-owned with explicit
  `events.EventService` / `AuthService` injection from the app root
- `artist.ArtworkService` is now provider-owned with explicit auth injection
- this does not remove the domain overlaps yet, but it makes the ownership
  relationship explicit and reduces hidden singleton construction inside
  provider-created services

### 3. `main.dart` previously owned too many responsibilities

[main.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/main.dart) currently
combines:

- environment bootstrap
- Firebase core startup
- config validation
- app check init
- localization bootstrap
- lifecycle manager startup
- debug diagnostics/performance instrumentation
- fallback error UI
- deferred init kickoff

Why this matters:
- startup behavior is harder to reason about and test
- release-critical boot order is embedded in one large entry file
- operational diagnostics and core startup policy are mixed together

Current status:
- first pass complete
- startup policy is now split across:
  - [core_startup.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/src/bootstrap/core_startup.dart)
  - [startup_diagnostics.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/src/bootstrap/startup_diagnostics.dart)
  - [deferred_startup.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/src/bootstrap/deferred_startup.dart)
- [main.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/main.dart) is now
  closer to orchestration-only

### 4. `app_router.dart` is still oversized, but the Firebase-decoupling pass and multiple domain-splitting passes are complete

[app_router.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/src/routing/app_router.dart)
is the largest root hotspot at 1303 lines and was previously performing direct
Firebase-driven routing behavior.

Concrete examples that were removed in the first pass:

- onboarding/profile/tickets/favorites route-time auth reads now use
  `AuthService`
- `_ArtistFeedLoader` now uses `ArtistProfileService` and `UserService` instead
  of direct Firestore access
- a focused scan of
  [app_router.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/src/routing/app_router.dart)
  now returns no direct `FirebaseAuth.instance` or `FirebaseFirestore.instance`
  reads

Current status:
- the highest-risk singleton coupling is removed
- domain extraction is now complete for artist, events, settings,
  subscription, community, messaging, artwork, admin, misc, gallery,
  commission, ads, and IAP routing via dedicated handler files under
  `lib/src/routing/handlers/`
- auth/profile-adjacent direct routes have also been extracted out of
  the former root route handler
  into
  [auth_profile_route_handler.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/src/routing/handlers/auth_profile_route_handler.dart)
- the remaining generic direct routes have also been extracted into
  [direct_route_handler.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/src/routing/handlers/direct_route_handler.dart)
- protected-route policy is now isolated in
  [route_access_policy.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/src/routing/route_access_policy.dart)
- prefix-based specialized route selection is now isolated in
  [specialized_route_dispatcher.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/src/routing/handlers/specialized_route_dispatcher.dart)
- the legacy root route wrapper has now been removed entirely
- router-level code is still too large and still mixes route generation with
  some coordination responsibilities, but the bulk extraction work is complete
- the next router task should be continued structural splitting, not another
  singleton cleanup sweep

### 5. `app.dart` stays thin, but it currently hides the size of the real root graph

[app.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/app.dart) is small,
but it wraps the entire provider graph and route generation behind:

- `createAppProviders()`
- `AppRouter.onGenerateRoute`

That means `app.dart` is not the real complexity center. The complexity is
displaced into [app_providers.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/src/app_providers.dart)
and [app_router.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/src/routing/app_router.dart),
which is exactly why those two files should be the next root-level refactor
targets.

## Recommended Refactor Order

### 1. Split provider composition by domain

Start with
[app_providers.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/src/app_providers.dart).

Target shape:
- `core_providers.dart`
- `community_providers.dart`
- `artwork_providers.dart`
- `artist_providers.dart`
- `events_providers.dart`
- `admin_providers.dart`
- one small root `app_providers.dart` that only concatenates grouped lists

Goal:
- make ownership visible
- make duplicate domain services intentional instead of implicit
- reduce blast radius of provider graph edits

Status:
- complete for first pass
- first overlap-consolidation pass complete for artist-layer service wiring

### 2. Split bootstrap policy out of `main.dart`

Move startup concerns into focused bootstrap modules such as:
- env/config bootstrap
- Firebase bootstrap
- diagnostics bootstrap
- deferred post-frame bootstrap

Goal:
- keep `main.dart` as orchestration, not implementation
- make release-critical startup policy readable by inspection

Status:
- complete for first pass

### 3. Continue splitting `app_router.dart` by domain now that the third extraction pass is complete

The highest-risk Firebase singleton reads have already been removed from the
identified hotspots, and extraction is now complete for:
- artist routing
- events routing
- settings routing
- subscription routing
- community routing
- messaging routing
- artwork routing
- admin routing
- misc routing
- gallery routing
- commission routing
- ads routing
- IAP routing

Suggested next slices:
- reduce any remaining coordination-only boilerplate in
  [app_router.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/src/routing/app_router.dart)
- any remaining route-local widgets or helpers still hosted in the root

### 4. Make the new CI gate a merge expectation

The `Release Hardening Gates` job now exists in CI. The next operational step is
not more gate code. It is making that job a required branch-protection signal in
repository settings so it actually influences merge behavior. That remains a
GitHub settings action outside the repo itself.

## Working Conclusion

The package sweep should stay paused.

The next execution-confidence work is now clearly root composition work, not
feature cleanup:

- provider graph modularization: first pass complete
- provider overlap consolidation: first pass started
- startup/bootstrap decomposition: first pass complete
- router Firebase decoupling: first pass complete
- router domain split: third pass complete
- root auth/profile direct-route extraction: complete
- root generic direct-route extraction: complete
- route protection policy extraction: complete
- specialized route selection extraction: complete
- legacy root route wrapper removal: complete
- router extraction phase: effectively complete
- CI/release gate operationalization
