# ARTbeat Status And Next Steps

This file replaces the original repo review with the current execution status.
The original conclusion still stands: this app does not need a rewrite. It
needs controlled consolidation, safer boundaries, cleaner operational
workflows, and lower release risk.

## Bottom Line

Major progress has been made on the highest-risk architecture issue:
cross-package coupling.

The repo is now materially safer to change than it was when the review started.
The biggest win is that `artbeat_core` has been reduced from a broad
cross-feature hub to a nearly clean base package.

## What Is Done

### Documentation and operating structure

- Canonical project-control docs now exist under `docs/`.
- Active work is tracked in `docs/WORK_QUEUE.md`.
- Architecture and dependency policy are tracked in:
  - `docs/ARCHITECTURE.md`
  - `docs/DEPENDENCY_RULES.md`
  - `docs/PACKAGE_DEPENDENCY_INVENTORY.md`
  - `docs/DECISIONS.md`

### Localization workflow

- English is treated as the canonical locale source.
- Locale parity is now enforced with:
  - `tools/localization/report_missing_keys.py`
  - `test/localization_key_parity_test.dart`
- `assets/translations/missing_keys.md` is now generated from actual locale state instead of hand-maintained notes.

### Repo hygiene

- Ignore coverage and cleanup policy were improved.
- Archived docs and tool destinations were created.
- Accidental nested git residue under `packages/artbeat_admin/.git` was removed.
- Root clutter has been reduced in stages.

This work is not finished yet.

### Package boundary repair

This has been the main area of progress.

Completed package cleanup highlights:

- `artbeat_profile` now depends only on `artbeat_core`
- `artbeat_admin` now depends only on `artbeat_core`
- `artbeat_auth` now depends only on `artbeat_core`
- `artbeat_messaging` now depends only on `artbeat_core`
- `artbeat_settings` now depends only on `artbeat_core`
- `artbeat_ads` now depends only on `artbeat_core`

Major cross-feature cuts completed:

- `artbeat_auth -> artbeat_profile`
- `artbeat_events -> artbeat_auth`
- `artbeat_settings -> artbeat_artist/events`
- `artbeat_capture -> artbeat_art_walk`
- `artbeat_artist <-> artbeat_artwork`
- `artbeat_profile -> artbeat_auth/capture/art_walk`
- `artbeat_community -> messaging/artist/admin/events/artwork/art_walk`
- `artbeat_art_walk -> ads/community/profile/events/settings/capture`
- `artbeat_admin -> messaging/ads/events/community/capture/art_walk/artwork`

### `artbeat_core` reduction

This was the original highest-leverage architecture problem.

`artbeat_core` no longer depends on:

- `artbeat_auth`
- `artbeat_settings`
- `artbeat_sponsorships`
- `artbeat_profile`
- `artbeat_admin`
- `artbeat_ads`
- `artbeat_capture`
- `artbeat_artist`
- `artbeat_events`
- `artbeat_messaging`
- `artbeat_community`
- `artbeat_artwork`

Core now owns most of the read/write surfaces it previously borrowed from other
feature packages:

- artwork reads
- event reads
- artist reads
- community post reads
- commission previews
- unread messaging status
- user blocking
- achievement reads
- progression metadata
- daily challenge reads
- social activity reads
- nearby art reads
- discovery progress reads

Only one `artbeat_core -> artbeat_art_walk` dependency remains, and it is now
temporary tooling rather than live app behavior.

## Current Graph Snapshot

From `docs/PACKAGE_DEPENDENCY_INVENTORY.md`:

- `artbeat_core` still depends on `artbeat_art_walk`
- `artbeat_admin`, `artbeat_profile`, `artbeat_auth`, `artbeat_messaging`,
  `artbeat_settings`, and `artbeat_ads` depend only on `artbeat_core`
- the remaining higher-coupling feature packages are:
  - `artbeat_artist`
  - `artbeat_artwork`
  - `artbeat_sponsorships`
  - `artbeat_events`
  - `artbeat_art_walk`

## What Is Still In Progress

### 1. Finish repo hygiene

Still open:

- remaining tracked root cleanup
- final decision on `packages/artbeat_profile/ios`
- continued separation of durable source from local/generated artifacts

Primary tracking doc:

- `docs/REPO_HYGIENE.md`

### 2. Finish `artbeat_core` cleanup

Only one live manifest edge remains:

- `artbeat_core -> artbeat_art_walk`

Current reason:

- temporary XP repair tool at `packages/artbeat_core/lib/src/widgets/temp_xp_fix.dart`

Next action:

- replace the `RewardsService` usage there with a core-local equivalent, or
- delete/archive the temporary tool if it is no longer needed

Then:

- remove `artbeat_art_walk` from `packages/artbeat_core/pubspec.yaml`

### 3. Compliance and release follow-up

Still open:

- legal/security follow-up items
- production canary sign-off completion
- admin deletion fulfillment reliability

Primary trackers:

- `docs/WORK_QUEUE.md`
- `docs/KNOWN_ISSUES.md`

### 4. Backend/rules cleanup

Still largely untouched:

- split large function domains under `functions/src/index.js`
- clarify `dataconnect/`
- strengthen backend/rules testing discipline

## Recommended Next Phase

Do not continue broad refactors by default.

Recommended order:

1. Finish the last `artbeat_core -> artbeat_art_walk` dependency.
2. Complete repo hygiene decisions and cleanup.
3. Address legal/security and release-process follow-up.
4. Start backend/functions modularization only after the above is stable.

## What Good Looks Like Now

For this app, success is:

- predictable change impact
- lower release anxiety
- a clean app-shell boundary
- fewer cross-package surprises
- repeatable translation, testing, and release workflows
- `artbeat_core` acting like a true shared foundation

That is already much closer than it was at the start of this review.
