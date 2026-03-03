# artbeat_settings User Experience

This document reflects the current settings UX shipped in `packages/artbeat_settings`.

## Primary Journeys

1. Open settings hub
- Entry screen: `SettingsScreen`
- Users access account, privacy, notification, security, language, and theme settings.

2. Update personal/account settings
- `AccountSettingsScreen` covers account-level preferences and profile-related controls.
- `ThemeSettingsScreen` and `LanguageSettingsScreen` handle display/localization preferences.

3. Configure privacy and security
- `PrivacySettingsScreen` and `SecuritySettingsScreen` expose privacy and auth/security controls.
- `BlockedUsersScreen` handles user block list management.

4. Configure notifications
- `NotificationSettingsScreen` handles notification category and behavior preferences.

5. Artist transition
- `BecomeArtistScreen` and `BecomeArtistCard` support user-to-artist conversion flow entry.

## UX Building Blocks

- Section and structure components:
  - `SettingsHeader`
  - `SettingsCategoryHeader`
  - `SettingsSectionCard`
  - `SettingsListItem`
  - `SettingsToggleRow`
- Supporting UI primitives:
  - `GlassCard`, `GlassTextField`
  - `HudTopBar`, `HudButton`
  - `LanguageSelector`

## Experience Contracts

- Settings state is provided through `SettingsProvider`.
- Service layer (`SettingsService`/`IntegratedSettingsService`) persists user settings to Firestore.
- Block/unblock and privacy request interactions rely on authenticated user context.
