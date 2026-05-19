# Phase 2 Telemetry Validation Report

Last updated: May 18, 2026
Status: Prepared (runbook complete, data-entry pending)

## Purpose

Validate that Phase 2 route standardization changes did not introduce regressions and improved consistency signals.

Uses existing query pack:
- `docs/UX_BASELINE_QUERIES.md`

## Validation Window

- Pre-change window: __________________
- Post-change window: _________________
- Environment: production / staging (circle one)
- Dataset: `<PROJECT>.<DATASET>`

## Metrics to Compare

1. `navigation_error` rate
2. `ux_auth_interrupt` rate
3. `ux_route_rendered` success rate (especially `/dashboard`)
4. `ux_route_rendered` p50/p90 latency for top routes

## Query Mapping

- Route render health: Section 5 in `UX_BASELINE_QUERIES.md`
- Auth interruption rate: Section 3
- Top interrupted routes: Section 4
- Session baseline context: Section 1 and 2

## Results Table

| Metric | Pre-change | Post-change | Delta | Pass/Fail | Notes |
|---|---:|---:|---:|---|---|
| Navigation error rate | ___ | ___ | ___ | ___ | ___ |
| Auth interruption rate | ___ | ___ | ___ | ___ | ___ |
| `/dashboard` render success rate | ___ | ___ | ___ | ___ | ___ |
| `/dashboard` p50 render ms | ___ | ___ | ___ | ___ | ___ |
| `/dashboard` p90 render ms | ___ | ___ | ___ | ___ | ___ |

## Route Consistency Spot Check

Top routes to inspect in post-change data:
- `/dashboard`
- `/settings`
- `/art-walk/dashboard`
- `/community/hub`
- `/events/discover`

Checkpoints:
- Are route names canonical and expected?
- Is `source` populated sensibly (`direct_handler`, `specialized_handler`, etc.)?
- Any spike in `not_found` source rows?

## Acceptance Criteria

Pass if all are true:
- Navigation error rate does not increase materially.
- Auth interruption rate does not regress materially.
- `/dashboard` route render success remains stable or improves.
- No unexpected increase in render latency for top routes.

## Execution Notes

- If BigQuery export is delayed, use Firestore fallback checks in `UX_BASELINE_QUERIES.md` Section 7.
- Record exact query timestamps and table suffix ranges used.

## Decision

- [ ] Pass - proceed with next Phase 2 migration batch.
- [ ] Hold - investigate regressions before additional route migrations.

Owner: __________________
Date completed: __________________
