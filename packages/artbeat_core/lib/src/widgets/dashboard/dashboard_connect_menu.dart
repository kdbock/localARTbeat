import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart';

class DashboardConnectMenu extends StatelessWidget {
  const DashboardConnectMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.8,
      minChildSize: 0.3,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(
                    Icons.explore,
                    color: ArtbeatColors.primaryPurple,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'dashboard_connect_title'.tr(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: ArtbeatColors.textPrimary,
                          ),
                        ),
                        Text(
                          'dashboard_connect_subtitle'.tr(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: ArtbeatColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Menu items
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildMenuTile(
                    context: context,
                    icon: Icons.leaderboard,
                    title: 'dashboard_connect_leaderboard_title'.tr(),
                    subtitle: 'dashboard_connect_leaderboard_subtitle'.tr(),
                    color: ArtbeatColors.warning,
                    route: '/leaderboard',
                  ),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.person_search,
                    title: 'dashboard_connect_find_artists_title'.tr(),
                    subtitle: 'dashboard_connect_find_artists_subtitle'.tr(),
                    color: ArtbeatColors.primaryPurple,
                    route: '/artist/browse',
                  ),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.palette,
                    title: 'dashboard_connect_browse_artwork_title'.tr(),
                    subtitle: 'dashboard_connect_browse_artwork_subtitle'.tr(),
                    color: ArtbeatColors.primaryGreen,
                    route: '/artwork/browse',
                  ),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.directions_walk,
                    title: 'dashboard_connect_start_art_walk_title'.tr(),
                    subtitle: 'dashboard_connect_start_art_walk_subtitle'.tr(),
                    color: ArtbeatColors.info,
                    route: '/art-walk/create',
                  ),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.groups,
                    title: 'dashboard_connect_community_hub_title'.tr(),
                    subtitle: 'dashboard_connect_community_hub_subtitle'.tr(),
                    color: ArtbeatColors.primaryPurple,
                    route: '/community/hub',
                  ),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.camera_alt,
                    title: 'dashboard_connect_explore_art_title'.tr(),
                    subtitle: 'dashboard_connect_explore_art_subtitle'.tr(),
                    color: ArtbeatColors.primaryGreen,
                    route: '/captures/list',
                  ),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.event,
                    title: 'dashboard_connect_upcoming_events_title'.tr(),
                    subtitle: 'dashboard_connect_upcoming_events_subtitle'.tr(),
                    color: ArtbeatColors.error,
                    route: '/events/list',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String route,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, route);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ArtbeatColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: ArtbeatColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
