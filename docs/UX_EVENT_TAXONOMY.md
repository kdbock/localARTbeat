# UX Event Taxonomy (Phase 0 Baseline)

Last updated: May 18, 2026

## Purpose

Provide a single source of truth for first-session UX instrumentation so route, onboarding, and navigation analytics remain consistent across modules.

## Naming Rules

- Use `snake_case` event names.
- Keep parameters flat and primitive when possible.
- Reuse canonical parameter keys below.
- Prefer route constants as parameter values where available.

## Canonical Parameter Keys

- `route_name`
- `source`
- `session_id`
- `user_id`
- `is_authenticated` (0/1)
- `success` (0/1)
- `error_code`
- `error_message`
- `flow`
- `step_index`
- `step_name`
- `role_path`
- `action`
- `duration_ms`
- `has_arguments` (0/1)

## First-Session Funnel Events

### Entry and startup

1. `ux_session_start`
- When: app process starts first foreground session.
- Params: `session_id`, `is_authenticated`, `source` (`cold_start`/`warm_start`).

2. `ux_splash_shown`
- When: splash first frame rendered.
- Params: `session_id`.

3. `ux_splash_to_dashboard`
- When: navigation from splash to dashboard requested.
- Params: `session_id`, `route_name`.

### Onboarding

4. `onboarding_screen_view`
- Existing.
- Params: `flow`, `step_index`, `step_name`, `role_path`.

5. `onboarding_role_selected`
- Existing.
- Params: `flow`, `role`.

6. `onboarding_completion`
- Existing.
- Params: `flow`, `action`, `role_path`.

### Navigation quality

7. `navigation_attempt`
- Existing.
- Params: `route_name`, `has_arguments`, `replace`, `clear_stack`.

8. `navigation_success`
- Existing.
- Params: `route_name`.

9. `navigation_error`
- Existing.
- Params: `route_name`, `error_message`.

10. `ux_first_meaningful_action`
- When: user performs first core action in session (capture, browse, follow, upload, event engage).
- Params: `session_id`, `action`, `route_name`, `duration_ms`.

11. `ux_auth_interrupt`
- When: user intent is interrupted by auth requirement.
- Params: `session_id`, `route_name`, `source`.

12. `ux_route_rendered`
- When: destination route is visibly rendered (post-navigation).
- Params: `route_name`, `source`, `duration_ms`, `success`.

13. `ux_drawer_open`
- When: drawer is rendered/opened for a session interaction.
- Params: `session_id`.

14. `ux_drawer_route_tap`
- When: user taps a drawer route item.
- Params: `session_id`, `route_name`, `source`, `is_main_route`.

## Source Values (Recommended)

- `splash_auto`
- `onboarding`
- `dashboard_cta`
- `drawer`
- `bottom_nav`
- `deep_link`
- `system`

## First Meaningful Actions (Allowed Set)

- `open_capture_dashboard`
- `open_art_walk_dashboard`
- `open_explore_dashboard`
- `open_community_hub`
- `take_first_capture`
- `open_artwork_browse`
- `open_artist_browse`
- `follow_artist`
- `open_events_discover`
- `create_event`
- `start_artist_onboarding`
- `upload_first_artwork`
- `complete_onboarding_fan_action`
- `skip_onboarding`

## Data Quality Checks

- `navigation_attempt` to `navigation_success` conversion should be measurable by route.
- Every `ux_auth_interrupt` should have a downstream login/register or abandonment path.
- `ux_first_meaningful_action` should occur at most once per session.
- Unknown `source` values should be <5% of session events.

## Mapping to Existing Services

- `NavigationService`: `navigation_attempt`, `navigation_success`, `navigation_error` (existing).
- `RouteAnalyticsService`: `route_visit`, `route_performance`, `navigation_source` (existing).
- `OnboardingAnalyticsService`: onboarding events (existing).

## Implementation Order

1. Add `session_id` helper and `ux_session_start`.
2. Emit `ux_splash_shown` and `ux_splash_to_dashboard` in splash flow.
3. Emit `ux_route_rendered` from route render checkpoints.
4. Emit `ux_auth_interrupt` where auth-required guard blocks intent.
5. Emit `ux_first_meaningful_action` from first qualified action only.
