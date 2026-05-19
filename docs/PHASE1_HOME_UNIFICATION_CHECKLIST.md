# Phase 1 Home Unification Checklist

Last updated: May 18, 2026

## Goal

Ensure ARTbeat has one canonical home experience for all user-facing entry paths, while preserving themed visuals and motion quality.

## Current Reality (from implementation)

- Primary route `/dashboard` currently resolves to `AnimatedDashboardScreen`.
- Legacy route `/old-dashboard` is still reachable from current UI flows.
- Multiple modules reference dashboard-like destinations directly with string routes.

## Scope

In scope:
- User-facing navigation and entry routes that can land on home/dashboard experiences.
- Drawer and dashboard CTA links that reference legacy home.
- Labels and copy that imply multiple "home" concepts.

Out of scope:
- Removing visual richness/theme motion.
- Deep refactor of non-home feature modules.

## Canonical Decision

- Canonical home route: `/dashboard`
- Canonical home screen: `AnimatedDashboardScreen`
- Legacy dashboard (`/old-dashboard`) allowed only for internal debug/testing access.

## Task Checklist

### A. Route Inventory and Classification
- [x] Build route inventory for all references to `/dashboard` and `/old-dashboard`.
- [x] Tag each reference as user-facing vs internal/debug.
- [x] Identify cross-package ownership for each reference.

### B. User-Facing Path Migration
- [x] Replace user-facing pushes to `/old-dashboard` with `/dashboard`.
- [x] Keep internal debug switches behind debug-only gates.
- [ ] Validate onboarding and auth transitions always land on `/dashboard`.

### C. Navigation Surface Consistency
- [x] Ensure drawer "home" item points only to `/dashboard`.
- [x] Ensure quest/CTA buttons that represent home/explore do not deep-link to legacy dashboard.
- [x] Ensure profile/settings back-to-home actions resolve consistently.

### D. UX Copy and Naming
- [ ] Remove user-visible labels that imply two dashboard modes unless explicitly branded as advanced/debug.
- [ ] Keep experiential tone and animations unchanged while simplifying path semantics.

### E. Guardrails and Tests
- [x] Add route integrity tests for home path invariants.
- [x] Add smoke test: splash -> dashboard, login -> dashboard, onboarding -> dashboard.
- [x] Add assertion that legacy route is not present in user-facing menus.

## Acceptance Criteria

- 100% of user-facing home entries resolve to `/dashboard`.
- No user-visible flow sends users to `/old-dashboard`.
- Existing themed visual language remains intact on canonical home.
- Navigation error rates do not regress after migration.

## Rollout Plan

1. Merge route reference changes in small batches.
2. Validate telemetry (`ux_route_rendered`) for home route concentration.
3. Remove or hard-gate remaining legacy entry points.
4. Final pass on copy consistency.

## Telemetry Checks (Post-change)

- `ux_route_rendered` where `route_name = '/dashboard'` should increase concentration.
- `ux_route_rendered` where `route_name = '/old-dashboard'` should drop to near-zero in production flows.
- `ux_auth_interrupt` and navigation error rates should remain stable or improve.
