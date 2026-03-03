# artbeat_admin

Administrative module for ARTbeat. This package provides admin-facing models, services, moderation screens, and dashboard tooling for cross-package platform operations.

## Public API

Entrypoint: `lib/artbeat_admin.dart`

- Models
  - `AdminStatsModel`
  - `UserAdminModel`
  - `ContentReviewModel`
  - `ContentModel`
  - `AnalyticsModel`
  - `AdminSettingsModel`
  - `RecentActivityModel`
- Services
  - `AdminService`
  - `ContentReviewService`
  - `AnalyticsService`
  - `EnhancedAnalyticsService`
  - `FinancialAnalyticsService`
  - `CohortAnalyticsService`
  - `AdminSettingsService`
  - `RecentActivityService`
  - `MigrationService`
  - `ConsolidatedAdminService`
  - `UnifiedAdminService`
  - `AuditTrailService`
- Screens
  - `ModernUnifiedAdminDashboard`
  - `ModernUnifiedAdminUploadToolsScreen`
  - `AdminUserDetailScreen`
  - `AdminSettingsScreen`
  - `AdminSecurityCenterScreen`
  - `AdminSystemHealthScreen`
  - `AdminLoginScreen`
  - `EventModerationDashboardScreen`
  - `AdminArtworkModerationScreen`
  - `AdminCommunityModerationScreen`
  - `AdminArtWalkModerationScreen`
  - `AdminContentModerationScreen`
- Routes
  - `AdminRoutes`
- Widgets
  - widgets barrel (`src/widgets/widgets.dart`)
  - `coupon_dialogs.dart`

## Core Behavior

- `AdminService` aggregates user/content/event counts and supports user moderation actions.
- `ContentReviewService` fetches/normalizes pending and flagged content across captures, ads, posts, comments, artwork, and chapters.
- `AdminSettingsService` manages `admin_settings` state and change logging.
- `RecentActivityService` records and queries operational activity in `recent_activities`.

## Firestore Collections Used

Common collections touched directly by the admin package include:

- `users`
- `artwork`
- `captures`
- `events`
- `admin_settings`
- `admin_settings_logs`
- `admin_settings_backups`
- `recent_activities`
- moderation sources such as `posts`, `comments`, `ads`, and `captures`

## Testing

From repository root:

```bash
flutter test packages/artbeat_admin
flutter analyze packages/artbeat_admin
```
