import 'package:flutter/material.dart';
import 'package:artbeat_auth/artbeat_auth.dart'; // Assuming for logout/auth state
import 'package:provider/provider.dart';
import 'package:artbeat_capture/src/screens/terms_and_conditions_screen.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../widgets/world_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/section_header.dart';
import '../widgets/user_avatar_badge.dart';

class ProfileMenuScreen extends StatefulWidget {
  const ProfileMenuScreen({super.key});

  @override
  State<ProfileMenuScreen> createState() => _ProfileMenuScreenState();
}

class _ProfileMenuScreenState extends State<ProfileMenuScreen> {
  final UserService _userService = UserService();
  UserModel? _currentUser;

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
      // Handle error silently or show a message if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return const WorldBackground(
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: GlassCard(
            padding: EdgeInsets.all(20),
            radius: 28.0,
            child: _ProfileMenuContent(),
          ),
        ),
      ),
    );
  }
}

class _ProfileMenuContent extends StatelessWidget {
  const _ProfileMenuContent();

  @override
  Widget build(BuildContext context) {
    final currentUser = context
        .findAncestorStateOfType<_ProfileMenuScreenState>()!
        ._currentUser;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (currentUser != null && currentUser.profileImageUrl.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: UserAvatarBadge(
                    imageUrl: currentUser.profileImageUrl,
                    size: 40,
                  ),
                ),
              const Expanded(
                child: Text(
                  'My Profile',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Account'),
          _menuItem(
            context,
            icon: Icons.edit,
            label: 'Edit Profile',
            route: '/profile/edit',
          ),
          _menuItem(
            context,
            icon: Icons.settings_outlined,
            label: 'Profile Settings',
            route: '/profile/settings',
          ),
          _menuItem(
            context,
            icon: Icons.block,
            label: 'Blocked Users',
            route: '/profile/blocked',
          ),
          _menuItem(
            context,
            icon: Icons.emoji_events_outlined,
            label: 'My Achievements',
            route: '/profile/achievements',
          ),
          _menuItem(
            context,
            icon: Icons.info_outline,
            label: 'Experience Info',
            route: '/profile/achievement-info',
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Social'),
          _menuItem(
            context,
            icon: Icons.people_outline,
            label: 'Followers',
            route: '/profile/followers',
          ),
          _menuItem(
            context,
            icon: Icons.person_add_alt,
            label: 'Following',
            route: '/profile/following',
          ),
          _menuItem(
            context,
            icon: Icons.favorite_outline,
            label: 'Favorites',
            route: '/profile/favorites',
          ),
          _menuItem(
            context,
            icon: Icons.military_tech_outlined,
            label: 'Badges',
            route: '/profile/badges',
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'More'),
          _menuItem(
            context,
            icon: Icons.policy_outlined,
            label: 'Privacy & Terms',
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const TermsAndConditionsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.12)),
          const SizedBox(height: 8),
          _menuItem(
            context,
            icon: Icons.logout,
            label: 'Sign Out',
            destructive: true,
            onTap: () async {
              await context.read<AuthService>().signOut();
              if (context.mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/auth/login', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? route,
    VoidCallback? onTap,
    bool destructive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap:
              onTap ??
              () {
                if (route != null) Navigator.of(context).pushNamed(route);
              },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: destructive ? Colors.redAccent : Colors.white,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: destructive ? Colors.redAccent : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
