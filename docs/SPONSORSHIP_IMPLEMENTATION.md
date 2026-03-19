# Sponsorship Implementation

## Purpose

Document the sponsorship system as it exists in the codebase today.

This file is an implementation reference, not a build prompt. It should answer:

- what the sponsorship system currently does
- where the code lives
- how sponsorships are selected and rendered
- how business and admin flows are wired
- which gaps remain between the intended design and the current implementation

## Current Status

The sponsorship system is implemented and integrated.

It is not the primary repo-level blocker right now. Current release risk is
driven by the legal/data-rights rollout, not sponsorships.

Sponsorships currently support:

- a dedicated `artbeat_sponsorships` package
- Firestore-backed sponsorship records
- business-facing creation and review flows
- admin review/list/detail surfaces
- live in-app placement rendering through `SponsorBanner`
- placement-aware reads for art walk, capture, and discover surfaces

## Primary Code Locations

Package root:

- `packages/artbeat_sponsorships/`

Core model and services:

- `packages/artbeat_sponsorships/lib/src/models/sponsorship.dart`
- `packages/artbeat_sponsorships/lib/src/models/sponsorship_tier.dart`
- `packages/artbeat_sponsorships/lib/src/models/sponsorship_status.dart`
- `packages/artbeat_sponsorships/lib/src/services/sponsor_service.dart`
- `packages/artbeat_sponsorships/lib/src/services/sponsorship_repository.dart`
- `packages/artbeat_sponsorships/lib/src/services/sponsorship_checkout_service.dart`
- `packages/artbeat_sponsorships/lib/src/utils/sponsorship_placements.dart`
- `packages/artbeat_sponsorships/lib/src/utils/sponsorship_pricing.dart`

Business-facing screens:

- `packages/artbeat_sponsorships/lib/src/screens/sponsorships/create_sponsorship_screen.dart`
- `packages/artbeat_sponsorships/lib/src/screens/sponsorships/sponsorship_review_screen.dart`
- `packages/artbeat_sponsorships/lib/src/screens/sponsorships/sponsorship_dashboard_screen.dart`
- `packages/artbeat_sponsorships/lib/src/screens/sponsorships/sponsorship_detail_screen.dart`
- `packages/artbeat_sponsorships/lib/src/screens/sponsorships/art_walk_sponsorship_screen.dart`
- `packages/artbeat_sponsorships/lib/src/screens/sponsorships/capture_sponsorship_screen.dart`
- `packages/artbeat_sponsorships/lib/src/screens/sponsorships/discover_sponsorship_screen.dart`

Admin-facing screens:

- `packages/artbeat_admin/lib/src/screens/sponsorships/admin_sponsorship_list_screen.dart`
- `packages/artbeat_admin/lib/src/screens/sponsorships/admin_sponsorship_detail_screen.dart`
- `packages/artbeat_admin/lib/src/screens/sponsorships/admin_sponsorship_review_screen.dart`

App-shell routing:

- `lib/src/routing/app_router.dart`

Live integrations:

- `packages/artbeat_capture/lib/src/screens/capture_screen.dart`
- `packages/artbeat_art_walk/lib/src/screens/art_walk_detail_screen.dart`
- `packages/artbeat_art_walk/lib/src/screens/art_walk_map_screen.dart`
- `packages/artbeat_art_walk/lib/src/screens/discover_dashboard_screen.dart`
- `packages/artbeat_art_walk/lib/src/widgets/instant_discovery_radar.dart`
- `packages/artbeat_art_walk/lib/src/widgets/discovery_capture_modal.dart`
- `packages/artbeat_art_walk/lib/src/services/instant_discovery_service.dart`

## What Sponsorships Are

In this repo, sponsorships are a premium promotional system separate from local
ads.

They differ from local ads in a few important ways:

- they are explicitly modeled in their own Firestore collection
- they are lifecycle-controlled through `pending`, `active`, `expired`, and
  `rejected`
- they are rendered in fixed product surfaces instead of being treated as a
  generic ad feed
- they can be constrained by placement and optional geographic radius
- they include business/admin review flows rather than acting as a purely loose
  content object

## Current Data Model

The canonical runtime model is `Sponsorship` in
`packages/artbeat_sponsorships/lib/src/models/sponsorship.dart`.

Important fields currently in use:

- identity: `id`, `businessId`, `businessName`
- lifecycle: `tier`, `status`, `startDate`, `endDate`, `createdAt`
- placement: `placementKeys`
- display assets: `logoUrl`, `bannerUrl`, `linkUrl`
- targeting: `radiusMiles`, `latitude`, `longitude`
- contextual links: `relatedEntityId`, `chapterId`
- contact/ops details: `contactEmail`, `phone`, `brandingNotes`,
  `additionalNotes`
- payment-linked metadata: `paymentStatus`, `stripeCustomerId`,
  `stripeSubscriptionId`, `stripePriceId`, `stripeProductId`

Current tiers in code:

- `artWalk`
- `capture`
- `discover`

Current statuses in code:

- `pending`
- `active`
- `expired`
- `rejected`

## Firestore Contract

The active collection used by the runtime code is:

- `sponsorships`

Read/write access in the sponsorship package is centered around
`SponsorshipRepository` and `SponsorService`.

Repository responsibilities:

- create sponsorship records
- fetch by id
- fetch by business
- fetch by status for admin views
- update status
- expire sponsorships
- delete sponsorships

Selection responsibilities:

- resolve one sponsor for a placement
- resolve all active sponsors for a placement
- apply radius filtering when configured

## Placement Contract

The current placement list is defined in
`packages/artbeat_sponsorships/lib/src/utils/sponsorship_placements.dart`.

Supported placement keys today:

- `art_walk_header`
- `art_walk_stop_card`
- `capture_detail_banner`
- `discover_radar_banner`

This is narrower than the older design notes. There is no current runtime
placement list for splash, dashboard top/footer, or event header sponsorships.

## Runtime Selection Behavior

`SponsorService` is the main placement-resolution service.

Current behavior:

- queries only `active` sponsorships
- restricts by `placementKeys`
- restricts to `startDate <= now <= endDate`
- applies radius filtering when `radiusMiles` is present
- requires a valid user location for radius-targeted placements
- shuffles remaining matches and returns one

The service is intentionally lightweight and UI-agnostic.

## Rendering Behavior

`SponsorBanner` is the main runtime renderer for sponsorship placements.

Current properties of the widget:

- async-safe loading
- silent failure behavior so sponsorships do not break primary UI
- no reserved layout space while loading
- optional placeholder mode
- variant rendering based on sponsorship tier

Current render variants:

- `artWalk` uses a labeled banner treatment
- `capture` uses a compact banner treatment
- `discover` uses a compact banner treatment

## Business Flow

The business-facing flow is package-local and routed through the app shell.

Current flow shape:

1. User enters a sponsorship entry screen by type.
2. User configures sponsorship details and duration.
3. Review flow collects business contact information and branding notes.
4. Review flow creates a sponsorship record and coordinates checkout logic.
5. Business can view existing sponsorships in the dashboard/detail surfaces.

Primary screens involved:

- `ArtWalkSponsorshipScreen`
- `CaptureSponsorshipScreen`
- `DiscoverSponsorshipScreen`
- `CreateSponsorshipScreen`
- `SponsorshipReviewScreen`
- `SponsorshipDashboardScreen`
- `SponsorshipDetailScreen`

## Admin Flow

Admin sponsorship handling lives in `artbeat_admin`.

Current admin responsibilities exposed in code:

- list sponsorships
- inspect sponsorship details
- review and approve/reject sponsorships

This keeps sponsorship governance visible in admin tooling instead of relying
only on direct Firestore edits.

## App Integration Points

Sponsorships are currently integrated into user-facing surfaces in live app
flows.

Known integrations include:

- capture flow surface(s)
- art walk detail and map surfaces
- discover dashboard and radar surfaces
- discovery modal surfaces
- discover-service injection path that converts sponsorships into a virtual
  art-like representation for radar use

The main route registration lives in `lib/src/routing/app_router.dart`.

## Important Design Gaps And Mismatches

This section is the main reason this doc exists.

The old sponsorship prompt/spec does not fully match the current code.

Notable mismatches:

- the old prompt mentioned tiers such as `title` and `event`, but current code
  supports only `artWalk`, `capture`, and `discover`
- the old prompt described a broader placement-key contract; current code ships
  only four placement keys
- `SponsorService` comments mention title-sponsor override behavior, but the
  current implementation does not perform title-priority resolution
- `SponsorBanner` only renders current runtime tiers and does not implement
  legacy prompt concepts that are no longer present in the enums

These are not necessarily bugs by themselves. They do mean older design notes
should not be treated as authoritative.

## Dependency Notes

`artbeat_core` no longer depends on `artbeat_sponsorships`.

That cleanup is already tracked in the architecture docs and is complete.

The sponsorship package still participates in the remaining higher-coupling
feature graph, especially around app integrations and `artbeat_art_walk`.

## Operational Guidance

When changing sponsorships:

- treat placement behavior as product behavior, not just a UI concern
- verify Firestore field compatibility before changing model fields
- verify at least one business-facing flow and one runtime placement
- keep failures non-blocking for the host feature surface
- document any new placement keys here and in code together

## Recommended Follow-Up

The implementation is real, but the documentation should keep improving.

Recommended next improvements:

1. Decide whether `title` and `event` sponsorship concepts still matter.
2. Remove stale selection-rule comments if those behaviors are not planned.
3. If title-priority behavior is still intended, implement it and test it.
4. Add a small sponsorship test matrix for placement selection and radius
   filtering.
5. Keep this doc aligned with actual placement keys and route surfaces.
