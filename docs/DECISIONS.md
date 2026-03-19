# ARTbeat Decisions

## Purpose

Keep a short log of important technical and process decisions so the project
does not re-argue the same fundamentals.

## Decision Log

### 2026-03-18: Root `lib/` is the app shell

Decision:

- treat root `lib/` as the application composition layer

Why:

- startup, provider wiring, and route integration already live there
- this is the cleanest place to coordinate features without pushing more
  orchestration into packages

### 2026-03-18: `artbeat_core` should stop growing as a feature host

Decision:

- no new feature-specific logic should be added to `artbeat_core`

Why:

- it already acts as both a base layer and a feature/orchestration layer
- continuing that pattern increases coupling and release risk

### 2026-03-18: English is the canonical locale

Decision:

- `assets/translations/en.json` is the source locale for key creation

Why:

- translation integrity is easier to validate from one canonical key set

### 2026-03-18: Canonical project-control docs live under `docs/`

Decision:

- `ROADMAP.md`, `WORK_QUEUE.md`, `RELEASE_CHECKLIST.md`, `TEST_STRATEGY.md`,
  `DEPENDENCY_RULES.md`, `KNOWN_ISSUES.md`, and `OPERATIONS.md` are the
  operating docs for the repo

Why:

- current project state is spread across many one-off docs and notes

### 2026-03-18: High-risk refactors must be incremental

Decision:

- no large architecture rewrite while the app is live

Why:

- the codebase already ships to iOS and Android
- stability and controlled complexity matter more than conceptual purity

### 2026-03-18: `artbeat_auth` no longer owns profile creation UI

Decision:

- remove the direct `artbeat_auth -> artbeat_profile` package dependency
- keep auth responsible for route decisions, but let the host app own the
  `/profile/create` screen implementation

Why:

- the auth package only used `artbeat_profile` for a bridge screen
- the host app already handles `/profile/create` in its own route layer
- moving orchestration upward is lower-risk than preserving sideways package
  coupling

### 2026-03-18: `artbeat_events` no longer depends on `artbeat_auth`

Decision:

- remove the direct `artbeat_events -> artbeat_auth` package dependency

Why:

- no source-level usage remained in `packages/artbeat_events`
- auth/runtime coordination belongs in the host app or through Firebase/auth
  primitives, not a direct feature-package link

### 2026-03-18: `artbeat_settings` no longer depends on `artbeat_artist` or `artbeat_events`

Decision:

- remove the direct `artbeat_settings -> artbeat_artist` and
  `artbeat_settings -> artbeat_events` package dependencies

Why:

- `artbeat_events` had no source-level usage in `packages/artbeat_settings`
- `artbeat_artist` was only used to directly construct onboarding UI
- settings now routes to the host app's artist onboarding route instead of
  importing artist package UI

### 2026-03-18: `artbeat_capture` no longer depends on `artbeat_ads` or `artbeat_profile`

Decision:

- remove the direct `artbeat_capture -> artbeat_ads` and
  `artbeat_capture -> artbeat_profile` package dependencies

Why:

- no source-level usage remained in `packages/artbeat_capture` for those
  packages
- keeping unused feature-package dependencies makes the graph look more coupled
  than the runtime actually is

### 2026-03-18: `artbeat_artwork` no longer depends on `artbeat_profile`

Decision:

- remove the direct `artbeat_artwork -> artbeat_profile` package dependency

Why:

- no source-level usage remained in `packages/artbeat_artwork`
- keeping unused feature-package dependencies makes the graph look more coupled
  than the runtime actually is

### 2026-03-18: `artbeat_artist` no longer depends on `artbeat_ads`

Decision:

- remove the direct `artbeat_artist -> artbeat_ads` package dependency

Why:

- no source-level usage remained in `packages/artbeat_artist`
- keeping unused feature-package dependencies makes the graph look more coupled
  than the runtime actually is

### 2026-03-18: `artbeat_artwork` no longer depends on `artbeat_events`

Decision:

- remove the direct `artbeat_artwork -> artbeat_events` package dependency

Why:

- no source-level usage remained in `packages/artbeat_artwork`
- keeping unused feature-package dependencies makes the graph look more coupled
  than the runtime actually is

### 2026-03-18: `artbeat_capture` no longer depends on `artbeat_art_walk`

Decision:

- remove the direct `artbeat_capture -> artbeat_art_walk` package dependency
- keep art-walk reward/challenge/social behavior behind a
  `CapturePostCaptureHooks` interface owned by `artbeat_capture`
- provide the concrete art-walk implementation from the app shell

Why:

- the dependency was real, but it was orchestration and cross-feature behavior,
  not core capture domain state
- root `lib/` is the right place to compose capture behavior with art-walk
  services

### 2026-03-18: artwork management route ownership moved out of `artbeat_artist`

Decision:

- remove the duplicate `MyArtworkScreen` from `artbeat_artist`
- let the host app route `artistArtwork` to
  `artbeat_artwork`'s `ArtistArtworkManagementScreen`

Why:

- the artwork package already owned the consolidated replacement screen
- this reduces duplicated UI ownership between artist and artwork
- route composition belongs in the host app, not in sideways package exports

### 2026-03-18: `ArtistPublicProfileScreen` now uses artist-local artwork data

Decision:

- switch `artbeat_artist`'s `ArtistPublicProfileScreen` off
  `artbeat_artwork` models and services
- keep the screen on artist-local artwork types for public profile rendering

Why:

- the screen needs artwork data, but not artwork-owned UI components
- this reduces sideways package coupling while keeping route behavior unchanged

### 2026-03-18: `GalleryHubScreen` now routes artwork flows through the app shell

Decision:

- stop constructing `artbeat_artwork` screens directly inside
  `GalleryHubScreen`
- route artwork management and auction setup through shared app routes instead

Why:

- the artist package should trigger flows, not own cross-feature screen
  composition
- this reduces direct UI coupling between `artbeat_artist` and
  `artbeat_artwork`

### 2026-03-18: `AuctionHubScreen` now uses artist-local auction data and app-shell routes

Decision:

- switch `AuctionHubScreen` off `artbeat_artwork` models
- route auction management and setup through shared app routes instead of
  constructing artwork package UI directly in the artist package

Why:

- the artist package can render auction summaries from local data without
  depending on artwork-package model types
- cross-feature auction UI composition belongs in the app shell

### 2026-03-18: `artbeat_artist` no longer depends on `artbeat_artwork`

Decision:

- remove the direct `artbeat_artist -> artbeat_artwork` package dependency

Why:

- no source-level imports remain in `packages/artbeat_artist`
- artwork management, public profile artwork rendering, gallery-hub artwork
  flows, and auction-hub UI composition were all moved off direct artwork
  package ownership first

### 2026-03-18: `artbeat_artwork` no longer depends on `artbeat_artist`

Decision:

- remove the direct `artbeat_artwork -> artbeat_artist` package dependency

Why:

- artwork upload and detail flows now use `artbeat_core` artist/subscription
  services and an artwork-local visibility tracker
- no source-level imports remain in `packages/artbeat_artwork`

### 2026-03-18: `artbeat_core` now owns almost all former `artbeat_art_walk` reads and writes

Decision:

- move achievement, progression, social-activity, daily-challenge,
  nearby-art, and discovery-progress behavior used by `artbeat_core` into
  core-local models and services
- leave only the temporary XP repair widget on the old `artbeat_art_walk`
  package surface for now

Why:

- the remaining core-side art-walk usage was mostly convenience reads/writes,
  not art-walk-owned UI composition
- moving those paths into `artbeat_core` keeps the base package from staying
  coupled to a feature package just to power dashboard and engagement behavior
- the only remaining exception is clearly temporary tooling, which can be
  handled last without broad product risk

### 2026-03-18: `artbeat_profile` dropped four unused feature dependencies

Decision:

- remove the direct `artbeat_profile -> artbeat_ads`
- remove the direct `artbeat_profile -> artbeat_artist`
- remove the direct `artbeat_profile -> artbeat_artwork`
- remove the direct `artbeat_profile -> artbeat_community`

Why:

- no source-level imports remained for those packages in
  `packages/artbeat_profile`
- this shrinks `artbeat_profile` to the dependencies it actually uses before
  deeper refactor work starts

### 2026-03-18: `artbeat_profile` no longer depends on `artbeat_auth`

Decision:

- remove the direct `artbeat_profile -> artbeat_auth` package dependency

Why:

- the remaining usage was only auth sign-out and post-auth route constants
- `artbeat_core` already provides `AuthService` and shared route constants for
  those flows

### 2026-03-18: `artbeat_profile` no longer depends on `artbeat_capture`

Decision:

- remove the direct `artbeat_profile -> artbeat_capture` package dependency
- consume `CaptureServiceInterface` from the app shell instead of importing the
  concrete capture package directly

Why:

- profile only needed read access to a user's captures for profile display
- `artbeat_core` already defines the capture interface and model types for this
  use case
- concrete feature composition belongs in root `lib/`, not in sideways
  package dependencies

### 2026-03-18: `artbeat_profile` no longer depends on `artbeat_art_walk`

Decision:

- remove the direct `artbeat_profile -> artbeat_art_walk` package dependency
- replace art-walk achievement, badge, and challenge reads with profile-local
  read models and services
- keep profile's daily challenge view read-only; profile no longer creates
  challenge state as a side effect

Why:

- the remaining coupling was presentation-side read logic, not ownership of
  art-walk feature workflows
- moving those read models into profile removes the last sideways feature
  dependency from the package
- challenge creation belongs with art-walk domain behavior, not with profile
  display code

### 2026-03-18: `artbeat_community` no longer depends on `artbeat_messaging`

Decision:

- remove the direct `artbeat_community -> artbeat_messaging` package
  dependency
- route community user-profile handoff through `AppRoutes.messagingUser`
  instead of constructing messaging package screens directly

Why:

- the remaining usage was navigation/composition, not community-owned
  messaging domain logic
- root routing is the right place to connect community and messaging flows

### 2026-03-18: `artbeat_community` no longer depends on `artbeat_artist`

Decision:

- remove the direct `artbeat_community -> artbeat_artist` package dependency
- route artist onboarding through `AppRoutes.artistOnboarding`
- move artist follow/unfollow behavior into community's own service layer
- replace commission-browser artist-name lookup with a local Firestore read
  using core artist models

Why:

- the remaining community usage was screen composition and simple profile/name
  reads, not ownership of artist package workflows
- community already owns artist discovery and follow UX, so those service calls
  belong with community's data layer
- app-shell routing is the correct place to launch artist onboarding

### 2026-03-18: `artbeat_community` no longer depends on `artbeat_admin`

Decision:

- remove the direct `artbeat_community -> artbeat_admin` package dependency
- route leaderboard, community moderation, and admin dashboard entry points
  through shared app routes instead of constructing admin screens directly

Why:

- the remaining usage was navigation/composition, not community-owned admin
  logic
- admin surfaces already have canonical routes in the app shell

### 2026-03-18: `artbeat_community` no longer depends on `artbeat_events`

Decision:

- remove the direct `artbeat_community -> artbeat_events` package dependency
- replace artist-feed event reads with a community-local Firestore reader built
  on `core.EventModel`

Why:

- community only needed a narrow read path for recent artist events
- `core.EventModel` already provides the event shape community needs
- this removes another sideways feature dependency without moving event domain
  ownership into community

### 2026-03-18: `artbeat_community` no longer depends on `artbeat_artwork`

Decision:

- remove the direct `artbeat_community -> artbeat_artwork` package dependency
- route artwork browse, discovery, and detail launches through shared app
  routes
- replace artist-feed artwork reads with a community-local Firestore reader

Why:

- the remaining usage was a mix of route composition and a narrow read path
- community already has its own artwork display models for feed UI
- this keeps artwork ownership out of community while reducing another
  sideways feature dependency

### 2026-03-18: `artbeat_community` no longer depends on `artbeat_art_walk`

Decision:

- remove the direct `artbeat_community -> artbeat_art_walk` package
  dependency
- replace social-activity reads with a community-local read service and
  community-local activity types

Why:

- the remaining coupling was a narrow social-feed read path, not ownership of
  art-walk exploration or rewards flows
- community only needed activity feed data from `socialActivities`
- moving that read layer into community removes the last non-ad/widget feature
  dependency from the package without shifting art-walk domain ownership

### 2026-03-18: `artbeat_art_walk` no longer depends on `artbeat_ads`, `artbeat_community`, or `artbeat_profile`

Decision:

- remove the direct `artbeat_art_walk -> artbeat_ads` package dependency
- remove the direct `artbeat_art_walk -> artbeat_community` package
  dependency
- remove the direct `artbeat_art_walk -> artbeat_profile` package dependency

Why:

- no source-level usage remained for those packages in `artbeat_art_walk`
- keeping stale manifest edges makes the graph look denser than the runtime
  actually is
- this narrows the remaining art-walk refactor surface to the packages it
  really uses: `capture`, `settings`, and `sponsorships`

### 2026-03-18: `artbeat_art_walk` no longer depends on `artbeat_events`

Decision:

- remove the direct `artbeat_art_walk -> artbeat_events` package dependency
- use the art-walk-local `GradientCTAButton` in the create flow instead of
  borrowing the events package widget

Why:

- the remaining events usage was presentational only
- `artbeat_art_walk` already owns an equivalent CTA component
- this keeps the remaining art-walk dependency set focused on real domain
  integrations instead of shared UI residue

### 2026-03-18: `artbeat_art_walk` no longer depends on `artbeat_settings`

Decision:

- remove the direct `artbeat_art_walk -> artbeat_settings` package dependency
- replace the create-flow settings read with an art-walk-local distance-unit
  preference service that reads the existing `userSettings` document

Why:

- the remaining settings usage was a narrow preference read for `distanceUnit`
- `artbeat_art_walk` did not need the settings package's broader service/model
  surface to support that behavior
- this preserves the same stored preference source while removing another
  sideways feature dependency

### 2026-03-18: `artbeat_art_walk` no longer depends on `artbeat_capture`

Decision:

- remove the direct `artbeat_art_walk -> artbeat_capture` package dependency
- replace screen-level capture reads with an art-walk-local capture read
  service built on Firestore and core `CaptureModel`

Why:

- the remaining capture usage was read-heavy map, dashboard, and create-flow
  access rather than capture-creation ownership
- `CaptureModel` already lives in core, which let art-walk keep its local map
  and clustering behavior without importing the capture package
- this leaves `artbeat_art_walk` with only the sponsorship integration as a
  non-core feature dependency

### 2026-03-18: `artbeat_admin` no longer depends on `artbeat_messaging`

Decision:

- remove the direct `artbeat_admin -> artbeat_messaging` package dependency
- move admin broadcast sending into an admin-local service

Why:

- the remaining messaging usage in admin was a narrow broadcast write path
  against `broadcasts` and `admin_activity`
- admin platform curation did not need messaging chat models or UI to send
  those announcements
- this reduces another sideways feature dependency without changing the
  existing broadcast data shape

### 2026-03-18: `artbeat_admin` no longer depends on `artbeat_ads`

Decision:

- remove the direct `artbeat_admin -> artbeat_ads` package dependency
- move local ad moderation reads and writes into admin-local models and a
  Firestore moderation service

Why:

- admin only needed a narrow ads moderation surface: pending ads, ad stats,
  pending reports, and approve/reject/report-review writes
- that did not justify importing ads package models and services into the
  admin widget
- this keeps admin moderation logic in the admin package while preserving the
  existing `localAds` and `ad_reports` collections

### 2026-03-18: `artbeat_admin` no longer depends on `artbeat_events`

Decision:

- remove the direct `artbeat_admin -> artbeat_events` package dependency
- move the event moderation dashboard onto admin-local models and an admin
  Firestore moderation service

Why:

- admin only needed a narrow moderation surface for events: flagged, pending,
  and approved reads, review actions, analytics, and deletion
- that did not justify importing event package models and services into the
  admin moderation screen
- this keeps moderation ownership inside admin while preserving the existing
  `events` and `event_flags` collections

### 2026-03-18: `artbeat_admin` no longer depends on `artbeat_community`

Decision:

- remove the direct `artbeat_admin -> artbeat_community` package dependency
- move the community moderation queue onto admin-local moderation models and an
  admin Firestore service

Why:

- admin only needed the flagged post/comment queue plus approve/remove writes
- that did not justify importing community models and services into the admin
  moderation screen
- this keeps moderation ownership inside admin while preserving the existing
  `posts` and `comments` collections

### 2026-03-18: `artbeat_admin` no longer depends on `artbeat_capture`

Decision:

- remove the direct `artbeat_admin -> artbeat_capture` package dependency
- move capture moderation queries/actions and the geo-backfill helper into an
  admin-local Firestore service

Why:

- admin only needed pending/reported/status capture reads, approve/reject/delete
  writes, and the capture geo backfill migration helper
- that did not justify importing capture package services into admin screens
  and migration logic
- this keeps admin moderation ownership inside admin while preserving the
  existing `captures` collection shape

### 2026-03-18: `artbeat_admin` no longer depends on `artbeat_art_walk`

Decision:

- remove the direct `artbeat_admin -> artbeat_art_walk` package dependency
- move the art-walk moderation list/actions into an admin-local Firestore
  service and admin-local model

Why:

- admin only needed all/reported art-walk reads plus clear-reports and delete
  actions
- that did not justify importing art-walk models and services into the admin
  moderation screen
- this keeps moderation ownership inside admin while preserving the existing
  `artWalks` collection shape

### 2026-03-18: `artbeat_admin` no longer depends on `artbeat_artwork`

Decision:

- remove the direct `artbeat_admin -> artbeat_artwork` package dependency
- move admin-specific artwork moderation, featured-artwork curation, and
  chapter-count updates into admin-local models and services

Why:

- admin only needed a narrow artwork surface for moderation and curation, plus
  a small helper for keeping chapter counts in sync after chapter moderation
- that did not justify importing artwork package services and models into admin
  screens and services
- this leaves `artbeat_admin` depending only on `artbeat_core`

### 2026-03-18: `artbeat_core` no longer depends on `artbeat_auth`,
`artbeat_settings`, or `artbeat_sponsorships`

Decision:

- remove the stale `artbeat_core -> artbeat_auth` package dependency
- remove the stale `artbeat_core -> artbeat_settings` package dependency
- remove the stale `artbeat_core -> artbeat_sponsorships` package dependency

Why:

- the core package no longer imports any source from those three packages
- removing manifest residue lowers the `artbeat_core` dependency count before
  the harder UI and service ownership cuts
- this leaves `artbeat_core` with only the sibling packages it still imports
  directly today

### 2026-03-18: `artbeat_core` no longer depends on `artbeat_profile`

Decision:

- remove the direct `artbeat_core -> artbeat_profile` package dependency
- route the universal header profile action through `AppRoutes.profileMenu`
  instead of constructing profile UI directly

Why:

- the only remaining core usage was a direct `ProfileMenuScreen` import in the
  header
- shared routes already existed for the profile menu, so the direct UI import
  was unnecessary
- this is the lowest-risk real `artbeat_core` coupling cut because it changes
  navigation ownership without changing profile behavior

### 2026-03-18: `artbeat_core` no longer depends on `artbeat_admin`

Decision:

- remove the direct `artbeat_core -> artbeat_admin` package dependency
- change the developer menu to use shared admin routes instead of constructing
  admin screens directly

Why:

- the only remaining core usage was direct admin screen construction in the
  developer menu
- the app router already owned those admin destinations, so the direct UI
  import was unnecessary
- this is another low-risk `artbeat_core` cut because it changes composition
  ownership without changing admin behavior

### 2026-03-18: `artbeat_core` no longer depends on `artbeat_ads`

Decision:

- remove the direct `artbeat_core -> artbeat_ads` package dependency
- move the runtime ads screen into the app shell and keep only a preview card
  in core for the store surface

Why:

- the remaining core-side ads usage was a single screen plus the store preview
- route ownership already lived in the app shell, so the runtime screen did not
  need to remain inside `artbeat_core`
- this keeps core reusable UI while moving the feature-owned purchase flow back
  to the host app layer

### 2026-03-18: `artbeat_core` no longer depends on `artbeat_capture`

Decision:

- remove the direct `artbeat_core -> artbeat_capture` package dependency
- route the animated dashboard capture entry through
  `AppRoutes.captureDashboard` instead of constructing capture UI directly

Why:

- the remaining core-side capture usage was a single direct
  `EnhancedCaptureDashboardScreen` construction in the animated dashboard
- the app router already owned capture destinations, so this was a composition
  leak rather than a real core runtime dependency
- this removes another thin feature edge before tackling the heavier
  dashboard-viewmodel couplings

### 2026-03-18: `artbeat_core` no longer depends on `artbeat_artist`

Decision:

- remove the direct `artbeat_core -> artbeat_artist` package dependency
- move dashboard artist loading onto core `ArtistService`
- use the existing community service for artist follow/unfollow mutations

Why:

- the remaining core-side artist usage was confined to `DashboardViewModel`
- core already owned artist-profile read logic, and community already owned the
  follow/unfollow writes needed here
- this removes another dashboard-viewmodel coupling without broadening the app
  shell or adding new cross-package abstractions

### 2026-03-18: `artbeat_core` no longer depends on `artbeat_events`

Decision:

- remove the direct `artbeat_core -> artbeat_events` package dependency
- replace dashboard upcoming-event reads with a core-local Firestore reader
  that returns `EventModel` directly

Why:

- the remaining core-side events usage was confined to `DashboardViewModel`
- core already had the canonical `EventModel`, so borrowing the events package
  service only for a read query was unnecessary
- this keeps the dashboard on core-owned read models and reduces provider
  wiring in the app shell

### 2026-03-18: `artbeat_core` no longer depends on `artbeat_messaging`

Decision:

- remove the direct `artbeat_core -> artbeat_messaging` package dependency
- move unread-count and user block/unblock operations onto small core-local
  Firestore/Auth services

Why:

- the remaining core-side messaging usage was limited to unread badges and user
  moderation helpers
- those operations were narrow Firestore/Auth queries, not full messaging UI or
  chat-domain logic
- this removes another thin feature edge while leaving the app shell free to
  keep using the messaging package where real chat screens are needed

### 2026-03-18: `artbeat_core` no longer depends on `artbeat_community`

Decision:

- remove the direct `artbeat_core -> artbeat_community` package dependency
- move post-feed reads and commission-artist preview data into small core-local
  Firestore read services
- route prefilled post creation through the app router instead of constructing
  community UI directly inside core

Why:

- the remaining core-side community usage was a mix of post previews,
  commission preview UI, and direct `CreatePostScreen` launches
- those behaviors only needed small read models and shared route handoff, not
  the broader community package surface
- this removes another dashboard/store coupling and leaves `artbeat_core` with
  only the heavier `art_walk` and `artwork` edges

### 2026-03-18: `artbeat_core` no longer depends on `artbeat_artwork`

Decision:

- remove the direct `artbeat_core -> artbeat_artwork` package dependency
- move dashboard artwork/book reads behind a core-local `ArtworkReadService`
- standardize core artwork filtering on core `ArtworkModel`

Why:

- the remaining core-side artwork usage had already been narrowed to read paths
  in `DashboardViewModel` and `FilterService`
- those flows needed Firestore queries and core models, not artwork-owned UI or
  service types
- this removes the last non-`art_walk` feature dependency from `artbeat_core`

### 2026-03-18: `artbeat_core` owns its achievement read model again

Decision:

- move core achievement reads back onto `artbeat_core`'s own
  `AchievementModel`
- stop importing `artbeat_art_walk`'s internal achievement model file from core

Why:

- the dashboard user section and user service only needed the achievement read
  shape, title, description, and icon mapping
- that data is presentation-side state owned by core's dashboard UI, not a
  reason to depend on another package's internal model path
- this narrows the remaining `artbeat_core -> artbeat_art_walk` work to the
  real service layer: progression, activity feed, challenge reads, and
  nearby-art map queries

### 2026-03-18: `artbeat_core` now owns progression metadata and daily login tracking

Decision:

- move level-title, perk, and XP-progress logic into a core-local
  `UserProgressionService`
- move the daily-login streak transaction used by core surfaces into that same
  service

Why:

- the dashboard, leaderboard, drawer, and user experience card only needed
  progression metadata and login-streak updates, not the broader art-walk
  rewards surface
- this removes another set of convenience imports from core and leaves the
  remaining `artbeat_core -> artbeat_art_walk` work concentrated in activity,
  challenge, and nearby-art reads

### 2026-03-18: `artbeat_core` now owns activity and challenge reads

Decision:

- move dashboard social-activity reads onto a core-local
  `SocialActivityReadService` and `SocialActivityModel`
- move dashboard challenge reads onto a core-local
  `DailyChallengeReadService` and `DailyChallengeModel`

Why:

- the dashboard VM and engagement widgets only needed read access to activity
  feed and daily challenge documents
- those surfaces did not need the broader art-walk service layer or its model
  exports just to render core-owned UI
- this narrows the remaining `artbeat_core -> artbeat_art_walk` work to
  nearby-art discovery/map queries and a small number of write-side hooks

### 2026-03-18: `artbeat_core` now owns nearby-art and discovery-progress reads

Decision:

- move nearby public-art queries onto a core-local `PublicArtReadService`
- move dashboard discovery-count/streak/weekly-progress reads onto a core-local
  `DiscoveryProgressReadService`

Why:

- the dashboard VM and hero section only needed read access to nearby public
  art and user discovery stats
- those surfaces did not need the broader art-walk discovery service layer once
  the read shapes were isolated
- this leaves the remaining `artbeat_core -> artbeat_art_walk` dependency as a
  small set of write-side or temporary exceptions rather than a live read
  cluster

## Usage Rule

Add a new entry when:

- a change affects where code should live
- a workflow becomes standard
- a dependency exception is granted
- a release/process rule changes permanently
