# ARTbeat Art Walk - User Experience Guide

This guide reflects the current `artbeat_art_walk` package behavior and route flow.

## Core User Journeys

1. Discover
- Open dashboard/list/map surfaces.
- Browse or filter available walks.
- Enter detail view for a selected walk.

2. Start a Walk
- Start from detail/review flow into experience.
- Progress tracking starts and is persisted under `artWalkProgress`.

3. Navigate and Visit Art
- Follow generated navigation steps.
- Each art visit can award points based on proximity and optional photo proof.
- Milestone XP can trigger at progress thresholds.

4. Manage Active Walk
- Pause/resume through progress lifecycle.
- Complete or abandon walk.
- Completion computes bonus XP (base + conditional bonuses).

5. Post-Walk
- Celebration flow renders when valid `CelebrationData` is supplied.
- If celebration payload is missing, user sees a safe fallback screen.

## Active Route Surface

Configured by `ArtWalkRouteConfig` and `ArtWalkRoutes`.

- Static routes:
  - `/art-walk/map`
  - `/art-walk/list`
  - `/art-walk/dashboard`
  - `/quest-history`
  - `/weekly-goals`
  - `/instant-discovery`
- Generated route handlers:
  - `/art-walk/detail`
  - `/art-walk/review`
  - `/art-walk/experience`
  - `/art-walk/create`
  - `/art-walk/edit`
  - `/enhanced-create-art-walk`
  - `/art-walk/celebration`

## UX-Sensitive Contracts

- Progress state is explicit:
  - `notStarted`
  - `inProgress`
  - `paused`
  - `completed`
  - `abandoned`
- Completion readiness in model:
  - `canComplete` at `>= 80%`
- Duplicate art visits are ignored to prevent double credit.
- Missing/invalid route arguments should fail safely (null route or fallback UI).

## Accessibility and Resilience Expectations

- Fail-safe route handling for invalid navigation payloads.
- Persisted progress so users can resume.
- Security layer sanitizes user-generated text for walks/comments.
- Validation rejects prohibited content, spam patterns, and invalid ZIP/tag shapes.

## Testing Focus (Current)

Implemented tests cover:
- Service contracts:
  - `ArtWalkService`
  - `ArtWalkProgressService`
  - `ArtWalkNavigationService`
  - `ArtWalkSecurityService`
- Route behavior:
  - known route wiring
  - unknown route null return
  - celebration fallback UI
- Widget behavior:
  - `GradientCTAButton` interaction/loading states
  - `GlassCard` tap behavior

Recommended next wave:
1. Add widget tests for navigation overlays and map action widgets with fake dependencies.
2. Add integration-style tests for experience screen lifecycle (`start -> pause -> resume -> complete`) with mocked services.
