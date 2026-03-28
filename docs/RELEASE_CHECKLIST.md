# ARTbeat Release Checklist

## Purpose

This is the current release checklist to use before uploading to Android or
iOS.

It exists in `docs/` so release-facing docs can point to one stable path.
The older copy in `docs/archive/RELEASE_CHECKLIST.md` is now reference-only.

## What "Ready To Upload" Means

Before upload, confirm these are true:

- the active engineering work is reflected correctly in `WORK_QUEUE.md`
- `flutter analyze` and the relevant tests pass
- release-critical manual QA has been completed for the touched flows
- no open issue in `KNOWN_ISSUES.md` is still a release blocker
- if legal/data-rights behavior changed, the legal release status is current
- Android and iOS version/build numbers are correct

## Pre-Release

- confirm the scope is reflected in `WORK_QUEUE.md`
- confirm any high-risk changes are called out in PR or commit notes
- verify version/build numbers are correct
- review relevant decisions in `DECISIONS.md`
- confirm required env vars and secrets are available
- run the release config gate:
  `bash tools/architecture/check_release_payment_config.sh`
- run the monetization prerequisite gate:
  `bash tools/architecture/check_release_monetization_prereqs.sh`
- if using the convenience build script, confirm it still runs both gates before
  building:
  `scripts/build_secure.sh`

## Code Quality

- run `flutter analyze`
- run root app tests that cover touched areas
- run package tests for touched packages
- run localization parity checks if translation keys changed
- run backend checks if `functions/`, rules, or Firebase config changed

Recommended baseline commands:

```bash
bash tools/architecture/check_release_payment_config.sh
bash tools/architecture/check_release_monetization_prereqs.sh
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
- messaging if chat, notifications, or presence code is touched
- translation coverage when locale keys changed

## Firebase / Backend Checks

Required when touching backend-related files:

- `functions/src/**`
- `firebase.json`
- `firestore.rules`
- `storage.rules`

Checks:

- validate rules intent against changed behavior
- verify staging or emulator path where practical
- confirm callable/function names and secrets are unchanged or intentionally
  migrated
- check for rollback path before production deploy
- confirm the monetization prerequisite gate still passes after any backend
  change:
  `bash tools/architecture/check_release_monetization_prereqs.sh`

## Android Release

- run `flutter pub get`
- run release hardening gates before building:
  - `bash tools/architecture/check_release_payment_config.sh`
  - `bash tools/architecture/check_release_monetization_prereqs.sh`
- build release AAB
- verify release build succeeds cleanly
- test critical flows on at least one Android device/emulator
- upload to internal or staged track first unless emergency hotfix
- monitor Crashlytics and payment/usage metrics after rollout

Recommended commands:

```bash
bash tools/architecture/check_release_payment_config.sh
bash tools/architecture/check_release_monetization_prereqs.sh
./scripts/build_secure.sh
flutter build appbundle --release
flutter build apk --release
```

## iOS Release

- run `flutter pub get`
- run release hardening gates before building:
  - `bash tools/architecture/check_release_payment_config.sh`
  - `bash tools/architecture/check_release_monetization_prereqs.sh`
- build iOS release
- verify archive/signing flow
- test critical flows on at least one iOS device/simulator where practical
- use TestFlight before full rollout unless emergency hotfix
- monitor Crashlytics and user-reported regressions after rollout

Recommended command:

```bash
bash tools/architecture/check_release_payment_config.sh
bash tools/architecture/check_release_monetization_prereqs.sh
flutter build ios --release --no-codesign
```

## Legal / Support Sign-Off

This is what the docs mean by "non-engineering sign-off":

- product/legal owner sign-off:
  confirm the current deletion/data-rights behavior and evidence are acceptable
  for release
- support readiness sign-off:
  confirm support knows what changed, how to recognize a deletion/data-rights
  problem, and where the runbook/evidence live if a user reports an issue

If those two approvals are not needed for the release scope, say so explicitly
in `WORK_QUEUE.md` or `docs/security/LEGAL_RELEASE_STATUS.md` instead of
leaving the status ambiguous.

For the current March 26, 2026 legal-policy pass, owner approval and current
support-readiness approval have been recorded in
`docs/security/LEGAL_RELEASE_STATUS.md`.

## Post-Release

- confirm deployment artifacts completed successfully
- watch Crashlytics for new signatures
- watch authentication, payment, and startup metrics
- record any new issue in `KNOWN_ISSUES.md`
- update `DECISIONS.md` if the release created a new permanent workflow or rule
