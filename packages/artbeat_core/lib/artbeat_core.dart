// artbeat_core entry point

/// ARTbeat Core package with shared functionality
library artbeat_core;

// Export Firebase configuration
export 'src/firebase/secure_firebase_config.dart';

// Export Theme
export 'src/theme/artbeat_colors.dart' show ArtbeatColors;
export 'src/theme/artbeat_components.dart' show ArtbeatComponents;
export 'src/theme/artbeat_theme.dart' show ArtbeatTheme;
export 'src/theme/artbeat_typography.dart' show ArtbeatTypography;

// Export Models
// Note: AchievementModel is now provided by artbeat_art_walk package

// Export Core Services
export 'src/services/config_service.dart' show ConfigService;
export 'src/services/user_service.dart' show UserService;
export 'src/services/connectivity_service.dart' show ConnectivityService;
export 'src/services/subscription_service.dart' show SubscriptionService;
export 'src/services/artist_service.dart' show ArtistService;
export 'src/services/artist_feature_service.dart' show ArtistFeatureService;
export 'src/services/unified_payment_service.dart'
    show
        UnifiedPaymentService,
        PaymentResult,
        SubscriptionResult,
        RiskAssessment,
        PaymentMethodWithRisk,
        ArtbeatModule,
        RevenueStream;
export 'src/services/crash_prevention_service.dart' show CrashPreventionService;
// Legacy compatibility exports (deprecated - use UnifiedPaymentService instead)
export 'src/services/payment_service.dart' show PaymentService;
export 'src/services/enhanced_payment_service_working.dart'
    show EnhancedPaymentService;
// Deprecated: GiftPurchaseScreen removed (legacy basic screen, use EnhancedGiftPurchaseScreen)
export 'src/services/in_app_purchase_manager.dart'
    show InAppPurchaseManager, PurchaseEvent, PurchaseEventType;
export 'src/services/in_app_purchase_setup.dart' show InAppPurchaseSetup;
export 'src/models/in_app_purchase_models.dart' show CompletedPurchase;
export 'src/services/in_app_ad_service.dart' show InAppAdService;
export 'src/services/notification_service.dart'
    show NotificationService, NotificationType;
export 'src/services/feedback_service.dart' show FeedbackService;
export 'src/services/maps_diagnostic_service.dart' show MapsDiagnosticService;
export 'src/services/image_management_service.dart' show ImageManagementService;
export 'src/services/leaderboard_service.dart'
    show LeaderboardService, LeaderboardCategory, LeaderboardEntry;
export 'src/services/enhanced_storage_service.dart' show EnhancedStorageService;
export 'src/services/firebase_storage_auth_service.dart'
    show FirebaseStorageAuthService;
export 'src/services/coupon_service.dart' show CouponService;
export 'src/services/stripe_payment_service.dart' show StripePaymentService;
export 'src/services/capture_service_interface.dart'
    show CaptureServiceInterface, DefaultCaptureService;
// CRITICAL: Crash prevention services (2025 stability fixes)
export 'src/services/stripe_safety_service.dart'
    show StripeSafetyService, PaymentSheetResult;
export 'src/services/auth_safety_service.dart' show AuthSafetyService;
export 'src/services/crash_recovery_service.dart'
    show CrashRecoveryService, CrashRecoveryConfig;
export 'src/services/enhanced_share_service.dart' show EnhancedShareService;
export 'src/services/offline_caching_service.dart' show OfflineCachingService;
export 'src/screens/order_review_screen.dart';
export 'src/utils/order_review_helpers.dart';
// 2025 Enhanced Services
export 'src/services/ai_service.dart' show AIService;
export 'src/services/ai_features_service.dart'
    show AIFeaturesService, AIResult, AIFeatureAccess;
export 'src/services/usage_tracking_service.dart' show UsageTrackingService;
export 'src/services/subscription_migration_service.dart'
    show SubscriptionMigrationService;
export 'src/services/artist_feature_testing_service.dart'
    show ArtistFeatureTestingService, TestResult;

export 'src/services/content_engagement_service.dart'
    show ContentEngagementService;
export 'src/services/engagement_config_service.dart'
    show EngagementConfigService;
export 'src/services/accessibility_service.dart'
    show AccessibilityService, AccessibleNavItem, AccessibilityMixin;
export 'src/mixins/user_moderation_mixin.dart' show UserModerationMixin;
export 'src/services/performance_optimization_service.dart'
    show
        PerformanceOptimizationService,
        PerformanceSummary,
        MemoryInfo,
        LazyLoadController;
export 'src/services/internationalization_service.dart'
    show
        InternationalizationService,
        I18nText,
        InternationalizationMixin,
        DateFormat,
        NumberFormat;

// Export Search Components
export 'src/controllers/search_controller.dart'
    show SearchController, SearchStatus;
export 'src/repositories/known_entity_repository.dart'
    show KnownEntityRepository;

// Export Screens
export 'src/screens/leaderboard_screen.dart' show LeaderboardScreen;
export 'src/screens/help_support_screen.dart' show HelpSupportScreen;
export 'src/screens/subscriptions/subscriptions_screen.dart'
    show SubscriptionsScreen;
export 'src/screens/gifts/gifts_screen.dart' show GiftsScreen;
export 'src/screens/ads/ads_screen.dart' show AdsScreen;

// Export Core Models
export 'src/models/index.dart'; // This will export all models through the barrel file
export 'src/models/types/index.dart'; // Export all type definitions
export 'src/models/known_entity_model.dart'
    show KnownEntity, KnownEntityType, KnownEntityTypeExtension;
export 'src/models/event_model.dart' show EventModel;
export 'src/models/capture_model.dart'
    show CaptureModel, CaptureStatus, CaptureStatusExtension;
export 'src/models/user_type.dart' show UserType;
export 'src/models/subscription_tier.dart' show SubscriptionTier;
export 'src/models/payment_method_model.dart' show PaymentMethodModel;
export 'src/models/feedback_model.dart'
    show FeedbackModel, FeedbackType, FeedbackPriority, FeedbackStatus;
export 'src/models/engagement_model.dart'
    show EngagementStats, EngagementType, EngagementModel;
export 'src/models/coupon_model.dart'
    show CouponModel, CouponType, CouponStatus;
// 2025 Enhanced Models
export 'src/models/feature_limits.dart' show FeatureLimits;

// Export Core Widgets
export 'src/widgets/artbeat_button.dart';
export 'src/widgets/artbeat_input.dart';
export 'src/widgets/login_prompt_dialog.dart';

export 'src/widgets/artbeat_drawer.dart';
export 'src/widgets/artbeat_drawer_items.dart';
export 'src/widgets/art_capture_warning_dialog.dart';
export 'src/widgets/loading_screen.dart';

export 'src/widgets/content_engagement_bar.dart' show ContentEngagementBar;
export 'src/widgets/universal_content_card.dart' show UniversalContentCard;
export 'src/widgets/profile_tab_interface.dart';
export 'src/widgets/featured_content_row_widget.dart';
export 'src/widgets/network_error_widget.dart';
export 'src/widgets/main_layout.dart';
export 'src/widgets/enhanced_universal_header.dart';
export 'src/widgets/enhanced_profile_menu.dart';
export 'src/widgets/enhanced_bottom_nav.dart';
export 'src/widgets/artbeat_gradient_background.dart';
export 'src/widgets/skeleton_widgets.dart';
export 'src/widgets/secure_network_image.dart' show SecureNetworkImage;
export 'src/widgets/artist_cta_widget.dart'
    show ArtistCTAWidget, CompactArtistCTAWidget;
// 2025 Enhanced Widgets
export 'src/widgets/usage_limits_widget.dart' show UsageLimitsWidget;

export 'src/widgets/user_avatar.dart';
export 'src/widgets/optimized_image.dart';
export 'src/widgets/feedback_form.dart';
export 'src/widgets/developer_feedback_admin_screen.dart';
export 'src/widgets/feedback_system_info_screen.dart';
export 'src/widgets/developer_menu.dart';

// Export Core Widget Utils
export 'src/widgets/filter/index.dart';

// Export Core Utils
export 'src/utils/color_extensions.dart';
export 'src/utils/connectivity_utils.dart';
export 'src/utils/date_utils.dart';
export 'src/utils/validators.dart';
export 'src/utils/user_sync_helper.dart';
export 'src/utils/location_utils.dart' show LocationUtils;
export 'src/utils/image_utils.dart' show ImageUtils;
export 'src/utils/permission_utils.dart' show PermissionUtils;
export 'src/utils/performance_monitor.dart' show PerformanceMonitor;
export 'src/utils/auth_helper.dart' show AuthHelper;
export 'src/utils/env_loader.dart' show EnvLoader;
export 'src/utils/logger.dart' show AppLogger, LoggerExtension, LoggingMixin;
export 'src/utils/image_url_validator.dart' show ImageUrlValidator;
export 'src/utils/distance_utils.dart' show DistanceUtils;

// Export Screens
export 'src/screens/splash_screen.dart' show SplashScreen;
export 'src/screens/dashboard/artbeat_dashboard_screen.dart'
    show ArtbeatDashboardScreen;
// Deprecated: Use SearchResultsPage instead
// export 'src/screens/search_results_screen.dart' show SearchResultsScreen;
export 'src/screens/search_results_page.dart' show SearchResultsPage;
export 'src/screens/auth_required_screen.dart' show AuthRequiredScreen;
export 'src/screens/system_settings_screen.dart' show SystemSettingsScreen;
export 'src/screens/subscription_purchase_screen.dart'
    show SubscriptionPurchaseScreen;
export 'src/screens/subscription_plans_screen.dart'
    show SubscriptionPlansScreen;
export 'src/screens/simple_subscription_plans_screen.dart'
    show SimpleSubscriptionPlansScreen;
export 'src/screens/coupon_management_screen.dart' show CouponManagementScreen;
export 'src/screens/advanced_analytics_dashboard.dart'
    show AdvancedAnalyticsDashboard;
export 'src/screens/full_browse_screen.dart' show FullBrowseScreen;

// Export ViewModels
export 'src/viewmodels/dashboard_view_model.dart' show DashboardViewModel;

// Export Providers
export 'src/providers/messaging_provider.dart' show MessagingProvider;
export 'src/providers/community_provider.dart' show CommunityProvider;

// Export Dashboard Widgets
export 'src/widgets/dashboard/index.dart';

// Export Widgets
export 'src/widgets/enhanced_navigation_menu.dart' show EnhancedNavigationMenu;
export 'src/widgets/quick_navigation_fab.dart'
    show QuickNavigationFAB, EnhancedAppBar;

// Export In-App Purchase Widgets
export 'src/widgets/widgets.dart';

// Export Artbeat Store Screen
export 'src/screens/artbeat_store.dart' show ArtbeatStoreScreen;
