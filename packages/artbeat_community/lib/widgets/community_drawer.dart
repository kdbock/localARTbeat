import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../screens/unified_community_hub.dart';
import '../screens/feed/enhanced_community_feed_screen.dart';
import '../screens/feed/trending_content_screen.dart';
import '../screens/portfolios/portfolios_screen.dart';
import '../screens/studios/studios_screen.dart';
import '../screens/commissions/commission_hub_screen.dart';
import '../screens/gifts/gifts_screen.dart';

import '../src/screens/community_artists_screen.dart';
import '../screens/settings/quiet_mode_screen.dart';
import '../screens/moderation/moderation_queue_screen.dart';
import '../../theme/community_colors.dart';

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
    return Drawer(
      child: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                CommunityColors.primary,
                CommunityColors.secondary,
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
                      _buildDrawerItem(
                        icon: Icons.home,
                        title: 'Community Hub',
                        onTap: () => _navigateToScreen(
                          context,
                          const UnifiedCommunityHub(),
                        ),
                      ),
                      _buildDrawerItem(
                        icon: Icons.feed,
                        title: 'Art Feed',
                        onTap: () => _navigateToScreen(
                          context,
                          const EnhancedCommunityFeedScreen(),
                        ),
                      ),
                      _buildDrawerItem(
                        icon: Icons.trending_up,
                        title: 'Trending',
                        onTap: () => _navigateToScreen(
                          context,
                          const TrendingContentScreen(),
                        ),
                      ),
                      _buildDrawerItem(
                        icon: Icons.palette,
                        title: 'Artist Portfolios',
                        onTap: () => _navigateToScreen(
                          context,
                          const PortfoliosScreen(),
                        ),
                      ),
                      _buildDrawerItem(
                        icon: Icons.business,
                        title: 'Studios',
                        onTap: () =>
                            _navigateToScreen(context, const StudiosScreen()),
                      ),
                      _buildDrawerItem(
                        icon: Icons.handshake,
                        title: 'Commissions',
                        onTap: () => _navigateToScreen(
                          context,
                          const CommissionHubScreen(),
                        ),
                      ),
                      _buildDrawerItem(
                        icon: Icons.card_giftcard,
                        title: 'Gifts',
                        onTap: () => _navigateToScreen(
                          context,
                          const ViewReceivedGiftsScreen(),
                        ),
                      ),
                      const Divider(),
                      _buildDrawerItem(
                        icon: Icons.search,
                        title: 'Search Community',
                        onTap: () => _navigateToScreen(
                          context,
                          const CommunityArtistsScreen(),
                        ),
                      ),
                      _buildDrawerItem(
                        icon: Icons.settings,
                        title: 'Community Settings',
                        onTap: () =>
                            _navigateToScreen(context, const QuietModeScreen()),
                      ),
                      _buildDrawerItem(
                        icon: Icons.admin_panel_settings,
                        title: 'Moderation',
                        onTap: () => _navigateToScreen(
                          context,
                          const ModerationQueueScreen(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer with version info
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: const Text(
                  'ARTbeat Community v0.0.2',
                  style: TextStyle(
                    color: CommunityColors.textSecondary,
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
                      CommunityColors.primary,
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
                        color: CommunityColors.primary,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.person,
                    size: 40,
                    color: CommunityColors.primary,
                  ),
          ),

          const SizedBox(height: 12),

          // User name
          Text(
            _isLoading
                ? 'Loading...'
                : _currentUser?.fullName ?? 'Community Member',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          // User role/status
          Text(
            _isLoading ? '' : _getUserRoleText(),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getUserRoleText() {
    if (_currentUser == null) return 'Member';

    final userType = _currentUser!.userType;
    if (userType == null) return 'Community Member';

    switch (userType) {
      case 'artist':
        return 'Artist';
      case 'business':
        return 'Gallery';
      case 'moderator':
        return 'Moderator';
      case 'admin':
        return 'Admin';
      default:
        return 'Community Member';
    }
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: CommunityColors.primary),
      title: Text(
        title,
        style: const TextStyle(
          color: CommunityColors.textPrimary,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.pop(context); // Close drawer
    Navigator.push<Widget>(
      context,
      MaterialPageRoute<Widget>(builder: (context) => screen),
    );
  }
}
