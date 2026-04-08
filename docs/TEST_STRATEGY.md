# ARTbeat Test Strategy

Last updated: April 7, 2026

## Purpose

Define the practical testing strategy used to keep releases safe for the current app architecture.

## Test Layers

## 1. Static Analysis

- Run `flutter analyze` at root for every production-affecting change.
- Use package-local analysis when touching package internals.

## 2. Automated Tests

- Run `flutter test` at root.
- Add/maintain focused tests for:
  - startup/bootstrap behaviors
  - routing/auth guard behavior
  - monetization and verification flows
  - localization key integrity
  - feature-specific regression points (capture/art walk/community)

Current examples exist in `test/` including onboarding/auth/instant discovery/localization/sponsorship coverage.

## 3. Manual QA (Release-Critical)

Manual QA is required for user journeys that involve:

- camera/media capture and upload
- payments and subscription/boost flows
- moderation and safety enforcement
- account, profile, and auth state transitions
- release-only behavior not fully covered by unit/widget tests

Use `docs/RELEASE_CONFIDENCE_QA_CHECKLIST.md` for manual release confidence passes.

## 4. Compliance/Security Validation

For legal, security, and data-rights changes:

- run staging validation scripts and checks in `docs/security/`
- update legal release status in `docs/security/LEGAL_RELEASE_STATUS.md`
- ensure policy docs remain aligned with behavior

## Release Gate

A build is not release-ready unless all are true:

- analysis passes
- automated tests pass
- required manual QA pass is complete for changed flows
- legal/security rollout status is current when affected
