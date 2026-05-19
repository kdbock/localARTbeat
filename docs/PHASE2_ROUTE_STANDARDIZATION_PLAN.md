# Phase 2 Route Standardization Plan

Last updated: May 18, 2026

## Objective

Standardize user-critical navigation flows to centralized route constants and reduce literal-string drift.

## Priority Buckets

### P0 (Immediate)
- Auth -> Dashboard transition paths
- Dashboard CTA paths in primary home screens
- Drawer top navigation routes
- Profile/settings jumps that affect return-to-home consistency

### P1 (Next)
- Feature headers and secondary menus (events/messaging/artwork)
- Module-local helper classes still using literals where constants exist

### P2 (Later)
- Low-traffic/debug/developer-only routes
- Legacy aliases intentionally retained for backward compatibility

## Initial High-Impact Findings

1. `packages/artbeat_auth/lib/src/screens/login_screen.dart`
- Mixed use of `AuthRoutes.dashboard` and literal `'/dashboard'`.
- Action: replace literal with route constant.

2. `lib/src/guards/auth_guard.dart`
- Uses literal `'/auth'` for sign-in redirect.
- Action: replace with `core.AppRoutes.auth`.

3. `lib/src/services/navigation_service.dart`
- Critical home fallback/telemetry switch uses literals for `/dashboard` and others.
- Action: replace dashboard literal with `AppRoutes.dashboard` where compatible.

## Phase 2 Execution Checklist

- [x] Create prioritized route standardization plan doc.
- [x] Apply first-pass replacements in critical auth/home flows.
- [x] Build top-20 drawer route constant migration checklist.
- [x] Migrate top-20 drawer route literals to `AppRoutes` where available.
- [x] Migrate dashboard CTA literal routes where constants exist.
- [x] Add/expand route integrity tests for migrated routes.
- [x] Validate telemetry impact after each batch (runbook/report template created).

## Validation Criteria

- No regressions in auth-to-home transitions.
- `navigation_error` does not increase.
- `ux_route_rendered` for `/dashboard` remains healthy.
