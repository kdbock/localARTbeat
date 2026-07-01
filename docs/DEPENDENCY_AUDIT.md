# Dependency Audit

Last updated: July 1, 2026

## Summary

`flutter pub outdated --json` currently reports 92 packages with a newer version
available. Most are transitive packages. Several direct dependencies and local
overrides are intentionally held because this release already builds signed
Android and iOS artifacts and the repo contains local plugin patches.

Do not run a blind `flutter pub upgrade --major-versions` during a release
wrap-up. Upgrade in focused groups, then verify Android AAB, iOS IPA, capture,
radar/map, community feed, sponsorship checkout, event submission, auth, and
profile flows.

## Direct Dependencies To Review First

- `audioplayers`: `6.6.0` -> `6.8.1`
- `device_info_plus`: local override at `12.3.0`; latest `13.2.0`
- `file_picker`: local override at `10.3.10`; latest `11.0.2`
- `flutter_dotenv`: `6.0.0` -> `6.0.1`
- `flutter_local_notifications`: `21.0.0`; latest `22.0.1`
- `flutter_svg`: `2.2.4` -> `2.3.0`
- `geolocator`: `14.0.2` -> `14.0.3`
- `google_fonts`: `8.0.2` -> `8.1.0`
- `image_picker`: `1.2.1` -> `1.2.3`
- `in_app_purchase`: `3.2.3`; latest `3.3.0`
- `in_app_purchase_android`: `0.4.0+10`; latest `0.5.1`
- `in_app_purchase_storekit`: `0.4.8+1` -> `0.4.10+1`
- `intl`: `0.20.2` -> `0.20.3`
- `package_info_plus`: local override at `9.0.0`; latest `10.2.0`
- `path_provider`: `2.1.5` -> `2.1.6`

## Local Overrides

The app currently uses local overrides in `third_party/pub_overrides/` for:

- `audioplayers_android`
- `camera_android_camerax`
- `cloud_functions`
- `device_info_plus`
- `file_picker`
- `firebase_analytics`
- `firebase_app_check`
- `firebase_remote_config`
- `firebase_storage`
- `google_sign_in_android`
- `local_auth_android`
- `package_info_plus`
- `pedometer`
- `share_plus`
- `shared_preferences_android`
- `sign_in_with_apple`
- `stripe_android`
- `stripe_ios`
- `video_player_android`

Each override should keep a short reason in its package folder or in the release
notes before it is kept long-term. Remove an override only after confirming the
published package contains the local fix and both store builds pass.

## Kotlin / AGP Status

Android now keeps `android.builtInKotlin=true`. The Android release build no
longer emits Flutter's future KGP failure warning.

Several plugins are temporarily vendored under `third_party/pub_overrides`
because their published Android Gradle files still explicitly apply the Kotlin
Gradle Plugin. The vendored copies remove that KGP application and rely on AGP
built-in Kotlin, matching Flutter's migration direction.

Track these overrides during dependency upgrades and remove them when the
published package has migrated:

- `audioplayers_android`
- `cloud_functions`
- `device_info_plus`
- `file_picker`
- `firebase_analytics`
- `firebase_app_check`
- `firebase_remote_config`
- `firebase_storage`
- `package_info_plus`
- `pedometer`
- `share_plus`
- `sign_in_with_apple`
- `stripe_android`

## Recommended Upgrade Order

1. Patch-only direct Dart packages: `flutter_dotenv`, `geolocator`,
   `image_picker`, `path_provider`, `flutter_svg`, `google_fonts`.
2. In-app purchase packages together, then retest iOS and Android purchase
   surfaces.
3. Notification packages together, then retest notification permission and
   receipt flows.
4. Plus plugins and their local overrides one at a time.
5. Stripe overrides last, because they affect paid sponsorship/event flows.
