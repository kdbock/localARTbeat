# ARTbeat Architecture

## Purpose

Describe how the app is structured today, where code should live, and what
boundaries we are trying to enforce as the codebase matures.

## System Overview

ARTbeat is a Flutter application with:

- root app shell in `lib/`
- 14 local Flutter feature packages in `packages/`
- Firebase Functions backend in `functions/`
- Firebase config, rules, and indexes at repo root
- platform projects in `android/`, `ios/`, `web/`, `linux/`, `macos/`,
  `windows/`

Primary startup and composition files:

- `lib/main.dart`
- `lib/app.dart`
- `lib/src/routing/app_router.dart`

Primary backend and rules files:

- `functions/src/index.js`
- `firebase.json`
- `firestore.rules`
- `storage.rules`

## App Shell

The root `lib/` directory is the application shell.

It owns:

- Flutter startup
- Firebase/bootstrap wiring
- localization initialization
- provider composition
- route registration
- app-level screens that are not reusable package features
- top-level integration between features

It should not become the place where all business logic lives.

## Package Map

Current package responsibilities:

- `artbeat_core`
  - shared theme, models, widgets, services, utilities, route constants
- `artbeat_auth`
  - login, registration, auth flows
- `artbeat_profile`
  - user profile and social graph profile surfaces
- `artbeat_artist`
  - artist tools, earnings, subscriptions, gallery flows
- `artbeat_artwork`
  - artwork upload, discovery, auctions, collections
- `artbeat_capture`
  - capture workflows, camera, offline queue
- `artbeat_community`
  - social feed, posts, commissions, community flows
- `artbeat_art_walk`
  - location-based discovery, challenges, walk progression
- `artbeat_events`
  - event CRUD, ticketing, reminders, event discovery
- `artbeat_messaging`
  - chats, presence, reactions, conversation screens
- `artbeat_ads`
  - local advertising workflows
- `artbeat_settings`
  - settings, privacy/security preferences, data requests
- `artbeat_sponsorships`
  - sponsorship placement and business promotion flows
- `artbeat_admin`
  - moderation, admin dashboards, system ops surfaces

## Current Architectural Reality

The repo is package-organized but not strictly layered.

Current problems:

- `artbeat_core` depends on many sibling feature packages.
- feature packages depend on other feature packages.
- orchestration and reusable code are mixed together.
- repo source and generated/local artifacts are not cleanly separated.

This means the codebase behaves more like one large app split into packages than
like a clean modular monorepo.

## Target Architectural Direction

We are not rewriting the app. We are moving toward a safer dependency shape.

Target rules:

1. `artbeat_core` should contain only shared primitives and low-level shared
   services.
2. feature packages should depend on `artbeat_core`, not on each other by
   default.
3. the root app shell should compose features together.
4. cross-feature workflows should be coordinated in the app shell or through a
   narrow shared interface, not through broad direct imports.

## What Belongs In `artbeat_core`

Allowed:

- shared models used by multiple features
- design system and theme
- low-level utility services
- environment/config helpers
- logging, analytics, navigation primitives
- shared widgets that are truly generic

Not allowed going forward:

- feature-specific screens
- feature-specific business workflows
- direct ownership of artist/artwork/community/settings-specific orchestration
- code that exists only because two features are tightly coupled today

## Backend Architecture

Firebase is the primary backend platform.

Current backend pieces:

- Cloud Functions in `functions/`
- Firestore rules in `firestore.rules`
- Storage rules in `storage.rules`
- Data Connect config in `dataconnect/`

Target direction:

- group functions by domain
- treat rules and functions as first-class production systems
- add stronger automated verification around security-sensitive changes

## Localization Architecture

Localization currently uses `easy_localization` with assets in
`assets/translations/`.

Rules:

- English is the canonical source locale.
- new keys must be added to English first.
- locale parity must be validated automatically.
- `assets/translations/missing_keys.md` is a tracking aid, not the source of
  truth.

## Documentation Ownership

The canonical process docs are:

- `docs/ROADMAP.md`
- `docs/WORK_QUEUE.md`
- `docs/TEST_STRATEGY.md`
- `docs/RELEASE_CHECKLIST.md`
- `docs/DEPENDENCY_RULES.md`
- `docs/DECISIONS.md`

If this architecture doc and the code diverge, update the doc as part of the
same work.
