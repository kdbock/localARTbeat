import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final sections = _buildSectionsData()
        .where((section) => section.matches(_searchQuery))
        .toList();

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'help_title'.tr(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: Stack(
        children: [
          _buildWorldBackground(),
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 120, 16, 40),
              child: Column(
                children: [
                  _buildHeroSection(),
                  const SizedBox(height: 20),
                  _buildAssistHub(),
                  const SizedBox(height: 20),
                  _buildSectionList(sections),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    final badges = [
      'Visibility hotline',
      'Priority support',
      'Learning library',
    ];

    return _buildGlassPanel(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
                  ),
                ),
                child: const Icon(
                  Icons.help_outline,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'help_welcome_title'.tr(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'help_welcome_text'.tr(),
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: badges
                .map(
                  (badge) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                    child: Text(
                      badge,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistHub() {
    final quickActions = [
      _QuickAction(
        label: 'help_contact_support'.tr(),
        icon: Icons.support_agent,
        onTap: _contactSupport,
      ),
      _QuickAction(
        label: 'help_report_issue'.tr(),
        icon: Icons.bug_report,
        onTap: _reportIssue,
      ),
      _QuickAction(
        label: 'help_video_tutorials'.tr(),
        icon: Icons.play_circle_fill,
        onTap: _openVideoTutorials,
      ),
      _QuickAction(
        label: 'help_community_forum'.tr(),
        icon: Icons.forum,
        onTap: _openCommunityForum,
      ),
    ];

    return _buildGlassPanel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'help_quick_actions'.tr(),
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _buildSearchField(),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: quickActions
                .map((action) => _buildActionCard(action))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionList(List<_HelpSectionData> sections) {
    if (sections.isEmpty) {
      return _buildGlassPanel(
        child: Column(
          children: [
            const Icon(Icons.search_off, color: Colors.white70, size: 36),
            const SizedBox(height: 12),
            Text(
              'No help topics match your search yet.',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Column(children: sections.map(_buildSectionCard).toList());
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        color: Colors.white.withValues(alpha: 0.05),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        style: GoogleFonts.spaceGrotesk(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'help_search_hint'.tr(),
          hintStyle: GoogleFonts.spaceGrotesk(
            color: Colors.white.withValues(alpha: 0.55),
          ),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: const Icon(Icons.clear, color: Colors.white70),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18),
        ),
      ),
    );
  }

  Widget _buildActionCard(_QuickAction action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minWidth: 140),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          color: Colors.white.withValues(alpha: 0.03),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(action.icon, color: Colors.white, size: 28),
            const SizedBox(height: 10),
            Text(
              action.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(_HelpSectionData section) {
    final filteredItems = _searchQuery.isEmpty
        ? section.items
        : section.items
              .where((item) => item.toLowerCase().contains(_searchQuery))
              .toList();

    if (filteredItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: ExpansionTile(
            backgroundColor: Colors.white.withValues(alpha: 0.04),
            collapsedBackgroundColor: Colors.white.withValues(alpha: 0.02),
            collapsedIconColor: Colors.white,
            iconColor: Colors.white,
            leading: Icon(section.icon, color: Colors.white),
            title: Text(
              section.title,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              section.description,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            children: filteredItems
                .map(
                  (item) => ListTile(
                    title: Text(
                      item,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassPanel({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(24),
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            color: Colors.white.withValues(alpha: 0.05),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildWorldBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF03050F), Color(0xFF09122B), Color(0xFF021B17)],
          ),
        ),
        child: Stack(
          children: [
            _buildGlow(const Offset(-160, -60), Colors.purpleAccent),
            _buildGlow(const Offset(120, 240), Colors.cyanAccent),
            _buildGlow(const Offset(-20, 380), Colors.pinkAccent),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlow(Offset offset, Color color) {
    return Positioned(
      left: offset.dx < 0 ? null : offset.dx,
      right: offset.dx < 0 ? -offset.dx : null,
      top: offset.dy,
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 110,
              spreadRadius: 18,
            ),
          ],
        ),
      ),
    );
  }

  List<_HelpSectionData> _buildSectionsData() {
    return [
      _HelpSectionData(
        title: 'help_section_getting_started'.tr(),
        description: 'help_section_getting_started_desc'.tr(),
        icon: Icons.person_add,
        items: [
          'help_registration'.tr(),
          'help_user_types'.tr(),
          'help_profile_creation'.tr(),
        ],
      ),
      _HelpSectionData(
        title: 'help_section_discovery'.tr(),
        description: 'help_section_discovery_desc'.tr(),
        icon: Icons.explore,
        items: [
          'help_art_walks'.tr(),
          'help_artwork_browsing'.tr(),
          'help_events'.tr(),
          'help_capturing'.tr(),
        ],
      ),
      _HelpSectionData(
        title: 'help_section_artists'.tr(),
        description: 'help_section_artists_desc'.tr(),
        icon: Icons.palette,
        items: [
          'help_artist_dashboard'.tr(),
          'help_gallery_ops'.tr(),
          'help_earnings'.tr(),
          'help_advertising'.tr(),
          'help_subscriptions'.tr(),
        ],
      ),
      _HelpSectionData(
        title: 'help_section_community'.tr(),
        description: 'help_section_community_desc'.tr(),
        icon: Icons.people,
        items: [
          'help_community_feed'.tr(),
          'help_direct_commissions'.tr(),
          'help_studio_system'.tr(),
          'help_profile_features'.tr(),
          'help_messaging'.tr(),
          'help_gifts'.tr(),
        ],
      ),
      _HelpSectionData(
        title: 'help_section_ai'.tr(),
        description: 'help_section_ai_desc'.tr(),
        icon: Icons.auto_awesome,
        items: [
          'help_smart_cropping'.tr(),
          'help_bg_removal'.tr(),
          'help_auto_tagging'.tr(),
          'help_color_palette'.tr(),
          'help_recommendations'.tr(),
          'help_insights'.tr(),
          'help_similar_artwork'.tr(),
        ],
      ),
      _HelpSectionData(
        title: 'help_section_settings'.tr(),
        description: 'help_section_settings_desc'.tr(),
        icon: Icons.security,
        items: [
          'help_account_settings'.tr(),
          'help_privacy_controls'.tr(),
          'help_security_settings'.tr(),
          'help_notification_settings'.tr(),
          'help_blocked_users'.tr(),
        ],
      ),
      _HelpSectionData(
        title: 'help_section_admin'.tr(),
        description: 'help_section_admin_desc'.tr(),
        icon: Icons.admin_panel_settings,
        items: [
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

class _QuickAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

class _HelpSectionData {
  final String title;
  final String description;
  final IconData icon;
  final List<String> items;

  const _HelpSectionData({
    required this.title,
    required this.description,
    required this.icon,
    required this.items,
  });

  bool matches(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return title.toLowerCase().contains(q) ||
        description.toLowerCase().contains(q) ||
        items.any((item) => item.toLowerCase().contains(q));
  }
}
