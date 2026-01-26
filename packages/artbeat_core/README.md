# ArtBeat Core

The core package for the ArtBeat application, providing shared functionality, widgets, services, and infrastructure used across all other packages in the ArtBeat ecosystem.

## Features

### 🎨 UI Components & Widgets

#### Navigation & Layout

- **EnhancedBottomNav**: Advanced bottom navigation with badges and special buttons
- **EnhancedNavigationMenu**: Comprehensive navigation menu system
- **QuickNavigationFAB**: Floating action button with navigation shortcuts
- **EnhancedUniversalHeader**: Universal header component with branding
- **MainLayout**: Consistent layout wrapper for screens

#### Content & Media

- **SecureNetworkImage**: Secure image loading with validation and caching
- **OptimizedImage**: Performance-optimized image component
- **UniversalContentCard**: Reusable content card component
- **ArtbeatGradientBackground**: Consistent gradient backgrounds
- **SkeletonWidgets**: Loading state placeholders

#### Interactive Elements

- **ArtbeatButton**: Styled button components
- **ArtbeatInput**: Custom input field components
- **ArtbeatDrawer**: Navigation drawer with custom styling
- **ContentEngagementBar**: User engagement interaction bar
- **FeedbackForm**: User feedback collection widget

#### Specialized Widgets

- **ArtistCTAWidget**: Call-to-action components for artists
- **UserAvatar**: User profile avatar display
- **UsageLimitsWidget**: Feature usage limit indicators
- **ArtCaptureWarningDialog**: Safety warnings for art capture
- **NetworkErrorWidget**: Network error handling display

### 🛠 Core Services

#### Authentication & Security

- **UserService**: User management and profile handling
- **AuthSafetyService**: Enhanced authentication safety measures
- **BiometricAuthService**: Biometric authentication integration
- **CrashPreventionService**: Proactive crash prevention
- **CrashRecoveryService**: Application crash recovery

#### Payment & Subscriptions

- **UnifiedPaymentService**: Comprehensive payment processing for Artwork, Auctions, Subscriptions, and Events
- **StripeSafetyService**: Stripe payment safety measures
- **SubscriptionService**: Subscription management
- **InAppPurchaseManager**: In-app purchase handling
- **CouponService**: Discount and coupon management

#### Content & Media Management

- **ImageManagementService**: Secure image handling and validation
- **EnhancedStorageService**: Advanced cloud storage management
- **FirebaseStorageAuthService**: Authenticated Firebase storage
- **OfflineCachingService**: Offline content caching
- **CachingService**: General-purpose caching

#### AI & Intelligence

- **AIService**: Core AI functionality integration
- **AIFeaturesService**: AI-powered features management
- **ContentEngagementService**: Content engagement analytics

#### Communication & Notifications

- **NotificationService**: Push notification management
- **MessagingService**: In-app messaging system
- **EnhancedShareService**: Social sharing capabilities
- **FeedbackService**: User feedback collection

#### Analytics & Monitoring

- **UsageTrackingService**: Feature usage analytics
- **LeaderboardService**: Gamification leaderboards
- **PerformanceOptimizationService**: App performance monitoring

#### Infrastructure Services

- **ConnectivityService**: Network connectivity management
- **ConfigService**: Application configuration management
- **NavigationService**: Navigation state management
- **AccessibilityService**: Accessibility features support
- **InternationalizationService**: Multi-language support

### 📱 Screens & Interfaces

#### Core Screens

- **SplashScreen**: Application startup screen
- **ArtbeatDashboardScreen**: Main user dashboard
- **AuthRequiredScreen**: Authentication gate screen
- **AdvancedAnalyticsDashboard**: Comprehensive analytics and insights

#### Commerce & Subscriptions

- **SubscriptionPurchaseScreen**: Subscription purchase flow
- **SubscriptionPlansScreen**: Subscription plan selection
- **SimpleSubscriptionPlansScreen**: Simplified plan selection
- **OrderReviewScreen**: Purchase order review
- **CouponManagementScreen**: Coupon code management

#### Navigation & Discovery

- **SearchResultsPage**: Search results display
- **FullBrowseScreen**: Content browsing interface
- **LeaderboardScreen**: Gamification leaderboards
- **HelpSupportScreen**: Help and support interface
- **SystemSettingsScreen**: App settings management

### 🗂 Data Models

#### User & Authentication

- **UserModel**: User profile and account data
- **UserType**: User role and type definitions
- **ArtistModel**: Artist-specific profile data

#### Commerce & Subscriptions

- **SubscriptionModel**: Subscription data structures
- **SubscriptionTier**: Subscription level definitions
- **PaymentMethodModel**: Payment method information
- **CouponModel**: Discount and promotion data
- **InAppPurchaseModels**: In-app purchase data

#### Content & Engagement

- **ArtworkModel**: Artwork metadata and information
- **CaptureModel**: Art capture session data
- **CommentModel**: User comment data
- **EngagementModel**: User engagement metrics
- **EventModel**: Event and activity data

#### System & Configuration

- **FeedbackModel**: User feedback data structures
- **NotificationModel**: Push notification data
- **FeatureLimits**: Feature usage limit definitions

### 🔧 Utilities & Helpers

- **AppLogger**: Comprehensive logging system
- **PerformanceMonitor**: Performance tracking utilities
- **ImageUtils**: Image processing utilities
- **LocationUtils**: Geolocation helper functions
- **PermissionUtils**: Permission management helpers
- **ValidationUtils**: Data validation utilities

### 🎯 State Management

- **CommunityProvider**: Community-related state management
- **MessagingProvider**: Messaging state management
- **DashboardViewModel**: Dashboard screen state management

## Installation & Usage

Add to your `pubspec.yaml`:

```yaml
dependencies:
  artbeat_core:
    path: ../packages/artbeat_core
```

Import the core package:

```dart
import 'package:artbeat_core/artbeat_core.dart';
```

## Key Usage Examples

### Navigation Components

```dart
// Enhanced bottom navigation with badges
EnhancedBottomNav(
  currentIndex: 0,
  onTap: (index) => handleNavigation(index),
  showLabels: true,
)

// Universal header with branding
EnhancedUniversalHeader(
  title: 'ArtBeat',
  showBackButton: true,
)

// Quick navigation FAB
QuickNavigationFAB(
  onPressed: () => navigateToCapture(),
)
```

### Secure Media & Content

```dart
// Secure image loading with validation
SecureNetworkImage(
  imageUrl: 'https://example.com/image.jpg',
  width: 200,
  height: 200,
  placeholder: SkeletonWidgets.imageSkeleton(),
)

// Content engagement bar
ContentEngagementBar(
  likes: 42,
  comments: 8,
  onLike: () => handleLike(),
  onComment: () => showComments(),
)
```

### Payment & Subscriptions

```dart
// Unified payment service (2025 enhanced)
final paymentResult = await UnifiedPaymentService.instance.processPayment(
  amount: 999, // $9.99
  currency: 'USD',
  description: 'Premium Subscription',
);

// Subscription management
final subscription = await SubscriptionService.instance.getCurrentSubscription();
```

### AI & Smart Features

```dart
// AI service integration
final aiResult = await AIService.instance.analyzeArtwork(imageBytes);

// Feature usage tracking
UsageTrackingService.instance.trackFeatureUsage('art_capture');
```

### User Management & Authentication

```dart
// User service with safety measures
final user = await UserService.instance.getCurrentUser();

// Biometric authentication
final authResult = await BiometricAuthService.instance.authenticate(
  reason: 'Authenticate to access premium features',
);
```

## Architecture & Design Patterns

### Service Layer Architecture

- **Unified Services**: Modern service layer replacing legacy implementations
- **Safety First**: Built-in crash prevention and recovery mechanisms
- **Performance Optimized**: Memory management and lazy loading
- **Offline Support**: Comprehensive caching and offline functionality

### State Management

- **Provider Pattern**: Centralized state management with ChangeNotifier
- **View Models**: MVVM architecture for complex screens
- **Repository Pattern**: Data access abstraction layer

### Security & Compliance

- **Secure by Design**: All services include safety measures and validation
- **Privacy Compliant**: GDPR and App Store privacy compliance built-in
- **Payment Security**: PCI-compliant payment processing with Stripe integration

## Dependencies & Requirements

### Environment

- **Flutter**: >=3.35.0
- **Dart SDK**: >=3.8.0 <4.0.0

### Key Dependencies

- **Firebase**: Complete Firebase suite (Auth, Firestore, Storage, Analytics)
- **Payment Processing**: Stripe, In-App Purchases
- **Image Handling**: Cached Network Images, Image optimization
- **Location Services**: Google Maps, Geolocator
- **Security**: JWT, Cryptography, Biometric authentication

## Development Status

### ✅ Fully Implemented

- Core UI component library
- Payment and subscription systems
- User authentication and management
- Image and media handling
- Firebase integration
- AI service integration
- Analytics and tracking

### 🚧 In Development

- Advanced AI features expansion
- Enhanced offline capabilities
- Performance optimization features

### ⚠️ Testing Status

**Note**: Test suite is currently being rebuilt to match the comprehensive service architecture. Previous test count references are outdated.

## Package Structure

```
lib/
├── artbeat_core.dart          # Main export file
├── firebase_options.dart      # Firebase configuration
├── widgets.dart              # Widget exports
├── bin/main.dart            # CLI entry point
├── services/
│   └── user_service.dart    # Legacy user service export
└── src/
    ├── controllers/         # Business logic controllers
    ├── data/               # Data layer components
    ├── examples/           # Integration examples
    ├── firebase/           # Firebase configuration
    ├── interfaces/         # Abstract interfaces
    ├── models/             # Data models and types
    ├── providers/          # State management providers
    ├── repositories/       # Data access layer
    ├── screens/           # Screen implementations
    ├── services/          # Service layer (50+ services)
    ├── storage/           # Storage abstractions
    ├── theme/             # UI theming and styling
    ├── utils/             # Utility functions
    ├── view_models/       # MVVM view models
    └── widgets/           # UI component library
```

## Integration with ArtBeat Ecosystem

ArtBeat Core serves as the foundation for other packages:

- **artbeat_auth**: Authentication and user management
- **artbeat_community**: Social features and community
- **artbeat_settings**: Application settings and preferences
- **artbeat_art_walk**: Location-based art discovery
- **artbeat_events**: Event management and calendar

## Migration Notes

### Legacy Service Deprecations (2025)

- `PaymentService` → Use `UnifiedPaymentService`
- `EnhancedPaymentService` → Use `UnifiedPaymentService`
- Basic achievement widgets → Use achievement system from `artbeat_art_walk`

### Breaking Changes

- Enhanced safety measures require updated error handling
- Some screen interfaces have been updated for consistency
- Firebase configuration now uses secure patterns

## Contributing

When adding new features to ArtBeat Core:

1. **Services**: Add to `src/services/` and export in `artbeat_core.dart`
2. **Widgets**: Add to `src/widgets/` and include in widget exports
3. **Models**: Add to `src/models/` and include in model index
4. **Screens**: Add to `src/screens/` for shared screen implementations

Ensure all new services include:

- Proper error handling and crash prevention
- Logging integration with `AppLogger`
- Performance monitoring where appropriate
- Offline support if applicable

## License

Part of the ArtBeat application ecosystem.
Copyright © 2025 ArtBeat. All rights reserved.

- **2025 Optimization Implementation** (32 tests): Subscription tiers, feature limits, overage pricing, usage tracking
- **AuthService** (11 tests): Authentication state management, user operations, token handling
- **AI Features Service** (4 tests): Feature availability and credit cost calculations
- **UserModel** (14 tests): Model operations, JSON serialization, user type validation
- **Widget Tests** (8 tests): UniversalContentCard and EnhancedBottomNav functionality

**Test Coverage**: Comprehensive coverage of all major components including business logic, data models, and UI widgets.

## Dependencies

- Flutter SDK
- Firebase services (Auth, Firestore, Storage)
- Provider for state management
- Various utility packages

## Architecture

The core package follows clean architecture principles:

- **Models**: Data structures and entities
- **Services**: Business logic and external integrations
- **Providers**: State management
- **Widgets**: UI components
- **Screens**: Complete screen implementations

This package serves as the foundation for all other ArtBeat packages and should maintain backward compatibility.
