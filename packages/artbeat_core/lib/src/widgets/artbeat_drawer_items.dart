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
    title: 'Dashboard',
    icon: Icons.dashboard_outlined,
    route: '/dashboard',
  );

  static const browse = ArtbeatDrawerItem(
    title: 'Browse',
    icon: Icons.search_outlined,
    route: '/browse',
  );

  static const community = ArtbeatDrawerItem(
    title: 'Community',
    icon: Icons.groups_outlined,
    route: '/community/feed',
  );

  static const events = ArtbeatDrawerItem(
    title: 'Events',
    icon: Icons.event_outlined,
    route: '/events/discover',
  );

  static const artWalk = ArtbeatDrawerItem(
    title: 'Art Walk',
    icon: Icons.map_outlined,
    route: '/art-walk/map',
  );

  static const messaging = ArtbeatDrawerItem(
    title: 'Messages',
    icon: Icons.message_outlined,
    route: '/messaging',
    requiresAuth: true,
    supportsBadge: true,
  );

  static const advertise = ArtbeatDrawerItem(
    title: 'Advertise',
    icon: Icons.campaign,
    route: '/ads/create',
    color: ArtbeatColors.primaryGreen,
  );

  // Role-specific creation items
  static const createPost = ArtbeatDrawerItem(
    title: 'Community Hub',
    icon: Icons.groups_outlined,
    route: '/community/hub',
    requiredRoles: ['artist', 'admin', 'gallery'],
  );

  static const createEvent = ArtbeatDrawerItem(
    title: 'Create Event',
    icon: Icons.add_circle_outline,
    route: '/events/create',
    requiredRoles: ['artist', 'admin', 'gallery'],
  );

  static const createArtWalk = ArtbeatDrawerItem(
    title: 'Create Art Walk',
    icon: Icons.add_location_outlined,
    route: '/art-walk/create',
  );

  // Quest & Goals items
  static const dailyQuests = ArtbeatDrawerItem(
    title: 'Daily Quests',
    icon: Icons.assignment_outlined,
    route: '/quest-history',
    color: ArtbeatColors.primaryGreen,
  );

  static const weeklyGoals = ArtbeatDrawerItem(
    title: 'Weekly Goals',
    icon: Icons.flag_outlined,
    route: '/weekly-goals',
    color: ArtbeatColors.primaryBlue,
  );

  // Commission items
  static const artistCommissions = ArtbeatDrawerItem(
    title: 'Commission Hub',
    icon: Icons.handshake_outlined,
    route: '/commission/hub',
    requiredRoles: ['artist'],
  );

  static const commissionRequests = ArtbeatDrawerItem(
    title: 'Commission Requests',
    icon: Icons.request_quote_outlined,
    route: '/commission/request',
    requiredRoles: ['artist'],
  );

  // Role-Specific Items

  // Artist-specific items
  static const artistDashboard = ArtbeatDrawerItem(
    title: 'Artist Dashboard',
    icon: Icons.palette_outlined,
    route: '/artist/dashboard',
    requiredRoles: ['artist'],
  );

  static const myArtwork = ArtbeatDrawerItem(
    title: 'My Artwork',
    icon: Icons.image_outlined,
    route: '/artist/artwork',
    requiredRoles: ['artist'],
  );

  static const uploadArtwork = ArtbeatDrawerItem(
    title: 'Upload Artwork',
    icon: Icons.add_photo_alternate_outlined,
    route: '/artwork/upload',
    requiredRoles: ['artist'],
  );

  static const artistAnalytics = ArtbeatDrawerItem(
    title: 'Analytics',
    icon: Icons.analytics_outlined,
    route: '/artist/analytics',
    requiredRoles: ['artist'],
  );

  static const artistEarnings = ArtbeatDrawerItem(
    title: 'Earnings',
    icon: Icons.account_balance_wallet_outlined,
    route: '/artist/earnings',
    requiredRoles: ['artist'],
  );

  static const adPerformance = ArtbeatDrawerItem(
    title: 'Ad Performance',
    icon: Icons.analytics_outlined,
    route: '/ads/statistics',
    color: ArtbeatColors.primaryGreen,
  );

  static const artistEvents = ArtbeatDrawerItem(
    title: 'My Events',
    icon: Icons.event_note_outlined,
    route: '/events/my-events',
    requiredRoles: ['artist'],
  );

  static const artistProfileEdit = ArtbeatDrawerItem(
    title: 'Edit Profile',
    icon: Icons.edit_outlined,
    route: '/artist/profile-edit',
    requiredRoles: ['artist'],
  );

  static const artistPublicProfile = ArtbeatDrawerItem(
    title: 'Public Profile',
    icon: Icons.person_outline,
    route: '/artist/public-profile',
    requiredRoles: ['artist'],
  );

  static const artistBrowse = ArtbeatDrawerItem(
    title: 'Browse Artists',
    icon: Icons.people_outline,
    route: '/artist/browse',
    requiredRoles: ['artist'],
  );

  static const featuredArtists = ArtbeatDrawerItem(
    title: 'Featured Artists',
    icon: Icons.star_outline,
    route: '/artist/featured',
    requiredRoles: ['artist'],
  );

  static const payoutRequest = ArtbeatDrawerItem(
    title: 'Payout Request',
    icon: Icons.request_quote_outlined,
    route: '/artist/payout-request',
    requiredRoles: ['artist'],
  );

  static const payoutAccounts = ArtbeatDrawerItem(
    title: 'Payout Accounts',
    icon: Icons.account_balance_outlined,
    route: '/artist/payout-accounts',
    requiredRoles: ['artist'],
  );

  // Gallery-specific items
  static const galleryDashboard = ArtbeatDrawerItem(
    title: 'Gallery Dashboard',
    icon: Icons.business_outlined,
    route: '/gallery/artists-management',
    requiredRoles: ['gallery'],
  );

  static const manageArtists = ArtbeatDrawerItem(
    title: 'Manage Artists',
    icon: Icons.manage_accounts_outlined,
    route: '/gallery/artists-management',
    requiredRoles: ['gallery'],
  );

  static const galleryAnalytics = ArtbeatDrawerItem(
    title: 'Gallery Analytics',
    icon: Icons.bar_chart_outlined,
    route: '/gallery/analytics',
    requiredRoles: ['gallery'],
  );

  static const galleryCommissions = ArtbeatDrawerItem(
    title: 'Commissions',
    icon: Icons.handshake_outlined,
    route: '/gallery/commissions',
    requiredRoles: ['gallery'],
  );

  // Admin-specific items - Streamlined to unified dashboard
  static const unifiedAdminDashboard = ArtbeatDrawerItem(
    title: 'Admin Dashboard',
    icon: Icons.admin_panel_settings,
    route: '/admin/dashboard',
    requiredRoles: ['admin'],
    color: ArtbeatColors.primaryPurple,
  );

  static const adminSettings = ArtbeatDrawerItem(
    title: 'Admin Settings',
    icon: Icons.settings_outlined,
    route: '/admin/settings',
    requiredRoles: ['admin'],
    color: ArtbeatColors.primaryPurple,
  );

  // Moderator-specific items
  static const moderatorDashboard = ArtbeatDrawerItem(
    title: 'Moderation Dashboard',
    icon: Icons.security_outlined,
    route: '/admin/dashboard', // Redirects to unified admin dashboard
    requiredRoles: ['moderator'],
    color: ArtbeatColors.warning,
  );

  // User-specific items
  static const editProfile = ArtbeatDrawerItem(
    title: 'Edit Profile',
    icon: Icons.edit_outlined,
    route: '/profile/edit',
  );

  static const achievements = ArtbeatDrawerItem(
    title: 'Achievements',
    icon: Icons.emoji_events_outlined,
    route: '/achievements',
  );

  static const favorites = ArtbeatDrawerItem(
    title: 'Favorites',
    icon: Icons.favorite_outline,
    route: '/favorites',
  );

  static const following = ArtbeatDrawerItem(
    title: 'Following',
    icon: Icons.person_add_outlined,
    route: '/profile/following',
  );

  static const followers = ArtbeatDrawerItem(
    title: 'Followers',
    icon: Icons.people_outlined,
    route: '/profile/followers',
    requiredRoles: ['artist', 'admin', 'gallery'], // Artist POV
  );

  static const myTickets = ArtbeatDrawerItem(
    title: 'Create Event',
    icon: Icons.add_circle_outline,
    route: '/events/create',
    requiredRoles: ['artist', 'admin', 'gallery'],
  );

  static const notifications = ArtbeatDrawerItem(
    title: 'Notifications',
    icon: Icons.notifications_outlined,
    route: '/notifications',
  );

  // Enhanced feature items
  static const artWalkCreate = ArtbeatDrawerItem(
    title: 'Create Art Walk',
    icon: Icons.add_location_outlined,
    route: '/art-walk/create',
  );

  static const enhancedSearch = ArtbeatDrawerItem(
    title: 'Advanced Search',
    icon: Icons.search,
    route: '/search',
  );

  static const subscriptionPlans = ArtbeatDrawerItem(
    title: 'Subscription Plans',
    icon: Icons.card_membership_outlined,
    route: '/subscription/plans',
    requiredRoles: ['artist', 'gallery'],
  );

  static const paymentMethods = ArtbeatDrawerItem(
    title: 'Payment Methods',
    icon: Icons.payment_outlined,
    route: '/payment/methods',
    requiredRoles: ['artist', 'gallery'],
  );

  static const paymentScreen = ArtbeatDrawerItem(
    title: 'Payment Screen',
    icon: Icons.payment,
    route: '/payment/screen',
    requiredRoles: ['artist'],
  );

  static const refundRequest = ArtbeatDrawerItem(
    title: 'Refund Request',
    icon: Icons.undo_outlined,
    route: '/payment/refund',
    requiredRoles: ['artist'],
  );

  // Advertising items for artists and galleries
  static const createAd = ArtbeatDrawerItem(
    title: 'Create Ad',
    icon: Icons.campaign_outlined,
    route: '/ads/create',
    color: ArtbeatColors.primaryGreen,
    requiredRoles: ['artist', 'gallery'],
  );

  static const manageMyAds = ArtbeatDrawerItem(
    title: 'My Ads',
    icon: Icons.ads_click_outlined,
    route: '/ads/management',
    requiredRoles: ['artist', 'gallery'],
  );

  static const myAdStatistics = ArtbeatDrawerItem(
    title: 'Ad Performance',
    icon: Icons.analytics_outlined,
    route: '/ads/statistics',
    color: ArtbeatColors.primaryGreen,
    requiredRoles: ['artist', 'gallery'],
  );

  static const approvedAds = ArtbeatDrawerItem(
    title: 'Approved Ads',
    icon: Icons.verified_outlined,
    route: '/artist/approved-ads',
    requiredRoles: ['artist'],
  );

  // Admin advertising items
  static const manageAds = ArtbeatDrawerItem(
    title: 'Manage Ads',
    icon: Icons.ads_click_outlined,
    route: '/ads/management',
    requiredRoles: ['admin'],
    color: ArtbeatColors.primaryPurple,
  );

  static const adStatistics = ArtbeatDrawerItem(
    title: 'Ad Statistics',
    icon: Icons.analytics_outlined,
    route: '/ads/statistics',
    requiredRoles: ['admin'],
    color: ArtbeatColors.primaryPurple,
  );

  static const captureModeration = ArtbeatDrawerItem(
    title: 'Capture Moderation',
    icon: Icons.photo_library_outlined,
    route: '/capture/admin/moderation',
    requiredRoles: ['admin'],
    color: ArtbeatColors.primaryPurple,
  );

  static const artWalkModeration = ArtbeatDrawerItem(
    title: 'Art Walk Moderation',
    icon: Icons.route_outlined,
    route: '/artwalk/admin/moderation',
    requiredRoles: ['admin'],
    color: ArtbeatColors.primaryPurple,
  );

  // Settings items
  static const settings = ArtbeatDrawerItem(
    title: 'Settings',
    icon: Icons.settings_outlined,
    route: '/settings',
  );

  static const help = ArtbeatDrawerItem(
    title: 'Help & Support',
    icon: Icons.help_outline,
    route: '/support',
  );

  // Sign out
  static const signOut = ArtbeatDrawerItem(
    title: 'Sign Out',
    icon: Icons.logout,
    route: '/login',
    color: ArtbeatColors.error,
    requiresAuth: false,
  );

  // Grouped items for different user types
  static const artbeatStore = ArtbeatDrawerItem(
    title: 'Artbeat Store',
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
    sections.add(DrawerSection(title: 'Navigation', items: coreItems));

    // 2. Creation Tools (for artists, galleries, admins)
    final hasCreationRole =
        userRole == 'artist' || userRole == 'gallery' || userRole == 'admin';
    if (hasCreationRole) {
      sections.add(DrawerSection(title: 'Create', items: creationItems));
    }

    // 3. Messaging (always available for authenticated users)
    sections.add(const DrawerSection(items: [messaging]));

    // 4. Role-Specific Management Tools
    switch (userRole) {
      case 'artist':
        sections.add(DrawerSection(title: 'Artist', items: artistItems));
        break;
      case 'gallery':
        sections.add(DrawerSection(title: 'Gallery', items: galleryItems));
        break;
      case 'admin':
        sections.add(DrawerSection(title: 'Admin', items: adminItems));
        // Removed paymentMethods from admin drawer - admins should use AdminPaymentScreen
        break;
      case 'moderator':
        sections.add(DrawerSection(title: 'Moderation', items: moderatorItems));
        break;
    }

    // 6. Personal & Social Features
    sections.add(DrawerSection(title: 'Personal', items: personalItems));

    // 7. Settings & Support
    sections.add(
      DrawerSection(title: 'Settings', items: settingsItems, showDivider: true),
    );

    return sections;
  }

  // Helper method to get items for a specific user role (legacy method for backward compatibility)
  static List<ArtbeatDrawerItem> getItemsForRole(String? userRole) {
    final sections = getSectionsForRole(userRole);
    return sections.expand((section) => section.items).toList();
  }
}
