# ARTbeat Pre-Submission Remaining Work

Current app version: `2.6.11+111`  
Status date: March 26, 2026

This is the short, current list of work still left before Android and iOS
submission.

## Already Complete

- release-confidence QA passed on 2026-03-26
- account/profile persistence passed
- capture upload reliability passed
- messaging location, gallery, and camera upload passed
- admin data-rights deletion passed
- owner-approved legal/policy baseline is documented
- support-readiness sign-off for the current owner-operated flow is documented

## Still Required Before Upload

### 1. Legal/Data-Rights Production Canary

Use:

- [LEGAL_PRODUCTION_CANARY_ROLLOUT_RUNBOOK.md](/Volumes/ExternalDrive/DevProjects/artbeat/docs/security/LEGAL_PRODUCTION_CANARY_ROLLOUT_RUNBOOK.md)

Remaining actions:

- reserve a 24-48 hour observation window
- identify the rollback operator
- run the production legal/data-rights canary
- verify export request, deletion request, admin processing, and no new rule
  denies on profile, capture, ads, and chat media
- monitor for 24-48 hours

This is the clearest remaining release gate from the current docs.

### 2. Release Build Execution

Use:

- [RELEASE_CHECKLIST.md](/Volumes/ExternalDrive/DevProjects/artbeat/docs/RELEASE_CHECKLIST.md)

Required execution steps:

- run `flutter analyze`
- run `flutter test`
- run `flutter test test/localization_key_parity_test.dart`
- confirm Android and iOS version/build numbers are correct for the release
- build Android release artifacts
- build iOS release artifacts
- test critical flows on at least one Android device/emulator and one iOS
  device/simulator

### 3. Submission Metadata / Store Ops

Not blocked by engineering, but still required:

- confirm App Store / Play Store listing text matches the current policy and
  product behavior
- confirm privacy/contact/support information is current
- confirm release notes reflect the current scope
- choose staged rollout / internal track / TestFlight sequence

## Non-Blocking Follow-Up Work

These should not stop submission unless you choose a stricter bar:

- payment/config hygiene and audit logging
- funnel instrumentation and monetization telemetry
- CI/package ownership/process scaling
- broader moat/defensibility work

## Practical Next Order

1. Schedule and execute the legal/data-rights production canary.
2. Run release analyze/tests/builds.
3. Confirm store metadata and release notes.
4. Upload to internal/staged tracks first.
