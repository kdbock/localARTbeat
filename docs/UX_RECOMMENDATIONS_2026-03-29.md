# ARTbeat UX Recommendations — March 29, 2026

Based on 4 field tours in eastern North Carolina and direct user feedback.
This document prioritises the three areas users named. Ordered by impact on retention.

## Implementation Status (Updated March 30, 2026)

### Priority 1 — Art Walk flow

- Complete: Discover-first routing is primary across major Art Walk entry points.
- Complete: Guided navigation remains the primary walk behavior.
- Complete: Instant Radar works as a companion mode during active walk navigation.
- Complete: Completion flow includes celebration + selfie action + contextual create CTA.
- Complete: Create flow is map-first with optional metadata and auto-generated fallback details.
- Complete: Map and list performance tuned for faster first paint (lighter capture limits, true paged list loading, and less expensive list rendering).
- Complete: copy-consistency pass finished on active Art Walk map/list surfaces (guided-walk language unified).

### Priority 2 — Community Hub auto-post model

- Complete: auto-share preference gate is active for social activity posting with default ON behavior.
- Complete: user-facing "Auto-share Activities" toggle is available in Notification Settings and persists to user settings.
- Complete: automatic social post on public Art Walk creation publishes walk title, stop count, and location metadata.
- Complete: direct feed posting actions are visible to artists, admins, and moderators in community hubs; user-generated sharing for other users remains auto/activity-driven.
- Complete: capture flow prompts an "ARTflex Shot" (selfie with artwork) and auto-posts it to social activities.
- Complete: upload safety moderation is enforced before publishing activity/capture images (fail-closed behavior, endpoint deployed and smoke-tested).

### Priority 3 — Onboarding compression

- Complete: dedicated 3-screen **user onboarding** flow implemented with fan/artist split (hook -> one action -> welcome).
- Complete: explicit route separation added (`/onboarding/user`) with legacy alias support (`/2025_modern_onboarding`).
- Complete: route/copy separation now clearly distinguishes **user onboarding** from **artist onboarding**.
- Complete: first-run **artist onboarding** no longer hard-blocks on paid tier selection (defaults to free when no plan is chosen).
- Complete: onboarding funnel analytics instrumentation implemented for screen view, role selection, permission result, and completion events.
- In progress: localized strings + curated local artist imagery pass for onboarding hero content.

---

## Priority 1 — Art Walk: Make It Feel Like a Game, Not a Form

### The problem
Users open Create Art Walk and see a map, a form, GPS loading, geocoding, route optimizer, zip code field, duration field, description field. They have no idea why they're doing any of it or what the payoff looks like. They leave.

### The fix: Discover first, create second

**New entry flow:**

1. User taps "Art Walk" tab → lands on **Discover screen** (already exists as `DiscoverDashboardScreen`)
2. Show a big, visual "Walks Near You" card with a photo from the nearest walk, the number of stops, distance, and who made it. Like AllTrails.
3. A single button: **"Start This Walk"** — opens a guided route immediately (Google Maps turn-by-turn + next-stop guidance), no creation required.
4. They walk with clear directions to each stop (street-safe routing), with Instant Radar available as a companion mode to detect nearby art while on route.
5. At the end, celebration screen focuses on completion payoff: art found, distance walked, points earned, streak/challenge progress.
6. On that same completion moment, add a **"Take Celebration Selfie"** action and post that selfie to the Community Hub feed with the completed walk summary.
7. **Single creation entry point**: one secondary CTA on completion, e.g. **"Create Your Own Walk"**.

**Foundational mechanics that must remain intact:**

- Camera capture flow remains core: user opens camera from bottom nav, captures outdoor art, adds details, and uploads.
- Every approved capture becomes a discoverable map marker/stop that other users can find through walks and radar.
- Art Walks are a treasure-hunt layer built on top of captured public art data (not a replacement for it).
- Existing goals/challenges around walk completion, reviews, and creator behavior remain first-class mechanics.
- Art Walk sponsorship surfaces and sponsored walk experiences remain part of discovery and monetization.

**Guided Navigation + Radar Companion (core product concept):**

- **Guided navigation is primary**: users should never wander aimlessly; the app always provides clear route guidance to the next stop.
- **Instant Radar is companion mode** during active walks: it enhances discovery while preserving turn-by-turn navigation.
- The full-screen Instant Radar experience remains available as a deep-dive mode and should not be removed.
- Radar companion should feel game-like but not distract from safe, street-aware routing.
- "Start This Walk" must always answer: *where do I go first, and how do I get there?*

**Discovery detail requirements (active walk):**

- While a walk is active, the top of the screen should always show: **Next stop**, **distance remaining**, **ETA**, and **time left in route**.
- Primary sticky action remains **Navigate to Next Stop**.
- If the user drifts off route, show a non-blocking reroute state: **"Off route - tap to rejoin."**
- Radar should classify pieces with clear labels: **On Route** (fits current route sequence) and **Nearby Bonus** (close enough to discover, optional detour).
- Tapping any discovery piece should open details with immediate direction options: **Go Now** (set as next) or **Save for Later**.
- Discovery cards and map markers should display whether that piece awards standard discovery points, bonus points, or challenge progress.

**Capture detail requirements (during guided navigation):**

- When launched from an active walk, camera opens in **Route Capture Mode** (no long form before capture).
- After taking a photo, minimal required details only; optional metadata remains deferred/editable.
- Capture metadata should include route context: `walkId`, `routeSegmentIndex`, `capturedDuringWalk=true`, and `captureSource=guided_navigation`.
- After upload, show one decision sheet: **Add to This Walk** (default) or **Keep as Standalone Capture**.
- If user chooses **Add to This Walk**, route recomputes with safe forward ordering and preserves completed stops.
- Auto-insert rule: only auto-insert into live route when the capture is within detour threshold (for example <=120m from current path). Otherwise classify as **Nearby Bonus** and suggest adding after completion.
- Never block active navigation with multi-step forms while user is en route.

**Current experience points and progression (must be preserved and surfaced):**

- Reaching a planned stop grants existing stop-reach points and contributes to active streak/challenge counters.
- Discovering an on-route piece from Radar grants current discovery points and challenge progress exactly as today.
- Capturing a new piece during a walk grants current capture points; if it is inserted into route, also grant route-contribution bonus points.
- Completing the walk continues to grant existing completion points, streak progression, and completion rewards.
- UI must show point events inline during navigation so users understand why they earned progress (reach, discover, capture, completion).

**Entry point alignment (must-do):**

- Audit every Art Walk entry point across drawers and screens.
- Ensure all entry points follow the same concept: **Discover first, create second**.
- Primary destination should be Discover (`DiscoverDashboardScreen`) or a nearby/public walks list with guided navigation options, not form-first creation.
- Keep creation accessible, but always as a secondary action after users can see and start a walk.
- Every "Start Walk" action should route into guided navigation with optional Radar companion controls.
- Every "Create Walk" action should be positioned as secondary and contextual (post-completion prompt or secondary CTA).

**On the Create screen itself:**

- Drop the form-first approach entirely. Replace step 1 with:
  > "Stand near your first stop. Tap to add it."
  
  One button. Map opens. They drop a pin. That's it.
- Each stop is a single tap — the title and description can be added AFTER (or skipped entirely with auto-generated placeholder text like "Stop 1 near Downtown Greenville")
- Minimum viable walk = 2 stops. They can always edit later.
- Show a live preview of the route building as they add stops — make it feel like drawing on a map, not filling out a form.

**Bells and whistles people actually like:**
- 🗺️ The route animates as stops are added (line draws itself)
- A small "preview" button that shows what users will see when they walk it
- "Quick Walk" mode: no title, no description, just pin locations. App names it after the neighborhood automatically.
- After saving: instant shareable image card — a map thumbnail + "I made an Art Walk in [city]" that can be shared to Instagram Stories. This turns every creator into a promoter.
- Completion selfie flow: one tap to take a post-walk selfie, prefilled caption, auto-post to Community Hub (with optional edit before posting).
- Streak indicator: "You've made a walk 2 weeks in a row 🔥"
- Radar companion proximity pulse when bonus art enters 100m.
- Radar badges with clear color language: **on-route** vs **bonus nearby**.
- Small XP pop when opening a radar-detected piece during active navigation.

---

## Priority 2 — Community Hub: Activities Should Be Posts

### The problem
"Show Activities" shows you a list of your own activity records (art captured, walk completed) as quiet cards. You can't interact with them. Nobody else sees them. It's a log, not a feed. Users compare it to Instagram and walk away.

### The fix: Auto-post activities into the community feed

When a user completes any of these actions, the app automatically creates a post in the community feed:

| Activity | Auto-post content |
|---|---|
| Captures a piece of art | Photo + "📍 [Name] discovered [Art Title] in [City]" |
| Completes an Art Walk | Map thumbnail + stops count + "[Name] just finished '[Walk Name]'" |
| Earns an achievement | Badge image + "[Name] earned the Explorer badge" |
| Adds a new walk | "[Name] created a new Art Walk: '[Walk Name]' — X stops in [City]" |

Each of these auto-posts:
- Has a photo/image (pulls from the capture or walk)
- Has a location tag
- Supports likes, comments, replies (infrastructure already exists in `PostCard`, `CommentsScreen`, `EnhancedPostCard`)
- Shows in every follower's feed

**Users can control this** — a toggle in settings: "Auto-share my activities to the feed." Default: ON.

**What users actually want in a feed:**
- ❤️ Like with a single tap
- 💬 Comment with a single tap that opens the comment thread
- ↩️ Reply to a specific comment (thread stays readable)
- 🔗 Share button → copies a link or sends to messages/Instagram
- 📍 Tap the location tag to see other art nearby
- The creator's avatar + name is clickable → goes to their profile

**The Show Activities toggle** becomes less necessary — because the activities *are* posts now. The toggle can simply become "Show community activity posts in feed" (on/off) rather than a hidden switch.

**One quick win** that users will notice immediately: Add a reaction bar (❤️ 🤩 👏 🔥) instead of just a like button. Apps with multi-reactions see 3× more engagement than single-like. It's one row of emoji, it costs almost nothing to build on top of the like system you already have.

---

## Priority 3 — Onboarding: Half the Screens, Twice the Excitement

### Scope clarification: two onboarding tracks

To avoid ambiguity during implementation, this phase defines **two related but distinct flows**:

- **User onboarding (primary Phase 3 scope):** the first-run experience for any new user entering the app.
- **Artist onboarding (companion scope):** the deeper creator setup flow for users who choose to become/act as artists.

The product goal is to make user onboarding fast and exciting, then move deeper artist setup to contextual moments.

### The problem
7 screens: Welcome → Introduction → Story → Artwork Upload → Featured Artwork → Benefits → Tier Selection.

Users are asked to write their artist story, upload artwork, and pick a subscription tier before they've seen the app do anything interesting. By screen 4 they're gone.

### The fix: 3 screens, defer the rest

**New flow:**

**Screen 1 — The Hook (replaces Welcome + Introduction + Benefits)**
- Full-screen art photo (rotating, beautiful, from real eastern NC artists)
- One sentence: *"Discover, photograph, and share public art near you."*
- Two buttons: **"Explore as a Fan"** / **"I'm an Artist"**
- No feature list. No bullet points. Just the art.

**Screen 2 — One thing to do (replaces Artwork Upload + Story + Featured)**
- If fan: *"Allow location so we can show you art nearby."* → one permission prompt, then straight into the app.
- If artist: *"Upload one photo of your work."* Just one. A single image upload. That's it for now.

**Screen 3 — You're in (replaces Tier Selection + Completion)**
- Celebration moment: confetti, their username, "Welcome to ARTbeat."
- One banner: *"Complete your profile to be featured to collectors."* (links to profile — deferred, optional)
- Straight into the Discover dashboard.

**What gets deferred (shown later in-context, not during onboarding):**
- Artist story → prompted when they first view their public profile ("Add your story so collectors know who you are")
- Tier selection → prompted the first time they try to list work for sale ("To sell, choose a plan")
- Featured artwork → prompted after their second capture ("Want this in your portfolio?")

### Artist onboarding changes (explicit definition)

These changes apply to the creator-specific setup journey and should be implemented alongside the compressed user onboarding:

1. **Do not require full artist profile completion during first-run onboarding.**
2. **Do not require subscription/tier selection during first-run onboarding.**
3. **Keep artist setup available, but trigger it contextually** (profile edit, first sell/list action, portfolio curation prompts).
4. **Route naming and product copy must clearly separate flows** so teams do not confuse user onboarding with artist setup.
5. **Completion criteria:** new users can reach Discover quickly; artist-specific setup remains accessible without blocking entry.

**Bells and whistles:**
- The art photos on screen 1 are from real local artists — credits shown. This immediately makes the app feel real and local.
- Progress dots are gone. No "Step 1 of 7" anxiety.
- Skip button is always visible.
- The whole thing takes under 60 seconds.

---

## How these three connect

These aren't separate features — they form a loop:

```
New user opens app
    ↓
Onboarding (60 seconds, one beautiful screen)
    ↓
Sees walks nearby on Discover
    ↓
Walks one → gets a post auto-created in the feed
    ↓
Their friends see it, tap Like
    ↓
Notification: "[Friend] liked your walk"
    ↓
They come back
```

Right now that loop is broken at every step. Onboarding is too long, walks are too hard to start, and completing a walk produces nothing visible in the community. Fix all three, and retention looks very different.

---

## Small wins worth doing in a day each

These are low-effort, high-visibility improvements:

- **Pull to refresh** on the community feed with a satisfying animation (if not already there)
- **"Near you now"** chip on the Discover screen — shows count of art within 1 mile. Even 1 piece makes the app feel live.
- **Share card** on every Art Walk completion — auto-generated image that can go to Instagram Stories. Users become marketers for free.
- **Notification when someone walks YOUR walk** — "3 people walked your Greenville Art Walk today." This is the single strongest creator retention mechanic.
- **Art counter on the app icon badge** — "2 new captures near you." Platform-specific but powerful.
- **Empty state helpers** — when the feed is empty, instead of a blank screen, show: "No posts yet. Be the first — capture some art nearby." With a button.

---

## What NOT to change right now

- The visual design — the glass cards, the dark theme, the animations — users called it beautiful. Keep it.
- The core data model — walks, captures, posts, comments. All solid.
- The achievement/streak system — users who engaged with it loved it.

The problem is never the features. It's the path to them.

---

## Recommended Next Steps (Post-Implementation)

1. Add focused widget tests for user onboarding paths (entry, role split, skip/enter routing, completion flag).
2. Replace temporary onboarding copy/images with curated eastern NC artist assets + localized strings.
3. Build dashboard/query views for onboarding funnel analytics to validate retention impact.
4. Run A/B experiment on hero visual variants and CTA wording once baseline metrics are stable.

*Priority order now: finish onboarding polish/measurement, then continue retention loop tuning across Discover -> Walk completion -> Feed feedback.*
