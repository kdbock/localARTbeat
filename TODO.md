# Priority TODO Backlog

Last scanned: 2026-02-14  
Priority scale: `P0` critical, `P1` high, `P2` medium, `P3` low  
Scope: app code + all local packages (excluding build artifacts, lockfiles, and node_modules)

## P0 Critical
- [x] Integrate IAP in onboarding tier selection (`packages/artbeat_core/lib/src/screens/artist_onboarding/tier_selection_screen.dart:91`)

## P1 High
- [x] Confirm and finalize account deletion flow (`packages/artbeat_settings/lib/src/screens/privacy_settings_screen.dart:96`)
- [x] Refactor trends tab placeholder (`packages/artbeat_events/lib/src/screens/advanced_analytics_dashboard_screen.dart:358`)
- [x] Refactor events tab placeholder (`packages/artbeat_events/lib/src/screens/advanced_analytics_dashboard_screen.dart:359`)
- [x] Refactor activity tab placeholder (`packages/artbeat_events/lib/src/screens/advanced_analytics_dashboard_screen.dart:361`)

## P2 Medium
- [x] Replace placeholder Haversine note with final distance approach (or document final decision) (`packages/artbeat_sponsorships/lib/src/services/sponsor_service.dart:113`)
- [x] Implement `searchTokens` support for better known-entity search performance (`packages/artbeat_core/lib/src/repositories/known_entity_repository.dart:67`)
- [x] Implement real proximity check once chapter locations are available (`packages/artbeat_core/lib/src/providers/chapter_partner_provider.dart:104`)
- [x] Send notifications for expiring features (`packages/artbeat_core/lib/src/services/feature_maintenance_service.dart:30`)
- [x] Replace placeholder profile URL with real profile URL (`packages/artbeat_core/lib/src/screens/artist_onboarding/completion_screen.dart:46`)

## P3 Low
- [x] Migrate Linux Flutter CMake TODO into expected ephemeral structure (`linux/flutter/CMakeLists.txt:9`)
- [x] Migrate Windows Flutter CMake TODO into expected ephemeral structure (`windows/flutter/CMakeLists.txt:9`)
- [x] Fill local env setup value for Google credentials source (`scripts/setup_env_local.sh:25`)
- [x] Add license text placeholder resolution (`packages/artbeat_admin/LICENSE:1`)
- [x] Add license text placeholder resolution (`packages/artbeat_messaging/LICENSE:1`)

## Completed In This Pass
- [x] Capture settings route implemented (was `lib/src/routing/app_router.dart:1937`)
- [x] Event sponsorship review navigation TODO was stale; flow already wired (`packages/artbeat_sponsorships/lib/src/screens/sponsorships/event_sponsorship_screen.dart:258`)
- [x] Paid tier selection now routes through subscription purchase flow before persisting selection (`packages/artbeat_core/lib/src/screens/artist_onboarding/tier_selection_screen.dart:91`)
- [x] Privacy settings delete account now uses confirmed deletion flow with re-auth handling (`packages/artbeat_settings/lib/src/screens/privacy_settings_screen.dart:96`)
- [x] Advanced analytics trends/events/activity tabs now render functional content instead of TODO placeholders (`packages/artbeat_events/lib/src/screens/advanced_analytics_dashboard_screen.dart:358`)
- [x] Known entity search now uses `searchTokens` fast path with fallback scan (`packages/artbeat_core/lib/src/repositories/known_entity_repository.dart:67`)
- [x] Sponsorship radius filtering now uses Haversine distance when coordinates exist (`packages/artbeat_sponsorships/lib/src/services/sponsor_service.dart:113`)
- [x] Chapter auto-detect now selects nearest chapter using coordinates (`packages/artbeat_core/lib/src/providers/chapter_partner_provider.dart:104`)
- [x] Feature maintenance now sends expiring-feature notifications (`packages/artbeat_core/lib/src/services/feature_maintenance_service.dart:30`)
- [x] Onboarding completion share now uses real profile URL (`packages/artbeat_core/lib/src/screens/artist_onboarding/completion_screen.dart:46`)
- [x] Resolved remaining low-priority template TODO markers in Linux/Windows Flutter CMake files (`linux/flutter/CMakeLists.txt:9`, `windows/flutter/CMakeLists.txt:9`)
- [x] Replaced setup script credential TODO with concrete Google Cloud setup instructions (`scripts/setup_env_local.sh:25`)
- [x] Replaced package license placeholders with full MIT license text (`packages/artbeat_admin/LICENSE:1`, `packages/artbeat_messaging/LICENSE:1`)

## TBD Markers (Informational)
- `packages/artbeat_core/lib/src/widgets/dashboard/dashboard_events_section.dart:416` (`'TBD'` fallback label)
- `packages/artbeat_community/artbeat_community_texts_data.json:31` (`"art_walk_artist_feed_tbd"` translation key)
