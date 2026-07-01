# Architecture

Local ARTbeat is now organized around the mobile app's active product loop:

- auth and account setup
- capture
- radar/discovery
- map and art walks
- community activity feed
- rankings and achievements
- community events
- sponsorship submission and display
- profile and settings

## Active Packages

- `artbeat_auth`
- `artbeat_core`
- `artbeat_capture`
- `artbeat_art_walk`
- `artbeat_community`
- `artbeat_events`
- `artbeat_profile`
- `artbeat_settings`
- `artbeat_sponsorships`

## Removed Mobile Surfaces

The mobile app no longer includes admin dashboards, old local ads, artist storefronts, artwork marketplace/sales, commissions, gallery tools, messaging, subscriptions, boosts, quests, or goals.

Admin and moderation work should live outside the mobile app.
