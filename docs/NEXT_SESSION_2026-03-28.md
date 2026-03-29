# Next Session: March 28, 2026

## Where To Begin

Do not continue the package sweep by default.

Resume from the current validated state with the March 28 hardening sprint closed.

Today completed and validated:
- `artbeat_admin` UI/provider-boundary pass
- `artbeat_core` UI/provider-boundary pass
- `artbeat_artist` UI/provider-boundary pass
- `artbeat_artwork` UI/provider-boundary pass
- `artbeat_events` UI/provider-boundary pass
- `artbeat_profile` UI/provider-boundary pass
- major `artbeat_art_walk` Firebase/UI-boundary cleanup pass
- hardening sprint for env/config ownership, payment verification boundaries, and release gates
- provider root split from [app_providers.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/src/app_providers.dart) into grouped modules under `lib/src/providers/`
- bootstrap extraction from [main.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/main.dart) into focused files under `lib/src/bootstrap/`
- first router Firebase-decoupling pass in [app_router.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/src/routing/app_router.dart)
- first router domain-splitting pass in [app_router.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/src/routing/app_router.dart) for artist, events, settings, and subscription routing
- second router domain-splitting pass in [app_router.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/src/routing/app_router.dart) for community, messaging, artwork, admin, and misc routing
- third router domain-splitting pass in [app_router.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/src/routing/app_router.dart) for gallery, commission, ads, and IAP routing
- auth/profile-adjacent direct-route extraction into [auth_profile_route_handler.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/src/routing/handlers/auth_profile_route_handler.dart)
- generic direct-route extraction into [direct_route_handler.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/src/routing/handlers/direct_route_handler.dart)
- protected-route policy extraction into [route_access_policy.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/src/routing/route_access_policy.dart)
- prefix-based specialized dispatch extraction into [specialized_route_dispatcher.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/src/routing/handlers/specialized_route_dispatcher.dart)
- legacy `root_route_handler.dart` removal
- first provider overlap-consolidation pass in [artist_monetization_providers.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/src/providers/artist_monetization_providers.dart) with explicit root-owned auth/user/event injection

Validation standard used on each completed cluster:
- focused `tools/architecture/*_ui_boundaries.sh` guard
- `python3 tools/architecture/check_package_boundaries.py`
- `python3 tools/architecture/check_sibling_dependency_drift.py`
- `flutter analyze`

## Completed Package Status

Finished for the screens/widgets UI/provider-boundary pass:
- `artbeat_admin`
- `artbeat_core`
- `artbeat_artist`
- `artbeat_artwork`
- `artbeat_events`
- `artbeat_profile`

Mostly complete for this same pass:
- `artbeat_art_walk`

Notes:
- `artbeat_core` is clean for this pass. Do not spend more cycles there unless you intentionally switch to deeper service-layer singleton cleanup.
- `artbeat_art_walk` still has one deferred async-service ownership issue in `enhanced_art_walk_experience_screen.dart` where `SmartOnboardingService` is still built locally from `SharedPreferences`. That is not blocking the Firebase/UI-boundary pass.
- Do not take `artbeat_capture` next unless there is a specific reason strong enough to delay the next foundation phase.

## Next Priority

The package sweep should remain stopped here by default.

The hardening sprint documented in:
- [HARDENING_CHECKLIST_2026-03-28.md](/Volumes/ExternalDrive/DevProjects/artbeat/docs/HARDENING_CHECKLIST_2026-03-28.md)

is complete for the March 28 scope.

The next phase should be an execution-confidence/root-architecture sprint rather than a return to package cleanup by default.

## Next Priority

Start with root-level execution-confidence and scalability work:
- split or simplify oversized routing/bootstrap ownership
- audit duplicate provider ownership and composition at the app root
- build on the new CI-enforced release gates instead of treating them as local-only checks
- only return to package cleanup if a specific blocker is discovered

Concrete audit for this phase is documented in:
- [EXECUTION_CONFIDENCE_ROOT_AUDIT_2026-03-28.md](/Volumes/ExternalDrive/DevProjects/artbeat/docs/EXECUTION_CONFIDENCE_ROOT_AUDIT_2026-03-28.md)

Immediate sequence:
1. continue the provider-overlap cleanup at the app root, starting with the remaining explicit overlap pairs called out in the audit rather than reopening package sweeps
2. make `Release Hardening Gates` a required branch-protection signal in GitHub settings
3. only return to package cleanup if a specific blocker is discovered

Operational note:
- the branch-protection step is not a repo code change; it must be applied in GitHub repository settings after confirming the `Release Hardening Gates` job name stays stable

Do not reopen package sweeping as default work.

## Working Rule

Keep the same posture as the hardening pass:
- make ownership explicit
- remove hidden defaults where they create release risk
- turn policy into checks where possible
- prefer provable workflow and CI gates over undocumented assumptions

## If You Need A Single Sentence Restart Prompt

Treat the March 28 hardening sprint as complete and start the next execution-confidence pass on root routing/bootstrap/provider ownership and CI integration, without reopening the package sweep unless a specific blocker forces it.
