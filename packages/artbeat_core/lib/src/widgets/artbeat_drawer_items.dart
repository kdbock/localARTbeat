import 'package:flutter/material.dart';
import '../routing/app_routes.dart';
import '../theme/artbeat_colors.dart';

// Define drawer section structure
class DrawerSection {
  final String? title;
  final List<ArtbeatDrawerItem> items;
  final bool showDivider;

  const DrawerSection({
    this.title,
    required this.items,
    this.showDivider = false,
  });
}

class ArtbeatDrawerItem {
  final String title;
  final IconData icon;
  final String route;
  final Color? color;
  final bool requiresAuth;
  final List<String>? requiredRoles; // null means available to all users
  final bool supportsBadge; // Whether this item can show a badge count

  const ArtbeatDrawerItem({
    required this.title,
    required this.icon,
    required this.route,
    this.color,
    this.requiresAuth = true,
    this.requiredRoles,
    this.supportsBadge = false,
  });
}

class ArtbeatDrawerItems {
  // Core Navigation Items (Always Visible)
  static const dashboard = ArtbeatDrawerItem(
    title: 'drawer_dashboard',
    icon: Icons.dashboard_outlined,
    route: AppRoutes.dashboard,
  );

  static const browse = ArtbeatDrawerItem(
    title: 'drawer_browse',
    icon: Icons.search_outlined,
    route: AppRoutes.browse,
  );

  static const community = ArtbeatDrawerItem(
    title: 'drawer_community',
    icon: Icons.groups_outlined,
    route: AppRoutes.communityFeed,
  );

  static const events = ArtbeatDrawerItem(
    title: 'drawer_events',
    icon: Icons.event_outlined,
    route: AppRoutes.eventsDiscover,
  );

  static const artWalk = ArtbeatDrawerItem(
    title: 'drawer_art_walk',
    icon: Icons.map_outlined,
    route: AppRoutes.artWalkDashboard,
  );

  static const messaging = ArtbeatDrawerItem(
    title: 'drawer_messages',
    icon: Icons.message_outlined,
    route: AppRoutes.messaging,
    requiresAuth: true,
    supportsBadge: true,
  );

  static const advertise = ArtbeatDrawerItem(
    title: 'drawer_sponsorships',
    icon: Icons.campaign,
    route: AppRoutes.communitySponsorships,
    color: ArtbeatColors.primaryGreen,
  );

  static const capture = ArtbeatDrawerItem(
    title: 'drawer_capture',
    icon: Icons.camera_alt_outlined,
    route: AppRoutes.captureCamera,
  );

  static const radar = ArtbeatDrawerItem(
    title: 'drawer_radar',
    icon: Icons.radar_outlined,
    route: AppRoutes.instantDiscovery,
  );

  static const map = ArtbeatDrawerItem(
    title: 'drawer_map',
    icon: Icons.map_outlined,
    route: AppRoutes.artWalkMap,
  );

  static const feed = ArtbeatDrawerItem(
    title: 'drawer_feed',
    icon: Icons.dynamic_feed_outlined,
    route: AppRoutes.communityFeed,
  );

  static const rankings = ArtbeatDrawerItem(
    title: 'drawer_rankings',
    icon: Icons.emoji_events_outlined,
    route: AppRoutes.leaderboard,
  );

  static const myCaptures = ArtbeatDrawerItem(
    title: 'drawer_my_captures',
    icon: Icons.photo_library_outlined,
    route: AppRoutes.captureMyCaptures,
  );

  // Role-specific creation items
  static const createPost = ArtbeatDrawerItem(
    title: 'artist_artist_dashboard_text_add_post',
    icon: Icons.post_add_outlined,
    route: AppRoutes.artCommunityHub,
    requiredRoles: ['artist', 'admin', 'moderator'],
  );

  static const createEvent = ArtbeatDrawerItem(
    title: 'drawer_create_event',
    icon: Icons.add_circle_outline,
    route: AppRoutes.eventsCreate,
    requiredRoles: ['artist', 'admin', 'gallery'],
  );

  static const createArtWalk = ArtbeatDrawerItem(
    title: 'drawer_create_art_walk',
    icon: Icons.add_location_outlined,
    route: AppRoutes.artWalkDashboard,
  );

  // Quest & Goals items
  static const dailyQuests = ArtbeatDrawerItem(
    title: 'drawer_daily_quests',
    icon: Icons.assignment_outlined,
    route: '/quest-history',
    color: ArtbeatColors.primaryGreen,
  );

  static const weeklyGoals = ArtbeatDrawerItem(
    title: 'drawer_weekly_goals',
    icon: Icons.flag_outlined,
    route: '/weekly-goals',
    color: ArtbeatColors.primaryBlue,
  );

  // Role-Specific Items

  // Artist-specific items
  static const artistDashboard = ArtbeatDrawerItem(
    title: 'drawer_artist_dashboard',
    icon: Icons.palette_outlined,
    route: AppRoutes.artistDashboard,
    requiredRoles: ['artist'],
  );

  static const myArtwork = ArtbeatDrawerItem(
    title: 'drawer_my_artwork',
    icon: Icons.image_outlined,
    route: AppRoutes.artistArtwork,
    requiredRoles: ['artist'],
  );

  static const uploadArtwork = ArtbeatDrawerItem(
    title: 'drawer_upload_artwork',
    icon: Icons.add_photo_alternate_outlined,
    route: AppRoutes.artworkUpload,
    requiredRoles: ['artist'],
  );

  static const artistAnalytics = ArtbeatDrawerItem(
    title: 'drawer_analytics',
    icon: Icons.analytics_outlined,
    route: AppRoutes.artistAnalytics,
    requiredRoles: ['artist'],
  );

  static const artistEarnings = ArtbeatDrawerItem(
    title: 'drawer_earnings',
    icon: Icons.account_balance_wallet_outlined,
    route: AppRoutes.artistEarnings,
    requiredRoles: ['artist'],
  );

  static const adPerformance = ArtbeatDrawerItem(
    title: 'drawer_ad_performance',
    icon: Icons.analytics_outlined,
    route: '/ads/statistics',
    color: ArtbeatColors.primaryGreen,
  );

  static const artistEvents = ArtbeatDrawerItem(
    title: 'drawer_my_events',
    icon: Icons.event_note_outlined,
    route: AppRoutes.eventsMyEvents,
    requiredRoles: ['artist'],
  );

  static const artistProfileEdit = ArtbeatDrawerItem(
    title: 'drawer_edit_profile',
    icon: Icons.edit_outlined,
    route: AppRoutes.artistProfileEdit,
    requiredRoles: ['artist'],
  );

  static const artistPublicProfile = ArtbeatDrawerItem(
    title: 'drawer_public_profile',
    icon: Icons.person_outline,
    route: AppRoutes.artistPublicProfile,
    requiredRoles: ['artist'],
  );

  static const artistBrowse = ArtbeatDrawerItem(
    title: 'drawer_browse_artists',
    icon: Icons.people_outline,
    route: AppRoutes.artistBrowse,
    requiredRoles: ['artist'],
  );

  static const featuredArtists = ArtbeatDrawerItem(
    title: 'drawer_featured_artists',
    icon: Icons.star_outline,
    route: AppRoutes.artistFeatured,
    requiredRoles: ['artist'],
  );

  static const payoutRequest = ArtbeatDrawerItem(
    title: 'drawer_payout_request',
    icon: Icons.request_quote_outlined,
    route: AppRoutes.artistPayoutRequest,
    requiredRoles: ['artist'],
  );

  static const payoutAccounts = ArtbeatDrawerItem(
    title: 'drawer_payout_accounts',
    icon: Icons.account_balance_outlined,
    route: AppRoutes.artistPayoutAccounts,
    requiredRoles: ['artist'],
  );

  // Gallery-specific items
  static const galleryDashboard = ArtbeatDrawerItem(
    title: 'drawer_gallery_dashboard',
    icon: Icons.business_outlined,
    route: AppRoutes.galleryArtistsManagement,
    requiredRoles: ['gallery'],
  );

  static const manageArtists = ArtbeatDrawerItem(
    title: 'drawer_manage_artists',
    icon: Icons.manage_accounts_outlined,
    route: AppRoutes.galleryArtistsManagement,
    requiredRoles: ['gallery'],
  );

  static const galleryAnalytics = ArtbeatDrawerItem(
    title: 'drawer_gallery_analytics',
    icon: Icons.bar_chart_outlined,
    route: AppRoutes.galleryAnalytics,
    requiredRoles: ['gallery'],
  );

  // Admin-specific items - Streamlined to unified dashboard
  static const unifiedAdminDashboard = ArtbeatDrawerItem(
    title: 'drawer_admin_dashboard',
    icon: Icons.admin_panel_settings,
    route: AppRoutes.adminDashboard,
    requiredRoles: ['admin'],
    color: ArtbeatColors.primaryPurple,
  );

  static const adminSettings = ArtbeatDrawerItem(
    title: 'drawer_admin_settings',
    icon: Icons.settings_outlined,
    route: AppRoutes.adminSettings,
    requiredRoles: ['admin'],
    color: ArtbeatColors.primaryPurple,
  );

  // Moderator-specific items
  static const moderatorDashboard = ArtbeatDrawerItem(
    title: 'drawer_moderation_dashboard',
    icon: Icons.security_outlined,
    route: AppRoutes.adminDashboard, // Redirects to unified admin dashboard
    requiredRoles: ['moderator'],
    color: ArtbeatColors.warning,
  );

  // User-specific items
  static const editProfile = ArtbeatDrawerItem(
    title: 'drawer_edit_profile',
    icon: Icons.edit_outlined,
    route: AppRoutes.profileEdit,
  );

  static const achievements = ArtbeatDrawerItem(
    title: 'drawer_achievements',
    icon: Icons.emoji_events_outlined,
    route: AppRoutes.achievements,
  );

  static const favorites = ArtbeatDrawerItem(
    title: 'drawer_favorites',
    icon: Icons.favorite_outline,
    route: AppRoutes.favorites,
  );

  static const myTickets = ArtbeatDrawerItem(
    title: 'drawer_create_event',
    icon: Icons.add_circle_outline,
    route: AppRoutes.eventsCreate,
    requiredRoles: ['artist', 'admin', 'gallery'],
  );

  static const notifications = ArtbeatDrawerItem(
    title: 'drawer_notifications',
    icon: Icons.notifications_outlined,
    route: AppRoutes.notifications,
  );

  // Enhanced feature items
  static const artWalkCreate = ArtbeatDrawerItem(
    title: 'drawer_create_art_walk',
    icon: Icons.add_location_outlined,
    route: AppRoutes.artWalkDashboard,
  );

  static const enhancedSearch = ArtbeatDrawerItem(
    title: 'drawer_advanced_search',
    icon: Icons.search,
    route: AppRoutes.search,
  );

  static const subscriptionPlans = ArtbeatDrawerItem(
    title: 'drawer_subscription_plans',
    icon: Icons.card_membership_outlined,
    route: AppRoutes.subscriptionPlans,
    requiredRoles: ['artist', 'gallery'],
  );

  static const paymentMethods = ArtbeatDrawerItem(
    title: 'drawer_payment_methods',
    icon: Icons.payment_outlined,
    route: AppRoutes.paymentMethods,
    requiredRoles: ['artist', 'gallery'],
  );

  static const paymentScreen = ArtbeatDrawerItem(
    title: 'drawer_payment_screen',
    icon: Icons.payment,
    route: AppRoutes.paymentScreen,
    requiredRoles: ['artist'],
  );

  static const refundRequest = ArtbeatDrawerItem(
    title: 'drawer_refund_request',
    icon: Icons.undo_outlined,
    route: AppRoutes.paymentRefund,
    requiredRoles: ['artist'],
  );

  // Advertising items for artists and galleries
  static const createAd = ArtbeatDrawerItem(
    title: 'drawer_create_ad',
    icon: Icons.campaign_outlined,
    route: '/ads/create',
    color: ArtbeatColors.primaryGreen,
    requiredRoles: ['artist', 'gallery'],
  );

  static const manageMyAds = ArtbeatDrawerItem(
    title: 'drawer_my_ads',
    icon: Icons.ads_click_outlined,
    route: '/ads/management',
    requiredRoles: ['artist', 'gallery'],
  );

  static const myAdStatistics = ArtbeatDrawerItem(
    title: 'drawer_ad_performance',
    icon: Icons.analytics_outlined,
    route: '/ads/statistics',
    color: ArtbeatColors.primaryGreen,
    requiredRoles: ['artist', 'gallery'],
  );

  static const approvedAds = ArtbeatDrawerItem(
    title: 'drawer_approved_ads',
    icon: Icons.verified_outlined,
    route: '/artist/approved-ads',
    requiredRoles: ['artist'],
  );

  // Admin advertising items
  static const manageAds = ArtbeatDrawerItem(
    title: 'drawer_manage_ads',
    icon: Icons.ads_click_outlined,
    route: '/ads/management',
    requiredRoles: ['admin'],
    color: ArtbeatColors.primaryPurple,
  );

  static const adStatistics = ArtbeatDrawerItem(
    title: 'drawer_ad_statistics',
    icon: Icons.analytics_outlined,
    route: '/ads/statistics',
    requiredRoles: ['admin'],
    color: ArtbeatColors.primaryPurple,
  );

  static const captureModeration = ArtbeatDrawerItem(
    title: 'drawer_capture_moderation',
    icon: Icons.photo_library_outlined,
    route: AppRoutes.captureAdminModeration,
    requiredRoles: ['admin'],
    color: ArtbeatColors.primaryPurple,
  );

  static const artWalkModeration = ArtbeatDrawerItem(
    title: 'drawer_art_walk_moderation',
    icon: Icons.route_outlined,
    route: AppRoutes.artWalkAdminModeration,
    requiredRoles: ['admin'],
    color: ArtbeatColors.primaryPurple,
  );

  // Settings items
  static const settings = ArtbeatDrawerItem(
    title: 'drawer_settings',
    icon: Icons.settings_outlined,
    route: AppRoutes.settings,
  );

  static const help = ArtbeatDrawerItem(
    title: 'drawer_help_support',
    icon: Icons.help_outline,
    route: AppRoutes.support,
  );

  // Sign out
  static const signOut = ArtbeatDrawerItem(
    title: 'drawer_sign_out',
    icon: Icons.logout,
    route: AppRoutes.login,
    color: ArtbeatColors.error,
    requiresAuth: false,
  );

  static const platformCuration = ArtbeatDrawerItem(
    title: 'drawer_platform_curation',
    icon: Icons.auto_awesome,
    route: '/admin/curation',
    requiredRoles: ['admin'],
    color: ArtbeatColors.primaryPurple,
  );

  static const securityCenter = ArtbeatDrawerItem(
    title: 'drawer_security_center',
    icon: Icons.security,
    route: '/admin/security',
    requiredRoles: ['admin'],
    color: ArtbeatColors.primaryPurple,
  );

  static const systemHealth = ArtbeatDrawerItem(
    title: 'drawer_system_health',
    icon: Icons.health_and_safety,
    route: '/admin/monitoring',
    requiredRoles: ['admin'],
    color: ArtbeatColors.primaryPurple,
  );

  static const paymentManagement = ArtbeatDrawerItem(
    title: 'drawer_payment_management',
    icon: Icons.payments_outlined,
    route: '/admin/payments',
    requiredRoles: ['admin'],
    color: ArtbeatColors.primaryPurple,
  );

  static List<ArtbeatDrawerItem> get coreItems => [
    dashboard,
    capture,
    radar,
    map,
    feed,
    rankings,
    events,
    advertise,
  ];

  static List<ArtbeatDrawerItem> get creationItems => [myCaptures, advertise];

  static List<ArtbeatDrawerItem> get questsAndGoals => [
    dailyQuests,
    weeklyGoals,
  ];

  static List<ArtbeatDrawerItem> get personalItems => [
    notifications,
    favorites,
    myCaptures,
  ];

  static List<ArtbeatDrawerItem> get artistItems => [];

  static List<ArtbeatDrawerItem> get galleryItems => [];

  static List<ArtbeatDrawerItem> get adminItems => [];

  static List<ArtbeatDrawerItem> get moderatorItems => [];

  static List<ArtbeatDrawerItem> get settingsItems => [settings, help, signOut];

  static List<ArtbeatDrawerItem> _filterItemsForRole(
    List<ArtbeatDrawerItem> items,
    String? userRole,
  ) {
    return items.where((item) {
      final requiredRoles = item.requiredRoles;
      if (requiredRoles == null || requiredRoles.isEmpty) {
        return true;
      }
      if (userRole == null) return false;
      return requiredRoles.contains(userRole);
    }).toList();
  }

  // Helper method to get sections for a specific user role
  static List<DrawerSection> getSectionsForRole(
    String? userRole, {
    bool simpleMode = false,
    bool exploreMoreOpened = false,
  }) {
    final List<DrawerSection> sections = [];

    // 1. Core Navigation (Always Visible)
    final navigationItems = _filterItemsForRole(coreItems, userRole);
    if (simpleMode && !exploreMoreOpened) {
      navigationItems.removeWhere(
        (item) => !{
          dashboard.route,
          capture.route,
          radar.route,
          map.route,
          feed.route,
          rankings.route,
          events.route,
          advertise.route,
        }.contains(item.route),
      );
    }
    if (navigationItems.isNotEmpty) {
      sections.add(
        DrawerSection(
          title: 'drawer_section_navigation',
          items: navigationItems,
        ),
      );
    }

    // 2. Local ARTbeat actions
    if (!simpleMode || exploreMoreOpened) {
      final creationTools = _filterItemsForRole(creationItems, userRole);
      if (creationTools.isNotEmpty) {
        sections.add(
          DrawerSection(
            title: 'drawer_section_local_artbeat',
            items: creationTools,
          ),
        );
      }
    }

    // 6. Personal & Social Features
    final personal = _filterItemsForRole(personalItems, userRole);
    if ((!simpleMode || exploreMoreOpened) && personal.isNotEmpty) {
      sections.add(
        DrawerSection(title: 'drawer_section_personal', items: personal),
      );
    }

    // 7. Settings & Support
    final settingsAndSupport = _filterItemsForRole(settingsItems, userRole);
    if (settingsAndSupport.isNotEmpty) {
      sections.add(
        DrawerSection(
          title: 'drawer_settings',
          items: settingsAndSupport,
          showDivider: true,
        ),
      );
    }

    return sections;
  }

  // Helper method to get items for a specific user role (legacy method for backward compatibility)
  static List<ArtbeatDrawerItem> getItemsForRole(String? userRole) {
    final sections = getSectionsForRole(userRole);
    return sections.expand((section) => section.items).toList();
  }
}
