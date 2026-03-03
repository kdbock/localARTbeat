# artbeat_settings

Settings module for ARTbeat. This package provides settings models, services, provider state management, and settings-focused screens/widgets.

## Public API

Entrypoint: `lib/artbeat_settings.dart`

- Models (via `src/models/models.dart`)
  - `UserSettingsModel`
  - `NotificationSettingsModel`
  - `PrivacySettingsModel`
  - `SecuritySettingsModel`
  - `AccountSettingsModel`
  - `BlockedUserModel`
  - `SettingsCategoryModel`
  - `DeviceActivityModel`
- Services
  - `SettingsService`
  - `EnhancedSettingsService`
  - `IntegratedSettingsService`
- Provider
  - `SettingsProvider`
- Screens (barrel export)
  - `SettingsScreen`
  - `AccountSettingsScreen`
  - `BlockedUsersScreen`
  - `BecomeArtistScreen`
  - `NotificationSettingsScreen`
  - `PrivacySettingsScreen`
  - `SecuritySettingsScreen`
  - `LanguageSettingsScreen`
  - `ThemeSettingsScreen`
- Widgets (barrel export)
  - `BecomeArtistCard`
  - `GlassCard`
  - `GlassTextField`
  - `HudButton`
  - `HudTopBar`
  - `LanguageSelector`
  - `SettingsCategoryHeader`
  - `SettingsHeader`
  - `SettingsListItem`
  - `SettingsSectionCard`
  - `SettingsToggleRow`

## Core Behavior

- `SettingsService` manages user settings reads/writes in Firestore and handles:
  - general settings
  - notification/privacy preference storage
  - blocked users list updates
  - GDPR-style data request records (`download`, `deletion`)
- `SettingsProvider` wraps `IntegratedSettingsService` and exposes loading/error-aware state for UI.
- Utility support includes:
  - `SettingsConfiguration` for runtime configuration flags
  - `SettingsPerformanceMonitor` for timing/cache metrics

## Firestore Collections Used

Common collections accessed by settings services:

- `userSettings`
- `userSettings/{userId}/notifications/preferences`
- `userSettings/{userId}/privacy/preferences`
- `dataRequests`

## Routes

Route constants are exposed in `src/routes.dart` under `SettingsRoutes`, including:
- `/settings`
- `/settings/account`
- `/settings/privacy`
- `/settings/notifications`
- `/settings/security`
- `/settings/blocked-users`
- `/settings/become-artist`

## Testing

From repository root:

```bash
flutter test packages/artbeat_settings
flutter analyze packages/artbeat_settings
```
