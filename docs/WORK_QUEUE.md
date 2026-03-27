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
| Clean repo root and separate source from generated/local artifacts | in_progress | medium | repo hygiene | indirect | smoke + git review | Safe phase started: ignore coverage, destination folders, cleanup policy; tracked root notes/scripts/artifacts have been moved in batches, and `packages/artbeat_profile/ios` is now explicitly deferred to a dedicated removal change rather than opportunistic cleanup |
| Define and enforce package dependency rules | in_progress | high | architecture | indirect | analyze + targeted regression | Policy exists; Stage 1 cuts are done. Stage 2 cleanup cuts are landing, and the remaining work is shifting from manifest cleanup to targeted refactors |
| Reduce `artbeat_core` feature ownership | done | high | architecture | indirect | package tests + app smoke | `artbeat_core` no longer depends on sibling feature packages; the unreferenced temporary XP repair widget was removed and the last `artbeat_core -> artbeat_art_walk` edge is gone |
| Standardize translation validation workflow | done | medium | localization | low | locale parity report + parity test | Canonical report script added, locale files aligned, parity test added |
| Consolidate deployment and release process into canonical runbook | done | low | operations | none | doc review | Canonical checklist now lives at `docs/RELEASE_CHECKLIST.md`; archive copy is reference-only |
| Finish open legal/security follow-up items from `TODO.md` | in_progress | high | compliance | direct | staging validation | Automated staging checks passed; on 2026-03-19 the concrete deletion failure was fixed, `functions:processDataDeletionRequest` was redeployed, and a credentialed staging repro passed end-to-end with `result.ok=true`; manual QA for admin deletion also passed on 2026-03-26; owner policy decisions and support-readiness sign-off were recorded on 2026-03-26; remaining work is production canary scheduling and final production execution; see `docs/security/LEGAL_RELEASE_STATUS.md` |
| Run targeted release-confidence manual QA on hardened user flows | done | high | QA/release | direct | manual QA | Completed on 2026-03-26. Account/profile persistence, paid-flow visibility checks, capture upload reliability, chat media upload reliability, and admin deletion handling passed. Messaging media required a foundation fix: shared Firebase Storage upload hardening plus chat Storage rule alignment and redeploy. |
| Split large backend function domains into clearer modules | todo | medium | backend | medium | function smoke tests | Start after release process is tighter |

## Blocked Or Watch Items

| Item | Status | Risk | Blocker | Notes |
| --- | --- | --- | --- | --- |
| Production canary sign-off completion | blocked | high | canary scheduling and production execution still required | See `docs/security/LEGAL_RELEASE_STATUS.md` |
| Admin deletion fulfillment reliability | done | high | Credentialed staging repro passed on 2026-03-19 after redeploying the fix to `processDataDeletionRequest` | See `docs/security/LEGAL_RELEASE_STATUS.md` |

## Completed Recently

| Item | Status | Notes |
| --- | --- | --- |
| Documentation system scaffolded | done | Keep docs current as part of normal work |
| Release-confidence QA pass completed | done | 2026-03-26 pass succeeded across the targeted hardened flows; no checklist blocker remained reproducible |

## Repo Hygiene Subtasks

| Task | Status | Notes |
| --- | --- | --- |
| Tighten ignore rules for local/debug output | done | `.gitignore` updated for common root and package-local artifacts |
| Create canonical destinations for archived docs and tooling | done | Added `docs/archive/` and `tools/` guidance docs |
| Inventory tracked root files and classify cleanup targets | done | See `docs/REPO_HYGIENE.md` |
| Move or archive tracked root utility files | in_progress | Historical data files, standalone scripts, stale notes, and root debug artifacts moved out of root in batches; more cleanup remains |
| Audit unusual package-local project artifacts | done | Findings recorded in `docs/PACKAGE_RESIDUE_AUDIT.md` |
| Remove accidental committed package-local project artifacts | in_progress | Nested `packages/artbeat_admin/.git` removed; `packages/artbeat_profile/ios` reviewed and deferred to a dedicated tracked-source cleanup change |
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
| Narrow `artbeat_core -> artbeat_art_walk` to temporary tooling only | done | Achievement, progression, challenge, activity, nearby-art, and discovery-progress reads/writes moved into core first |
| Remove final `artbeat_core -> artbeat_art_walk` dependency | done | Deleted the unreferenced temporary XP repair widget and removed `artbeat_art_walk` from `artbeat_core/pubspec.yaml` |

## Queue Rules

- Do not start a `high` risk architecture task without a clear rollback path.
- Every production-affecting task must name the validation required before
  release.
- If a task is not in this file, it is not active engineering work yet.
