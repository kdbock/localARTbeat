---
description: Repository Information Overview
alwaysApply: true
---

# ArtBeat Information

## Summary

ArtBeat is a comprehensive Flutter application for art discovery, capture, and community engagement. The app allows users to explore art, participate in art walks, capture and share their own artwork, and connect with other art enthusiasts through a modular architecture with separate packages for different features.

## Structure

The project follows a modular architecture with separate packages for different features:

- **lib/**: Main app code with routing and core functionality
- **packages/**: Feature-specific packages (13 total) including core, auth, community, etc.
- **assets/**: App assets including images, icons, and fonts
- **scripts/**: Build and deployment scripts for different platforms
- **android/, ios/, web/, macos/, linux/, windows/**: Platform-specific code

## Language & Runtime

**Language**: Dart
**Version**: SDK ^3.8.0
**Framework**: Flutter >=3.35.0
**Build System**: Flutter build system
**Package Manager**: pub (Dart/Flutter package manager)

## Dependencies

**Main Dependencies**:

- Firebase suite (auth, firestore, storage, analytics, app_check)
- Provider for state management
- HTTP for API communication
- In-app purchase for monetization
- Google Maps for location features
- Image handling (image_picker, cached_network_image)
- Local storage (shared_preferences)

**Development Dependencies**:

- build_runner for code generation
- flutter_test and integration_test for testing
- mockito for mocking in tests
- flutter_lints for code quality

## Build & Installation

```bash
# Install dependencies
flutter pub get

# Run the app in development mode
flutter run

# Build production artifacts
RELEASE_STRIPE_PUBLISHABLE_KEY=pk_live_... GOOGLE_MAPS_API_KEY=... ./scripts/build_secure.sh all
```

## Testing

**Framework**: Flutter's built-in testing framework
**Test Location**:

- Unit/widget tests in `/test` directory
- Package-specific tests in `packages/*/test`
  **Run Command**:

```bash
# Run all tests
flutter test

# Run tests for specific package
cd packages/artbeat_core
flutter test
```

## Projects

### Core Package

**Configuration File**: packages/artbeat_core/pubspec.yaml

#### Language & Runtime

**Language**: Dart
**Version**: SDK >=3.8.0 <4.0.0
**Framework**: Flutter >=3.35.0

#### Dependencies

**Main Dependencies**:

- Firebase services (core, auth, firestore, storage, analytics)
- Image handling (image_picker, cached_network_image)
- Location services (google_maps_flutter, geolocator)
- Payment processing (in_app_purchase, flutter_stripe)
- Storage (shared_preferences)

#### Build & Installation

```bash
cd packages/artbeat_core
flutter pub get
```

### Auth Package

**Configuration File**: packages/artbeat_auth/pubspec.yaml

#### Language & Runtime

**Language**: Dart
**Version**: SDK >=3.8.0 <4.0.0
**Framework**: Flutter >=3.35.0

#### Dependencies

**Main Dependencies**:

- Firebase authentication
- Core package dependencies

#### Build & Installation

```bash
cd packages/artbeat_auth
flutter pub get
```

### Community Package

**Configuration File**: packages/artbeat_community/pubspec.yaml

#### Language & Runtime

**Language**: Dart
**Version**: SDK >=3.8.0 <4.0.0
**Framework**: Flutter >=3.35.0

#### Dependencies

**Main Dependencies**:

- Firebase Firestore for community data
- Core package dependencies

#### Build & Installation

```bash
cd packages/artbeat_community
flutter pub get
```

### Messaging Package

**Configuration File**: packages/artbeat_messaging/pubspec.yaml

#### Language & Runtime

**Language**: Dart
**Version**: SDK >=3.8.0 <4.0.0
**Framework**: Flutter >=3.35.0

#### Dependencies

**Main Dependencies**:

- Firebase Firestore for message storage
- Firebase Cloud Messaging for notifications
- Core package dependencies

#### Build & Installation

```bash
cd packages/artbeat_messaging
flutter pub get
```

### Art Walk Package

**Configuration File**: packages/artbeat_art_walk/pubspec.yaml

#### Language & Runtime

**Language**: Dart
**Version**: SDK >=3.8.0 <4.0.0
**Framework**: Flutter >=3.35.0

#### Dependencies

**Main Dependencies**:

- Location services (google_maps_flutter, geolocator)
- Firebase Firestore for art walk data
- Core package dependencies

#### Build & Installation

```bash
cd packages/artbeat_art_walk
flutter pub get
```
