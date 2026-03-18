# ARTbeat Decisions

## Purpose

Keep a short log of important technical and process decisions so the project
does not re-argue the same fundamentals.

## Decision Log

### 2026-03-18: Root `lib/` is the app shell

Decision:

- treat root `lib/` as the application composition layer

Why:

- startup, provider wiring, and route integration already live there
- this is the cleanest place to coordinate features without pushing more
  orchestration into packages

### 2026-03-18: `artbeat_core` should stop growing as a feature host

Decision:

- no new feature-specific logic should be added to `artbeat_core`

Why:

- it already acts as both a base layer and a feature/orchestration layer
- continuing that pattern increases coupling and release risk

### 2026-03-18: English is the canonical locale

Decision:

- `assets/translations/en.json` is the source locale for key creation

Why:

- translation integrity is easier to validate from one canonical key set

### 2026-03-18: Canonical project-control docs live under `docs/`

Decision:

- `ROADMAP.md`, `WORK_QUEUE.md`, `RELEASE_CHECKLIST.md`, `TEST_STRATEGY.md`,
  `DEPENDENCY_RULES.md`, `KNOWN_ISSUES.md`, and `OPERATIONS.md` are the
  operating docs for the repo

Why:

- current project state is spread across many one-off docs and notes

### 2026-03-18: High-risk refactors must be incremental

Decision:

- no large architecture rewrite while the app is live

Why:

- the codebase already ships to iOS and Android
- stability and controlled complexity matter more than conceptual purity

## Usage Rule

Add a new entry when:

- a change affects where code should live
- a workflow becomes standard
- a dependency exception is granted
- a release/process rule changes permanently
