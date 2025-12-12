import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/artbeat_colors.dart';
import '../widgets/enhanced_universal_header.dart';

/// Help & Support Screen - Comprehensive guide for ARTbeat users
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EnhancedUniversalHeader(
        title: 'help_title'.tr(),
        showLogo: false,
        showBackButton: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'help_search_hint'.tr(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome section
                  _buildWelcomeSection(),
                  const SizedBox(height: 24),

                  // Quick actions
                  _buildQuickActions(),
                  const SizedBox(height: 24),

                  // Help topics
                  ..._buildHelpSections(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ArtbeatColors.primary.withValues(alpha: 0.1),
            ArtbeatColors.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ArtbeatColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.palette, color: ArtbeatColors.primary, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'help_welcome_title'.tr(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ArtbeatColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'help_welcome_subtitle'.tr(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: ArtbeatColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'help_welcome_text'.tr(),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'help_quick_actions'.tr(),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'help_contact_support'.tr(),
                icon: Icons.support_agent,
                onTap: () => _contactSupport(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                title: 'help_report_issue'.tr(),
                icon: Icons.bug_report,
                onTap: () => _reportIssue(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'help_video_tutorials'.tr(),
                icon: Icons.play_circle_fill,
                onTap: () => _openVideoTutorials(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                title: 'help_community_forum'.tr(),
                icon: Icons.forum,
                onTap: () => _openCommunityForum(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: ArtbeatColors.primary),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildHelpSections() {
    final sections = [
      _buildSection(
        'help_section_getting_started'.tr(),
        'help_section_getting_started_desc'.tr(),
        Icons.person_add,
        [
          'help_registration'.tr(),
          'help_user_types'.tr(),
          'help_profile_creation'.tr(),
        ],
      ),
      _buildSection(
        'help_section_discovery'.tr(),
        'help_section_discovery_desc'.tr(),
        Icons.explore,
        [
          'help_art_walks'.tr(),
          'help_artwork_browsing'.tr(),
          'help_events'.tr(),
          'help_capturing'.tr(),
        ],
      ),
      _buildSection(
        'help_section_artists'.tr(),
        'help_section_artists_desc'.tr(),
        Icons.palette,
        [
          'help_artist_dashboard'.tr(),
          'help_gallery_ops'.tr(),
          'help_earnings'.tr(),
          'help_advertising'.tr(),
          'help_subscriptions'.tr(),
        ],
      ),
      _buildSection(
        'help_section_community'.tr(),
        'help_section_community_desc'.tr(),
        Icons.people,
        [
          'help_community_feed'.tr(),
          'help_direct_commissions'.tr(),
          'help_studio_system'.tr(),
          'help_profile_features'.tr(),
          'help_messaging'.tr(),
          'help_gifts'.tr(),
        ],
      ),
      _buildSection(
        'help_section_ai'.tr(),
        'help_section_ai_desc'.tr(),
        Icons.auto_awesome,
        [
          'help_smart_cropping'.tr(),
          'help_bg_removal'.tr(),
          'help_auto_tagging'.tr(),
          'help_color_palette'.tr(),
          'help_recommendations'.tr(),
          'help_insights'.tr(),
          'help_similar_artwork'.tr(),
        ],
      ),
      _buildSection(
        'help_section_settings'.tr(),
        'help_section_settings_desc'.tr(),
        Icons.security,
        [
          'help_account_settings'.tr(),
          'help_privacy_controls'.tr(),
          'help_security_settings'.tr(),
          'help_notification_settings'.tr(),
          'help_blocked_users'.tr(),
        ],
      ),
      _buildSection(
        'help_section_admin'.tr(),
        'help_section_admin_desc'.tr(),
        Icons.admin_panel_settings,
        [
          'help_admin_dashboard'.tr(),
          'help_user_management'.tr(),
          'help_content_moderation'.tr(),
          'help_events_management'.tr(),
          'help_advertising_mgmt'.tr(),
          'help_financial_analytics'.tr(),
          'help_system_admin'.tr(),
        ],
      ),
    ];

    final List<Widget> filteredSections = [];
    for (final section in sections) {
      if (_searchQuery.isEmpty ||
          section.toString().toLowerCase().contains(_searchQuery)) {
        filteredSections.add(section);
      }
    }

    return filteredSections;
  }

  Widget _buildSection(
    String title,
    String description,
    IconData icon,
    List<String> items,
  ) {
    // Filter items based on search query
    List<String> filteredItems = items;
    if (_searchQuery.isNotEmpty) {
      filteredItems = items
          .where((item) => item.toLowerCase().contains(_searchQuery))
          .toList();
    }

    // If search is active and no items match, don't show the section
    if (_searchQuery.isNotEmpty && filteredItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Icon(icon, color: ArtbeatColors.primary),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          description,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: ArtbeatColors.textSecondary),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: filteredItems.map((item) {
                // Highlight search terms
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: ArtbeatColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _contactSupport() async {
    const email = 'support@artbeat.com';
    const subject = 'ARTbeat Support Request';
    final uri = Uri(scheme: 'mailto', path: email, query: 'subject=$subject');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('help_contact_email_error'.tr())),
        );
      }
    }
  }

  Future<void> _reportIssue() async {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('help_report_dialog_title'.tr()),
        content: Text('help_report_dialog_text'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common_ok'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _contactSupport();
            },
            child: Text('help_contact_support_btn'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _openVideoTutorials() async {
    const url = 'https://youtube.com/@artbeat';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('help_video_tutorials_error'.tr())),
        );
      }
    }
  }

  Future<void> _openCommunityForum() async {
    const url = 'https://community.artbeat.com';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('help_forum_error'.tr())));
      }
    }
  }
}
