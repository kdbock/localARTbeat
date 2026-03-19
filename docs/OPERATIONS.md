# ARTbeat Operations

## Purpose

Capture recurring practical workflows so the project is operable without relying
on memory.

## Local Environment

Primary references:

- `docs/ENV_SETUP.md`
- `scripts/setup_env_local.sh`

Rules:

- keep secrets out of git-tracked files
- prefer `.env.example` and `.env.local.example` for templates
- do not rely on ad hoc root notes as the only setup source

## Secrets And Config

Current sensitive areas include:

- `.env*`
- `key.properties`
- Firebase service/account files
- platform config files

Rules:

- examples/templates may be tracked
- live secret values should not be committed
- if a script needs a key, prefer environment injection over hardcoded values

## Translation Workflow

Canonical runtime assets:

- `assets/translations/*.json`

Working rules:

- add keys to English first
- validate locale parity before release
- use one maintained workflow for extract/validate/apply instead of many
  one-off scripts over time

Current report command:

- `python3 tools/localization/report_missing_keys.py`

This rewrites:

- `assets/translations/missing_keys.md`

## Build And Release

Use:

- `docs/RELEASE_CHECKLIST.md`

Legacy supporting references:

- `docs/DEPLOYMENT_CHECKLIST.md`
- `docs/TESTING_GUIDE.md`
- `scripts/deploy.sh`
- platform build scripts under `scripts/`

Rule:

- `docs/RELEASE_CHECKLIST.md` is the canonical release process
- older deployment/testing docs are incident-specific references, not the main
  operating procedure

## Firebase / Backend

Production-sensitive files:

- `firebase.json`
- `firestore.rules`
- `storage.rules`
- `functions/`

Rules:

- treat rules changes as production changes
- document staging/prod validation for security-sensitive work
- keep rollback path clear before deploy

## Incident Handling

Primary security/legal references:

- `docs/security/LEGAL_INCIDENT_RESPONSE_PLAN.md`
- `docs/security/SECURITY_RULES_STAGED_ROLLOUT.md`

Project rule:

- if an issue affects auth, payments, user data, deletion, or permissions, log
  it in `KNOWN_ISSUES.md` and treat it as a release-affecting item

## Cleanup Discipline

The repo should distinguish:

- source
- generated output
- local/debug output
- archival docs

Working rule:

- if a file is not source, config, or durable documentation, it should not live
  indefinitely at the repo root
