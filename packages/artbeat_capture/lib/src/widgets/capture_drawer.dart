import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Capture specific drawer with focused navigation for capture features
class CaptureDrawer extends StatefulWidget {
  const CaptureDrawer({super.key});

  @override
  State<CaptureDrawer> createState() => _CaptureDrawerState();
}

class _CaptureDrawerState extends State<CaptureDrawer> {
  UserModel? _currentUser;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _userService.getCurrentUserModel();
      if (mounted) {
        setState(() => _currentUser = user);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ArtbeatColors.primaryGreen.withValues(alpha: 0.05),
                Colors.white,
                ArtbeatColors.primaryPurple.withValues(alpha: 0.02),
              ],
            ),
          ),
          child: Column(
            children: [
              // Header with user info
              _buildDrawerHeader(),

              // Navigation items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    // Quick Actions Section
                    _buildSectionHeader('Quick Actions'),
                    _buildDrawerItem(
                      context,
                      'Take Photo',
                      Icons.camera_alt,
                      '/capture/camera',
                      ArtbeatColors.primaryGreen,
                    ),
                    _buildDrawerItem(
                      context,
                      'Browse Captures',
                      Icons.grid_view,
                      '/capture/browse',
                      ArtbeatColors.secondaryTeal,
                    ),

                    const Divider(height: 24),

                    // My Captures Section
                    _buildSectionHeader('My Captures'),
                    _buildDrawerItem(
                      context,
                      'My Captures',
                      Icons.photo_album,
                      '/capture/my-captures',
                      ArtbeatColors.primaryGreen,
                    ),
                    _buildDrawerItem(
                      context,
                      'Pending Review',
                      Icons.pending,
                      '/capture/pending',
                      ArtbeatColors.accentYellow,
                    ),
                    _buildDrawerItem(
                      context,
                      'Approved Captures',
                      Icons.check_circle,
                      '/capture/approved',
                      ArtbeatColors.primaryGreen,
                    ),

                    const Divider(height: 24),

                    // Community Section
                    _buildSectionHeader('Community'),
                    _buildDrawerItem(
                      context,
                      'Public Captures',
                      Icons.public,
                      '/capture/public',
                      ArtbeatColors.primaryPurple,
                    ),
                    _buildDrawerItem(
                      context,
                      'Nearby Art',
                      Icons.location_on,
                      '/capture/nearby',
                      ArtbeatColors.secondaryTeal,
                    ),
                    _buildDrawerItem(
                      context,
                      'Popular Captures',
                      Icons.trending_up,
                      '/capture/popular',
                      ArtbeatColors.accentYellow,
                    ),

                    const Divider(height: 24),

                    // Tools Section
                    _buildSectionHeader('Tools'),
                    _buildDrawerItem(
                      context,
                      'Search Captures',
                      Icons.search,
                      '/capture/search',
                      ArtbeatColors.primaryGreen,
                    ),
                    _buildDrawerItem(
                      context,
                      'Capture Map',
                      Icons.map,
                      '/capture/map',
                      ArtbeatColors.primaryPurple,
                    ),
                    _buildDrawerItem(
                      context,
                      'Capture Settings',
                      Icons.settings,
                      '/capture/settings',
                      Colors.grey,
                    ),

                    const Divider(height: 24),

                    // Content Moderation (if admin)
                    if (_currentUser?.userType == UserType.admin)
                      _buildSectionHeader('Moderation'),
                    if (_currentUser?.userType == UserType.admin)
                      _buildDrawerItem(
                        context,
                        'Content Moderation',
                        Icons.admin_panel_settings,
                        '/capture/admin/moderation',
                        Colors.red,
                      ),

                    const Divider(height: 24),

                    // General Navigation
                    _buildSectionHeader('Navigation'),
                    _buildDrawerItem(
                      context,
                      'Main Dashboard',
                      Icons.dashboard,
                      '/dashboard',
                      Colors.grey,
                    ),
                    _buildDrawerItem(
                      context,
                      'Art Walk',
                      Icons.directions_walk,
                      '/art-walk/dashboard',
                      ArtbeatColors.secondaryTeal,
                    ),
                    _buildDrawerItem(
                      context,
                      'Profile',
                      Icons.person,
                      '/profile',
                      Colors.grey,
                    ),

                    const SizedBox(height: 16),

                    // Sign Out
                    _buildSignOutItem(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    final user = FirebaseAuth.instance.currentUser;
    final displayName =
        _currentUser?.fullName ?? user?.displayName ?? 'Art Capturer';
    final email = user?.email ?? '';

    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ArtbeatColors.primaryPurple, Colors.pink],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                imageUrl: _currentUser?.profileImageUrl,
                displayName: displayName,
                radius: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.camera_alt, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text(
                  'capture_drawer_art_capture'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: ArtbeatColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          fontFamily: 'Roboto',
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    String title,
    IconData icon,
    String route,
    Color color,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: ArtbeatColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () => _navigateToRoute(context, route),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      dense: true,
    );
  }

  Widget _buildSignOutItem(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.logout, color: Colors.red, size: 20),
      ),
      title: Text(
        'capture_drawer_sign_out'.tr(),
        style: const TextStyle(
          color: Colors.red,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () => _signOut(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      dense: true,
    );
  }

  void _navigateToRoute(BuildContext context, String route) {
    Navigator.pop(context); // Close drawer

    // Use pushReplacement for main routes to avoid back navigation issues
    const mainRoutes = ['/dashboard', '/profile'];
    if (mainRoutes.contains(route)) {
      Navigator.pushReplacementNamed(context, route);
    } else {
      Navigator.pushNamed(context, route);
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        // ignore: use_build_context_synchronously
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('capture_drawer_error_signing_out'.tr().replaceAll('{error}', e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
