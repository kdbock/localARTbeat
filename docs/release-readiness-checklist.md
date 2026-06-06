# Release Readiness Checklist

Use this before the June 21, 2026 Washington NC capture tour and before any production release that changes capture, upload, auth, App Check, or rules behavior.

## Code Validation

- [ ] Run `flutter analyze`.
- [ ] Run `flutter test`.
- [ ] Run `flutter test` in `packages/artbeat_art_walk`.
- [ ] Run `npm audit --json` at the repo root and confirm `total` is `0`.
- [ ] Run `npm audit --json` in `functions` and confirm `total` is `0`.
- [ ] Run `npm audit --json` in `functions/test/rules` and confirm `total` is `0`.
- [ ] Run `npm run build` in `functions`.
- [ ] Run `npm test` in `functions`.
- [ ] Run `npm run lint` in `functions`.
- [ ] Run `npm run test:rules` in `functions`.
- [ ] Run `npm run test:storage-rules` in `functions`.

## Release Builds

- [ ] Run `flutter build web --release`.
- [ ] Run `flutter build appbundle --release`.
- [ ] Run `flutter build ios --release --no-codesign` on macOS when iOS readiness matters.

## Firebase Rules

- [ ] Confirm App Check is registered for the live Android/iOS apps.
- [ ] Confirm App Check enforcement is enabled for Firebase Storage.
- [ ] Deploy Storage rules with `firebase deploy --only storage`.
- [ ] Check Firebase Console after deploy for Storage rules publish status.

## Production Capture Smoke Test

- [ ] Sign in as a normal non-admin user.
- [ ] Capture a new photo on cellular data.
- [ ] Upload the captured media.
- [ ] Reload the app and verify the uploaded media still renders.
- [ ] Create the related post, event, or art-walk activity if applicable.
- [ ] Confirm the upload path belongs to the signed-in user.
- [ ] Try one denied path or invalid media type and confirm the app fails visibly, not silently.
- [ ] Repeat once on Wi-Fi.

## Field-Day Checks

- [ ] Confirm device location permission is enabled.
- [ ] Confirm camera permission is enabled.
- [ ] Confirm enough device storage is available.
- [ ] Confirm cellular data is usable at the capture site.
- [ ] Confirm the app build installed on the field device matches the latest validated build.
