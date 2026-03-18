# ARTbeat Documentation Index

This directory contains the canonical project docs used to plan work,
understand architecture, test safely, and ship changes.

## Core Operating Docs

- `ARCHITECTURE.md`
  - Current system structure, package boundaries, and dependency intent.
- `ROADMAP.md`
  - Current priorities, next steps, and deferred work.
- `WORK_QUEUE.md`
  - Active engineering queue with status and release/test notes.
- `RELEASE_CHECKLIST.md`
  - Standard release process for Android, iOS, Firebase rules, and functions.
- `TEST_STRATEGY.md`
  - Testing pyramid, ownership, and release-critical coverage.
- `DEPENDENCY_RULES.md`
  - Package dependency policy and architectural guardrails.
- `DECISIONS.md`
  - Short architecture and process decisions with rationale.
- `OPERATIONS.md`
  - Practical runbooks for env setup, secrets, translations, deploys, and
    incident handling.
- `KNOWN_ISSUES.md`
  - Live issues, impact, workarounds, and target fixes.
- `FEATURE_SPECS/`
  - Short specs for active feature work.

## Existing Domain Docs

Many older docs in this folder are still useful reference material, especially
for legal, payment, onboarding, and one-off project work. Prefer the core
operating docs above for current process and project control.

## Maintenance Rule

If a doc here stops influencing decisions or execution, archive it or remove it.
The goal is a working system, not documentation volume.
