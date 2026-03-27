# Dependency Rules

## Purpose

Define the package-boundary rules that keep ARTbeat modular, reviewable, and
safe to change.

## Core Rules

### 1. `artbeat_core` is a base layer

- `artbeat_core` must not depend on sibling feature packages.
- Shared models, route constants, base services, and reusable widgets should
  live behind public `artbeat_core` exports, not feature-package internals.

### 2. Feature packages do not depend on each other by default

- A feature package may depend on another feature package only when the
  dependency is real, intentional, and documented.
- When a feature-to-feature dependency is added or removed, update:
  - `docs/DECISIONS.md`
  - `docs/PACKAGE_DEPENDENCY_INVENTORY.md`
  - `docs/WORK_QUEUE.md` if refactor priority changes

### 3. Cross-package `src/` imports are forbidden

- Packages must not import another package's `src/` internals.
- If another package needs something, export it publicly through that package's
  barrel or another public entry point.
- Internal `src/` imports are acceptable only inside the same package.

### 4. `pubspec.yaml` must match source usage

- If `lib/` imports a sibling package, that sibling must be declared in the
  package's `pubspec.yaml`.
- Do not keep unused sibling-package dependencies around "just in case."

### 5. App-shell orchestration belongs in root `lib/`

- Root `lib/` is the app shell and composition layer.
- Cross-feature route wiring, provider composition, and host-app orchestration
  belong there rather than inside sideways package imports.

## Practical Guidance

- Prefer interface ownership in the consuming package and implementation wiring
  in the app shell when cross-feature behavior is orchestration, not domain
  ownership.
- Prefer public barrel exports when multiple packages need the same type or
  utility from `artbeat_core`.
- Do not route around boundaries by importing "just one file" from another
  package's `src/`.

## Automated Enforcement

Current automated boundary checks live in:

- `tools/architecture/check_package_boundaries.py`
- `tools/architecture/check_sibling_dependency_drift.py`
- `tools/architecture/check_provider_owned_capture_service.sh`
- `tools/architecture/generate_package_dependency_inventory.py --check`

These checks should fail CI when package boundaries drift.
