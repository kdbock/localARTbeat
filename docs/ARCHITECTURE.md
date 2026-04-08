# ARTbeat Architecture

Last updated: April 7, 2026

## Purpose

Define the current production architecture of the app so engineering, QA, and release work are based on how the code is actually wired today.

## System Shape

ARTbeat is a Flutter app shell (`lib/`) composed with first-party feature packages (`packages/artbeat_*`) and Firebase-backed services.

- App shell owns startup, provider composition, and route registration.
- Feature packages own domain UI + domain services.
- `artbeat_core` owns shared primitives (routes, shared models/widgets/theme/base services), not feature-specific orchestration.

## Package Topology

Root app imports and composes these first-party packages from `pubspec.yaml`:

- `artbeat_core`
- `artbeat_auth`
- `artbeat_profile`
- `artbeat_artist`
- `artbeat_artwork`
- `artbeat_capture`
- `artbeat_community`
- `artbeat_art_walk`
- `artbeat_events`
- `artbeat_messaging`
- `artbeat_ads`
- `artbeat_settings`
- `artbeat_sponsorships`
- `artbeat_admin`

## Runtime Ownership

- Startup entry: `lib/main.dart`
- Bootstrap modules: `lib/src/bootstrap/`
- Provider graph: `lib/src/app_providers.dart` + `lib/src/providers/`
- Route dispatch: `lib/src/routing/app_router.dart` + handlers in `lib/src/routing/handlers/`
- Route constants: `packages/artbeat_core/lib/src/routing/app_routes.dart`

## Routing Domains (Current)

Route handlers are split by domain and actively dispatch for:

- Auth/profile
- Artist + onboarding + earnings/payout
- Artwork (upload/search/detail/auction/purchase)
- Capture (camera/create/moderation/review/map)
- Art walk (map/list/create/start/discovery/achievements)
- Community (feed/posts/studios/moderation/sponsorships)
- Events (discover/create/calendar/my-events/tickets)
- Messaging (inbox/new/chat/thread)
- Ads + IAP + subscriptions + payments
- Admin moderation/management
- Settings + misc/system flows

Public-route policy is currently enforced in `lib/src/routing/route_access_policy.dart`.

## Backend And Platform Dependencies

Primary runtime dependencies in root `pubspec.yaml`:

- Firebase: Auth, Firestore, Storage, Analytics, Messaging, App Check, Data Connect
- Payments: in-app purchase (`in_app_purchase*`) and Stripe platform dependencies
- Location/maps: `geolocator`, `geocoding`, `google_maps_flutter`
- Media: camera/image/video/audio stack
- Localization: `easy_localization`

## Security And Reliability Baselines

- Startup error handling is centralized in bootstrap modules.
- Upload moderation service exists in `artbeat_core` (`upload_safety_service.dart`).
- Purchase verification and payment services are centralized in `artbeat_core` service layer.
- Compliance/security rollout runbooks are under `docs/security/`.

## Architectural Guardrails

- Dependency policy: `docs/DEPENDENCY_RULES.md`
- Current graph snapshot: `docs/PACKAGE_DEPENDENCY_INVENTORY.md`
- Decisions log: `docs/DECISIONS.md`
- Known architecture risks: `docs/KNOWN_ISSUES.md`
