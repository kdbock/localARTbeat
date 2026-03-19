# ARTbeat Dependency Rules

## Purpose

Define which layers may depend on which so package structure becomes useful
instead of merely cosmetic.

## Current Problem

The repo currently has bidirectional and cross-feature dependencies that make
small changes expensive and risky.

The goal of these rules is to stop the situation from getting worse first, then
gradually improve it.

## Target Dependency Shape

Allowed by default:

- app shell -> any package
- feature package -> `artbeat_core`
- backend/functions -> backend-only dependencies

Not allowed by default:

- `artbeat_core` -> feature packages
- feature package -> feature package
- package -> root app shell

## `artbeat_core` Rules

`artbeat_core` may contain:

- shared UI primitives
- shared models
- low-level shared services
- app-wide constants
- low-level utilities
- theme/design system

`artbeat_core` may not gain new:

- feature-specific screens
- feature-specific orchestration
- direct imports from feature packages
- one-off code added only to avoid choosing the correct feature owner

## Feature Package Rules

Feature packages should own their domain behavior and UI.

If a feature needs data or behavior from another feature:

1. prefer moving the truly shared part into `artbeat_core`
2. otherwise orchestrate from the app shell
3. only keep direct cross-feature dependency as a temporary exception with a
   documented reason

## Temporary Exceptions

Until the codebase is refactored, some existing cross-feature dependencies will
remain.

Rule:

- no new cross-feature dependency should be added without recording it in
  `DECISIONS.md`
- every new exception must include an exit plan

## Practical Placement Guide

If you are unsure where code goes:

- reusable across many domains -> `artbeat_core`
- one feature only -> that feature package
- coordinates multiple features at runtime -> root app shell
- backend-only concern -> `functions/` or backend config

## Enforcement Direction

Near-term:

- use this doc as a review rule
- use `docs/PACKAGE_DEPENDENCY_INVENTORY.md` as the concrete baseline for
  current violations

Mid-term:

- add CI checks or review tooling to prevent banned dependency directions

Long-term:

- reduce current violations until package boundaries reflect real ownership
