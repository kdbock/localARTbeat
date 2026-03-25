# ARTbeat Status And Next Steps

This file replaces the original repo review with the current execution status.
The original conclusion still stands: this app does not need a rewrite. It
needs controlled consolidation, safer boundaries, cleaner operational
workflows, and lower release risk.

## Bottom Line

Major progress has been made on the highest-risk architecture issue:
cross-package coupling.

The repo is now materially safer to change than it was when the review started.
The biggest win is that `artbeat_core` has been reduced from a broad
cross-feature hub to a nearly clean base package.

## What Is Done

### Documentation and operating structure

- Canonical project-control docs now exist under `docs/`.
- Active work is tracked in `docs/WORK_QUEUE.md`.
- Architecture and dependency policy are tracked in:
  - `docs/ARCHITECTURE.md`
  - `docs/DEPENDENCY_RULES.md`
  - `docs/PACKAGE_DEPENDENCY_INVENTORY.md`
  - `docs/DECISIONS.md`

### Localization workflow

- English is treated as the canonical locale source.
- Locale parity is now enforced with:
  - `tools/localization/report_missing_keys.py`
  - `test/localization_key_parity_test.dart`
- `assets/translations/missing_keys.md` is now generated from actual locale state instead of hand-maintained notes.

### Repo hygiene

- Ignore coverage and cleanup policy were improved.
- Archived docs and tool destinations were created.
- Accidental nested git residue under `packages/artbeat_admin/.git` was removed.
- Root clutter has been reduced in stages.

This work is not finished yet.

### Package boundary repair

This has been the main area of progress.

Completed package cleanup highlights:

- `artbeat_profile` now depends only on `artbeat_core`
- `artbeat_admin` now depends only on `artbeat_core`
- `artbeat_auth` now depends only on `artbeat_core`
- `artbeat_messaging` now depends only on `artbeat_core`
- `artbeat_settings` now depends only on `artbeat_core`
- `artbeat_ads` now depends only on `artbeat_core`

Major cross-feature cuts completed:

- `artbeat_auth -> artbeat_profile`
- `artbeat_events -> artbeat_auth`
- `artbeat_settings -> artbeat_artist/events`
- `artbeat_capture -> artbeat_art_walk`
- `artbeat_artist <-> artbeat_artwork`
- `artbeat_profile -> artbeat_auth/capture/art_walk`
- `artbeat_community -> messaging/artist/admin/events/artwork/art_walk`
- `artbeat_art_walk -> ads/community/profile/events/settings/capture`
- `artbeat_admin -> messaging/ads/events/community/capture/art_walk/artwork`

### `artbeat_core` reduction

This was the original highest-leverage architecture problem.

`artbeat_core` no longer depends on:

- `artbeat_auth`
- `artbeat_settings`
- `artbeat_sponsorships`
- `artbeat_profile`
- `artbeat_admin`
- `artbeat_ads`
- `artbeat_capture`
- `artbeat_artist`
- `artbeat_events`
- `artbeat_messaging`
- `artbeat_community`
- `artbeat_artwork`

Core now owns most of the read/write surfaces it previously borrowed from other
feature packages:

- artwork reads
- event reads
- artist reads
- community post reads
- commission previews
- unread messaging status
- user blocking
- achievement reads
- progression metadata
- daily challenge reads
- social activity reads
- nearby art reads
- discovery progress reads

`artbeat_core` no longer depends on sibling feature packages.

## Current Graph Snapshot

From `docs/PACKAGE_DEPENDENCY_INVENTORY.md`:

- `artbeat_core` depends on no sibling feature packages
- `artbeat_admin`, `artbeat_profile`, `artbeat_auth`, `artbeat_messaging`,
  `artbeat_settings`, and `artbeat_ads` depend only on `artbeat_core`
- the remaining higher-coupling feature packages are:
  - `artbeat_artist`
  - `artbeat_artwork`
  - `artbeat_sponsorships`
  - `artbeat_events`
  - `artbeat_art_walk`

## What Is Still In Progress

### 1. Finish repo hygiene

Still open:

- remaining tracked root cleanup
- dedicated tracked-source cleanup change for `packages/artbeat_profile/ios`
- continued separation of durable source from local/generated artifacts

Primary tracking doc:

- `docs/REPO_HYGIENE.md`

### 2. Compliance and release follow-up

Still open:

- legal/security follow-up items
- production canary sign-off completion
- admin deletion fulfillment reliability
- credentialed staging repro after the 2026-03-18 diagnostic rollout

Primary trackers:

- `docs/WORK_QUEUE.md`
- `docs/KNOWN_ISSUES.md`
- `docs/security/LEGAL_RELEASE_STATUS.md`

Current stopping point:

- function-side deletion diagnostics are in place
- admin UI now shows failed request details
- `scripts/legal_staging_regression.sh` now prints request status and
  processing errors after the callable
- a fresh staging deploy of `functions:processDataDeletionRequest` was started
  from this machine on 2026-03-18
- a local 2026-03-19 rerun of `scripts/legal_staging_regression.sh` passed the
  non-admin rule/storage/chat checks
- the credentialed staging repro was completed on 2026-03-19 and passed after
  fixing `deletionSummary.pipelineSteps` to stop using
  `FieldValue.serverTimestamp()` inside array items
- the remaining blockers are fresh manual in-app QA evidence and current
  product/legal + support sign-off before reopening the production canary

### 3. Backend/rules cleanup

Still largely untouched:

- split large function domains under `functions/src/index.js`
- clarify `dataconnect/`
- strengthen backend/rules testing discipline

## Recommended Next Phase

Do not continue broad refactors by default.

Recommended order:

1. Complete repo hygiene decisions and cleanup.
2. Finish the legal/security staging repro and close the deletion blocker.
3. Complete release-process follow-up and canary gating.
4. Start backend/functions modularization only after the above is stable.

## Immediate Manual QA Next Steps

If the goal is to move the current version live soon, the next work is a fresh
manual user-flow pass focused on release confidence, not more architecture
cleanup.

Recommended order for the next QA session:

1. Profile/settings flow
   - sign in as a normal user
   - edit profile fields
   - change profile photo
   - confirm profile changes persist after app restart

2. Legal/data-rights user flow
   - submit one data export request
   - submit one data deletion request
   - confirm both requests are created successfully in-app

3. Admin deletion fulfillment flow
   - sign in as admin
   - open admin data requests queue
   - process the fresh deletion request
   - confirm the request completes without the prior
     `[firebase_functions/internal] INTERNAL` failure

4. Critical upload flows called out by the canary runbook
   - capture upload
   - chat media upload
   - ads upload

5. Final release confidence smoke
   - verify no unexpected Firestore/Storage permission errors in normal use
   - verify no App Check failures are blocking common user actions
   - capture fresh notes/screenshots for any failures

## What Must Pass Before Live Release

Minimum practical pass criteria from the current docs:

- profile update flow passes
- profile photo upload/edit passes
- data export request creation passes
- data deletion request creation passes
- admin deletion fulfillment passes
- capture upload passes
- chat media upload passes
- ads upload passes if that surface is part of the release scope

## Best Next Test

Because App Check and profile photo editing were just fixed today, the next
highest-value sequence is:

1. Re-test profile edit + photo update
2. Submit export request
3. Submit deletion request
4. Fulfill deletion request from admin queue
5. Then move to capture/chat/ads uploads

## What Good Looks Like Now

For this app, success is:

- predictable change impact
- lower release anxiety
- a clean app-shell boundary
- fewer cross-package surprises
- repeatable translation, testing, and release workflows
- `artbeat_core` acting like a true shared foundation

That is already much closer than it was at the start of this review.

## Ad Rebuild Plan For A Simple, Compliant Launch

This section assumes sponsorships are frozen for now and the immediate revenue
focus is a simpler ad product that fits the app's local-exploration identity.

### Product Decision

For launch, ads should not behave like a general-purpose ad network.

They should be:

- local-business only
- monthly only
- simple to understand
- visually native to the app
- limited to placements users are already browsing naturally

Recommended launch ad products:

- `Inline Ad`
  - a larger, native-feeling unit that appears inside browse/feed surfaces
  - use this between artists, artwork cards, or community posts
- `Banner Ad`
  - a smaller section-break unit between dashboard modules
  - use this between major sections, not as a hero takeover

Do not sell any other ad variants at launch.

Do not expose duration choices at launch.

Do not expose customer-facing analytics/statistics language at launch.

### Product Boundary

Use this boundary consistently:

- `Ads`
  - lightweight monthly promotion
  - local business visibility inside browsing/feed surfaces
- `Sponsorships`
  - premium branded support of a core ARTbeat experience
  - art walk
  - capture
  - discovery

Do not blur these two products in the UI.

### Recommended Live Ad Placements

Launch only in places where ads already match user intent:

1. Explore / browse surfaces
   - inline between artist cards
   - inline between artwork cards
   - banner between major browse sections

2. Community Hub
   - inline between posts
   - banner between feed sections or tabs only where spacing already exists

3. Events
   - inline between event cards only if the list remains readable
   - banner between sections, not above the main hero

4. Main dashboards
   - banner only between sections
   - no full-screen or dominant hero ad takeover

Do not add ads to the capture flow itself.

Do not make ads the focal point of the art walk experience.

### Placements To Avoid For Launch

- full-screen interstitial-style units
- autoplay or overly animated ad behavior
- top-of-screen hero takeovers on primary dashboards
- anything that interrupts capture, discovery, or mapping at a critical moment
- any zone or placement not visibly live in the app

### Merchant Experience Recommendation

The business owner flow should feel like:

1. Choose ad type
   - `Inline Ad`
   - `Banner Ad`
2. Enter business name
3. Enter headline
4. Enter short description
5. Add website or contact info
6. Upload artwork
7. Review preview
8. Start monthly placement

It should not feel like:

- choosing zones from a long list
- choosing 1 week vs 1 month vs 3 months
- comparing metrics terminology
- managing a campaign like a professional ad platform

### Compliance Recommendation

For iOS, the safest interpretation is:

- if the business is buying ad inventory shown in the same app, treat it as an
  in-app digital purchase
- if self-serve purchase remains inside the iOS app, use Apple-compliant IAP
  rather than external payment links inside the app

Lowest-risk launch path:

1. keep ad display and admin management in the app
2. keep the merchant UI simple
3. if compliance or IAP complexity is not ready, disable self-serve iOS purchase
   and use manual activation / off-app intake temporarily

Practical launch preference:

- `Phase 1 launch-safe option`
  - build the simplified ad product and placements
  - let businesses submit or request an ad
  - you activate it manually from admin/back office
- `Phase 2`
  - add fully compliant in-app purchase/subscription flow after the product and
    inventory model are stable

### Engineering Plan

#### Phase A. Simplify the data model

- collapse ads to two formats only:
  - `inline`
  - `banner`
- collapse duration to:
  - `monthly`
- remove customer-facing size/duration matrix logic from the creation flow
- keep internal status fields needed for moderation/review
- stop presenting unused or non-live placement zones as saleable inventory

#### Phase B. Simplify the ad creation flow

- replace size/duration pricing grid with one simple product selector
- show plain-language explanation for each ad type
- add preview cards that match actual live placement styles
- keep form fields minimal:
  - business name
  - ad headline
  - short body copy
  - destination link or contact
  - image upload

#### Phase C. Rebuild placements around user context

- inline ads on artist/artwork/community content surfaces
- banner ads between dashboard sections
- add placements to the core dashboards intentionally and sparingly
- ensure empty ad slots collapse cleanly unless a deliberate placeholder pattern
  is chosen later

#### Phase D. Tighten moderation and activation

- new ads should not go live until they pass moderation/approval
- ensure upload path, rules, and review workflow are stable
- keep one obvious admin path for:
  - pending
  - active
  - rejected
  - expired

#### Phase E. Decide the payment model

Pick one of these and commit to it for launch:

- `Option 1: Manual activation first`
  - simplest operationally
  - lowest App Review risk
  - fastest path to a clean launch
- `Option 2: iOS self-serve using compliant IAP`
  - more product polish
  - more implementation and App Store setup work
  - only do this if purchase completion and subscription lifecycle are handled
    correctly

Do not keep the current half-self-serve purchase flow.

#### Phase F. QA and launch sign-off

- verify each live placement on real data
- verify ad previews match production rendering closely enough
- verify rejection/moderation workflow
- verify expiration behavior for monthly ads
- verify no ad unit breaks feed layout or causes visual clutter

### Outside VS Code Checklist

These are tasks that require you, not local code changes.

#### Product / business decisions

- [ ] Decide launch payment path:
  - [ ] manual ad intake/activation first
  - [ ] or iOS self-serve IAP first
- [ ] Decide whether launch includes both `Inline Ad` and `Banner Ad`
- [ ] Decide the launch monthly prices for:
  - [ ] `Inline Ad`
  - [ ] `Banner Ad`
- [ ] Decide whether schools/public-sector orgs will see ads immediately at
      launch or only after a soft rollout

#### App Store / Apple setup

- [ ] If using IAP, create the App Store Connect products
- [ ] If using IAP subscriptions, decide exact subscription names and
      descriptions
- [ ] Prepare App Review notes explaining what businesses are buying and where
      those ads appear in the app
- [ ] Verify the iOS purchase path matches the final App Review-safe design

#### Business operations

- [ ] Decide the ad review policy:
  - [ ] what is allowed
  - [ ] what is rejected
  - [ ] how fast you aim to review ads
- [ ] Decide who can buy ads:
  - [ ] only verified local businesses
  - [ ] local artists promoting shows/events too
- [ ] Decide your refund/cancellation policy for monthly ads
- [ ] Prepare one plain-language help/support response for ad buyers

#### Content / launch materials

- [ ] Gather 2-4 realistic local business sample ads for testing
- [ ] Prepare final copy for:
  - [ ] `Inline Ad`
  - [ ] `Banner Ad`
  - [ ] merchant CTA text
- [ ] Review ad wording so it feels local, community-minded, and not corporate

#### Release / rollout

- [ ] Decide if ads go live for everyone at once or by a small canary rollout
- [ ] Test the merchant flow on a real iPhone build before enabling it publicly
- [ ] Test the viewer experience with real ad content in:
  - [ ] community
  - [ ] explore/artwork
  - [ ] events
  - [ ] primary dashboards

### Graphic / Asset Brief For Another AI Or Designer

If you want a new ad visual system built quickly, ask for these assets:

1. `Inline Ad mock`
   - aspect ratio: roughly feed-card friendly
   - mood: local, polished, human, not corporate
   - should visually fit between artist/artwork/community cards
   - include:
     - business name
     - short headline
     - optional image area
     - discreet sponsored label
     - CTA area
   - style:
     - dark-glass / modern editorial
     - vibrant but tasteful accents
     - no loud coupon-style design
     - should feel like part of a curated downtown culture app

2. `Banner Ad mock`
   - wide, low-height format
   - built for between-section placement
   - minimal text
   - one strong line of copy plus subtle CTA
   - style:
     - softer than the inline ad
     - should act like a visual pause, not a sales interruption

3. `Merchant Create Ad preview graphic`
   - one panel showing both ad types side by side
   - left: inline ad preview
   - right: banner ad preview
   - labels:
     - `Best for feed visibility`
     - `Best for section visibility`
   - should help a non-technical local business understand the difference
     instantly

Prompt direction for another AI:

- Design for a mobile app that helps people explore downtowns, public art,
  local artists, and local events.
- The ad system should feel community-centered, cultured, and local-business
  friendly.
- Avoid generic startup SaaS visuals, bright coupon aesthetics, or aggressive
  marketing styles.
- The ad should look like it belongs inside a premium art-and-exploration app.
- Use elegant typography, restrained motion, layered glass or card surfaces,
  and editorial photography or illustration.

### Launch Recommendation

If the goal is to go live soon and stay compliant, the recommended launch order
is:

1. Freeze sponsorship changes.
2. Rebuild ads into only `Inline Ad` and `Banner Ad`.
3. Make ads monthly only.
4. Remove customer-facing statistics and campaign-like complexity.
5. Launch with manual activation first unless compliant iOS IAP is fully ready.
6. Add self-serve payments only after the simplified ad model is stable in
   production.
