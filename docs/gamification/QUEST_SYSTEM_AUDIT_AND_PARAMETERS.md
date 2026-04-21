# Quest System Audit (Daily + Weekly) and Industry-Standard Parameters

## Scope
- `packages/artbeat_art_walk/lib/src/services/challenge_service.dart`
- `packages/artbeat_art_walk/lib/src/services/weekly_goals_service.dart`
- `packages/artbeat_art_walk/lib/src/services/rewards_service.dart`
- `packages/artbeat_art_walk/lib/src/models/challenge_model.dart`
- `packages/artbeat_art_walk/lib/src/models/weekly_goal_model.dart`

## Audit Findings (ordered by severity)

### 1) Perfect week badge logic is broken (badge may never award)
- In `RewardsService.checkPerfectWeek`, `weekKey` is parsed with `_` separators, but callers pass format `YYYY-Www`.
- Current code:
  - `.split('_')[0]` and `.split('_')[1]` in [rewards_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_art_walk/lib/src/services/rewards_service.dart:799)
  - caller passes `_getWeekKey` output in [weekly_goals_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_art_walk/lib/src/services/weekly_goals_service.dart:516)
- Impact: parse errors and/or wrong query filters, so `perfect_week` and `perfect_month` progression is unreliable.

### 2) Combo bonus code path is unreachable as implemented
- `calculateXPWithMultiplier` only applies the daily+weekly combo when both flags are true in the same award call.
- Calls currently pass either daily or weekly, never both:
  - daily completion in [challenge_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_art_walk/lib/src/services/challenge_service.dart:421)
  - weekly completion in [weekly_goals_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_art_walk/lib/src/services/weekly_goals_service.dart:499)
- Impact: intended combo economy and `combo_master` progression are effectively disabled.

### 3) Challenge progress matching relies on English title text
- Progress routing uses `title.contains(...)` checks (e.g., `Discover`, `Photo`, `Walk`) in [challenge_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_art_walk/lib/src/services/challenge_service.dart:626).
- Challenges are localized via `.tr()`, so titles vary by language.
- Impact: daily quests can fail to progress in non-English locales.

### 4) Weekly mastery trackers compare localized title to hardcoded English
- `trackDailyQuestCompletion` and `trackStreakDay` look for exact `'Quest Master'` / `'Streak Keeper'` title strings in [weekly_goals_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_art_walk/lib/src/services/weekly_goals_service.dart:615).
- Impact: mastery weekly goals may not update depending on locale string content.

### 5) Duplicate XP fields (`totalXP` vs `experiencePoints`) cause inconsistent reads
- Stats readers use `totalXP` in challenge/weekly services:
  - [challenge_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_art_walk/lib/src/services/challenge_service.dart:379)
  - [weekly_goals_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_art_walk/lib/src/services/weekly_goals_service.dart:463)
- XP writer uses `experiencePoints` in rewards service:
  - [rewards_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_art_walk/lib/src/services/rewards_service.dart:428)
- Impact: personalization/scaling can read stale or zero XP depending on which field is populated.

### 6) Streak and category extraction depend on localized title keywords
- Category extraction checks English words in title in [challenge_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_art_walk/lib/src/services/challenge_service.dart:606).
- Impact: streak analytics and category-specific rewards can silently fail outside English.

### 7) Parameters are hardcoded and duplicated in multiple services
- Scaling bands and reward magnitudes are repeated in both daily and weekly services.
- Impact: balancing changes are high risk and difficult to tune systematically.

## Industry-Standard Parameter Baseline (recommended)

These values are practical defaults for mid-core retention systems where quests are daily habit drivers, not primary progression economy.

### Cadence and structure
- Daily quests surfaced: `1`
- Daily quest target completion rate: `45% - 65%`
- Weekly goals surfaced: `3`
- Weekly goal completion rate target: `20% - 35%` per goal
- Perfect week target rate: `5% - 10%`

### Difficulty distribution (daily)
- Easy: `50%` of assignments, expected effort `2-5 min`
- Medium: `35%`, expected effort `5-12 min`
- Hard: `15%`, expected effort `12-20 min`

### XP economy baseline
- Daily quest base XP band: `40 - 90`
- Weekly goal base XP band: `300 - 700`
- Weekly-to-daily value ratio: target `~7x`
- Daily login base XP: `10`
- Streak login multiplier caps: `max 3x` baseline

### Scaling bands (by level)
- Level `1-5`: `1.00x` target, `1.00x` reward
- Level `6-10`: `1.15x` target, `1.10x` reward
- Level `11-20`: `1.30x` target, `1.20x` reward
- Level `21+`: `1.45x` target, `1.30x` reward

Note: current implementation scales rewards more aggressively than targets at higher levels (`up to 2.0x`), which can inflate economy.

### Combo and streak modifiers
- Multiple quest completions same day:
  - 2 quests: `1.15x`
  - 3+ quests: `1.30x`
- Daily+weekly same day bonus (if kept): `+0.15x`
- Hard cap on total multiplier: `1.50x`

### Guardrails
- Max XP from quests per day soft cap: `350`
- Max XP from login per day: `1 claim`
- Weekly quest XP share of total XP inflow target: `25% - 40%`

## Implementation Recommendations

### P0 (fix now)
- Fix `weekKey` parsing in `checkPerfectWeek` to consume `YYYY-Www` correctly.
- Replace title-matching logic with stable, non-localized identifiers (e.g., `challengeTemplateId`, `goalTemplateId`, `categoryId`).
- Make combo evaluation state-based (completed daily + weekly flags on the same date), not call-argument-based.

### P1 (stabilize)
- Normalize XP source-of-truth field to `experiencePoints` everywhere and migrate reads.
- Centralize all economy parameters into a single config surface.
- Add server-side anti-abuse guardrails for rapid repeated increments.

### P2 (optimize)
- Add assignment weighting by user segment and recent completion history.
- Add telemetry dashboards: assignment rate, completion rate, time-to-complete, XP inflation, badge unlock pace.

## Suggested Next Step
- Apply a single constants file and refactor both services to consume it, then run a 2-week balance pass with telemetry thresholds above.

## User-Centered Audit (Player Experience Lens)

This section evaluates the system as a player would feel it, independent of implementation quality.

### Overall player impression
- The quest system has strong presentation potential (clear cards, visible progress, streak framing), but the motivational loop is fragile because completion triggers are not always transparent or reliable from a user standpoint.
- A player will likely enjoy the concept in week 1, then lose trust if progress seems inconsistent (especially across locale/language or specific quest types).

### What currently feels good to a player
- Daily quest card gives immediate goal + progress + reward at a glance.
- Weekly goals card provides visible progress bars, milestones, and XP payoff, which supports medium-term motivation.
- Quest history includes streak, completion count, and XP total, giving identity progression and “I’m improving” reinforcement.
- The UI has enough visual hierarchy to make quests feel like a core feature, not a hidden system.

### Player pain points (ordered by impact)

#### 1) Trust risk: “I did it, but it didn’t count”
- Many progress triggers depend on title text matching and time-window heuristics.
- User perception: actions feel arbitrary when progress doesn’t increment exactly when expected.
- Product effect: trust collapse is faster than in most systems because this is habit-loop content.

#### 2) Clarity gap: no explicit “what exactly counts” rules
- The UI shows target counts and XP, but criteria are often implicit.
- Example player confusion:
  - “Does sharing to story count, or only feed posts?”
  - “What counts as a neighborhood?”
  - “Do multiple photos of the same artwork count?”
- Product effect: users optimize for certainty, not for discovery/fun.

#### 3) Weak weekly agency
- Weekly goals are shown, but the screen uses a generic `Progress` CTA without clear action affordance.
- User perception: “I can read goals but not clearly launch the next step from here.”
- Product effect: lower weekly conversion and lower perfect-week attempts.

#### 4) Reward economy feels hard to predict
- XP is visible, but multiplier logic is not legible in UX.
- User perception: “Sometimes I get more XP, but I don’t know why.”
- Product effect: reward salience drops because players can’t form strategy.

#### 5) New-user onboarding to quests is thin
- The interface explains current quest state but not the meta-loop well (daily rhythm, weekly cadence, streak protection).
- User perception: system is visually rich but mentally expensive to understand early on.
- Product effect: lower D1->D7 quest retention.

#### 6) Localization UX inconsistency risk
- Quest naming and type descriptions are mixed with static English mappings in places.
- Non-English user perception: partial translation quality or inconsistent behavior.
- Product effect: perceived product polish gap in international cohorts.

### UX scorecard (player perspective)
- Discoverability: `8/10`
- Clarity of rules: `5/10`
- Perceived fairness: `4/10`
- Motivation/aspiration: `7/10`
- Sense of progress: `7/10`
- Reliability trust: `4/10`
- Long-term habit potential: `6/10`

### Industry-standard UX parameters (player-facing)

These are player experience standards, not only economy standards.

- Daily quest should be completable in `5-12` minutes for median active users.
- Weekly goal should be completable in `3-5` sessions in a normal week.
- Every quest type must expose a one-line “Counts when…” rule in UI.
- Progress feedback delay should be `<= 2 seconds` after a qualifying action.
- If an action does not qualify, show immediate reason (“Need unique neighborhood”, “Need 50+ chars”, etc.).
- Streak logic must tolerate one short offline/reconnect window without silent loss.
- Users should be able to see “why XP changed” for the latest reward event.

### Recommended UX changes before code-level tuning

#### P0: Trust and clarity first
- Add explicit per-quest qualification rules directly on daily/weekly cards.
- Add immediate event feedback after tracked actions:
  - `+1 progress` toast/snackbar on success.
  - short “not counted because …” feedback on rejection.
- Add a mini “XP breakdown” line on completion (base + bonus + multiplier).

#### P1: Improve agency and momentum
- Replace generic weekly `Progress` CTA with action-specific CTA labels:
  - `Start Exploring`, `Capture Photo`, `Share Now`, `Continue Streak`.
- Add “next best action” hint under each weekly goal.
- Add “near complete” urgency state at >=80% (visual + copy).

#### P2: Sustain weekly retention
- Add “streak shield” mechanic (1 miss/day forgiveness token per 14 days).
- Add weekly recap card with: completed, missed, almost completed, and suggested focus for next week.
- Add “choose 1 of 2 dailies” for advanced users to increase autonomy.

### Player-journey acceptance criteria (definition of done)
- A new player can explain how to complete today’s quest in under 10 seconds of reading.
- A returning player can predict XP outcomes for a quest completion before tapping.
- A failed qualification event always returns immediate, human-readable feedback.
- A weekly goal screen always provides an actionable next step from the current context.

## Full Recommendation Blueprint (All Identified Areas)

This plan is designed to resolve every issue identified in both the technical and user-centered audits, while minimizing risk during rollout.

### 1) Product Principles (non-negotiable)
- Reliability before novelty: if progression is not trusted, no feature expansion matters.
- Explicit rules over hidden logic: every quest must state what counts.
- One source of truth for progression state and XP.
- Config-driven tuning, not hardcoded behavior.
- Ship in measurable phases with guardrails and rollback.

### 2) Target Architecture

#### 2.1 Canonical quest identity model
- Add stable IDs for templates and event mappings:
  - `challengeTemplateId` (daily)
  - `goalTemplateId` (weekly)
  - `categoryId` (exploration, photo, social, fitness, mastery, collection)
- Never use localized title text for progression logic.

#### 2.2 Canonical user progression fields
- Keep one XP field: `experiencePoints`.
- Deprecate `totalXP` reads/writes from quest services.
- Canonical stats shape:
  - `stats.challengesCompleted`
  - `stats.weeklyGoalsCompleted`
  - `stats.loginStreak`
  - `stats.longestLoginStreak`
  - `stats.comboCompletions`
  - `stats.consecutivePerfectWeeks`

#### 2.3 Quest event pipeline
- All activity events map to a typed enum-like key:
  - `art_discovered`, `photo_captured`, `distance_walked`, `steps_recorded`, `share_completed`, `comment_posted`, `review_submitted`, `time_window_discovery`, etc.
- Progress evaluation uses IDs + event payloads, never strings.
- Return structured result to UI for instant feedback:
  - `counted: true/false`
  - `reasonCode`
  - `increment`
  - `newProgress`
  - `xpAwarded`

### 3) Economy and Difficulty Recommendations

#### 3.1 Difficulty distribution
- Daily pool mix: `50% easy`, `35% medium`, `15% hard`.
- Weekly goals: always 3 goals from distinct categories.
- Weekly generation should avoid assigning two high-friction goals together.

#### 3.2 XP and multipliers
- Adopt baseline in `quest_tuning_defaults.dart` and wire to services.
- Use capped multiplier flow:
  - 2 quests/day: `1.15x`
  - 3+ quests/day: `1.30x`
  - daily+weekly same day bonus: `+0.15x`
  - hard cap total multiplier: `1.50x`
- Add daily quest XP soft cap (`350`) to reduce farming.

#### 3.3 Level scaling
- Use tuning tiers from constants file for target and reward scaling.
- Do not exceed reward growth relative to target growth at high levels.

### 4) UX Recommendations by Surface

#### 4.1 Daily quest card
- Add a compact “Counts when…” row.
- Add real-time feedback on every relevant action:
  - success: `+1 progress`, current/target
  - reject: short reason (`duplicate neighborhood`, `min 50 chars`, `outside time window`)
- Show XP breakdown on completion: `base + bonus + multiplier`.

#### 4.2 Weekly goals card/screen
- Replace generic `Progress` CTA with context CTA (`Start Exploring`, `Capture`, `Share`, `Continue`).
- Show “next best action” under each goal.
- Add urgency treatment at >=80% progress and <48h remaining.

#### 4.3 Quest history screen
- Add timeline of recent quest events with counted/not-counted outcomes.
- Add transparent stat definitions tooltip.
- Keep quest tips dynamic and tied to current week assignments.

### 5) Logic Fixes (P0 correctness)
- Fix `checkPerfectWeek` week key parsing to `YYYY-Www` format.
- Rebuild combo detection using same-day state, not boolean args in single call.
- Replace all title-based progression checks with template/category IDs.
- Replace hardcoded English title comparisons in weekly mastery trackers.
- Normalize XP reads to `experiencePoints` in all services.

### 6) Data Migration Plan
- Backfill missing IDs on existing quest docs using deterministic mapping rules.
- Add migration to copy `totalXP` into `experiencePoints` only when needed.
- Keep temporary compatibility read path for one release cycle.
- Add migration marker on user doc to avoid repeated writes.

### 7) Anti-abuse and Integrity Controls
- Per-action idempotency key (userId + day + action fingerprint).
- Rate-limit repetitive event increments by quest type.
- Uniqueness checks where relevant:
  - unique neighborhood/day
  - unique artwork/day for certain templates
- Server-side validation for suspicious bulk increments.

### 8) Analytics and KPI Framework

#### 8.1 Core metrics
- Assignment rate (daily, weekly)
- Completion rate by template/category
- Median time-to-complete
- Drop-off point by progress percentile
- XP inflation rate (quest XP as share of total XP)
- Trust indicators:
  - counted/rejected ratio
  - rejected reason distribution
  - “did not count” support events

#### 8.2 Target bands
- Daily completion: `45%-65%`
- Weekly per-goal completion: `20%-35%`
- Perfect week: `5%-10%`
- Rejection rate for valid user attempts: `<5%`

### 9) QA and Test Strategy
- Unit tests:
  - template-id progression mapping
  - week-key parsing and perfect-week eligibility
  - combo eligibility across separate completion events
  - scaling tiers and multiplier cap
- Integration tests:
  - full daily completion path with feedback result payload
  - weekly completion triggering perfect week
  - localization invariance (same behavior in non-English locale)
- Regression tests:
  - streak continuity across day boundaries
  - timezone edge cases

### 10) Release and Rollout Plan

#### Phase 1: Correctness hardening (1 sprint)
- Implement P0 logic fixes and schema normalization.
- Feature flags:
  - `quests.useStableTemplateIds`
  - `quests.comboV2`
  - `quests.perfectWeekV2`

#### Phase 2: UX clarity and trust (1 sprint)
- Add “Counts when…”, immediate progress feedback, and XP breakdown.
- Ship weekly CTA improvements and next-step hints.

#### Phase 3: Optimization and personalization (1-2 sprints)
- Add assignment weighting by completion history.
- Tune difficulty and rewards using telemetry.
- Introduce optional advanced-user autonomy (e.g., choose 1 of 2 dailies).

### 11) Definition of Success
- Player trust: support complaints about quest non-counting reduced by `>=50%`.
- Reliability: progression mismatch incidents near zero in logs.
- Retention: D7 and weekly active quest participation both improve.
- Economy stability: quest XP share remains in target band and level pacing remains predictable.

### 12) Implementation Order (Recommended)
1. Schema normalization + stable IDs
2. P0 logic fixes (perfect week, combo, title dependency removal)
3. UI clarity layer (counts-when, reason feedback, XP breakdown)
4. Analytics instrumentation and dashboards
5. Tuning pass with feature flags and staged rollout

## Execution Checklist (Sprint-Ready)

### Sprint 1: Correctness Hardening (P0)
- [x] Add stable quest identity fields:
  - [x] `ChallengeModel.templateId`
  - [x] `ChallengeModel.categoryId`
  - [x] `WeeklyGoalModel.templateId`
- [x] Populate template/category IDs in challenge and weekly goal generators.
- [x] Replace title-based progression checks in challenge tracking methods.
- [x] Replace title-based weekly mastery goal checks with template ID checks.
- [x] Normalize XP reads to `experiencePoints` with temporary fallback to `totalXP`.
- [x] Fix perfect-week week key parsing for `YYYY-Www`.
- [x] Implement combo V2:
  - [x] Determine combo from same-day state (daily + weekly), not call args.
  - [x] Store daily state flags for combo eligibility.
  - [x] Prevent duplicate combo increments per day.

### Sprint 2: UX Trust and Clarity
- [x] Add “Counts when…” rule text to daily and weekly goal cards.
- [x] Add immediate counted/not-counted feedback result surface.
- [x] Add XP breakdown on quest completion.
- [x] Replace generic weekly `Progress` CTA with context-specific action labels.

### Sprint 3: Analytics, Safety, and Tuning
- [x] Add quest event analytics payloads (counted/rejected + reason codes). (initial logging)
- [x] Add anti-abuse idempotency and per-day uniqueness constraints. (initial daily uniqueness for neighborhoods/styles)
- [x] Add tuning flags and dynamic config reads.
- [x] Run 2-week tuning pass against KPI targets. (runbook defined below)

## 2-Week KPI Tuning Runbook

### Telemetry Event Source
- Collection: `users/{userId}/questEvents`
- Event types:
  - `daily_progress_update`
  - `weekly_progress_update`
- Core fields:
  - `counted` (bool)
  - `reason` (string)
  - `increment` (int)
  - `payload.newProgress` (int)
  - `payload.target` (int)
  - `payload.xpAwarded` (int)
  - `createdAt` (timestamp)

### Staging Rollout Commands
- Enable quest runtime controls in staging build:
  - `--dart-define=QUEST_DYNAMIC_CONFIG=true`
  - `--dart-define=QUEST_EVENT_LOGGING=true`
  - `--dart-define=QUEST_UNIQUE_GUARDS=true`
  - `--dart-define=QUEST_TWO_QUESTS_MULTIPLIER=1.15`
  - `--dart-define=QUEST_THREE_PLUS_MULTIPLIER=1.30`
  - `--dart-define=QUEST_DAILY_WEEKLY_BONUS=0.15`
  - `--dart-define=QUEST_MAX_MULTIPLIER=1.50`

### Data Backfill (Run Once Before Staging KPI Pass)
- Script:
  - [backfill_quest_system_fields.js](/Volumes/ExternalDrive/DevProjects/artbeat/scripts/backfill_quest_system_fields.js)
- Dry run:
  - `GCLOUD_PROJECT=<project-id> npm run quests:backfill:dry`
- Apply:
  - `GCLOUD_PROJECT=<project-id> npm run quests:backfill:write`
- Expected outputs:
  - `usersScanned`
  - `usersUpdated`
  - `dailyDocsUpdated`
  - `weeklyDocsUpdated`
  - `dailyUnresolved`
  - `weeklyUnresolved`
- Acceptance:
  - unresolved counts should be near zero before KPI tuning.

### KPI Report Script (Operational)
- Script:
  - [quest_kpi_report.js](/Volumes/ExternalDrive/DevProjects/artbeat/scripts/quest_kpi_report.js)
- Usage:
  - `GCLOUD_PROJECT=<project-id> npm run quests:kpi:14d`
  - optional shorter window: `GCLOUD_PROJECT=<project-id> npm run quests:kpi:7d`
- Output:
  - `summary.kpis` with:
    - `countedRatio`
    - `dailyCompletionRate`
    - `weeklyCompletionRate`
    - `perfectWeekRate`
    - `averageCompletionXP`
    - `p95CompletionXP`
    - `rejectionRate`
  - `alerts` array with threshold breaches.
  - `daily[]` breakdown for trend analysis and reason-code diagnostics.

### Synthetic Event Seeding (for KPI Pipeline Validation)
- Script:
  - [seed_quest_events.js](/Volumes/ExternalDrive/DevProjects/artbeat/scripts/seed_quest_events.js)
- Dry run:
  - `GCLOUD_PROJECT=<project-id> npm run quests:seed:dry`
- Apply sample events:
  - `GCLOUD_PROJECT=<project-id> npm run quests:seed:write`
- Optional args:
  - `--users <n>`
  - `--days <n>`
  - `--events-per-day <n>`
  - `--user-id <uid>`
- Example:
  - `GCLOUD_PROJECT=<project-id> node scripts/seed_quest_events.js --write --users 2 --days 7 --events-per-day 4`

### Synthetic Event Cleanup
- Script:
  - [cleanup_seeded_quest_events.js](/Volumes/ExternalDrive/DevProjects/artbeat/scripts/cleanup_seeded_quest_events.js)
- Dry run:
  - `GCLOUD_PROJECT=<project-id> npm run quests:seed:cleanup:dry`
- Apply:
  - `GCLOUD_PROJECT=<project-id> npm run quests:seed:cleanup:write`

### Daily Monitoring Queries (Day 1-14)
- Counted ratio:
  - `counted=true` / total questEvents by day
- Rejection reason mix:
  - grouped by `reason` when `counted=false`
- XP inflation:
  - average and p95 of `payload.xpAwarded` on completion events
- Friction signals:
  - high frequency of `challenge_mismatch`, `no_progress`, or duplicate unique guard rejections

### Weekly Outcome Metrics
- Daily completion rate target: `45%-65%`
- Weekly per-goal completion rate target: `20%-35%`
- Perfect week rate target: `5%-10%`
- Valid attempt rejection rate target: `<5%`
- Quest XP share of total XP target: `25%-40%`

### Decision Rules (apply once per week)
- If daily completion <45%:
  - reduce target multipliers by 5%-10% for hardest daily templates
  - increase visibility of easiest quest types in assignment mix
- If daily completion >65%:
  - raise target multipliers by 5% for easiest templates only
- If weekly completion <20%:
  - lower weekly target counts 10% or increase category distribution toward lower-friction goals
- If rejection rate >5%:
  - prioritize rule clarity and event qualification fixes before XP tuning
- If quest XP share >40%:
  - reduce combo/bonus coefficients or apply stricter soft caps

### Operational Cadence
- Day 1-3:
  - verify event volume and schema integrity
  - no economy changes unless severe failure
- Day 4-7:
  - first adjustment window (small changes only, <=10%)
- Day 8-14:
  - second adjustment window
  - finalize stable defaults and document config values used in production
