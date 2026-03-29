import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/auth_service.dart' as core_auth;
import '../theme/artbeat_colors.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import 'artbeat_drawer_items.dart';
import 'user_avatar.dart';
import '../utils/logger.dart';

/// Enhanced navigation menu with comprehensive feature access
///
/// Provides categorized navigation to all implemented features based on user role
class EnhancedNavigationMenu extends StatefulWidget {
  final void Function(String)? onNavigate;

  const EnhancedNavigationMenu({super.key, this.onNavigate});

  @override
  State<EnhancedNavigationMenu> createState() => _EnhancedNavigationMenuState();
}

class _EnhancedNavigationMenuState extends State<EnhancedNavigationMenu>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  UserModel? _userModel;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadUserModel();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserModel() async {
    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final user = context.read<core_auth.AuthService>().currentUser;
      if (user != null) {
        final userModel = await userService.getUserById(user.uid);
        if (mounted) {
          setState(() {
            _userModel = userModel;
            _userRole = _getUserRole();
          });
        }
      }
    } catch (error) {
      AppLogger.error('❌ Error loading user model: $error');
    }
  }

  String? _getUserRole() {
    final userModel = _userModel;
    if (userModel != null) {
      if (userModel.isAdmin) return 'admin';
      if (userModel.isArtist) return 'artist';
      if (userModel.isGallery) return 'gallery';
      if (userModel.isModerator) return 'moderator';
    }
    return null; // Regular user
  }

  void _handleNavigation(String route) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(route);
    } else {
      Navigator.of(context).pushNamed(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(context),

          // Tab Bar
          _buildTabBar(context),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCoreFeatures(),
                _buildContentFeatures(),
                _buildSocialFeatures(),
                _buildRoleSpecificFeatures(),
                _buildToolsFeatures(),
                _buildSettingsFeatures(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: ArtbeatColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // User info
          Row(
            children: [
              UserAvatar(
                imageUrl: _userModel?.profileImageUrl,
                displayName: _userModel?.fullName ?? 'Welcome',
                radius: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userModel?.fullName ?? 'Welcome',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _userRole?.toUpperCase() ?? 'USER',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ArtbeatColors.primaryPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: const Border(
          bottom: BorderSide(color: ArtbeatColors.border, width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: ArtbeatColors.primaryPurple,
        labelColor: ArtbeatColors.primaryPurple,
        unselectedLabelColor: ArtbeatColors.textSecondary,
        labelStyle: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: Theme.of(context).textTheme.bodyMedium,
        tabs: const [
          Tab(text: 'Core'),
          Tab(text: 'Content'),
          Tab(text: 'Social'),
          Tab(text: 'Role'),
          Tab(text: 'Tools'),
          Tab(text: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildCoreFeatures() {
    final items = [
      ArtbeatDrawerItems.dashboard,
      ArtbeatDrawerItems.browse,
      ArtbeatDrawerItems.community,
      ArtbeatDrawerItems.messaging,
      ArtbeatDrawerItems.enhancedSearch,
    ];

    return _buildFeatureList(items, 'Core Features');
  }

  Widget _buildContentFeatures() {
    final items = [
      ArtbeatDrawerItems.events,
      ArtbeatDrawerItems.artWalk,
      ArtbeatDrawerItems.artWalkCreate,
      if (_userRole == 'artist') ArtbeatDrawerItems.uploadArtwork,
      if (_userRole == 'artist') ArtbeatDrawerItems.createEvent,
    ];

    return _buildFeatureList(items, 'Content & Discovery');
  }

  Widget _buildSocialFeatures() {
    final items = [
      ArtbeatDrawerItems.community,
      ArtbeatDrawerItems.favorites,
      ArtbeatDrawerItems.achievements,
      ArtbeatDrawerItems.notifications,
      ArtbeatDrawerItems.myTickets,
    ];

    return _buildFeatureList(items, 'Social & Personal');
  }

  Widget _buildRoleSpecificFeatures() {
    List<ArtbeatDrawerItem> items = [];

    switch (_userRole) {
      case 'artist':
        items = ArtbeatDrawerItems.artistItems;
        break;
      case 'gallery':
        items = ArtbeatDrawerItems.galleryItems;
        break;
      case 'admin':
        items = ArtbeatDrawerItems.adminItems;
        break;
      case 'moderator':
        items = ArtbeatDrawerItems.moderatorItems;
        break;
      default:
        items = [
          const ArtbeatDrawerItem(
            title: 'Become an Artist',
            icon: Icons.palette_outlined,
            route: '/artist/onboarding',
          ),
        ];
    }

    return _buildFeatureList(
      items,
      '${_userRole?.toUpperCase() ?? 'USER'} Features',
    );
  }

  Widget _buildToolsFeatures() {
    final items = [
      if (_userRole == 'artist') ArtbeatDrawerItems.subscriptionPlans,
      if (_userRole == 'artist' || _userRole == 'gallery')
        ArtbeatDrawerItems.paymentMethods,
      const ArtbeatDrawerItem(
        title: 'System Info',
        icon: Icons.info_outline,
        route: '/system/info',
      ),
      const ArtbeatDrawerItem(
        title: 'Feedback',
        icon: Icons.feedback_outlined,
        route: '/feedback',
      ),
    ];

    return _buildFeatureList(items, 'Tools & Utilities');
  }

  Widget _buildSettingsFeatures() {
    final items = [
      ArtbeatDrawerItems.settings,
      const ArtbeatDrawerItem(
        title: 'Account Settings',
        icon: Icons.account_circle_outlined,
        route: '/settings/account',
      ),
      const ArtbeatDrawerItem(
        title: 'Privacy Settings',
        icon: Icons.privacy_tip_outlined,
        route: '/settings/privacy',
      ),
      const ArtbeatDrawerItem(
        title: 'Security Settings',
        icon: Icons.security_outlined,
        route: '/settings/security',
      ),
      const ArtbeatDrawerItem(
        title: 'Notification Settings',
        icon: Icons.notifications_outlined,
        route: '/settings/notifications',
      ),
      ArtbeatDrawerItems.help,
    ];

    return _buildFeatureList(items, 'Settings & Support');
  }

  Widget _buildFeatureList(List<ArtbeatDrawerItem> items, String title) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: ArtbeatColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...items.map((item) => _buildFeatureItem(item)),
      ],
    );
  }

  Widget _buildFeatureItem(ArtbeatDrawerItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (item.color ?? ArtbeatColors.primaryPurple).withValues(
              alpha: 0.1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            item.icon,
            color: item.color ?? ArtbeatColors.primaryPurple,
            size: 20,
          ),
        ),
        title: Text(
          item.title,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: ArtbeatColors.textSecondary,
        ),
        onTap: () => _handleNavigation(item.route),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
