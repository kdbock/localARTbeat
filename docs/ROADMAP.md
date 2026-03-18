# ARTbeat Roadmap

## Purpose

Keep the project focused on the next set of important outcomes and make
de-scoping explicit.

## Now

These are the active priorities for the current stabilization phase.

### 1. Production Stability

- reduce cross-package change risk
- strengthen testing around startup, auth, payments, data requests, and routing
- keep release-critical fixes safe and incremental

### 2. Architecture Stabilization

- stop expanding `artbeat_core` with feature-specific logic
- reduce feature-to-feature dependencies
- clarify app shell versus reusable package responsibilities

### 3. Repo Hygiene

- clean source versus generated/local artifact boundaries
- reduce root-level clutter
- consolidate scripts and operational data files

### 4. Localization Reliability

- make English the canonical locale source
- validate translation key parity automatically
- replace ad hoc translation maintenance with a smaller workflow

### 5. Legal and Security Follow-Through

- finish open legal/compliance items tracked in `TODO.md`
- keep Firestore/Storage rules aligned with behavior
- preserve staging/prod verification discipline

## Next

These begin after the stabilization phase is underway.

- split backend functions by domain
- formalize release train and rollback workflows
- improve package-level ownership and testing
- consolidate evergreen docs versus archived reports
- improve analytics/monitoring visibility around critical flows

## Later

Important, but not part of the immediate focus.

- deeper package redesign
- design system cleanup and UI consistency passes
- broader performance tuning
- Data Connect adoption or archival decision
- long-term admin/system observability improvements

## Explicit Non-Goals Right Now

- no rewrite of the app
- no package explosion
- no large-scale state management migration
- no visual redesign pass unless tied to a production issue
- no moving code across many packages without tests and clear payoff

## Success Criteria For This Phase

- new work lands in the right place more often
- fewer changes require broad manual regression
- releases become more repeatable
- active work is visible in one queue
- architecture drift slows down instead of accelerating

## Review Cadence

- weekly: update `WORK_QUEUE.md`
- biweekly: review `ROADMAP.md`
- per release: confirm `RELEASE_CHECKLIST.md` still matches reality
