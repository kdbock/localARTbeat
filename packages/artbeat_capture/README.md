# artbeat_capture

Capture module for ARTbeat. This package handles capture creation flows, upload/review screens, offline queue behavior, and capture-specific UI widgets.

## Public API

Entrypoint: `lib/artbeat_capture.dart`

- Re-exported model
  - `CaptureModel` (from `artbeat_core`)
- Screens
  - `EnhancedCaptureDashboardScreen`
  - `CapturesListScreen`
  - `TermsAndConditionsScreen`
  - `CaptureUploadScreen`
  - `CaptureDetailScreen`
  - `CaptureDetailViewerScreen`
  - `CaptureEditScreen`
  - `MyCapturesScreen`
  - `MyCapturesPendingScreen`
  - `MyCapturesApprovedScreen`
  - `CaptureScreen`
  - `CaptureViewScreen`
  - `CaptureReviewScreen`
  - `CaptureSettingsScreen`
- Services
  - `CaptureService`
  - `StorageService`
  - `CameraService`
  - `AdvancedCameraService`
  - `AIMLIntegrationService`
  - `CaptureAnalyticsService`
  - `CaptureTermsService`
- Widgets
  - core capture widgets (`CapturesGrid`, `CaptureDrawer`, comment/like widgets)
  - dashboard/design widgets (`GlassCard`, `HudTopBar`, `XPBar`, quest/stat widgets)
- Models/Utils
  - `MediaCapture`
  - `OfflineQueueItem`
  - `CaptureHelper`

## Core Behavior

- `CaptureService` is the primary integration point for loading/saving captures and syncing public art records.
- Online/offline save routing is handled by `saveCaptureWithOfflineSupport` using connectivity checks and `OfflineQueueService`.
- Local queue and persistence support are provided by `OfflineQueueService` + `OfflineDatabaseService`.

## Firestore Collections Used

Primary collections referenced in capture services:

- `captures`
- `publicArt`
- `users`
- capture-adjacent activity collections used by integration flows

## Testing

From repository root:

```bash
flutter test packages/artbeat_capture
flutter analyze packages/artbeat_capture
```
