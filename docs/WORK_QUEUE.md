# ARTbeat Work Queue

## Purpose

Track active engineering work in one place with enough detail to execute and
ship safely.

Status values:

- `todo`
- `in_progress`
- `blocked`
- `done`

Risk values:

- `low`
- `medium`
- `high`

## Active Queue

| Task | Status | Risk | Area | Release Impact | Test Needed | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| Create canonical project docs and operating system | done | low | repo/process | none | doc review | Canonical docs created under `docs/` |
| Clean repo root and separate source from generated/local artifacts | in_progress | medium | repo hygiene | indirect | smoke + git review | Safe phase started: ignore coverage, destination folders, cleanup policy |
| Define and enforce package dependency rules | in_progress | high | architecture | indirect | analyze + targeted regression | Policy exists; Stage 1 cuts are done. Stage 2 cleanup cuts are landing, and the remaining work is shifting from manifest cleanup to targeted refactors |
| Reduce `artbeat_core` feature ownership | in_progress | high | architecture | indirect | package tests + app smoke | Admin, ads, capture, artist, events, messaging, community, and artwork are clean; art-walk usage is now reduced to the temporary XP repair widget in `temp_xp_fix.dart` |
| Standardize translation validation workflow | done | medium | localization | low | locale parity report + parity test | Canonical report script added, locale files aligned, parity test added |
| Consolidate deployment and release process into canonical runbook | done | low | operations | none | doc review | Durable release/testing steps folded into `docs/RELEASE_CHECKLIST.md`; older docs now reference-only |
| Finish open legal/security follow-up items from `TODO.md` | todo | high | compliance | direct | staging validation | Keep policy and behavior aligned |
| Split large backend function domains into clearer modules | todo | medium | backend | medium | function smoke tests | Start after release process is tighter |

## Blocked Or Watch Items

| Item | Status | Risk | Blocker | Notes |
| --- | --- | --- | --- | --- |
| Production canary sign-off completion | blocked | high | non-engineering sign-off and evidence | See `TODO.md` and legal docs |
| Admin deletion fulfillment reliability | blocked | high | observed manual QA failure | See `docs/archive/manual_qa_result_2026-02-27.md` |

## Completed Recently

| Item | Status | Notes |
| --- | --- | --- |
| Documentation system scaffolded | done | Keep docs current as part of normal work |

## Repo Hygiene Subtasks

| Task | Status | Notes |
| --- | --- | --- |
| Tighten ignore rules for local/debug output | done | `.gitignore` updated for common root and package-local artifacts |
| Create canonical destinations for archived docs and tooling | done | Added `docs/archive/` and `tools/` guidance docs |
| Inventory tracked root files and classify cleanup targets | done | See `docs/REPO_HYGIENE.md` |
| Move or archive tracked root utility files | in_progress | Historical data files and standalone scripts moved out of root; more cleanup remains |
| Audit unusual package-local project artifacts | done | Findings recorded in `docs/PACKAGE_RESIDUE_AUDIT.md` |
| Remove accidental committed package-local project artifacts | in_progress | Nested `packages/artbeat_admin/.git` removed; `packages/artbeat_profile/ios` still needs explicit decision |
| Reduce `artbeat_artwork` direct dependency on `artbeat_profile` | done | Removed unused manifest dependency; package verification pending broader Stage 2 reassessment |
| Remove `artbeat_artist` direct dependency on `artbeat_ads` | done | Removed unused manifest dependency; verify with package tests |
| Remove `artbeat_artwork` direct dependency on `artbeat_events` | done | Removed unused manifest dependency; verify with package tests |
| Remove `artbeat_capture` direct dependency on `artbeat_art_walk` | done | Replaced service coupling with app-shell hooks; verify with capture package tests |
| Reduce duplicated artwork-management ownership between `artbeat_artist` and `artbeat_artwork` | done | `artistArtwork` now routes to artwork package screen; obsolete artist duplicate removed |
| Move artist public profile artwork data back to artist-local types | done | `ArtistPublicProfileScreen` no longer uses artwork package models/services |
| Route gallery hub artwork flows through app-shell routes | done | `GalleryHubScreen` no longer constructs artwork management or auction setup screens directly |
| Move auction hub off artwork package models and direct auction UI | done | `AuctionHubScreen` now uses artist-local data and app-shell routes for auction flows |
| Remove `artbeat_artist` direct dependency on `artbeat_artwork` | done | No source-level imports remain; manifest dependency removed |
| Remove `artbeat_artwork` direct dependency on `artbeat_artist` | done | Upload/detail flows now use core artist services and artwork-local visibility tracking |
| Remove unused `artbeat_profile` feature dependencies | done | Dropped unused ads/artist/artwork/community manifest edges before deeper profile refactors |
| Remove `artbeat_profile` direct dependency on `artbeat_auth` | done | Profile now uses core auth service and shared routes for sign-out/post-auth navigation |
| Remove `artbeat_profile` direct dependency on `artbeat_capture` | done | Profile now reads captures through `CaptureServiceInterface` provided by the app shell |
| Remove `artbeat_profile` direct dependency on `artbeat_art_walk` | done | Achievement, badge, and challenge reads now use profile-local adapters; profile no longer creates daily challenge state |
| Remove `artbeat_community` direct dependency on `artbeat_messaging` | done | Community now routes user-profile handoff through shared messaging routes instead of constructing messaging screens directly |
| Remove `artbeat_community` direct dependency on `artbeat_artist` | done | Community now routes artist onboarding through shared routes and owns its own artist follow/name-read behavior |
| Remove `artbeat_community` direct dependency on `artbeat_admin` | done | Community now launches leaderboard, moderation, and admin dashboard via shared app routes |
| Remove `artbeat_community` direct dependency on `artbeat_events` | done | Artist community feed now reads recent events through a local Firestore reader using `core.EventModel` |
| Remove `artbeat_community` direct dependency on `artbeat_artwork` | done | Community now launches artwork screens via shared routes and reads artist artworks through a local Firestore reader |
| Remove `artbeat_community` direct dependency on `artbeat_art_walk` | done | Community feed now reads social activity through a community-local service and local activity types |
| Remove unused `artbeat_art_walk` feature dependencies | done | Dropped stale ads/community/profile manifest edges; remaining art-walk dependencies are real source usage |
| Remove `artbeat_art_walk` direct dependency on `artbeat_events` | done | Create flow now uses art-walk-local CTA UI instead of borrowing the events package widget |
| Remove `artbeat_art_walk` direct dependency on `artbeat_settings` | done | Create flow now reads `distanceUnit` through an art-walk-local preference service against `userSettings` |
| Remove `artbeat_art_walk` direct dependency on `artbeat_capture` | done | Map, dashboard, and create flow now read captures through an art-walk-local Firestore service using core `CaptureModel` |
| Remove `artbeat_admin` direct dependency on `artbeat_messaging` | done | Admin platform curation now sends broadcasts through an admin-local service instead of borrowing messaging admin tooling |
| Remove `artbeat_admin` direct dependency on `artbeat_ads` | done | Admin ad management now uses admin-local moderation models and Firestore service instead of ads package services/models |
| Remove `artbeat_admin` direct dependency on `artbeat_events` | done | Event moderation dashboard now uses admin-local event moderation models and Firestore service |
| Remove `artbeat_admin` direct dependency on `artbeat_community` | done | Community moderation queue now uses admin-local moderation models and Firestore service |
| Remove `artbeat_admin` direct dependency on `artbeat_capture` | done | Capture moderation and geo-backfill workflow now use an admin-local Firestore service |
| Remove `artbeat_admin` direct dependency on `artbeat_art_walk` | done | Art-walk moderation screen now uses admin-local moderation models and Firestore service |
| Remove `artbeat_admin` direct dependency on `artbeat_artwork` | done | Artwork moderation, featured-artwork curation, and chapter-count updates now use admin-local models/services |
| Remove stale `artbeat_core` direct dependency on `artbeat_auth` | done | No remaining source imports in core; manifest dependency removed |
| Remove stale `artbeat_core` direct dependency on `artbeat_settings` | done | No remaining source imports in core; manifest dependency removed |
| Remove stale `artbeat_core` direct dependency on `artbeat_sponsorships` | done | No remaining source imports in core; manifest dependency removed |
| Remove `artbeat_core` direct dependency on `artbeat_profile` | done | Universal header now routes to the profile menu through shared app routes instead of importing profile UI directly |
| Remove `artbeat_core` direct dependency on `artbeat_admin` | done | Developer menu now uses shared admin routes instead of constructing admin screens directly |
| Remove `artbeat_core` direct dependency on `artbeat_ads` | done | Runtime ads screen moved to the app shell; core now keeps only the store preview card |
| Remove `artbeat_core` direct dependency on `artbeat_capture` | done | Animated dashboard now routes through `AppRoutes.captureDashboard`, and the app shell owns the capture dashboard screen |
| Remove `artbeat_core` direct dependency on `artbeat_artist` | done | Dashboard artist loading moved to core `ArtistService`, and follow/unfollow now uses the existing community service |
| Remove `artbeat_core` direct dependency on `artbeat_events` | done | Dashboard upcoming-event reads now use a core-local Firestore reader returning `EventModel` directly |
| Remove `artbeat_core` direct dependency on `artbeat_messaging` | done | Core unread-count and block/unblock paths now use core-local Firestore/Auth services instead of the messaging package |
| Remove `artbeat_core` direct dependency on `artbeat_community` | done | Core post-feed reads, commission preview, and create-post launches now use core-local read surfaces and shared routes |
| Remove `artbeat_core` direct dependency on `artbeat_artwork` | done | Dashboard artwork/book reads and filtered artwork results now use a core-local `ArtworkReadService` and core `ArtworkModel` |
| Narrow `artbeat_core -> artbeat_art_walk` to temporary tooling only | done | Achievement, progression, challenge, activity, nearby-art, and discovery-progress reads/writes are now core-owned; only `temp_xp_fix.dart` still imports `artbeat_art_walk` |

## Queue Rules

- Do not start a `high` risk architecture task without a clear rollback path.
- Every production-affecting task must name the validation required before
  release.
- If a task is not in this file, it is not active engineering work yet.
