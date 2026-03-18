# ARTbeat Work Queue

## Purpose

Track active engineering work in one place with enough detail to execute and
ship safely.

Status values:

- `todo`
- `in_progress`
- `blocked`
- `done`

Risk values:

- `low`
- `medium`
- `high`

## Active Queue

| Task | Status | Risk | Area | Release Impact | Test Needed | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| Create canonical project docs and operating system | done | low | repo/process | none | doc review | Canonical docs created under `docs/` |
| Clean repo root and separate source from generated/local artifacts | in_progress | medium | repo hygiene | indirect | smoke + git review | Safe phase started: ignore coverage, destination folders, cleanup policy |
| Define and enforce package dependency rules | todo | high | architecture | indirect | analyze + targeted regression | Start with policy before moving code |
| Reduce `artbeat_core` feature ownership | todo | high | architecture | indirect | package tests + app smoke | Do in small slices |
| Standardize translation validation workflow | todo | medium | localization | low | locale parity test | Seed from `assets/translations/` |
| Consolidate deployment and release process into canonical runbook | todo | low | operations | none | dry run doc review | Existing docs are fragmented |
| Finish open legal/security follow-up items from `TODO.md` | todo | high | compliance | direct | staging validation | Keep policy and behavior aligned |
| Split large backend function domains into clearer modules | todo | medium | backend | medium | function smoke tests | Start after release process is tighter |

## Blocked Or Watch Items

| Item | Status | Risk | Blocker | Notes |
| --- | --- | --- | --- | --- |
| Production canary sign-off completion | blocked | high | non-engineering sign-off and evidence | See `TODO.md` and legal docs |
| Admin deletion fulfillment reliability | blocked | high | observed manual QA failure | See `docs/archive/manual_qa_result_2026-02-27.md` |

## Completed Recently

| Item | Status | Notes |
| --- | --- | --- |
| Documentation system scaffolded | done | Keep docs current as part of normal work |

## Repo Hygiene Subtasks

| Task | Status | Notes |
| --- | --- | --- |
| Tighten ignore rules for local/debug output | done | `.gitignore` updated for common root and package-local artifacts |
| Create canonical destinations for archived docs and tooling | done | Added `docs/archive/` and `tools/` guidance docs |
| Inventory tracked root files and classify cleanup targets | done | See `docs/REPO_HYGIENE.md` |
| Move or archive tracked root utility files | todo | Do only after confirming no active workflow depends on them |
| Remove accidental committed package-local project artifacts | todo | Higher-risk because some may be intentionally used |

## Queue Rules

- Do not start a `high` risk architecture task without a clear rollback path.
- Every production-affecting task must name the validation required before
  release.
- If a task is not in this file, it is not active engineering work yet.
