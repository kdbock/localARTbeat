# Investor Audit: Marketability

## Investor View

**Current rating:** 8/10  
**Assessment:** Strong product breadth and monetization variety, but weak conversion instrumentation and fragmented commerce flows reduce confidence that demand can be measured and scaled efficiently.

## Code Reviewed

- `packages/artbeat_ads/IAP_SKU_LIST.md`
- `packages/artbeat_ads/lib/src/services/local_ad_iap_service.dart`
- `packages/artbeat_sponsorships/lib/src/services/sponsorship_checkout_service.dart`
- `lib/src/services/route_analytics_service.dart`
- `lib/src/routing/app_router.dart`

## Findings

### 1. The product surface is broad enough to tell a real commercial story

The repo supports multiple monetization and engagement surfaces:

- monthly local ads and boosts in `packages/artbeat_ads/IAP_SKU_LIST.md`
- artist subscriptions in `packages/artbeat_ads/IAP_SKU_LIST.md`
- sponsorship subscriptions in `packages/artbeat_sponsorships/lib/src/services/sponsorship_checkout_service.dart`
- route-level usage analytics in `lib/src/services/route_analytics_service.dart`

This is a real strength. ARTbeat is not a single-feature app.

### 2. Monetization flows are fragmented by channel and implementation

The app currently mixes:

- Apple/Google IAP logic in `packages/artbeat_ads/lib/src/services/local_ad_iap_service.dart`
- Stripe subscription setup in `packages/artbeat_sponsorships/lib/src/services/sponsorship_checkout_service.dart`
- Cloud Function backed payment orchestration in core payment services

That can be valid, but there is no obvious single product-catalog or experiment layer controlling pricing, packaging, feature entitlements, and conversion reporting across all revenue lines. That reduces go-to-market agility.

### 3. Instrumentation is route-oriented, not funnel-oriented

`lib/src/services/route_analytics_service.dart` tracks route visits and route popularity, but it does not appear to track the business funnel stages that investors care about:

- paywall viewed
- product loaded
- checkout started
- checkout failed
- purchase completed
- renewal retained
- ad approved
- sponsor activated

Without those events, marketability is hard to prove numerically.

### 4. Ad purchase UX is commercially viable but operationally thin

`packages/artbeat_ads/lib/src/services/local_ad_iap_service.dart` successfully loads products and completes purchases, but the service only returns purchase metadata. It does not itself show a stronger post-purchase lifecycle such as:

- entitlement reconciliation
- retry-safe server confirmation
- purchase state restoration reporting
- conversion telemetry by placement and product

That makes the commercial story harder to validate.

## Recommended Action Checklist

- [ ] Create a single monetization catalog document and code source of truth for IAP, Stripe, sponsorship, boosts, and artist subscriptions.
- [ ] Add funnel events for every paid flow: impression, tap, product-load success, checkout start, checkout success, checkout failure, entitlement activation, renewal, cancellation.
- [ ] Add conversion dashboards keyed by product family, placement, and user segment.
- [ ] Normalize post-purchase handling so every paid flow records server confirmation and final entitlement state.
- [ ] Add a feature-flag or remote-config layer for pricing tests, paywall copy tests, and placement experiments.
- [ ] Track ad-review and sponsorship-approval latency so sales friction is measurable.
- [ ] Add retention metrics for artists, sponsors, and advertisers, not just general route traffic.
- [ ] Produce one investor-facing KPI report sourced from the app telemetry: CAC proxy, activation, purchase conversion, 30-day retention, and revenue by stream.
