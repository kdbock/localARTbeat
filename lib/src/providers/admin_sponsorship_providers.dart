import 'package:artbeat_admin/artbeat_admin.dart';
import 'package:artbeat_sponsorships/artbeat_sponsorships.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> createAdminSponsorshipProviders() => [
  Provider<AdminAdModerationService>(
    create: (_) => AdminAdModerationService(),
    lazy: true,
  ),
  Provider<AdminSponsorshipModerationService>(
    create: (_) => AdminSponsorshipModerationService(),
    lazy: true,
  ),
  Provider<AdminDataRightsService>(
    create: (_) => AdminDataRightsService(),
    lazy: true,
  ),
  Provider<AuditTrailService>(create: (_) => AuditTrailService(), lazy: true),
  Provider<RecentActivityService>(
    create: (_) => RecentActivityService(),
    lazy: true,
  ),
  Provider<AdminService>(create: (_) => AdminService(), lazy: true),
  Provider<EnhancedAnalyticsService>(
    create: (_) => EnhancedAnalyticsService(),
    lazy: true,
  ),
  Provider<ConsolidatedAdminService>(
    create: (_) => ConsolidatedAdminService(),
    lazy: true,
  ),
  Provider<ContentReviewService>(
    create: (_) => ContentReviewService(),
    lazy: true,
  ),
  Provider<UnifiedAdminService>(
    create: (_) => UnifiedAdminService(),
    lazy: true,
  ),
  Provider<FinancialService>(create: (_) => FinancialService(), lazy: true),
  Provider<PaymentAuditService>(
    create: (_) => PaymentAuditService(),
    lazy: true,
  ),
  Provider<AdminPayoutService>(create: (_) => AdminPayoutService(), lazy: true),
  Provider<AdminBroadcastService>(
    create: (_) => AdminBroadcastService(),
    lazy: true,
  ),
  Provider<AdminArtworkService>(
    create: (_) => AdminArtworkService(),
    lazy: true,
  ),
  Provider<AdminCaptureModerationService>(
    create: (_) => AdminCaptureModerationService(),
    lazy: true,
  ),
  Provider<AdminCommunityModerationService>(
    create: (_) => AdminCommunityModerationService(),
    lazy: true,
  ),
  Provider<AdminArtWalkModerationService>(
    create: (_) => AdminArtWalkModerationService(),
    lazy: true,
  ),
  Provider<AdminEventModerationService>(
    create: (_) => AdminEventModerationService(),
    lazy: true,
  ),
  Provider<FlaggingQueueService>(
    create: (_) => FlaggingQueueService(),
    lazy: true,
  ),
  Provider<AdminSettingsService>(
    create: (_) => AdminSettingsService(),
    lazy: true,
  ),
  ChangeNotifierProvider<SecurityService>(
    create: (_) => SecurityService(),
    lazy: true,
  ),
  ChangeNotifierProvider<AdminRoleService>(
    create: (_) => AdminRoleService(),
    lazy: true,
  ),
  Provider<AdminPaymentOperationsService>(
    create: (context) => AdminPaymentOperationsService(
      paymentAuditService: context.read<PaymentAuditService>(),
      auditTrailService: context.read<AuditTrailService>(),
      roleService: context.read<AdminRoleService>(),
    ),
    lazy: true,
  ),
  Provider<SponsorshipCheckoutService>(
    create: (_) => SponsorshipCheckoutService(),
    lazy: true,
  ),
  Provider<SponsorshipSubmissionService>(
    create: (_) => SponsorshipSubmissionService(),
    lazy: true,
  ),
];
