# Release Upload Checklist (Android + iOS)

## Versioning
- [x] Root Flutter version updated in `pubspec.yaml` to `2.6.17+122`
- [x] Android `versionCode` updated to `122`
- [x] Android `versionName` updated to `2.6.17`
- [x] iOS uses Flutter build variables:
  - `CFBundleShortVersionString = $(FLUTTER_BUILD_NAME)`
  - `CFBundleVersion = $(FLUTTER_BUILD_NUMBER)`

## Dependency Refresh
- [x] Run `flutter pub get` at repo root
- [x] Run `flutter pub get` for each first-party package under `packages/`
- [x] Ensure lockfiles are updated as expected

## Code Quality Gates
- [x] Run `dart format .` (first-party code paths)
- [x] Run `flutter analyze`
- [x] Resolve all analyzer errors and lints
- [x] Re-run `flutter analyze` until clean

## Regression Verification (Critical Flows)
- [ ] Capture -> social feed post includes image
- [ ] Capture discovery copy fallback:
  - `username discovered outdoor artwork in their area and got XP points`
- [ ] Community HUD drawer shows Add Post only for artist/admin/moderator
- [ ] Main drawer shows Add Post above Browse for artist/admin/moderator
- [ ] Search/browse consistency checks:
  - query echo in result summaries
  - clear/reset behavior in empty/no-results states
  - recent-search chip behavior

## Android Release Prep
- [x] `flutter build appbundle --release`
- [x] Validate `app-release.aab` generated successfully
- [ ] Upload to Play Console internal testing
- [ ] Verify release notes and rollout settings

## iOS Release Prep
- [x] `flutter build ipa --release`
- [x] Validate generated IPA in `build/ios/ipa/`
- [ ] Upload via Transporter/Xcode Organizer
- [ ] Configure App Store Connect release metadata

## Final Sign-Off
- [ ] Smoke test installed Android build
- [ ] Smoke test installed iOS build
- [ ] Confirm analytics/crash reporting enabled for release
- [ ] Tag release in git
