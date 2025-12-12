import 'package:flutter/material.dart';
import 'package:artbeat_core/src/services/auth_service.dart';
import 'package:easy_localization/easy_localization.dart';

/// Admin Package Specific Drawer
///
/// Color: #8c52ff (140, 82, 255)
/// Text/Icon Color: #00bf63
/// Font: Limelight
class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  static const Color _headerColor = Color(0xFF8C52FF); // Admin header color
  static const Color _iconTextColor = Color(0xFF00BF63); // Text/Icon color

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate available height and adjust header accordingly
          final availableHeight = constraints.maxHeight;
          final isCompact = availableHeight < 400;

          return Column(
            children: [
              // Custom drawer header with admin branding - flexible height
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: isCompact ? 80 : 120,
                  maxHeight:
                      availableHeight * 0.3, // Use 30% of available height
                ),
                decoration: const BoxDecoration(
                  color: _headerColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(isCompact ? 8 : 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Admin icon
                        Container(
                          width: isCompact ? 40 : 50,
                          height: isCompact ? 40 : 50,
                          decoration: BoxDecoration(
                            color: _iconTextColor.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _iconTextColor,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.admin_panel_settings,
                            size: isCompact ? 20 : 25,
                            color: _iconTextColor,
                          ),
                        ),
                        SizedBox(height: isCompact ? 4 : 8),
                        // Title
                        Text(
                          'admin_drawer_title_panel'.tr(),
                          style: TextStyle(
                            color: _iconTextColor,
                            fontFamily: 'Limelight',
                            fontSize: isCompact ? 14 : 18,
                            fontWeight: FontWeight.normal,
                            letterSpacing: 1.2,
                          ),
                        ),
                        if (!isCompact) ...[
                          const SizedBox(height: 2),
                          Text(
                            'admin_drawer_title_console'.tr(),
                            style: TextStyle(
                              color: _iconTextColor.withValues(alpha: 0.8),
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Scrollable menu items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: [
                    // Artbeat Home button - navigate to main app dashboard
                    _buildDrawerItem(
                      context,
                      icon: Icons.home,
                      title: 'admin_drawer_menu_home'.tr(),
                      route: '/dashboard',
                      subtitle: 'admin_drawer_menu_home_subtitle'.tr(),
                    ),

                    const Divider(height: 16),

                    // Main Admin Dashboard - All-in-One Interface
                    _buildSectionHeader('admin_drawer_section_dashboard'.tr()),
                    _buildDrawerItem(
                      context,
                      icon: Icons.dashboard,
                      title: 'admin_drawer_menu_unified_dashboard'.tr(),
                      route: '/admin/dashboard',
                      subtitle:
                          'admin_drawer_menu_unified_dashboard_subtitle'.tr(),
                    ),

                    const Divider(height: 16),

                    // Business Management Section
                    _buildSectionHeader('admin_drawer_section_business'.tr()),
                    _buildDrawerItem(
                      context,
                      icon: Icons.local_offer,
                      title: 'admin_drawer_menu_coupons'.tr(),
                      route: '/admin/coupons',
                      subtitle: 'admin_drawer_menu_coupons_subtitle'.tr(),
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.payment,
                      title: 'admin_drawer_menu_payments'.tr(),
                      route: '/admin/payments',
                      subtitle: 'admin_drawer_menu_payments_subtitle'.tr(),
                    ),

                    const Divider(height: 16),

                    // Content Management Section
                    _buildSectionHeader('admin_drawer_section_content'.tr()),
                    _buildDrawerItem(
                      context,
                      icon: Icons.content_paste,
                      title: 'admin_drawer_menu_content_moderation'.tr(),
                      route:
                          '/admin/dashboard', // Unified dashboard handles content moderation
                      subtitle:
                          'admin_drawer_menu_content_moderation_subtitle'.tr(),
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.photo_library,
                      title: 'admin_drawer_menu_capture_moderation'.tr(),
                      route: '/capture/admin/moderation',
                      subtitle:
                          'admin_drawer_menu_capture_moderation_subtitle'.tr(),
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.route,
                      title: 'admin_drawer_menu_artwalk_moderation'.tr(),
                      route: '/artwalk/admin/moderation',
                      subtitle:
                          'admin_drawer_menu_artwalk_moderation_subtitle'.tr(),
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.people,
                      title: 'admin_drawer_menu_user_management'.tr(),
                      route:
                          '/admin/dashboard', // Unified dashboard handles user management
                      subtitle:
                          'admin_drawer_menu_user_management_subtitle'.tr(),
                    ),

                    const Divider(height: 16),

                    // System Management Section
                    _buildSectionHeader('admin_drawer_section_system'.tr()),
                    _buildDrawerItem(
                      context,
                      icon: Icons.settings,
                      title: 'admin_drawer_menu_admin_settings'.tr(),
                      route: '/admin/settings',
                      subtitle:
                          'admin_drawer_menu_admin_settings_subtitle'.tr(),
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.security,
                      title: 'admin_drawer_menu_security_center'.tr(),
                      route: '/admin/security',
                      subtitle:
                          'admin_drawer_menu_security_center_subtitle'.tr(),
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.monitor,
                      title: 'admin_drawer_menu_system_monitoring'.tr(),
                      route: '/admin/monitoring',
                      subtitle:
                          'admin_drawer_menu_system_monitoring_subtitle'.tr(),
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.sync_alt,
                      title: 'admin_drawer_menu_data_migration'.tr(),
                      route: '/admin/migration',
                      subtitle:
                          'admin_drawer_menu_data_migration_subtitle'.tr(),
                    ),

                    const Divider(height: 16),

                    // Developer Tools Section
                    _buildSectionHeader('admin_drawer_section_developer'.tr()),
                    _buildDrawerItem(
                      context,
                      icon: Icons.upload_file,
                      title: 'admin_drawer_menu_data_upload_tools'.tr(),
                      route: '/dev',
                      subtitle:
                          'admin_drawer_menu_data_upload_tools_subtitle'.tr(),
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.feedback,
                      title: 'admin_drawer_menu_developer_feedback'.tr(),
                      route: '/developer-feedback-admin',
                      subtitle:
                          'admin_drawer_menu_developer_feedback_subtitle'.tr(),
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.admin_panel_settings,
                      title: 'admin_drawer_menu_admin_upload_tools'.tr(),
                      route: '/dev', // Developer menu has admin upload tools
                      subtitle:
                          'admin_drawer_menu_admin_upload_tools_subtitle'.tr(),
                    ),

                    const Divider(height: 16),

                    // Support & Account Section
                    _buildSectionHeader('admin_drawer_section_support'.tr()),
                    _buildDrawerItem(
                      context,
                      icon: Icons.logout,
                      title: 'admin_drawer_menu_logout'.tr(),
                      onTap: () => _handleLogout(context),
                      isDestructive: true,
                    ),
                    const SizedBox(height: 16), // Bottom padding
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    String? route,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : _headerColor;

    return ListTile(
      leading: Icon(
        icon,
        color: color,
        size: 22, // Reduced icon size
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.black87,
          fontSize: 14, // Reduced font size
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
              ),
            )
          : null,
      onTap: onTap ??
          () {
            Navigator.pop(context); // Close drawer
            if (route != null) {
              Navigator.pushNamed(context, route);
            }
          },
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      hoverColor: color.withValues(alpha: 0.1),
      splashColor: color.withValues(alpha: 0.2),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: _headerColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    Navigator.pop(context); // Close drawer
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('admin_drawer_logout_dialog_title'.tr()),
        content: Text('admin_drawer_logout_dialog_content'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('admin_drawer_logout_dialog_cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Handle logout logic using AuthService from artbeat_core
                final authService = AuthService();
                await authService.signOut();

                // Navigate to login screen
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/admin/login',
                    (route) => false,
                  );
                }
              } catch (e) {
                // Handle logout error
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('admin_drawer_logout_error'
                          .tr(namedArgs: {'error': e.toString()})),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text('admin_drawer_logout_dialog_confirm'.tr()),
          ),
        ],
      ),
    );
  }
}
