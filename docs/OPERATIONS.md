# ARTbeat Operations

Last updated: April 7, 2026

## Purpose

Define the current runbook for daily engineering operations, release preparation, and production response.

## Local Setup

1. Install Flutter and Dart versions compatible with root `pubspec.yaml` constraints.
2. Run `flutter pub get` in repo root.
3. Run `flutter pub get` in each first-party package under `packages/` when dependency manifests change.
4. Configure env files required by runtime (`.env`, `.env.production`) and Firebase configuration.

## Engineering Quality Gates

For production-affecting changes:

- `flutter analyze`
- `flutter test`
- targeted package tests where applicable
- targeted manual QA for changed user flows

When payments, legal, safety, or data-rights behavior changes, include runbook and policy validation from `docs/security/` and policy docs.

## Release Process

Canonical release flow is defined in `docs/RELEASE_CHECKLIST.md`.

Minimum release expectations:

- work scope reflected in `docs/WORK_QUEUE.md`
- no release-blocking open issue in `docs/KNOWN_ISSUES.md`
- quality gates passed
- version/build numbers correct across Android/iOS
- legal/security release status updated if affected

## Incident And Compliance Response

- Legal/security incident handling: `docs/security/LEGAL_INCIDENT_RESPONSE_PLAN.md`
- Legal canary and rollout controls: `docs/security/LEGAL_PRODUCTION_CANARY_ROLLOUT_RUNBOOK.md`
- Law enforcement intake policy: `docs/LAW_ENFORCEMENT_REQUEST_POLICY.md`
- Safety response policy: `docs/SAFETY_AND_ABUSE_RESPONSE_POLICY.md`
- Copyright/DMCA process: `docs/COPYRIGHT_AND_DMCA_POLICY.md`

## Moderation And Safety Controls

- Upload safety implementation details: `docs/UPLOAD_SAFETY_IMPLEMENTATION.md`
- Community and abuse enforcement baseline: `docs/COMMUNITY_GUIDELINES.md`, `docs/SAFETY_AND_ABUSE_RESPONSE_POLICY.md`

## Documentation Maintenance Rule

If a doc is time-bound or session-specific, move it to `docs/archive/` after it no longer drives active execution.
