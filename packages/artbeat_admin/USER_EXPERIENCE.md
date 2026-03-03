# artbeat_admin User Experience

This document reflects the UX currently implemented in `packages/artbeat_admin`.

## Primary Journeys

1. Admin authentication and entry
- Entry: `AdminLoginScreen`
- Post-auth destination: `ModernUnifiedAdminDashboard`

2. Unified operational dashboard
- Primary control surface: `ModernUnifiedAdminDashboard`
- Cross-cutting KPIs, moderation queues, and management shortcuts are consolidated here.

3. User and account administration
- User detail and actions: `AdminUserDetailScreen`
- Settings and security controls: `AdminSettingsScreen`, `AdminSecurityCenterScreen`
- System status view: `AdminSystemHealthScreen`

4. Moderation workflows
- Content moderation views: `AdminContentModerationScreen`, `AdminArtworkModerationScreen`, `AdminCommunityModerationScreen`, `AdminArtWalkModerationScreen`, `EventModerationDashboardScreen`

5. Upload and operations tooling
- Admin tooling surface: `ModernUnifiedAdminUploadToolsScreen`

## UX Building Blocks

- Shared admin widgets include: `AdminHeader`, `AdminDrawer`, `AdminMetricsCard`, `AdminDataTable`, `AdminSearchModal`, and moderation/sponsorship helpers in `src/widgets/`.

## Experience Contracts

- Dashboard and moderation flows depend on Firestore-backed service layers.
- Privileged actions are tied to authenticated admin user context.
- Admin settings operations are persisted in `admin_settings` with change logs.
