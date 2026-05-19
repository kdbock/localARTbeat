# Phase 3 First-Session Progressive Disclosure Plan

Last updated: May 18, 2026

## Objective

Reduce first-session cognitive load while preserving ARTbeat’s immersive identity by introducing guided, role-aware progression and a simplified first-session navigation mode.

## Scope

In scope:
- Post-onboarding “first 3 actions” checklist
- Role-specific first-session task flows (fan vs artist)
- Simple mode navigation profile for first sessions
- Non-destructive gating of advanced modules behind “Explore more”

Out of scope:
- Removing existing features
- Replacing ARTbeat visual language or animation style

## Deliverables

1. Guided Checklist (Post-Onboarding)
- Fan path:
  - Discover nearby art
  - Follow one artist
  - Save one artwork
- Artist path:
  - Complete profile basics
  - Upload first work
  - Open artist dashboard tool

2. Simple Mode (First Session)
- Reduced drawer sections
- Larger tap targets
- Fewer simultaneous CTAs
- Maintain theme fidelity (not a flat UI)

3. Explore More Expansion
- Keep advanced modules accessible via explicit expansion entry points
- Avoid feature removal; use progressive reveal

## Technical Approach

### A. Checklist state model
- Store first-session checklist status per user in lightweight state (local + optional backend sync).
- Mark checklist completion events for analytics.

### B. Role-aware orchestration
- Reuse existing onboarding role selection output.
- Map role to checklist config and CTA destinations.

### C. Simple mode rendering
- Add a simple-mode flag in onboarding/session state.
- Route drawer/menu builders through a filtered config when flag is active.

### D. Theme guardrails
- Preserve motion tiers and anti-boring constraints from UX plan section 12.
- Ensure simple mode reduces complexity, not brand character.

## Measurement Hooks

Add/confirm events:
- `ux_checklist_shown`
- `ux_checklist_step_completed`
- `ux_simple_mode_enabled`
- `ux_explore_more_opened`

Track:
- first meaningful action completion rate
- time to first meaningful action
- early session drop-off after onboarding

## Phase 3 Execution Checklist

- [x] Define checklist data model and event schema
- [ ] Implement fan checklist UI + actions
- [ ] Implement artist checklist UI + actions
- [ ] Implement simple mode navigation filter
- [ ] Implement “Explore more” expansion access
- [ ] Add tests for checklist progression and simple mode behavior
- [ ] Validate first-session KPI movement

## Acceptance Criteria

- First-session completion rate improves from Phase 0 baseline.
- Time to first meaningful action improves for new/older cohorts.
- No measurable drop in feature discoverability due to progressive reveal.
- Visual quality remains consistent with anti-boring guardrails.
