# Fix Flutter Build Issues

## Issues Identified

- Disk space critically low (299Mi available, 17G Gradle cache)
- Flutter version 3.29.3 installed, pubspec requires >=3.35.0
- AGP 9+ DSL incompatibility with Flutter Gradle plugin
- Kotlin plugin version mismatch in flutter_tts

## Plan

- [x] Delete Gradle cache (~/.gradle) to free up space
- [x] Update Flutter to latest version (already 3.38.7)
- [x] Add android.newDsl=false to android/gradle.properties
- [x] Run flutter clean
- [x] Run flutter pub get
- [x] Try flutter build appbundle again (running)

# Version Upgrade Preparation

## Current Status

- Flutter: 3.38.7 (latest stable)
- Dart: 3.10.7
- Many dependencies outdated with potential major version updates

## Upgrade Plan

- [ ] Update pubspec.yaml environment to latest Flutter/Dart versions
- [ ] Update dependency versions in pubspec.yaml to latest available
- [ ] Run flutter pub upgrade on each local package (packages/artbeat\_\*)
- [ ] Run flutter pub upgrade on overall app
- [ ] Run flutter analyze
- [ ] Test build and fix any issues
- [ ] Provide recommendations for breaking changes
