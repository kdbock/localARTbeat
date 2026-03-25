# Investor Audit: Defensibility

## Investor View

**Current rating:** 5.5/10  
**Assessment:** The moat today is product breadth and execution effort, not a durable technical or data advantage.

## Code Reviewed

- `packages/artbeat_ads/IAP_SKU_LIST.md`
- `lib/src/services/route_analytics_service.dart`
- `packages/artbeat_sponsorships/lib/src/services/sponsorship_checkout_service.dart`
- `packages/artbeat_core/lib/src/services/unified_payment_service.dart`
- `lib/src/routing/app_router.dart`

## Findings

### 1. The current edge is breadth, not proprietary leverage

`packages/artbeat_ads/IAP_SKU_LIST.md` shows multiple revenue streams and roles across artists, supporters, businesses, and advertisers. That is useful product positioning, but it is still mostly a packaging advantage. Competitors can copy packaging faster than they can copy proprietary networks or data.

### 2. Analytics capture does not yet compound into a moat

`lib/src/services/route_analytics_service.dart` stores route events and route popularity, but there is no visible evidence of:

- recommendation ranking loops
- creator quality scoring
- demand forecasting
- ad yield optimization
- sponsorship placement optimization

This means the app collects activity, but it is not obviously turning that activity into defensible intelligence.

### 3. Payments are broad, but not strategically differentiated yet

`packages/artbeat_core/lib/src/services/unified_payment_service.dart` consolidates many payment flows, which is useful operationally. However, that is an integration layer, not a moat by itself. It becomes defensible only when paired with strong proprietary measurement, underwriting, recommendation, or workflow automation.

### 4. Routing and feature sprawl may weaken focus

`lib/src/routing/app_router.dart` is very large and centralizes a large amount of product surface. That supports many features, but it also suggests the app is expanding faster than it is distilling what is uniquely valuable.

## Recommended Action Checklist

- [ ] Define the actual moat hypothesis in writing: creator network, local art discovery graph, advertiser demand network, or artist commerce workflow lock-in.
- [ ] Add business events and data models that can power personalization, ranking, and market intelligence rather than only route tracking.
- [ ] Build a creator reputation graph using signals such as engagement quality, commission completion, sponsorship performance, and repeat buyer activity.
- [ ] Build recommendation systems for discovery, boosts, ads, and sponsors using proprietary usage and outcome data.
- [ ] Create internal dashboards for ad yield, sponsor ROI, and creator monetization quality so data compounds over time.
- [ ] Reduce undifferentiated feature sprawl and prioritize the 2-3 workflows that can become category-defining.
- [ ] Add export-resistant value for creators, such as richer audience intelligence, verified performance history, or local demand visibility.
- [ ] Write and maintain a moat roadmap linking each new telemetry event to a future ranking, pricing, or retention advantage.
