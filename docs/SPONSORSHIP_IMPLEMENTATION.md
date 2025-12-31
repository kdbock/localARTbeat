📁 FILE: docs/SPONSORSHIP_IMPLEMENTATION.md
GOAL

Add a premium sponsorship system alongside the existing local ad system.

Sponsorships are:

tiered

higher priority than ads

optionally radius-based

manually approved or admin-controlled

rendered in fixed UI placements (not feeds)

🧠 Copilot Prompt Blocks — Sponsorship System
🧩 BLOCK 1 — Sponsorship Enums

Prompt to Copilot:

Create two Dart enums for a premium sponsorship system.

SponsorshipTier with values:

title

event

artWalk

capture

discover

SponsorshipStatus with values:

pending

active

expired

rejected

Place them in:

lib/src/models/sponsorship_tier.dart

lib/src/models/sponsorship_status.dart

Keep enums simple. Do not add UI helpers or extensions yet.

🧩 BLOCK 2 — Sponsorship Model

Prompt to Copilot:

Create a Dart model called Sponsorship in
lib/src/models/sponsorship.dart.

The model MUST include:

id (String)

businessId (String)

tier (SponsorshipTier)

status (SponsorshipStatus)

startDate (DateTime)

endDate (DateTime)

radiusMiles (double?, nullable for global)

placementKeys (List<String>)

logoUrl (String)

bannerUrl (String?, optional)

linkUrl (String)

relatedEntityId (String?, eventId or artWalkId)

createdAt (DateTime)

Include:

constructor

fromMap

toMap

Assume Firestore timestamps.
Do NOT add business logic or rendering code.

🧩 BLOCK 3 — Firestore Collection Contract

Prompt to Copilot:

Document the Firestore schema for a new collection called sponsorships.

Each document MUST contain:

tier

status

startDate

endDate

placementKeys

The collection is separate from localAds.

Add a brief comment explaining why sponsorships are not ads.

(You can let Copilot generate a comment block or markdown file.)

🧩 BLOCK 4 — Sponsor Service (Core Logic)

Prompt to Copilot:

Create a service called SponsorService in
lib/src/services/sponsor_service.dart.

It must include:

Future<Sponsorship?> getSponsorForPlacement({
  required String placementKey,
  required LatLng? userLocation,
});

Future<List<Sponsorship>> getActiveSponsorsForPlacement(
  String placementKey,
);

bool isSponsorActive(Sponsorship sponsor);


Use Firestore.
Do NOT reference UI widgets.
Do NOT implement payment logic.

🧩 BLOCK 5 — Sponsor Selection Rules

Prompt to Copilot:

Implement sponsor selection logic in SponsorService with the following strict rules:

Only return sponsors where:

status == active

now is between startDate and endDate

placementKeys contains the placementKey

If radiusMiles is not null:

userLocation must be provided

filter out sponsors outside the radius

If multiple sponsors remain:

shuffle

return the first

If a sponsor has tier == title:

it ALWAYS overrides all others

no rotation

no fallback ads

Write clean, readable logic.
Do not optimize prematurely.

🧩 BLOCK 6 — Placement Key Contract

Prompt to Copilot:

Define a constant map of sponsorship placement keys.

Use string keys only.

Include:

splash

dashboard_top

dashboard_footer

event_header

art_walk_header

art_walk_stop_card

capture_detail_banner

discover_radar_banner

Place this in a shared constants file.
Do NOT tie placement keys to tiers in code.

🧩 BLOCK 7 — Sponsor Banner Widget

Prompt to Copilot:

Create a reusable Flutter widget called SponsorBanner.

File: lib/src/widgets/sponsor_banner.dart

The widget must:

accept placementKey

accept optional userLocation

call SponsorService internally

render nothing if no sponsor is found

never block screen rendering

The widget should be safe to place anywhere in the UI.

🧩 BLOCK 8 — Sponsor Rendering Rules

Prompt to Copilot:

Inside SponsorBanner, render sponsors differently based on tier:

title → full-width logo or banner

event → banner + “Sponsored by”

artWalk → logo + XP callout

capture → compact banner

discover → compact banner

Keep visuals simple.
No animations.
No gestures beyond link tap.

🧩 BLOCK 9 — Splash Screen Integration

Prompt to Copilot:

Inject SponsorBanner into the splash screen using placementKey splash.

If a title sponsor exists:

hide all ads

show sponsor immediately

Do NOT delay app startup.
Do NOT block navigation.

🧩 BLOCK 10 — Dashboard Integration

Prompt to Copilot:

Add sponsor banners to:

home dashboard (top)

community dashboard (footer)

Use placement keys:

dashboard_top

dashboard_footer

Do NOT place sponsors inside scrolling lists.

🧩 BLOCK 11 — Capture Detail Integration

Prompt to Copilot:

Inject a SponsorBanner into the capture detail drawer.

Placement:

below artwork info

above comments

Use placementKey:

capture_detail_banner

🧩 BLOCK 12 — Discover Radar Integration

Prompt to Copilot:

Add sponsor banners to:

discovery result modal

discovery detail drawer

Use placementKey:

discover_radar_banner

🧩 BLOCK 13 — Art Walk Integration

Prompt to Copilot:

Add sponsor banners to Art Walk screens:

Art Walk detail header

Stop completion XP modal

Use placement keys:

art_walk_header

art_walk_stop_card

Do NOT mix with ads.

🧩 BLOCK 14 — Local Business Screen

Prompt to Copilot:

Create local_business_screen.dart.

Layout sections in this exact order:

Business profile

Active sponsorships

Active ads

Promote Your Business (CTA grid)

This screen is a control panel, not a feed.

🧩 BLOCK 15 — Promotion CTAs

Prompt to Copilot:

Add CTA buttons:

Run Local Ad

Sponsor Art Walk

Sponsor Captures

Sponsor Discoveries

Become Title Sponsor (contact-only)

Each CTA routes to a tier-specific flow.
Do NOT reuse the generic ad creation screen.

🧩 BLOCK 16 — Pricing Rules

Prompt to Copilot:

Hardcode sponsorship pricing rules:

Title Sponsor: $10,000 / 12 months

Event Sponsor: $750 / event

Art Walk Sponsor: $250 / 30 days

Capture Sponsor: $250 / 30 days

Discover Sponsor: $250 / 30 days

Payment handled outside IAP.
Do NOT integrate Stripe yet.

🧩 BLOCK 17 — Admin Controls

Prompt to Copilot:

Add admin controls for sponsorships:

approve

reject with reason

force-expire

disable immediately

Reuse patterns from the local ads admin system.

🧩 BLOCK 18 — Metrics (Minimal)

Prompt to Copilot:

Track sponsor impressions with:

sponsorshipId

placementKey

timestamp

businessId

Store in:

sponsorship_metrics/


Do not over-engineer analytics.

🧩 BLOCK 19 — Guardrails

Prompt to Copilot:

Add comments documenting what NOT to do:

do not merge sponsorships into LocalAd

do not rotate title sponsor

do not auto-approve premium tiers

do not place sponsors inside feeds

These are hard product constraints.

PART 1 — DATA MODEL
1. Create Sponsorship Tier Enum

File:
lib/src/models/sponsorship_tier.dart

enum SponsorshipTier {
  title,
  event,
  artWalk,
  capture,
  discover,
}

2. Create Sponsorship Status Enum

File:
lib/src/models/sponsorship_status.dart

enum SponsorshipStatus {
  pending,
  active,
  expired,
  rejected,
}

3. Create Sponsorship Model

File:
lib/src/models/sponsorship.dart

Include ALL fields below — do not omit any.

class Sponsorship {
  final String id;
  final String businessId;
  final SponsorshipTier tier;
  final SponsorshipStatus status;

  final DateTime startDate;
  final DateTime endDate;

  final double? radiusMiles; // null = global
  final List<String> placementKeys;

  final String logoUrl;
  final String? bannerUrl;
  final String linkUrl;

  final String? relatedEntityId; // eventId, artWalkId, etc
  final DateTime createdAt;

  Sponsorship({
    required this.id,
    required this.businessId,
    required this.tier,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.placementKeys,
    required this.logoUrl,
    required this.linkUrl,
    required this.createdAt,
    this.radiusMiles,
    this.bannerUrl,
    this.relatedEntityId,
  });
}

4. Firestore Collection Structure

Create collection:

sponsorships/


Each document MUST include:

tier

status

startDate

endDate

placementKeys

Do NOT reuse localAds.

PART 2 — FIRESTORE INDEXES

Create composite indexes for:

sponsorships

status == active

placementKeys array-contains

startDate <= now

endDate >= now

Optional radius filtering handled client-side (GeoFire optional later).

PART 3 — SERVICE LAYER
5. Create SponsorService

File:
lib/src/services/sponsor_service.dart

Methods REQUIRED:

Future<Sponsorship?> getSponsorForPlacement({
  required String placementKey,
  required LatLng? userLocation,
});

Future<List<Sponsorship>> getActiveSponsorsForPlacement(
  String placementKey,
);

bool isSponsorActive(Sponsorship sponsor);

6. Sponsor Selection Rules (MANDATORY)

Implement logic in this order:

Filter:

status == active

current date within start/end

placementKey match

If radiusMiles != null

userLocation MUST exist

distance <= radiusMiles

Rotation:

shuffle eligible sponsors

return first

Title Sponsor:

ALWAYS override everything

NO rotation

NO fallback ads

PART 4 — UI PLACEMENTS (FIXED CONTRACT)

Use string keys only — do not hardcode tiers in UI.

Required Placement Keys
const sponsorshipPlacements = {
  'splash',
  'dashboard_top',
  'dashboard_footer',
  'event_header',
  'art_walk_header',
  'art_walk_stop_card',
  'capture_detail_banner',
  'discover_radar_banner',
};

PART 5 — SPONSOR BANNER WIDGET
7. Create Reusable Widget

File:
lib/src/widgets/sponsor_banner.dart

Widget responsibilities:

accept placementKey

resolve sponsor via SponsorService

render nothing if none found

never block screen load

SponsorBanner(
  placementKey: 'capture_detail_banner',
  userLocation: currentLatLng,
)

8. Render Rules
Tier	Render Style
Title	Full-width logo or banner
Event	Banner + “Sponsored by”
Art Walk	Logo + XP callout
Capture	Small banner
Discover	Small banner
PART 6 — SCREEN INTEGRATION
9. Splash Screen

Inject SponsorBanner(placementKey: 'splash')

If Title Sponsor exists:

hide all other ads

load immediately

10. Dashboards

Add banners to:

Home dashboard top

Community dashboard footer

Do NOT place inside scroll lists.

11. Capture Detail Screen

Add sponsor banner inside:

art detail drawer

BELOW artwork info

ABOVE comments

Placement key:

capture_detail_banner

12. Discover Radar Screen

Inject banner into:

discovery result modal

discovery detail drawer

Placement key:

discover_radar_banner

13. Art Walk Screens

Add sponsor banners to:

Art Walk detail header

Stop completion XP modal

PART 7 — LOCAL BUSINESS SCREEN
14. Create local_business_screen.dart

Sections (in this order):

Business Profile

Active Sponsorships

Active Ads

Promote Your Business (CTA grid)

15. CTA Buttons (Hardcoded)

Buttons:

Run Local Ad

Sponsor Art Walk

Sponsor Captures

Sponsor Discoveries

Become Title Sponsor (contact-only)

Each button routes to a tier-specific purchase screen.

PART 8 — PRICING & DURATION RULES

Hardcode pricing (NOT IAP):

Tier	Price	Duration
Title	$10,000	12 months
Event	$750	Event dates
Art Walk	$250	30 days
Capture	$250	30 days
Discover	$250	30 days

Payment method:

Stripe / invoice / admin approval

NOT in-app purchase

PART 9 — ADMIN CONTROLS
16. Admin Can:

approve sponsorship

reject with reason

force-expire

disable immediately

Reuse admin patterns from local_ads.

PART 10 — ANALYTICS (MINIMUM)

Track:

sponsor impressions

placementKey

date

optional businessId

Store in:

sponsorship_metrics/

PART 11 — WHAT NOT TO DO

❌ Do NOT:

merge sponsorships into LocalAd

rotate title sponsor

auto-approve high tiers

place sponsors inside feeds

reuse ad pricing logic

DONE WHEN

App loads with no sponsor → behaves exactly like today

Sponsor active → appears ONLY in allowed placements

Ads still function normally

No UI hard dependencies on sponsorships