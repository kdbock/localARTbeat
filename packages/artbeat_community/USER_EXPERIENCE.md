# artbeat_community User Experience

This document reflects the current UX surface in `packages/artbeat_community`.

## Primary Journeys

1. Community feed and post engagement
- Entry screens include `ArtCommunityHub`, `UnifiedCommunityHub`, and feed-focused screens in `screens/feed/`.
- Users browse posts, react, comment, and open post detail/comment views.

2. Content creation
- Post creation flows use `CreateArtPostScreen`, `CreatePostScreen`, and group variants.
- Users can publish text/media posts and participate in group-oriented feeds.

3. Artist discovery and social graph
- Community surfaces include artist browsing widgets and discovery screens.
- Follow/follower behaviors and profile-linked interactions are embedded across feed cards and artist lists.

4. Commissions workflow
- Commission hub and specialized screens under `screens/commissions/` handle request, quoting, progress, dispute, and rating flows.

5. Groups and studios
- Group feed and studio screens support collaborative community experiences (`screens/studios/`, `GroupFeedScreen`, related widgets).

## UX Building Blocks

- High-traffic widgets include:
  - `PostCard` / `EnhancedPostCard`
  - `CommentsModal`
  - `CommunityDrawer` / `CommunityHudDrawer`
  - `CommissionArtistsBrowser`
  - `GroupPostCard`

## Experience Contracts

- Feed and engagement flows depend on Firestore-backed real-time data.
- Commission flows depend on direct commission models/services and payment integration surfaces.
- Moderation behaviors are enforced through `ModerationService` checks and queue actions.
