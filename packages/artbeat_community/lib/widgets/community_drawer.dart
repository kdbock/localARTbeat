import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_artist/artbeat_artist.dart' as artist;
import 'package:artbeat_artwork/artbeat_artwork.dart' as artwork;
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_admin/artbeat_admin.dart';
import '../screens/art_community_hub.dart';
import '../screens/feed/enhanced_community_feed_screen.dart';
import '../screens/feed/trending_content_screen.dart';
import '../screens/portfolios/portfolios_screen.dart';
import '../screens/studios/studios_screen.dart';
import '../screens/commissions/commission_hub_screen.dart';
import '../screens/boosts/boosts_screen.dart';

import '../src/screens/community_artists_screen.dart';
import '../screens/settings/quiet_mode_screen.dart';

/// Community navigation drawer with user profile and navigation options
class CommunityDrawer extends StatefulWidget {
  const CommunityDrawer({super.key});

  @override
  State<CommunityDrawer> createState() => _CommunityDrawerState();
}

class _CommunityDrawerState extends State<CommunityDrawer> {
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _currentUser = UserModel.fromFirestore(userDoc);
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      AppLogger.error('Error loading current user: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainFeedEntries = <_DrawerEntry>[
      _DrawerEntry(
        icon: Icons.home,
        titleBuilder: (_) => 'community_drawer_community_hub'.tr(),
        screenBuilder: () => const ArtCommunityHub(),
      ),
      _DrawerEntry(
        icon: Icons.feed,
        titleBuilder: (_) => 'community_drawer_art_feed'.tr(),
        screenBuilder: () => const EnhancedCommunityFeedScreen(),
      ),
      _DrawerEntry(
        icon: Icons.trending_up,
        titleBuilder: (_) => 'community_drawer_trending'.tr(),
        screenBuilder: () => const TrendingContentScreen(),
      ),
      _DrawerEntry(
        icon: Icons.explore,
        titleBuilder: (_) => 'community_drawer_art_discovery'.tr(),
        screenBuilder: () => const artwork.ArtworkDiscoveryScreen(),
      ),
      _DrawerEntry(
        icon: Icons.museum,
        titleBuilder: (_) => 'Art Gallery',
        screenBuilder: () => const artwork.ArtworkBrowseScreen(),
      ),
    ];

    final artistEntries = <_DrawerEntry>[
      _DrawerEntry(
        icon: Icons.palette,
        titleBuilder: (_) => 'community_drawer_artist_portfolios'.tr(),
        screenBuilder: () => const PortfoliosScreen(),
      ),
      _DrawerEntry(
        icon: Icons.brush,
        titleBuilder: (_) => 'Become an Artist',
        screenBuilder: () => const artist.ArtistOnboardScreen(),
      ),
    ];

    final studioEntries = <_DrawerEntry>[
      _DrawerEntry(
        icon: Icons.business,
        titleBuilder: (_) => 'community_drawer_studios'.tr(),
        screenBuilder: () => const StudiosScreen(),
      ),
      _DrawerEntry(
        icon: Icons.handshake,
        titleBuilder: (_) => 'community_drawer_commissions'.tr(),
        screenBuilder: () => const CommissionHubScreen(),
      ),
      _DrawerEntry(
        icon: Icons.bolt,
        titleBuilder: (_) => 'community_drawer_boosts'.tr(),
        screenBuilder: () => const ViewReceivedBoostsScreen(),
      ),
    ];

    final discoverEntries = <_DrawerEntry>[
      _DrawerEntry(
        icon: Icons.search,
        titleBuilder: (_) => 'community_drawer_search_community'.tr(),
        screenBuilder: () => const CommunityArtistsScreen(),
      ),
      _DrawerEntry(
        icon: Icons.leaderboard,
        titleBuilder: (_) => 'leaderboard_title'.tr(),
        screenBuilder: () => const LeaderboardScreen(),
      ),
    ];

    final settingsEntries = <_DrawerEntry>[
      _DrawerEntry(
        icon: Icons.settings,
        titleBuilder: (_) => 'community_drawer_community_settings'.tr(),
        screenBuilder: () => const QuietModeScreen(),
      ),
      _DrawerEntry(
        icon: Icons.admin_panel_settings,
        titleBuilder: (_) => 'community_drawer_moderation'.tr(),
        screenBuilder: () => const AdminCommunityModerationScreen(),
      ),
    ];

    return Drawer(
      child: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ArtbeatColors.primary,
                ArtbeatColors.primaryPurple,
                Colors.white,
              ],
              stops: [0.0, 0.3, 0.3],
            ),
          ),
          child: Column(
            children: [
              // User profile header
              _buildUserProfileHeader(),

              // Navigation items
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      ..._buildNavigationSection(
                        'Main Feeds',
                        mainFeedEntries,
                        context,
                      ),
                      ..._buildNavigationSection(
                        'Artists',
                        artistEntries,
                        context,
                      ),
                      ..._buildNavigationSection(
                        'Studios & Work',
                        studioEntries,
                        context,
                      ),
                      const Divider(),
                      ..._buildNavigationSection(
                        'Discover',
                        discoverEntries,
                        context,
                      ),
                      ..._buildNavigationSection(
                        'Settings',
                        settingsEntries,
                        context,
                      ),
                    ],
                  ),
                ),
              ),

              // Footer with version info
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Text(
                  'community_drawer_version'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    color: ArtbeatColors.textSecondary,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfileHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
      child: Column(
        children: [
          // User avatar
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: _isLoading
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ArtbeatColors.primary,
                    ),
                  )
                : _currentUser?.profileImageUrl != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: _currentUser!.profileImageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.person,
                        size: 40,
                        color: ArtbeatColors.primary,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.person,
                    size: 40,
                    color: ArtbeatColors.primary,
                  ),
          ),

          const SizedBox(height: 12),

          // User name
          Text(
            _isLoading
                ? 'community_drawer_loading'.tr()
                : _currentUser?.fullName ??
                      'community_drawer_community_member'.tr(),
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          // User role/status
          Text(
            _isLoading ? '' : _getUserRoleText(),
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getUserRoleText() {
    if (_currentUser == null) return 'community_drawer_member'.tr();

    final userType = _currentUser!.userType;
    if (userType == null) return 'community_drawer_community_member'.tr();

    switch (userType) {
      case 'artist':
        return 'community_drawer_artist'.tr();
      case 'business':
        return 'community_drawer_gallery'.tr();
      case 'moderator':
        return 'community_drawer_moderator'.tr();
      case 'admin':
        return 'community_drawer_admin'.tr();
      default:
        return 'community_drawer_community_member'.tr();
    }
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: ArtbeatColors.primary),
      title: Text(
        title,
        style: GoogleFonts.spaceGrotesk(
          color: ArtbeatColors.textPrimary,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.spaceGrotesk(
          color: ArtbeatColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  List<Widget> _buildNavigationSection(
    String title,
    List<_DrawerEntry> entries,
    BuildContext context,
  ) {
    final children = <Widget>[_buildSectionHeader(title)];
    children.addAll(
      entries.map(
        (entry) => _buildDrawerItem(
          icon: entry.icon,
          title: entry.titleBuilder(context),
          onTap: () => _navigateToScreen(context, entry.screenBuilder()),
        ),
      ),
    );
    return children;
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.pop(context); // Close drawer
    Navigator.push<Widget>(
      context,
      MaterialPageRoute<Widget>(builder: (context) => screen),
    );
  }
}

class _DrawerEntry {
  final IconData icon;
  final String Function(BuildContext) titleBuilder;
  final Widget Function() screenBuilder;

  const _DrawerEntry({
    required this.icon,
    required this.titleBuilder,
    required this.screenBuilder,
  });
}
