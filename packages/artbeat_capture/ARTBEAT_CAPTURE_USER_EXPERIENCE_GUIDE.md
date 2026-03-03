# artbeat_capture User Experience

This document reflects the current UX implemented in `packages/artbeat_capture`.

## Primary Journeys

1. Capture creation
- Entry points: `CaptureScreen`, `CaptureUploadScreen`, dashboard quick actions.
- Users capture media, add metadata, and submit for upload/review.

2. Capture detail and review
- Entry points: `CaptureDetailScreen`, `CaptureDetailViewerScreen`, `CaptureReviewScreen`, `CaptureEditScreen`.
- Users inspect capture metadata, edit fields, and complete submission flow.

3. Personal capture management
- Entry points: `MyCapturesScreen`, `MyCapturesPendingScreen`, `MyCapturesApprovedScreen`.
- Users track submitted captures by status and open individual detail views.

4. Discovery and browsing
- Entry points: `EnhancedCaptureDashboardScreen`, `CapturesListScreen`, `CaptureViewScreen`.
- Users browse feed-style capture surfaces and interact with comments/likes where available.

5. Settings and compliance
- Entry points: `CaptureSettingsScreen`, `TermsAndConditionsScreen`.
- Users manage capture settings and review terms/compliance requirements.

## UX Building Blocks

- Common capture widgets include:
  - `CaptureDrawer`
  - `CapturesGrid`
  - `LikeButtonWidget`
  - `CommentItemWidget`
  - `CommentsSectionWidget`
  - dashboard utility widgets (`XPBar`, quest/stat cards, HUD components)

## Experience Contracts

- Capture persistence and retrieval are mediated through `CaptureService`.
- Offline flow depends on queue/database services when connectivity is unavailable.
- Capture metadata and public-art propagation depend on Firestore-backed service contracts.
