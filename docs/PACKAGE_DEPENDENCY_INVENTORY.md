# Package Dependency Inventory

## Purpose

Record the current package-to-package dependency graph so architecture work can
start from the actual repo state.

Source:

- `packages/*/pubspec.yaml`

## Current Graph

### `artbeat_admin`

Depends on:

- `artbeat_core`

### `artbeat_ads`

Depends on:

- `artbeat_core`

### `artbeat_art_walk`

Depends on:

- `artbeat_core`
- `artbeat_sponsorships`

### `artbeat_artist`

Depends on:

- `artbeat_core`
- `artbeat_events`
- `artbeat_community`

### `artbeat_artwork`

Depends on:

- `artbeat_core`
- `artbeat_art_walk`
- `artbeat_ads`

### `artbeat_auth`

Depends on:

- `artbeat_core`

### `artbeat_capture`

Depends on:

- `artbeat_sponsorships`
- `artbeat_core`

### `artbeat_community`

Depends on:

- `artbeat_core`
- `artbeat_ads`

### `artbeat_core`

Depends on:
- no sibling feature packages

### `artbeat_events`

Depends on:

- `artbeat_core`
- `artbeat_ads`
- `artbeat_sponsorships`

### `artbeat_messaging`

Depends on:

- `artbeat_core`

### `artbeat_profile`

Depends on:

- `artbeat_core`

### `artbeat_settings`

Depends on:

- `artbeat_core`

### `artbeat_sponsorships`

Depends on:

- `artbeat_art_walk`
- `artbeat_auth`
- `artbeat_core`

## Violations Against Target Rules

Target rules from `docs/DEPENDENCY_RULES.md`:

- `artbeat_core` should not depend on feature packages
- feature packages should not depend on other feature packages by default

### Critical Violation: `artbeat_core`

`artbeat_core` currently depends on 0 sibling feature packages.

This is the highest-leverage architecture problem in the repo because it turns
the intended base layer into a cross-feature hub.

### High-Coupling Feature Packages

These packages currently have especially broad feature-to-feature coupling:

- `artbeat_artwork`
- `artbeat_artist`

### Apparent Cycles / Mutual Coupling

Examples of mutual or near-mutual coupling:

- `artbeat_sponsorships` <-> `artbeat_art_walk` (direct one-way in manifest,
  but highly integrated)

Even where formal cycles are not complete at the manifest level, the graph is
dense enough that change impact is still broad.

## Lowest-Risk Refactor Order

Do not start with the most tangled package. Start where isolation gain is high
and blast radius is smaller.

### Stage 1

- stop adding new feature-specific code to `artbeat_core`
- completed: remove `artbeat_auth -> artbeat_profile`
- completed: remove `artbeat_events -> artbeat_auth`
- completed: remove `artbeat_settings -> artbeat_artist/events`

### Stage 2

- completed: remove `artbeat_capture -> artbeat_art_walk` via app-shell hooks
- completed: remove `artbeat_artist -> artbeat_artwork`
- completed: remove `artbeat_artwork -> artbeat_artist`
- completed: remove `artbeat_artwork -> artbeat_profile`
- completed: remove `artbeat_artist -> artbeat_ads`
- completed: remove `artbeat_artwork -> artbeat_events`

### Stage 3

- break up `artbeat_profile`, `artbeat_community`, and `artbeat_art_walk`
  dependency sprawl
- completed: remove `artbeat_profile -> artbeat_ads`
- completed: remove `artbeat_profile -> artbeat_artist`
- completed: remove `artbeat_profile -> artbeat_artwork`
- completed: remove `artbeat_profile -> artbeat_community`
- completed: remove `artbeat_profile -> artbeat_auth`
- completed: remove `artbeat_profile -> artbeat_capture`
- completed: remove `artbeat_profile -> artbeat_art_walk`
- completed: remove `artbeat_community -> artbeat_messaging`
- completed: remove `artbeat_community -> artbeat_artist`
- completed: remove `artbeat_community -> artbeat_admin`
- completed: remove `artbeat_community -> artbeat_events`
- completed: remove `artbeat_community -> artbeat_artwork`
- completed: remove `artbeat_community -> artbeat_art_walk`
- completed: remove `artbeat_art_walk -> artbeat_ads`
- completed: remove `artbeat_art_walk -> artbeat_community`
- completed: remove `artbeat_art_walk -> artbeat_profile`
- completed: remove `artbeat_art_walk -> artbeat_events`
- completed: remove `artbeat_art_walk -> artbeat_settings`
- completed: remove `artbeat_art_walk -> artbeat_capture`
- completed: remove `artbeat_admin -> artbeat_messaging`
- completed: remove `artbeat_admin -> artbeat_ads`
- completed: remove `artbeat_admin -> artbeat_events`
- completed: remove `artbeat_admin -> artbeat_community`
- completed: remove `artbeat_admin -> artbeat_capture`
- completed: remove `artbeat_admin -> artbeat_art_walk`
- completed: remove `artbeat_admin -> artbeat_artwork`
- move orchestration up to the app shell where appropriate

### Stage 4

- completed: remove stale `artbeat_core -> artbeat_auth`
- completed: remove stale `artbeat_core -> artbeat_settings`
- completed: remove stale `artbeat_core -> artbeat_sponsorships`
- completed: remove `artbeat_core -> artbeat_profile`
- completed: remove `artbeat_core -> artbeat_admin`
- completed: remove `artbeat_core -> artbeat_ads`
- completed: remove `artbeat_core -> artbeat_capture`
- completed: remove `artbeat_core -> artbeat_artist`
- completed: remove `artbeat_core -> artbeat_events`
- completed: remove `artbeat_core -> artbeat_messaging`
- completed: remove `artbeat_core -> artbeat_community`
- completed: remove `artbeat_core -> artbeat_artwork`
- completed: narrow `artbeat_core -> artbeat_art_walk` to temporary tooling
- completed: remove all feature dependencies from `artbeat_core`

## Working Rule

No new package dependency should be added without updating:

- `docs/DECISIONS.md`
- `docs/WORK_QUEUE.md` if it changes refactor priority

This inventory should be updated whenever package manifests change materially.
