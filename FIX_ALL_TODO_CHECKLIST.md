# Comprehensive Project Fix & TODO Checklist

This document tracks all required and recommended fixes, as well as pending features across the ArtBeat codebase.

## ✅ Recently Completed
- [x] **Capture & Media Integration**: Integrated `AdvancedCameraService` with a custom `CaptureScreen` UI, updated `CaptureUploadScreen` and `CaptureEditScreen` to use it as a camera-only picker, and implemented backend update/submit logic.
- [x] **TTS Regex Investigation**: Exhaustive codebase search confirmed the invalid regex `^|[^\p{Letter}\\]` is not present in source code or assets. Likely originating from Firebase Remote Config or dynamic runtime generation in the native Android engine.
- [x] **Secure Env Loading**: Refactored `EnvLoader` to use `flutter_dotenv` consistent with `ConfigService`, allowing both `.env` files and `--dart-define` build flags.
- [x] **Audit Firestore Rules**: Comprehensive review and restriction of rules for `events`, `activities`, `art`, and `ads` (specifically `localAds`) to ensure appropriate public/private access.
- [x] **Firebase App Check**: Initialized `AppCheckProvider` in `SecureFirebaseConfig` and integrated into `main.dart` to resolve `permission-denied` errors.
- [x] **Theme Switching**: Functional implementation in `ThemeSettingsScreen` using `ArtbeatThemeProvider`.
- [x] **Author Name Fetching**: Implemented author name retrieval with caching in `WrittenContentDiscoveryScreen`.
- [x] **Implement Purchase Flow**: Completed the `UnifiedPaymentService` integration for written content in `WrittenContentDetailScreen`.
- [x] **Unified Payment Service Enhancement**: Added `clientSecret` support and `initPaymentSheetForPayment`/`presentPaymentSheet` methods.

## 🔴 High Priority: Critical Fixes & Security

## 🟡 Medium Priority: Core Features & Refactoring
- [ ] **Social & Engagement**:
    - [ ] Implement favorite functionality in `AudioContentDetailScreen`.
    - [ ] Refactor tabs in `AdvancedAnalyticsDashboardScreen` (Trends, Events, Activity).
    - [ ] Implement rating-based sorting in `WrittenContentDiscoveryScreen`.
- [ ] **Performance & Optimization**:
    - [ ] Implement `searchTokens` field in `KnownEntityRepository` for better search performance.
    - [ ] Optimize Haversine calculation in `SponsorService`.

## 🔵 Low Priority: UX & Maintenance
- [ ] **UI Thread Safety**: Audit fragments for `setValue` calls on background threads (e.g., `MyDeviceInfoFragment`).
- [ ] **Navigation & Routing**:
    - [ ] Implement missing `CaptureSettingsScreen`.
    - [ ] Confirm deletion flow in `PrivacySettingsScreen`.
    - [ ] Implement navigation to search from `WrittenContentDiscoveryScreen`.
    - [ ] Replace placeholders with `PublicArtCard` in `SearchResultsScreen`.
- [ ] **System Notifications**: Implement notification triggers for expiring features in `FeatureMaintenanceService`.

## 📱 Screen & Routing Status
- [x] **ExploreScreen** – Handled by `art_walk.DiscoverDashboardScreen` (`/art-walk/explore`)
- [x] **GalleryDetailsScreen** – Handled by `ArtistPublicProfileScreen`
- [x] **ArtistProfileScreen** – Handled by `ArtistPublicProfileScreen`
- [x] **EventDetailsScreen** – Verified
- [x] **FavoritesScreen** – Verified
- [x] **AdminEnhancedDashboardScreen** – Handled by `ModernUnifiedAdminDashboard`
- [x] **AdminLoginScreen** – Verified
- [ ] **AdEditScreen** – Missing/Pending
- [x] **ArtWalkListScreen** – Verified

## 🔧 System & Hardware (Lower Priority)
- [ ] **Photo Picker Sync**: Resolve `IllegalStateException` in `PickerSyncController`.
- [ ] **Bluetooth Stats**: Resolve `Cannot acquire BluetoothActivityEnergyInfo` (Error 11).
- [ ] **Network Routes**: Address duplicate route errors in `netd`.
