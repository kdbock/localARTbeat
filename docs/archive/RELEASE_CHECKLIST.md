# ARTbeat Release Checklist

## Purpose

Provide one repeatable release process for app code, Firebase config, rules, and
functions.

## Release Types

- app-only release
- backend/rules-only release
- combined release
- hotfix release

## Pre-Release

- confirm the scope is reflected in `WORK_QUEUE.md`
- confirm any high-risk changes are called out in PR or commit notes
- verify version/build numbers are correct
- review relevant decisions in `DECISIONS.md`
- confirm required env vars and secrets are available

## Code Quality

- run `flutter analyze`
- run root app tests that cover touched areas
- run package tests for touched packages
- run localization parity checks if translation keys changed
- run backend checks if `functions/`, rules, or Firebase config changed

Recommended baseline commands:

```bash
flutter analyze
flutter test
flutter test test/localization_key_parity_test.dart
```

When packages are touched, also run targeted package tests.

## Manual QA

Always validate the changed user flows, not just compile success.

High-priority flows:

- startup and splash navigation
- login, registration, logout
- dashboard load
- payments and subscriptions when payment code is touched
- data requests/deletion when legal/settings/rules code is touched
- messaging if chat, notifications, or presence code changed
- translation coverage when locale keys changed

Release-critical payment QA when payment code is touched:

- add payment method
- subscription checkout
- commission or other payment flow tied to changed code
- confirm 3DS/Stripe authentication does not crash

## Firebase / Backend Checks

Required when touching backend-related files:

- `functions/src/**`
- `firebase.json`
- `firestore.rules`
- `storage.rules`
- indexes/config under Firebase/Data Connect folders

Checks:

- validate rules intent against changed behavior
- verify staging or emulator path where practical
- confirm callable/function names and secrets are unchanged or intentionally
  migrated
- check for rollback path before production deploy

## Android Release

- optional clean build prep for larger releases:
  - `flutter clean`
  - `cd android && ./gradlew clean && cd ..`
- run `flutter pub get`
- build release AAB
- verify release build succeeds cleanly
- test critical flows on at least one Android device/emulator
- upload to internal or staged track first unless emergency hotfix
- monitor Crashlytics and payment/usage metrics after rollout

Recommended commands:

```bash
flutter build appbundle --release
flutter build apk --release
```

## iOS Release

- run `flutter pub get`
- build iOS release
- verify archive/signing flow
- test critical flows on at least one iOS device/simulator where practical
- use TestFlight before full rollout unless emergency hotfix
- monitor Crashlytics and user-reported regressions after rollout

Recommended command:

```bash
flutter build ios --release --no-codesign
```

## Hotfix Rules

Use hotfix flow only when:

- a production bug is user-visible or revenue/security affecting
- scope is narrow
- rollback path is clear

Hotfix constraints:

- no opportunistic refactors
- no architecture work in the same change
- no unrelated cleanup bundled in

## Post-Release

- confirm deployment artifacts completed successfully
- watch Crashlytics for new signatures
- watch authentication, payment, and startup metrics
- record any new issue in `KNOWN_ISSUES.md`
- update `DECISIONS.md` if the release created a new permanent workflow or rule

Payment-specific monitoring when relevant:

- payment success/failure rate
- 3DS completion rate
- new Stripe crash signatures
- payment abandonment complaints in store reviews/support channels

## Canonical Supporting Docs

- `docs/TEST_STRATEGY.md`
- `docs/OPERATIONS.md`
- `docs/KNOWN_ISSUES.md`

Incident/reference docs:

- `docs/DEPLOYMENT_CHECKLIST.md`
  - Stripe 3DS deployment incident checklist
- `docs/TESTING_GUIDE.md`
  - Stripe 3DS focused manual QA guide
- `scripts/deploy.sh`
  - convenience build script, not the source of truth for release policy
