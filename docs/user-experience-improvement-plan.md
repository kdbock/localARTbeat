# ARTbeat User Experience Improvement Plan (Implementation-Based)

Last updated: May 18, 2026  
Scope: Plan derived from actual app implementation files (routes, screens, navigation, onboarding), not product docs.

## Progress Tracker

### Phase 0 Status
- [x] Define funnel events for splash -> dashboard.
- [x] Define funnel events for dashboard -> first action.
- [x] Define funnel events for onboarding complete/skip.
- [x] Define funnel events for auth prompts/interruption after navigation intent.
- [x] Define funnel events for drawer open -> route tap -> successful render.
- [x] Add event taxonomy doc for route-level analytics consistency.
- [x] Create baseline dashboard/reporting queries for KPI reads.

### Phase 1 Status
- [x] Kickoff checklist created for canonical home unification.
- [x] Route inventory and migration execution in progress.
- [x] Legacy `/old-dashboard` gated to debug-only in router.
- [x] Added home-route guardrail tests and legacy-menu exclusion assertion.
- [x] Verified drawer home entries resolve only to canonical `/dashboard`.

### Phase 2 Status
- [x] Phase 2 prioritization plan created.
- [x] First-pass critical auth/home literal-route replacements applied.
- [x] Top-20 drawer route constant migration pass completed.
- [x] Primary dashboard CTA literal-route migration completed.
- [x] Route integrity tests added for migrated drawer/core routes.
- [x] Telemetry validation runbook/report scaffold created for post-change checks.

### Phase 3 Status
- [x] Phase 3 implementation plan scaffold created.
- [x] Checklist and simple-mode implementation completed.
- [x] Checklist state model/service and Phase 3 analytics event schema added (`ux_checklist_shown`, `ux_checklist_step_completed`, `ux_simple_mode_enabled`, `ux_explore_more_opened`).
- [x] Drawer simple-mode navigation filter and `Explore more` expansion implemented.
- [x] Tests added for simple-mode collapsed and expanded drawer behavior.

### Implemented Artifacts
- [x] `docs/UX_EVENT_TAXONOMY.md`
- [x] `ux_session_start` instrumentation
- [x] `ux_splash_shown` instrumentation
- [x] `ux_splash_to_dashboard` instrumentation
- [x] `ux_route_rendered` instrumentation
- [x] `ux_auth_interrupt` instrumentation
- [x] `ux_first_meaningful_action` instrumentation (dashboard + onboarding actions)
- [x] `ux_drawer_open` instrumentation
- [x] `ux_drawer_route_tap` instrumentation
- [x] `docs/UX_BASELINE_QUERIES.md` query pack
- [x] `docs/PHASE1_HOME_UNIFICATION_CHECKLIST.md`
- [x] `docs/PHASE1_HOME_ROUTE_INVENTORY.md` (route tags, ownership, profile/settings route map)
- [x] `docs/PHASE2_ROUTE_STANDARDIZATION_PLAN.md`
- [x] `docs/PHASE2_TELEMETRY_VALIDATION_REPORT.md`
- [x] `docs/PHASE3_FIRST_SESSION_PROGRESSIVE_DISCLOSURE_PLAN.md`

## 1. Objective

Improve ARTbeat usability and comprehension while preserving feature depth by:
- Reducing first-session cognitive load
- Making navigation and route behavior consistent
- Clarifying the primary home/dashboard model
- Improving accessibility and ease-of-use for older and new users

## 2. Baseline Assessment (From Code)

### 2.1 Overall Scores (Out of 10)
- Features/functions depth: 9.0
- Ease of use: 6.0
- Understanding/clarity: 5.5

### 2.2 Persona Scores

#### New user
- Features/functions: 7.0
- Ease of use: 6.0
- Understanding: 6.0

#### Older user
- Features/functions: 6.0
- Ease of use: 5.0
- Understanding: 5.0

#### Younger user
- Features/functions: 8.5
- Ease of use: 7.0
- Understanding: 6.5

#### Tech-savvy user
- Features/functions: 9.0
- Ease of use: 7.5
- Understanding: 7.0

## 3. Key Findings

### 3.1 Entry and launch behavior
- Splash routes to dashboard quickly, creating a fast entry impression.
- Some auth gating occurs later in user flows, not always before first actionable screens.
- Impact: users can be confused when they appear “in” then are blocked on deeper actions.

### 3.2 Authentication flow quality
- Login UX is strong (email/password + Google + Apple on iOS, validation and error feedback).
- Route usage patterns are mixed in code (constants and string literals), which can increase edge-case inconsistency.

### 3.3 First-run onboarding
- Role-first onboarding is short and clear (fan vs artist).
- Skip + immediate full feature surface can still overwhelm new users.

### 3.4 Navigation architecture
- App has broad, route-dense navigation across multiple domains.
- Drawer includes a very large actionable route surface.
- Impact: excellent depth, lower discoverability and higher cognitive load.

### 3.5 Dashboard model
- More than one dashboard-style experience is reachable (primary and legacy paths).
- Impact: users may not know which “home” is canonical.

### 3.6 Accessibility and motion load
- High-motion visual style is immersive but may challenge older users or motion-sensitive users.
- A simpler, lower-motion mode is not the default first-run path.

## 4. Strategy

### 4.1 Strategic principles
- One clear home
- Progressive disclosure over breadth-first exposure
- Consistent route contracts
- Accessible-by-default interaction patterns
- Role-aware guidance (fan vs artist)

### 4.2 Success criteria
- Improve ease-of-use score from 6.0 to >= 7.5
- Improve understanding score from 5.5 to >= 7.5
- Improve older-user ease from 5.0 to >= 7.0
- Reduce first-session abandonment (analytics-defined)
- Reduce route-failure and dead-end navigation events

## 5. Execution Plan (Phased)

## Phase 0: Instrumentation and Baseline (Week 1)

Goal: Establish measurable UX baseline before behavior changes.

Deliverables:
- Define funnel events for:
  - splash -> dashboard
  - dashboard -> first action
  - onboarding complete/skip
  - auth prompts triggered after navigation
  - drawer open -> route tap -> successful render
- Add event taxonomy doc for route-level analytics consistency.
- Create baseline dashboard for:
  - first-session completion rate
  - first meaningful action time
  - auth interruption rate
  - top failed/abandoned routes

Acceptance criteria:
- Baseline metrics available and queryable.
- All critical first-session events emit consistently.

## Phase 1: Information Architecture and Home Unification (Weeks 2-3)

Goal: Remove “which home?” ambiguity and simplify first decision points.

Deliverables:
- Define single canonical home dashboard for all entry points.
- Keep legacy dashboard only as internal/debug path (not user-facing nav).
- Update entry routing so all user-facing home transitions resolve to one path.
- Normalize dashboard labels/navigation affordances across drawer and shortcuts.

Acceptance criteria:
- 100% of home-entry paths land in canonical dashboard.
- No user-facing path references legacy dashboard nomenclature.

## Phase 2: Route and Navigation Consistency (Weeks 3-4)

Goal: Remove mixed route contracts and reduce navigation defects.

Deliverables:
- Route contract standard:
  - prefer centralized route constants for app-owned routes.
  - remove user-critical literal route strings where constants exist.
- Audit and refactor critical flows first:
  - auth -> dashboard
  - dashboard CTAs
  - drawer top 20 most-used routes
  - profile and settings jumps
- Add route integrity tests for high-frequency paths.

Acceptance criteria:
- Critical route flows use standardized route definitions.
- Navigation error frequency decreases from baseline.

## Phase 3: First-Session Progressive Disclosure (Weeks 4-5)

Goal: Reduce cognitive overload for new and older users.

Deliverables:
- Post-onboarding guided checklist with 3 role-based actions:
  - Fan path examples: discover nearby art, follow one artist, save first artwork.
  - Artist path examples: complete profile, upload first work, view creator dashboard tool.
- Introduce “simple mode” first-session nav profile:
  - reduced drawer sections
  - larger tap targets
  - fewer simultaneous CTAs
- Gate non-essential advanced modules behind “Explore more” expansion.

Acceptance criteria:
- Increase first meaningful action completion rate.
- Reduction in early-session idle/drop-off after onboarding.

## Phase 4: Accessibility and Motion Controls (Weeks 5-6)

Goal: Improve comfort and usability for older and motion-sensitive users.

Deliverables:
- Add visible “Reduce motion” preference surfaced early.
- Tone down non-essential ambient animations when preference is enabled.
- Improve readability defaults in simple mode:
  - larger typography scale option
  - stronger contrast in key controls
  - clearer button hierarchy
- Validate critical flows with larger text settings.

Acceptance criteria:
- Older-user task completion improves in usability sessions.
- Motion-preference usage and retention tracked.

## Phase 5: Auth Gating Clarity (Week 6)

Goal: Minimize surprise login interruptions.

Deliverables:
- Align auth gating with user intent:
  - allow broad browsing where appropriate
  - prompt earlier and more clearly before protected actions
- Add pre-action auth prompts with explicit value messaging.
- Ensure consistent return-to-intent behavior after login.

Acceptance criteria:
- Lower mid-flow auth interruption frustration signals.
- Higher completion of protected actions after login.

## Phase 6: Validation, Cleanup, and Rollout (Weeks 7-8)

Goal: Validate outcomes and finalize UX stability.

Deliverables:
- Usability test pass with all four personas:
  - new user
  - older user
  - younger user
  - tech-savvy user
- A/B or staged rollout for major nav changes.
- Remove deprecated nav artifacts and stale route aliases where safe.
- Publish post-change UX scorecard.

Acceptance criteria:
- Target scores met or trending within 10% of target.
- No regression in core engagement metrics.

## 6. Workstreams and Ownership

### Workstream A: Navigation and Routing
- Own route contract standardization.
- Own dashboard entry-path unification.
- Own navigation integrity tests.

### Workstream B: Onboarding and First Session
- Own checklist and progressive disclosure logic.
- Own simple-mode defaults and first-run toggles.

### Workstream C: Accessibility and Visual Comfort
- Own reduce-motion pathway.
- Own readability and target sizing improvements.

### Workstream D: Analytics and Validation
- Own metrics instrumentation and reporting.
- Own persona-based usability verification.

## 7. Risk Register and Mitigations

### Risk: Feature discoverability drops after simplification
- Mitigation: progressive disclosure, not removal; “Explore more” entry points.

### Risk: Route refactor introduces regressions
- Mitigation: prioritize high-frequency paths first; add integration route tests.

### Risk: Perceived loss of brand personality with reduced motion
- Mitigation: maintain visual identity while reducing non-essential animation only in accessibility modes.

### Risk: Team churn from broad cross-package updates
- Mitigation: phase by critical path, use clear route contract checklist, enforce CI checks on navigation tests.

## 8. Testing Plan

### 8.1 Functional UX tests
- Splash to home behavior
- Auth sign-in and return-to-intent
- Onboarding completion and skip branches
- Drawer navigation to top destinations
- Profile/settings/action loop completion

### 8.2 Persona usability scripts
- New user: discover and engage with one piece of art
- Older user: complete one core action with minimal confusion
- Younger user: complete discovery + social interaction quickly
- Tech-savvy user: find advanced feature paths efficiently

### 8.3 Non-functional checks
- Performance under reduced-motion and standard modes
- Readability checks with larger text settings
- Crash/error rates during navigation transitions

## 9. KPI Scorecard

Primary KPIs:
- First-session completion rate
- Time to first meaningful action
- Auth interruption rate in first session
- Navigation failure/error rate
- Persona task completion success rate

Secondary KPIs:
- Retention day 1/day 7 by persona segment (if available)
- Feature adoption rate for guided checklist tasks
- Simple mode opt-in and sustained usage

## 10. Definition of Done

The UX improvement plan is complete when:
- Canonical home and route consistency are in production.
- Progressive disclosure and simple mode are live for first-session users.
- Accessibility motion/readability controls are live and discoverable.
- KPI targets show statistically meaningful improvement against baseline.
- Deprecated user-facing dashboard/path confusion is removed.

## 11. Immediate Next Actions

1. Approve this plan and lock phase scope.
2. Implement Phase 0 instrumentation in current sprint.
3. Start Phase 1 home unification and Phase 2 route consistency in parallel.
4. Schedule persona usability validation sessions before Phase 4 completion.

## 13. What’s Next (Current Execution)

Phase 1 home unification and Phase 2 route consistency are complete enough to move forward.  
Next active phase: **Phase 4 - Accessibility and Motion Controls**.

### Next 5 execution tasks

1. Build a prioritized route-standardization list for top user-critical flows:
   - auth -> dashboard
   - dashboard CTAs
   - drawer top 20 routes
   - profile/settings jumps
2. Replace remaining user-critical literal route strings with centralized constants where available.
3. Add/expand route integrity tests for these critical flows.
4. Add route deprecation notes for any legacy aliases still intentionally retained.
5. Run a post-change telemetry check using:
   - `ux_route_rendered`
   - `navigation_error`
   - `ux_auth_interrupt`

### Definition of done for this next step

- Critical user flows use standardized route definitions.
- No increase in navigation error rate.
- Route behavior remains canonical with `/dashboard` as home.

## 12. Visual Identity and Animation Guardrails (Anti-Boring Requirements)

This section is mandatory for all UX improvements in this plan.

### 12.1 Non-negotiable design intent
- ARTbeat must remain immersive, energetic, and instantly recognizable.
- UX simplification must reduce confusion, not flatten personality.
- Every major screen should retain a sense of atmosphere (depth, motion, and visual storytelling).

### 12.2 Motion system standards
- Keep meaningful macro motion:
  - screen-intro transitions
  - ambient world/background animation
  - celebratory state changes (achievement/progress moments)
- Avoid random micro-motion noise that adds distraction without meaning.
- Motion must communicate hierarchy, focus, and progress.

### 12.3 Motion tier model

Use three motion tiers instead of “on/off” styling:

1. Full Motion (default)
- Rich ambient effects, world background movement, layered transitions.
- Used for most users and flagship experiences.

2. Balanced Motion
- Reduced animation intensity and frequency.
- Keeps brand atmosphere while lowering cognitive/visual load.
- Used for users who need calmer UX but still want visual richness.

3. Reduced Motion (accessibility)
- Removes non-essential ambient loops and high-frequency effects.
- Retains core transition clarity and key feedback animations.
- Must never degrade into a plain, lifeless UI.

### 12.4 Screen-level design quality bars
- Dashboard screens:
  - maintain cinematic depth (gradient/vignette/layering)
  - preserve signature CTA treatment and motion cues
- Auth/onboarding:
  - maintain premium visual lockup and animated entrance hierarchy
  - keep first actions visually bold and obvious
- Drawers/navigation panels:
  - maintain themed styling and section rhythm
  - avoid generic list-only flat menus without visual structure

### 12.5 Theme consistency requirements
- Define and enforce a shared motion token set:
  - durations
  - easing curves
  - delay patterns
  - stagger behavior
- Define and enforce visual token set:
  - background layers
  - glow/accent usage
  - corner radii
  - depth/shadow rules
- Do not introduce isolated visual patterns that break ARTbeat’s established language.

### 12.6 Anti-boring acceptance criteria

A UX change cannot be marked complete unless it passes all checks:
- Brand presence check:
  - Screen is clearly recognizable as ARTbeat within 2 seconds.
- Motion meaning check:
  - At least one purposeful motion pattern supports orientation or feedback.
- Atmosphere check:
  - Screen includes depth (not flat single-layer UI).
- Clarity check:
  - Visual richness does not block task comprehension.
- Accessibility check:
  - Balanced/Reduced tiers preserve brand quality while improving comfort.

### 12.7 Validation workflow for design quality
- Add review snapshots/video captures per phase for:
  - full motion
  - balanced motion
  - reduced motion
- Run quick internal “boring regression” review before release:
  - If screen appears generic or template-like, revise before merge.
- Include design QA sign-off alongside functional QA for all dashboard/nav/onboarding changes.

### 12.8 KPI additions for visual quality
- Perceived delight score from usability sessions.
- “Feels premium/immersive” agreement rate.
- “Feels confusing or noisy” disagreement rate.
- Retention delta between full and balanced motion cohorts.

Plan support artifact:
- docs/UX_EVENT_TAXONOMY.md (Phase 0 event contract)
- docs/UX_BASELINE_QUERIES.md (Phase 0 KPI query pack)
