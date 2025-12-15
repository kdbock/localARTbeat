import 'package:flutter/material.dart';
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
    route: '/dashboard',
  );

  static const browse = ArtbeatDrawerItem(
    title: 'drawer_browse',
    icon: Icons.search_outlined,
    route: '/browse',
  );

  static const community = ArtbeatDrawerItem(
    title: 'drawer_community',
    icon: Icons.groups_outlined,
    route: '/community/feed',
  );

  static const events = ArtbeatDrawerItem(
    title: 'drawer_events',
    icon: Icons.event_outlined,
    route: '/events/discover',
  );

  static const artWalk = ArtbeatDrawerItem(
    title: 'drawer_art_walk',
    icon: Icons.map_outlined,
    route: '/art-walk/map',
  );

  static const messaging = ArtbeatDrawerItem(
    title: 'drawer_messages',
    icon: Icons.message_outlined,
    route: '/messaging',
    requiresAuth: true,
    supportsBadge: true,
  );

  static const advertise = ArtbeatDrawerItem(
    title: 'drawer_advertise',
    icon: Icons.campaign,
    route: '/ads/create',
    color: ArtbeatColors.primaryGreen,
  );

  // Role-specific creation items
  static const createPost = ArtbeatDrawerItem(
    title: 'drawer_community_hub',
    icon: Icons.groups_outlined,
    route: '/community/hub',
    requiredRoles: ['artist', 'admin', 'gallery'],
  );

  static const createEvent = ArtbeatDrawerItem(
    title: 'drawer_create_event',
    icon: Icons.add_circle_outline,
    route: '/events/create',
    requiredRoles: ['artist', 'admin', 'gallery'],
  );

  static const createArtWalk = ArtbeatDrawerItem(
    title: 'drawer_create_art_walk',
    icon: Icons.add_location_outlined,
    route: '/art-walk/create',
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

  // Commission items
  static const artistCommissions = ArtbeatDrawerItem(
    title: 'drawer_commission_hub',
    icon: Icons.handshake_outlined,
    route: '/commission/hub',
    requiredRoles: ['artist'],
  );

  static const commissionRequests = ArtbeatDrawerItem(
    title: 'drawer_commission_requests',
    icon: Icons.request_quote_outlined,
    route: '/commission/request',
    requiredRoles: ['artist'],
  );

  // Role-Specific Items

  // Artist-specific items
  static const artistDashboard = ArtbeatDrawerItem(
    title: 'drawer_artist_dashboard',
    icon: Icons.palette_outlined,
    route: '/artist/dashboard',
    requiredRoles: ['artist'],
  );

  static const myArtwork = ArtbeatDrawerItem(
    title: 'drawer_my_artwork',
    icon: Icons.image_outlined,
    route: '/artist/artwork',
    requiredRoles: ['artist'],
  );

  static const uploadArtwork = ArtbeatDrawerItem(
    title: 'drawer_upload_artwork',
    icon: Icons.add_photo_alternate_outlined,
    route: '/artwork/upload',
    requiredRoles: ['artist'],
  );

  static const artistAnalytics = ArtbeatDrawerItem(
    title: 'drawer_analytics',
    icon: Icons.analytics_outlined,
    route: '/artist/analytics',
    requiredRoles: ['artist'],
  );

  static const artistEarnings = ArtbeatDrawerItem(
    title: 'drawer_earnings',
    icon: Icons.account_balance_wallet_outlined,
    route: '/artist/earnings',
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
    route: '/events/my-events',
    requiredRoles: ['artist'],
  );

  static const artistProfileEdit = ArtbeatDrawerItem(
    title: 'drawer_edit_profile',
    icon: Icons.edit_outlined,
    route: '/artist/profile-edit',
    requiredRoles: ['artist'],
  );

  static const artistPublicProfile = ArtbeatDrawerItem(
    title: 'drawer_public_profile',
    icon: Icons.person_outline,
    route: '/artist/public-profile',
    requiredRoles: ['artist'],
  );

  static const artistBrowse = ArtbeatDrawerItem(
    title: 'drawer_browse_artists',
    icon: Icons.people_outline,
    route: '/artist/browse',
    requiredRoles: ['artist'],
  );

  static const featuredArtists = ArtbeatDrawerItem(
    title: 'drawer_featured_artists',
    icon: Icons.star_outline,
    route: '/artist/featured',
    requiredRoles: ['artist'],
  );

  static const payoutRequest = ArtbeatDrawerItem(
    title: 'drawer_payout_request',
    icon: Icons.request_quote_outlined,
    route: '/artist/payout-request',
    requiredRoles: ['artist'],
  );

  static const payoutAccounts = ArtbeatDrawerItem(
    title: 'drawer_payout_accounts',
    icon: Icons.account_balance_outlined,
    route: '/artist/payout-accounts',
    requiredRoles: ['artist'],
  );

  // Gallery-specific items
  static const galleryDashboard = ArtbeatDrawerItem(
    title: 'drawer_gallery_dashboard',
    icon: Icons.business_outlined,
    route: '/gallery/artists-management',
    requiredRoles: ['gallery'],
  );

  static const manageArtists = ArtbeatDrawerItem(
    title: 'drawer_manage_artists',
    icon: Icons.manage_accounts_outlined,
    route: '/gallery/artists-management',
    requiredRoles: ['gallery'],
  );

  static const galleryAnalytics = ArtbeatDrawerItem(
    title: 'drawer_gallery_analytics',
    icon: Icons.bar_chart_outlined,
    route: '/gallery/analytics',
    requiredRoles: ['gallery'],
  );

  static const galleryCommissions = ArtbeatDrawerItem(
    title: 'drawer_commissions',
    icon: Icons.handshake_outlined,
    route: '/gallery/commissions',
    requiredRoles: ['gallery'],
  );

  // Admin-specific items - Streamlined to unified dashboard
  static const unifiedAdminDashboard = ArtbeatDrawerItem(
    title: 'drawer_admin_dashboard',
    icon: Icons.admin_panel_settings,
    route: '/admin/dashboard',
    requiredRoles: ['admin'],
    color: ArtbeatColors.primaryPurple,
  );

  static const adminSettings = ArtbeatDrawerItem(
    title: 'drawer_admin_settings',
    icon: Icons.settings_outlined,
    route: '/admin/settings',
    requiredRoles: ['admin'],
    color: ArtbeatColors.primaryPurple,
  );

  // Moderator-specific items
  static const moderatorDashboard = ArtbeatDrawerItem(
    title: 'drawer_moderation_dashboard',
    icon: Icons.security_outlined,
    route: '/admin/dashboard', // Redirects to unified admin dashboard
    requiredRoles: ['moderator'],
    color: ArtbeatColors.warning,
  );

  // User-specific items
  static const editProfile = ArtbeatDrawerItem(
    title: 'drawer_edit_profile',
    icon: Icons.edit_outlined,
    route: '/profile/edit',
  );

  static const achievements = ArtbeatDrawerItem(
    title: 'drawer_achievements',
    icon: Icons.emoji_events_outlined,
    route: '/achievements',
  );

  static const favorites = ArtbeatDrawerItem(
    title: 'drawer_favorites',
    icon: Icons.favorite_outline,
    route: '/favorites',
  );

  static const following = ArtbeatDrawerItem(
    title: 'drawer_following',
    icon: Icons.person_add_outlined,
    route: '/profile/following',
  );

  static const followers = ArtbeatDrawerItem(
    title: 'drawer_followers',
    icon: Icons.people_outlined,
    route: '/profile/followers',
    requiredRoles: ['artist', 'admin', 'gallery'], // Artist POV
  );

  static const myTickets = ArtbeatDrawerItem(
    title: 'drawer_create_event',
    icon: Icons.add_circle_outline,
    route: '/events/create',
    requiredRoles: ['artist', 'admin', 'gallery'],
  );

  static const notifications = ArtbeatDrawerItem(
    title: 'drawer_notifications',
    icon: Icons.notifications_outlined,
    route: '/notifications',
  );

  // Enhanced feature items
  static const artWalkCreate = ArtbeatDrawerItem(
    title: 'drawer_create_art_walk',
    icon: Icons.add_location_outlined,
    route: '/art-walk/create',
  );

  static const enhancedSearch = ArtbeatDrawerItem(
    title: 'drawer_advanced_search',
    icon: Icons.search,
    route: '/search',
  );

  static const subscriptionPlans = ArtbeatDrawerItem(
    title: 'drawer_subscription_plans',
    icon: Icons.card_membership_outlined,
    route: '/subscription/plans',
    requiredRoles: ['artist', 'gallery'],
  );

  static const paymentMethods = ArtbeatDrawerItem(
    title: 'drawer_payment_methods',
    icon: Icons.payment_outlined,
    route: '/payment/methods',
    requiredRoles: ['artist', 'gallery'],
  );

  static const paymentScreen = ArtbeatDrawerItem(
    title: 'drawer_payment_screen',
    icon: Icons.payment,
    route: '/payment/screen',
    requiredRoles: ['artist'],
  );

  static const refundRequest = ArtbeatDrawerItem(
    title: 'drawer_refund_request',
    icon: Icons.undo_outlined,
    route: '/payment/refund',
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
    route: '/capture/admin/moderation',
    requiredRoles: ['admin'],
    color: ArtbeatColors.primaryPurple,
  );

  static const artWalkModeration = ArtbeatDrawerItem(
    title: 'drawer_art_walk_moderation',
    icon: Icons.route_outlined,
    route: '/artwalk/admin/moderation',
    requiredRoles: ['admin'],
    color: ArtbeatColors.primaryPurple,
  );

  // Settings items
  static const settings = ArtbeatDrawerItem(
    title: 'drawer_settings',
    icon: Icons.settings_outlined,
    route: '/settings',
  );

  static const help = ArtbeatDrawerItem(
    title: 'drawer_help_support',
    icon: Icons.help_outline,
    route: '/support',
  );

  // Sign out
  static const signOut = ArtbeatDrawerItem(
    title: 'drawer_sign_out',
    icon: Icons.logout,
    route: '/login',
    color: ArtbeatColors.error,
    requiresAuth: false,
  );

  // Grouped items for different user types
  static const artbeatStore = ArtbeatDrawerItem(
    title: 'drawer_artbeat_store',
    icon: Icons.storefront_outlined,
    route: '/store',
    color: ArtbeatColors.primaryPurple,
    requiresAuth: false,
  );

  static List<ArtbeatDrawerItem> get coreItems => [
    artbeatStore,
    dashboard,
    browse,
    enhancedSearch,
    community,
    events,
    artWalk,
  ];

  static List<ArtbeatDrawerItem> get creationItems => [
    createPost,
    createEvent,
    createArtWalk,
    advertise,
  ];

  static List<ArtbeatDrawerItem> get questsAndGoals => [
    dailyQuests,
    weeklyGoals,
  ];

  static List<ArtbeatDrawerItem> get personalItems => [
    notifications,
    achievements,
    favorites,
    following,
    followers,
  ];

  static List<ArtbeatDrawerItem> get artistItems => [
    // Artist Management
    artistDashboard,
    artistAnalytics,
    artistEarnings,
    // Profile & Content
    artistProfileEdit,
    artistPublicProfile,
    uploadArtwork,
    createPost, // Post to feed
    // Artist Discovery
    artistBrowse,
    featuredArtists,
    artistEvents,
    // Commissions & Business
    artistCommissions, // Commission settings
    commissionRequests, // Commission requests
    // Payments & Payouts
    payoutAccounts,
    payoutRequest,
    paymentMethods,
    paymentScreen,
    refundRequest,
    // Advertising
    createAd,
    manageMyAds,
    myAdStatistics,
    approvedAds,
    // Subscriptions
    subscriptionPlans,
  ];

  static List<ArtbeatDrawerItem> get galleryItems => [
    // Gallery Management
    galleryDashboard,
    manageArtists,
    galleryAnalytics,
    galleryCommissions,
    // Advertising
    createAd,
    manageMyAds,
    myAdStatistics,
    // Subscriptions
    subscriptionPlans,
    paymentMethods,
  ];

  static List<ArtbeatDrawerItem> get adminItems => [
    unifiedAdminDashboard,
    adminSettings,
    captureModeration,
    artWalkModeration,
    manageAds,
    adStatistics,
  ];

  static List<ArtbeatDrawerItem> get moderatorItems => [moderatorDashboard];

  static List<ArtbeatDrawerItem> get settingsItems => [settings, help, signOut];

  // Helper method to get sections for a specific user role
  static List<DrawerSection> getSectionsForRole(String? userRole) {
    final List<DrawerSection> sections = [];

    // 1. Core Navigation (Always Visible)
    sections.add(
      DrawerSection(title: 'drawer_section_navigation', items: coreItems),
    );

    // 2. Creation Tools (for artists, galleries, admins)
    final hasCreationRole =
        userRole == 'artist' || userRole == 'gallery' || userRole == 'admin';
    if (hasCreationRole) {
      sections.add(
        DrawerSection(title: 'drawer_section_create', items: creationItems),
      );
    }

    // 3. Messaging (always available for authenticated users)
    sections.add(const DrawerSection(items: [messaging]));

    // 4. Role-Specific Management Tools
    switch (userRole) {
      case 'artist':
        sections.add(
          DrawerSection(title: 'drawer_section_artist', items: artistItems),
        );
        break;
      case 'gallery':
        sections.add(
          DrawerSection(title: 'drawer_section_gallery', items: galleryItems),
        );
        break;
      case 'admin':
        sections.add(
          DrawerSection(title: 'drawer_section_admin', items: adminItems),
        );
        // Removed paymentMethods from admin drawer - admins should use AdminPaymentScreen
        break;
      case 'moderator':
        sections.add(
          DrawerSection(
            title: 'drawer_section_moderation',
            items: moderatorItems,
          ),
        );
        break;
    }

    // 6. Personal & Social Features
    sections.add(
      DrawerSection(title: 'drawer_section_personal', items: personalItems),
    );

    // 7. Settings & Support
    sections.add(
      DrawerSection(
        title: 'drawer_settings',
        items: settingsItems,
        showDivider: true,
      ),
    );

    return sections;
  }

  // Helper method to get items for a specific user role (legacy method for backward compatibility)
  static List<ArtbeatDrawerItem> getItemsForRole(String? userRole) {
    final sections = getSectionsForRole(userRole);
    return sections.expand((section) => section.items).toList();
  }
}
