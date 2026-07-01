# Release Checklist

Last updated: July 1, 2026

## Versioning

- Confirm `pubspec.yaml` contains the next version, for example
  `version: 2.7.2+134`.
- Confirm Android matches in `android/app/build.gradle.kts`:
  `versionName` and `versionCode`.
- Confirm iOS uses Flutter build variables in `ios/Runner/Info.plist`.
- Confirm `ios/Flutter/AppFrameworkInfo.plist` matches the release version.
- Apple versions must always be higher than the latest approved App Store
  version.

## Preflight

```sh
flutter pub get
flutter analyze lib
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" \
  ./android/gradlew -p android :app:processDebugResources
```

## Android Testing Upload

```sh
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" \
  flutter build appbundle --release --build-name=<version> --build-number=<build>
```

Upload:

- `build/app/outputs/bundle/release/app-release.aab`

## iOS Testing Upload

Xcode must have an Apple Distribution certificate for team `H49R32NPY6`.

```sh
flutter build ipa \
  --release \
  --build-name=<version> \
  --build-number=<build> \
  --export-options-plist=ios/export_options.plist
```

Upload with Transporter:

- `build/ios/ipa/Local ARTbeat.ipa`

## Native Launch Screens

- iOS launch screen: `ios/Runner/Base.lproj/LaunchScreen.storyboard`
- Android pre-Flutter splash:
  - `android/app/src/main/res/drawable/launch_background.xml`
  - `android/app/src/main/res/drawable-v21/launch_background.xml`
  - `android/app/src/main/res/values-v31/styles.xml`

Delete the app from an iOS device/simulator before retesting launch screens,
because iOS can cache launch-screen assets.

## Known Non-Blocking Warnings

- Android: Built-in Kotlin is enabled and the release build should not emit
  Flutter's future KGP failure warning. See `docs/DEPENDENCY_AUDIT.md` before
  removing any local Android plugin overrides.
- iOS: The project has been migrated away from CocoaPods. If a CocoaPods warning
  returns, inspect `ios/Flutter/*.xcconfig`, `ios/Runner.xcworkspace`, and
  `ios/Runner.xcodeproj/project.pbxproj` for new Pods references.

## Smoke Test

- Auth: sign in and sign out.
- Dashboard: verify Local ARTbeat title, level/XP, capture, map, share, discover.
- Capture: capture or upload an image, edit details, submit.
- Map: tap a capture marker, open details, expand image full screen, close.
- Discover: verify radar appears full-width and nearby art loads.
- Community: verify automatic activity/capture feed items, reactions, comments,
  and in-feed share.
- Events: submit a paid event and confirm moderation status.
- Sponsorships: submit a paid placement request and confirm moderation status.
- Profile: verify achievements/badges have no overflow.
