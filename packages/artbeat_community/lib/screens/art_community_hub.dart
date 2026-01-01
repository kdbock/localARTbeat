// ✅ Local ARTbeat theme pass for this Community Hub file.
// Drop-in update: keeps your logic/services intact, but replaces the
// “basic Material” look with the new DARK + GLASS + GRADIENT HUD style.
//
// What changed:
// - World background (dark gradient + subtle blobs) behind everything
// - Glass HUD AppBar (no big bright gradient slab)
// - Glass drawer (pill items, section headers, footer)
// - Search dialog + create group dialog converted to glass
// - Tabs converted to glass strip, better contrast
// - Group cards + commission list tiles converted to glass cards
//
// NOTE: This file assumes `ArtbeatColors` still exists, but we purposely
// anchor the new look with local constants below to avoid relying on old palette.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../models/art_models.dart';
import '../models/post_model.dart';
import '../services/art_community_service.dart';
import '../src/services/moderation_service.dart';
import '../widgets/enhanced_post_card.dart';
import '../widgets/activity_card.dart';
import '../widgets/mini_artist_card.dart';
import '../widgets/comments_modal.dart';
import '../widgets/commission_artists_browser.dart';
import '../widgets/fullscreen_image_viewer.dart';
import '../widgets/drawer_section.dart' as lab_drawer;
import 'package:artbeat_core/artbeat_core.dart';
import 'package:google_fonts/google_fonts.dart';

import 'artist_onboarding_screen.dart';
import 'artist_feed_screen.dart';
import 'feed/comments_screen.dart';
import 'feed/create_post_screen.dart';
import 'package:artbeat_artist/src/services/community_service.dart'
    as artist_community;
import 'package:artbeat_art_walk/artbeat_art_walk.dart' as art_walk;
import 'package:artbeat_core/shared_widgets.dart';

import 'feed/trending_content_screen.dart';
import 'feed/group_feed_screen.dart';
import 'feed/social_engagement_demo_screen.dart';
import 'posts/user_posts_screen.dart';
import 'settings/quiet_mode_screen.dart';
import '../models/direct_commission_model.dart';
import '../services/direct_commission_service.dart';

/// ------------------------------------------------------------
/// Local ARTbeat visual tokens (do not depend on old theme)
/// ------------------------------------------------------------
class _LAB {
  // World
  static const Color world0 = Color(0xFF07060F);

  // Accents
  static const Color teal = Color(0xFF22D3EE);
  static const Color green = Color(0xFF34D399);
  static const Color purple = Color(0xFF7C4DFF);
  static const Color pink = Color(0xFFFF3D8D);
  static const Color yellow = Color(0xFFFFC857);

  // Text on dark
  static const Color textPrimary = Color(0xF2FFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color textTertiary = Color(0x73FFFFFF);

  // Glass
  static Color glassFill([double a = 0.08]) =>
      Colors.white.withValues(alpha: a);
  static Color glassBorder([double a = 0.14]) =>
      Colors.white.withValues(alpha: a);
}

/// ------------------------------------------------------------
/// Background + Glass primitives
/// ------------------------------------------------------------
class _WorldBackground extends StatelessWidget {
  const _WorldBackground({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return WorldBackground(child: child);
  }
}

class _Glass extends StatelessWidget {
  const _Glass({
    required this.child,
    this.padding,
    this.radius = 24,
    this.blur = 18,
    this.fillAlpha = 0.08,
    this.borderAlpha = 0.14,
  });

  final Widget child;
  final EdgeInsets? padding;
  final double radius;
  final double blur;
  final double fillAlpha;
  final double borderAlpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: _LAB.teal.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: GlassCard(
        padding: padding ?? const EdgeInsets.all(16),
        borderRadius: radius,
        blur: blur,
        glassOpacity: fillAlpha,
        borderOpacity: borderAlpha,
        child: child,
      ),
    );
  }
}

class _GradientIconChip extends StatelessWidget {
  const _GradientIconChip({required this.icon, this.size = 40});
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_LAB.purple, _LAB.teal, _LAB.green],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _LAB.purple.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.55),
    );
  }
}

class _PillTile extends StatelessWidget {
  const _PillTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.selected = false,
    this.accent = _LAB.teal,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool selected;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final fill = selected ? 0.14 : 0.08;
    final border = selected ? 0.22 : 0.14;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: _Glass(
          radius: 18,
          blur: 14,
          fillAlpha: fill,
          borderAlpha: border,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: selected ? 0.22 : 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: accent.withValues(alpha: selected ? 0.35 : 0.22),
                  ),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _LAB.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _LAB.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _LAB.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// Your existing logic stays below (PostLoadingMixin etc.)
/// ------------------------------------------------------------

// Mixin for shared post loading logic
mixin PostLoadingMixin<T extends StatefulWidget> on State<T> {
  List<PostModel> posts = [];
  List<PostModel> filteredPosts = [];
  bool isLoading = true;
  final ModerationService moderationService = ModerationService();

  Future<void> loadPosts(
    ArtCommunityService communityService, {
    int limit = 20,
  }) async {
    setState(() => isLoading = true);

    try {
      AppLogger.info('📱 Loading posts from community service...');

      final loadedPosts = await communityService.getFeed(limit: limit);

      AppLogger.info('📱 Loaded ${loadedPosts.length} posts');

      // Filter out posts from blocked users
      List<PostModel> filtered = loadedPosts;
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        try {
          final blockedUserIds = await moderationService.getBlockedUsers(
            currentUser.uid,
          );

          if (blockedUserIds.isNotEmpty) {
            filtered = loadedPosts
                .where((post) => !blockedUserIds.contains(post.userId))
                .toList();
            AppLogger.info(
              '📱 Filtered out ${loadedPosts.length - filtered.length} posts from blocked users',
            );
          }
        } catch (e) {
          AppLogger.error('📱 Error filtering blocked users: $e');
        }
      }

      if (mounted) {
        setState(() {
          posts = filtered;
          filteredPosts = filtered;
          isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('📱 Error loading posts: $e');
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading posts: $e')));
      }
    }
  }

  void filterPosts(String searchQuery) {
    setState(() {
      if (searchQuery.isEmpty) {
        filteredPosts = posts;
      } else {
        filteredPosts = posts.where((post) {
          final content = post.content.toLowerCase();
          final authorName = post.userName.toLowerCase();
          final location = post.location.toLowerCase();

          return content.contains(searchQuery) ||
              authorName.contains(searchQuery) ||
              location.contains(searchQuery);
        }).toList();
      }
    });
  }
}

/// ------------------------------------------------------------
/// CommissionsTab – themed
/// ------------------------------------------------------------
class CommissionsTab extends StatefulWidget {
  const CommissionsTab({super.key});

  @override
  State<CommissionsTab> createState() => _CommissionsTabState();
}

class _CommissionsTabState extends State<CommissionsTab>
    with SingleTickerProviderStateMixin {
  final DirectCommissionService _commissionService = DirectCommissionService();
  late final TabController _tabController;
  List<DirectCommissionModel> _commissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCommissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCommissions() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final commissions = await _commissionService.getCommissionsByUser(
        user.uid,
      );
      setState(() {
        _commissions = commissions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'community_hub_error_loading_commissions'.tr().replaceAll(
              '{error}',
              e.toString(),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _Glass(
            radius: 18,
            blur: 14,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: _LAB.glassFill(0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _LAB.glassBorder(0.22)),
              ),
              labelColor: _LAB.textPrimary,
              unselectedLabelColor: _LAB.textSecondary,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(fontWeight: FontWeight.w900),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
              tabs: [
                Tab(text: 'community_hub_commission_tab_active'.tr()),
                Tab(text: 'community_hub_commission_tab_pending'.tr()),
                Tab(text: 'community_hub_commission_tab_completed'.tr()),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_LAB.teal),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCommissionList(
                      _commissions
                          .where(
                            (c) =>
                                c.status == CommissionStatus.inProgress ||
                                c.status == CommissionStatus.accepted ||
                                c.status == CommissionStatus.quoted,
                          )
                          .toList(),
                    ),
                    _buildCommissionList(
                      _commissions
                          .where((c) => c.status == CommissionStatus.pending)
                          .toList(),
                    ),
                    _buildCommissionList(
                      _commissions
                          .where(
                            (c) =>
                                c.status == CommissionStatus.completed ||
                                c.status == CommissionStatus.delivered,
                          )
                          .toList(),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildCommissionList(List<DirectCommissionModel> commissions) {
    if (commissions.isEmpty) {
      return Center(
        child: Text(
          'community_hub_no_commissions'.tr(),
          style: const TextStyle(
            color: _LAB.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      itemCount: commissions.length,
      itemBuilder: (context, index) {
        final commission = commissions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => _showCommissionDetails(commission),
            child: _Glass(
              radius: 22,
              blur: 16,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const _GradientIconChip(icon: Icons.handshake, size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          commission.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _LAB.textPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${commission.status.displayName} • \$${commission.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: _LAB.textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: _LAB.textTertiary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCommissionDetails(DirectCommissionModel commission) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: _Glass(
          radius: 26,
          blur: 18,
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const _GradientIconChip(icon: Icons.receipt_long, size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'community_hub_commission_dialog_title'.tr(),
                      style: const TextStyle(
                        color: _LAB.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: _LAB.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _detailRow(
                'community_hub_commission_detail_id'.tr(),
                commission.id,
              ),
              _detailRow(
                'community_hub_commission_detail_title'.tr(),
                commission.title,
              ),
              _detailRow(
                'community_hub_commission_detail_client'.tr(),
                commission.clientName,
              ),
              _detailRow(
                'community_hub_commission_detail_artist'.tr(),
                commission.artistName,
              ),
              _detailRow(
                'community_hub_commission_detail_type'.tr(),
                commission.type.displayName,
              ),
              _detailRow(
                'community_hub_commission_detail_total'.tr(),
                '\$${commission.totalPrice.toStringAsFixed(2)}',
              ),
              _detailRow(
                'community_hub_commission_detail_status'.tr(),
                commission.status.displayName,
              ),
              _detailRow(
                'community_hub_commission_detail_requested'.tr(),
                commission.requestedAt.toString(),
              ),
              if (commission.deadline != null)
                _detailRow(
                  'community_hub_commission_detail_deadline'.tr(),
                  commission.deadline.toString(),
                ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: HudButton.secondary(
                  onPressed: () => Navigator.pop(context),
                  text: 'common_close'.tr(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: _LAB.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _LAB.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ------------------------------------------------------------
/// ArtCommunityHub – themed scaffold + drawer + HUD + tabs
/// ------------------------------------------------------------
class ArtCommunityHub extends StatefulWidget {
  const ArtCommunityHub({super.key});

  @override
  State<ArtCommunityHub> createState() => _ArtCommunityHubState();
}

class _ArtCommunityHubState extends State<ArtCommunityHub>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ArtCommunityService _communityService;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _communityService = ArtCommunityService();
    _checkAuthStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _communityService.dispose();
    super.dispose();
  }

  void _checkAuthStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      AppLogger.info('🔐 User is authenticated: ${user.uid} (${user.email})');
    } else {
      AppLogger.error('🔐 User is NOT authenticated');
    }
  }

  void _showSearchDialog() {
    final currentTab = _tabController.index;
    final tabLabels = [
      'community_hub_tab_feed'.tr(),
      'community_hub_tab_art_battle'.tr(),
      'community_hub_tab_artists'.tr(),
      'community_hub_tab_commissions'.tr(),
    ];
    final tabName = tabLabels[currentTab];

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: _Glass(
            radius: 26,
            blur: 18,
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const _GradientIconChip(icon: Icons.search, size: 42),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'community_hub_search_title'.tr(args: [tabName]),
                        style: const TextStyle(
                          color: _LAB.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: _LAB.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _Glass(
                  radius: 18,
                  blur: 14,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: _searchController,
                    enableInteractiveSelection: false,
                    style: const TextStyle(
                      color: _LAB.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: 'community_hub_search_hint'.tr(),
                      hintStyle: const TextStyle(
                        color: _LAB.textTertiary,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(Icons.search, color: _LAB.teal),
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value.toLowerCase());
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'community_hub_search_scope'.tr(args: [tabName]),
                    style: const TextStyle(
                      color: _LAB.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: HudButton.secondary(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          Navigator.of(context).pop();
                        },
                        text: 'community_hub_search_clear'.tr(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: HudButton.primary(
                        onPressed: () => Navigator.of(context).pop(),
                        text: 'community_hub_search_cta'.tr(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _closeDrawerAnd(VoidCallback action) {
    Navigator.pop(context);
    Future.delayed(const Duration(milliseconds: 220), action);
  }

  Widget _buildDrawer() {
    final footerTitle = 'community_hub_drawer_footer_title'.tr();
    final footerVersion = 'community_hub_drawer_version'.tr(args: ['v2.0.5']);

    return Drawer(
      backgroundColor: _LAB.world0,
      child: SafeArea(
        child: _WorldBackground(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: _Glass(
                  radius: 26,
                  blur: 18,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const _GradientIconChip(icon: Icons.people, size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'community_hub_drawer_brand_title'.tr(),
                              style: const TextStyle(
                                color: _LAB.textPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'community_hub_drawer_brand_tagline'.tr(),
                              style: const TextStyle(
                                color: _LAB.textSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 18),
                  children: [
                    lab_drawer.DrawerSection(
                      title: 'community_hub_drawer_section_main_feeds'.tr(),
                    ),
                    _PillTile(
                      icon: Icons.feed,
                      title: 'community_hub_drawer_item_feed_title'.tr(),
                      subtitle: 'community_hub_drawer_item_feed_subtitle'.tr(),
                      selected: _tabController.index == 0,
                      accent: _LAB.teal,
                      onTap: () =>
                          _closeDrawerAnd(() => _tabController.animateTo(0)),
                    ),
                    _PillTile(
                      icon: Icons.trending_up,
                      title: 'community_hub_drawer_item_trending_title'.tr(),
                      subtitle: 'community_hub_drawer_item_trending_subtitle'
                          .tr(),
                      accent: _LAB.yellow,
                      onTap: () => _navigateToScreen('TrendingContentScreen'),
                    ),
                    lab_drawer.DrawerSection(
                      title: 'community_hub_drawer_section_create'.tr(),
                    ),
                    _PillTile(
                      icon: Icons.add_circle,
                      title: 'community_hub_drawer_item_create_post_title'.tr(),
                      subtitle: 'community_hub_drawer_item_create_post_subtitle'
                          .tr(),
                      accent: _LAB.pink,
                      onTap: () => _navigateToScreen('CreatePostScreen'),
                    ),
                    _PillTile(
                      icon: Icons.group_add,
                      title: 'community_hub_drawer_item_create_group_title'
                          .tr(),
                      subtitle:
                          'community_hub_drawer_item_create_group_subtitle'
                              .tr(),
                      accent: _LAB.purple,
                      onTap: () => _closeDrawerAnd(_showGroupPostDialog),
                    ),
                    lab_drawer.DrawerSection(
                      title: 'community_hub_drawer_section_artists'.tr(),
                    ),
                    _PillTile(
                      icon: Icons.palette,
                      title: 'community_hub_drawer_item_artists_gallery_title'
                          .tr(),
                      subtitle:
                          'community_hub_drawer_item_artists_gallery_subtitle'
                              .tr(),
                      selected: _tabController.index == 1,
                      accent: _LAB.purple,
                      onTap: () =>
                          _closeDrawerAnd(() => _tabController.animateTo(1)),
                    ),
                    _PillTile(
                      icon: Icons.person_add,
                      title: 'community_hub_drawer_item_artist_onboarding_title'
                          .tr(),
                      subtitle:
                          'community_hub_drawer_item_artist_onboarding_subtitle'
                              .tr(),
                      accent: _LAB.teal,
                      onTap: () => _navigateToScreen('ArtistOnboardingScreen'),
                    ),
                    lab_drawer.DrawerSection(
                      title: 'community_hub_drawer_section_discover'.tr(),
                    ),
                    _PillTile(
                      icon: Icons.topic,
                      title: 'community_hub_drawer_item_topics_title'.tr(),
                      subtitle: 'community_hub_drawer_item_topics_subtitle'
                          .tr(),
                      selected: _tabController.index == 2,
                      accent: _LAB.green,
                      onTap: () =>
                          _closeDrawerAnd(() => _tabController.animateTo(2)),
                    ),
                    lab_drawer.DrawerSection(
                      title: 'community_hub_drawer_section_my_content'.tr(),
                    ),
                    _PillTile(
                      icon: Icons.person,
                      title: 'community_hub_drawer_item_my_posts_title'.tr(),
                      subtitle: 'community_hub_drawer_item_my_posts_subtitle'
                          .tr(),
                      accent: _LAB.teal,
                      onTap: () => _navigateToScreen('UserPostsScreen'),
                    ),
                    lab_drawer.DrawerSection(
                      title: 'community_hub_drawer_section_tools'.tr(),
                    ),
                    _PillTile(
                      icon: Icons.settings,
                      title: 'community_hub_drawer_item_quiet_mode_title'.tr(),
                      subtitle: 'community_hub_drawer_item_quiet_mode_subtitle'
                          .tr(),
                      accent: _LAB.yellow,
                      onTap: () => _navigateToScreen('QuietModeScreen'),
                    ),
                    _PillTile(
                      icon: Icons.analytics,
                      title: 'community_hub_drawer_item_social_title'.tr(),
                      subtitle: 'community_hub_drawer_item_social_subtitle'
                          .tr(),
                      accent: _LAB.pink,
                      onTap: () =>
                          _navigateToScreen('SocialEngagementDemoScreen'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _Glass(
                  radius: 18,
                  blur: 14,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: _LAB.textTertiary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          footerTitle,
                          style: const TextStyle(
                            color: _LAB.textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          footerVersion,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _LAB.textTertiary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToScreen(String screenClassName) {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    navigator.pop();

    Widget? screen;
    switch (screenClassName) {
      case 'TrendingContentScreen':
        screen = const TrendingContentScreen();
        break;
      case 'UserPostsScreen':
        screen = const UserPostsScreen();
        break;
      case 'QuietModeScreen':
        screen = const QuietModeScreen();
        break;
      case 'SocialEngagementDemoScreen':
        screen = const SocialEngagementDemoScreen();
        break;
      case 'ArtistOnboardingScreen':
        screen = const ArtistOnboardingScreen();
        break;
      case 'CreatePostScreen':
        screen = const CreatePostScreen();
        break;
      default:
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'community_hub_navigation_unavailable'.tr(
                args: [screenClassName],
              ),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
    }

    Future.delayed(const Duration(milliseconds: 220), () {
      navigator.push<Widget>(
        MaterialPageRoute<Widget>(builder: (context) => screen!),
      );
    });
  }

  void _showGroupPostDialog() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: _Glass(
          radius: 26,
          blur: 18,
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const _GradientIconChip(icon: Icons.group_add, size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'community_hub_group_post_title'.tr(),
                      style: const TextStyle(
                        color: _LAB.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: _LAB.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'community_hub_group_post_prompt'.tr(),
                style: const TextStyle(
                  color: _LAB.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: HudButton.secondary(
                      onPressed: () => Navigator.pop(context),
                      text: 'common_cancel'.tr(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: HudButton.primary(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => const CreatePostScreen(),
                          ),
                        );
                      },
                      text: 'community_hub_group_post_cta'.tr(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildHudAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(110),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          child: ClipRect(
            clipBehavior: Clip.hardEdge,
            child: Column(
              children: [
                // HUD row
                _Glass(
                  radius: 24,
                  blur: 16,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                  child: Row(
                    children: [
                      Builder(
                        builder: (context) => IconButton(
                          onPressed: () => Scaffold.of(context).openDrawer(),
                          icon: const Icon(Icons.menu, color: _LAB.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const _GradientIconChip(icon: Icons.people, size: 40),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'community_hub_title'.tr(),
                              style: const TextStyle(
                                color: _LAB.textPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'community_hub_subtitle'.tr(),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _LAB.textSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _showSearchDialog,
                        icon: const Icon(Icons.search, color: _LAB.textPrimary),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 0),

                // Tabs strip
                SizedBox(
                  height: 48,
                  child: _Glass(
                    radius: 18,
                    blur: 14,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: TabBar(
                      controller: _tabController,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: _LAB.glassFill(0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _LAB.glassBorder(0.22)),
                      ),
                      labelColor: _LAB.textPrimary,
                      unselectedLabelColor: _LAB.textSecondary,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                      tabs: [
                        Tab(
                          text: 'community_hub_tab_feed'.tr(),
                          icon: const Icon(Icons.feed, size: 16),
                        ),
                        Tab(
                          text: 'community_hub_tab_art_battle'.tr(),
                          icon: const Icon(Icons.sports_kabaddi, size: 16),
                        ),
                        Tab(
                          text: 'community_hub_tab_artists'.tr(),
                          icon: const Icon(Icons.palette, size: 16),
                        ),
                        Tab(
                          text: 'community_hub_tab_commissions'.tr(),
                          icon: const Icon(Icons.work, size: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFab() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_LAB.purple, _LAB.teal, _LAB.green],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _LAB.purple.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => const CreatePostScreen(),
            ),
          ).then((_) => setState(() {}));
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final hubTheme = baseTheme.copyWith(
      textTheme: GoogleFonts.spaceGroteskTextTheme(baseTheme.textTheme),
    );

    return Theme(
      data: hubTheme,
      child: Scaffold(
        backgroundColor: _LAB.world0,
        appBar: _buildHudAppBar(),
        drawer: _buildDrawer(),
        body: _WorldBackground(
          child: TabBarView(
            controller: _tabController,
            children: [
              CommunityFeedTab(
                communityService: _communityService,
                searchQuery: _searchQuery,
              ),
              const ArtBattleTab(),
              ArtistsGalleryTab(
                communityService: _communityService,
                searchQuery: _searchQuery,
              ),
              const CommissionsTab(),
            ],
          ),
        ),
        floatingActionButton: _buildFab(),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// Feed tab – minimal theme touch (background is now dark)
/// Your EnhancedPostCard/ActivityCard should ideally also be themed,
/// but this makes the container + empty states match.
/// ------------------------------------------------------------
class CommunityFeedTab extends StatefulWidget {
  final ArtCommunityService communityService;
  final String searchQuery;

  const CommunityFeedTab({
    super.key,
    required this.communityService,
    this.searchQuery = '',
  });

  @override
  State<CommunityFeedTab> createState() => _CommunityFeedTabState();
}

class _CommunityFeedTabState extends State<CommunityFeedTab>
    with PostLoadingMixin {
  List<art_walk.SocialActivity> _activities = [];
  bool _showActivities = true;
  List<dynamic> _feedItems = [];

  @override
  void initState() {
    super.initState();
    loadPosts(widget.communityService);
    _loadActivities();
  }

  @override
  Future<void> loadPosts(
    ArtCommunityService communityService, {
    int limit = 20,
  }) async {
    await super.loadPosts(communityService, limit: limit);
    _combineFeedItems();
  }

  @override
  void didUpdateWidget(CommunityFeedTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      filterPosts(widget.searchQuery.toLowerCase());
      _combineFeedItems();
    }
  }

  Future<void> _loadActivities() async {
    try {
      final socialService = art_walk.SocialService();
      final user = FirebaseAuth.instance.currentUser;

      List<art_walk.SocialActivity> activities = [];
      if (user != null) {
        final userActivities = await socialService.getUserActivities(
          userId: user.uid,
          limit: 10,
        );
        activities = userActivities;

        if (activities.length < 5) {
          try {
            final userPosition = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.medium,
              ),
            );
            final nearbyActivities = await socialService.getNearbyActivities(
              userPosition: userPosition,
              radiusKm: 80.0,
              limit: 10,
            );

            final ids = activities.map((a) => a.id).toSet();
            for (final a in nearbyActivities) {
              if (!ids.contains(a.id)) activities.add(a);
            }
          } catch (_) {}
        }
      }

      // Filter out RSS-like items (your existing logic)
      final filteredActivities = activities.where((activity) {
        final activityType = activity.type.toString().toLowerCase();
        final isRssFeed =
            activityType.contains('rss') ||
            activityType.contains('feed') ||
            activityType.contains('news');

        final message = activity.message.toLowerCase();
        final hasRssIndicators =
            message.contains('rss') ||
            message.contains('news feed') ||
            message.contains('political news') ||
            message.contains('news sports');

        return !isRssFeed && !hasRssIndicators;
      }).toList();

      if (mounted) {
        setState(() => _activities = filteredActivities);
        _combineFeedItems();
      }
    } catch (e) {
      AppLogger.error('📱 Error loading activities: $e');
    }
  }

  void _combineFeedItems() {
    final combinedItems = <dynamic>[];
    combinedItems.addAll(filteredPosts);
    if (_showActivities) combinedItems.addAll(_activities);

    combinedItems.sort((a, b) {
      DateTime timeA, timeB;

      if (a is PostModel) {
        timeA = a.createdAt;
      } else if (a is art_walk.SocialActivity) {
        timeA = a.timestamp;
      } else {
        return 0;
      }

      if (b is PostModel) {
        timeB = b.createdAt;
      } else if (b is art_walk.SocialActivity) {
        timeB = b.timestamp;
      } else {
        return 0;
      }

      return timeB.compareTo(timeA);
    });

    setState(() => _feedItems = combinedItems);
  }

  void _toggleActivitiesFilter() {
    setState(() {
      _showActivities = !_showActivities;
      _combineFeedItems();
    });
  }

  // --- your existing handlers remain unchanged below ---
  void _handlePostTap(PostModel post) => _showPostDetailDialog(post);

  void _showPostDetailDialog(PostModel post) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(14),
        child: _Glass(
          radius: 26,
          blur: 18,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: ImageUrlValidator.safeNetworkImage(
                      post.userPhotoUrl,
                    ),
                    child: !ImageUrlValidator.isValidImageUrl(post.userPhotoUrl)
                        ? Text(
                            post.userName.isNotEmpty
                                ? post.userName[0].toUpperCase()
                                : '?',
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.userName,
                          style: const TextStyle(
                            color: _LAB.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          _formatPostTime(post.createdAt),
                          style: const TextStyle(
                            color: _LAB.textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: _LAB.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    post.content,
                    style: const TextStyle(
                      color: _LAB.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _Glass(
                radius: 18,
                blur: 14,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _miniAction(
                      icon: post.isLikedByCurrentUser
                          ? Icons.favorite
                          : Icons.favorite_border,
                      label: 'community_hub_post_action_like'.tr(),
                      color: post.isLikedByCurrentUser ? _LAB.pink : _LAB.teal,
                      onTap: () {
                        Navigator.pop(context);
                        _handleLike(post);
                      },
                    ),
                    _miniAction(
                      icon: Icons.comment,
                      label: 'community_hub_post_action_comment'.tr(),
                      color: _LAB.green,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => CommentsScreen(post: post),
                          ),
                        );
                      },
                    ),
                    _miniAction(
                      icon: Icons.share,
                      label: 'community_hub_post_action_share'.tr(),
                      color: _LAB.yellow,
                      onTap: () {
                        Navigator.pop(context);
                        _handleShare(post);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: _LAB.textSecondary,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPostTime(DateTime postTime) {
    final now = DateTime.now();
    final difference = now.difference(postTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      final plural = years > 1 ? 's' : '';
      return 'community_hub_time_years_ago'
          .tr()
          .replaceAll('{count}', years.toString())
          .replaceAll('{plural}', plural);
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      final plural = months > 1 ? 's' : '';
      return 'community_hub_time_months_ago'
          .tr()
          .replaceAll('{count}', months.toString())
          .replaceAll('{plural}', plural);
    } else if (difference.inDays > 0) {
      final plural = difference.inDays > 1 ? 's' : '';
      return 'community_hub_time_days_ago'
          .tr()
          .replaceAll('{count}', difference.inDays.toString())
          .replaceAll('{plural}', plural);
    } else if (difference.inHours > 0) {
      final plural = difference.inHours > 1 ? 's' : '';
      return 'community_hub_time_hours_ago'
          .tr()
          .replaceAll('{count}', difference.inHours.toString())
          .replaceAll('{plural}', plural);
    } else if (difference.inMinutes > 0) {
      final plural = difference.inMinutes > 1 ? 's' : '';
      return 'community_hub_time_minutes_ago'
          .tr()
          .replaceAll('{count}', difference.inMinutes.toString())
          .replaceAll('{plural}', plural);
    } else {
      return 'community_hub_time_just_now'.tr();
    }
  }

  // Like/comment/share functions unchanged (keep yours)
  void _handleLike(PostModel post) async {
    // keep your existing implementation
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('community_hub_sign_in_like'.tr())),
        );
        return;
      }

      final postIndex = posts.indexWhere((p) => p.id == post.id);
      if (postIndex != -1) {
        setState(() {
          final currentLikeCount = posts[postIndex].engagementStats.likeCount;
          final isCurrentlyLiked = posts[postIndex].isLikedByCurrentUser;

          final newEngagementStats = EngagementStats(
            likeCount: isCurrentlyLiked
                ? currentLikeCount - 1
                : currentLikeCount + 1,
            commentCount: posts[postIndex].engagementStats.commentCount,
            shareCount: posts[postIndex].engagementStats.shareCount,
            lastUpdated: DateTime.now(),
          );

          posts[postIndex] = posts[postIndex].copyWith(
            isLikedByCurrentUser: !isCurrentlyLiked,
            engagementStats: newEngagementStats,
          );
        });
      }

      final success = await widget.communityService.toggleLike(post.id);

      if (!mounted) return;

      if (!success && postIndex != -1) {
        setState(() {
          final currentLikeCount = posts[postIndex].engagementStats.likeCount;
          final isCurrentlyLiked = posts[postIndex].isLikedByCurrentUser;

          final revertedEngagementStats = EngagementStats(
            likeCount: isCurrentlyLiked
                ? currentLikeCount - 1
                : currentLikeCount + 1,
            commentCount: posts[postIndex].engagementStats.commentCount,
            shareCount: posts[postIndex].engagementStats.shareCount,
            lastUpdated: DateTime.now(),
          );

          posts[postIndex] = posts[postIndex].copyWith(
            isLikedByCurrentUser: !isCurrentlyLiked,
            engagementStats: revertedEngagementStats,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('community_hub_like_failed'.tr())),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('community_hub_error_like'.tr())));
    }
  }

  void _handleComment(PostModel post) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('community_hub_sign_in_comment'.tr())),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsModal(
        post: post,
        communityService: widget.communityService,
        onCommentAdded: () => loadPosts(widget.communityService),
      ),
    );
  }

  void _handleShare(PostModel post) async {
    // keep your existing implementation
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('community_hub_sign_in_share'.tr())),
        );
        return;
      }

      final shareIntro = 'community_hub_share_intro'.tr();
      final shareOriginal = 'community_hub_share_original'.tr();
      String shareContent = '$shareIntro\n\n';
      if (post.content.isNotEmpty) {
        shareContent += '"${post.content}"\n\n';
      }
      shareContent += '$shareOriginal ${post.userName}';

      if (post.location.isNotEmpty) {
        shareContent += ' • ${post.location}';
      }

      if (post.tags.isNotEmpty) {
        shareContent += '\n\n${post.tags.map((tag) => '#$tag').join(' ')}';
      }

      final postId = await widget.communityService.createPost(
        content: shareContent,
        imageUrls: post.imageUrls,
        tags: post.tags,
        isArtistPost: false,
      );

      if (postId != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('community_hub_share_success'.tr())),
          );
        }
        await loadPosts(widget.communityService);
        widget.communityService.incrementShareCount(post.id);
      } else {
        throw Exception('Failed to create shared post');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('community_hub_share_failed'.tr())),
        );
      }
    }
  }

  void _handleEdit(PostModel post) {
    // Navigate to create post screen with post to edit
    Navigator.of(context).push(
      MaterialPageRoute<Widget>(
        builder: (context) => CreatePostScreen(postToEdit: post),
      ),
    );
  }

  void _handleDelete(PostModel post) async {
    try {
      final success = await widget.communityService.deletePost(post.id);
      if (success) {
        // Remove from local list
        setState(() {
          posts.removeWhere((p) => p.id == post.id);
          filteredPosts.removeWhere((p) => p.id == post.id);
          _feedItems.removeWhere(
            (item) => item is PostModel && item.id == post.id,
          );
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post deleted successfully')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete post')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error deleting post')));
      }
    }
  }

  void _showFullscreenImage(
    String imageUrl,
    int initialIndex,
    List<String> allImages,
  ) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) => FullscreenImageViewer(
        imageUrls: allImages,
        initialIndex: initialIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_LAB.teal),
        ),
      );
    }

    if (_feedItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: _Glass(
            radius: 28,
            blur: 18,
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _GradientIconChip(icon: Icons.palette_outlined, size: 52),
                const SizedBox(height: 14),
                Text(
                  'community_hub_no_posts'.tr(),
                  style: const TextStyle(
                    color: _LAB.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'community_hub_no_posts_subtitle'.tr(),
                  style: const TextStyle(
                    color: _LAB.textSecondary,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'community_hub_show_activities'.tr(),
                      style: const TextStyle(
                        color: _LAB.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Switch(
                      value: _showActivities,
                      onChanged: (_) => _toggleActivitiesFilter(),
                      activeThumbColor: _LAB.teal,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await loadPosts(widget.communityService);
        await _loadActivities();
      },
      color: _LAB.teal,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: _Glass(
                radius: 18,
                blur: 14,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'community_hub_show_activities'.tr(),
                      style: const TextStyle(
                        color: _LAB.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Switch(
                      value: _showActivities,
                      onChanged: (_) => _toggleActivitiesFilter(),
                      activeThumbColor: _LAB.teal,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = _feedItems[index];

                if (item is PostModel) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: EnhancedPostCard(
                      post: item,
                      onTap: () => _handlePostTap(item),
                      onLike: () => _handleLike(item),
                      onComment: () => _handleComment(item),
                      onShare: () => _handleShare(item),
                      onImageTap: (String imageUrl, int imgIndex) =>
                          _showFullscreenImage(
                            imageUrl,
                            imgIndex,
                            item.imageUrls,
                          ),
                      onBlockStatusChanged: () =>
                          loadPosts(widget.communityService),
                      onEdit: () => _handleEdit(item),
                      onDelete: () => _handleDelete(item),
                    ),
                  );
                } else if (item is art_walk.SocialActivity) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ActivityCard(
                      activity: item,
                      onTap: () =>
                          AppLogger.info('Activity tapped: ${item.message}'),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }, childCount: _feedItems.length),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

/// ------------------------------------------------------------
/// ArtistsGalleryTab and GroupsTab:
/// Background is dark now; your existing widgets (MiniArtistCard etc.)
/// should ideally also be themed, but the tabs will still read properly.
/// For GroupsTab, update group cards + dialog below.
/// ------------------------------------------------------------

class ArtistsGalleryTab extends StatefulWidget {
  final ArtCommunityService communityService;
  final String searchQuery;

  const ArtistsGalleryTab({
    super.key,
    required this.communityService,
    this.searchQuery = '',
  });

  @override
  State<ArtistsGalleryTab> createState() => _ArtistsGalleryTabState();
}

class _ArtistsGalleryTabState extends State<ArtistsGalleryTab> {
  List<ArtistProfile> _artists = [];
  List<ArtistProfile> _filteredArtists = [];
  bool _isLoading = true;
  late artist_community.CommunityService _artistCommunityService;

  @override
  void initState() {
    super.initState();
    _artistCommunityService = artist_community.CommunityService();
    _loadArtists();
  }

  @override
  void didUpdateWidget(ArtistsGalleryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      _filterArtists();
    }
  }

  Future<void> _loadArtists() async {
    setState(() => _isLoading = true);
    try {
      final artists = await widget.communityService.fetchArtists(limit: 20);
      if (mounted) {
        setState(() {
          _artists = artists;
          _filteredArtists = artists;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterArtists() {
    setState(() {
      if (widget.searchQuery.isEmpty) {
        _filteredArtists = _artists;
      } else {
        _filteredArtists = _artists.where((artist) {
          final displayName = artist.displayName.toLowerCase();
          final bio = artist.bio.toLowerCase();
          return displayName.contains(widget.searchQuery) ||
              bio.contains(widget.searchQuery);
        }).toList();
      }
    });
  }

  void _handleArtistTap(ArtistProfile artist) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ArtistFeedScreen(
          artistId: artist.userId,
          artistName: artist.displayName,
        ),
      ),
    );
  }

  void _handleFollow(ArtistProfile artist, bool isFollowing) async {
    try {
      final success = isFollowing
          ? await _artistCommunityService.followArtist(artist.userId)
          : await _artistCommunityService.unfollowArtist(artist.userId);

      if (!success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('community_hub_artists_follow_error'.tr()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
        _loadArtists();
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('community_hub_artists_follow_error'.tr()),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      _loadArtists();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_LAB.teal),
        ),
      );
    }

    if (_artists.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: _Glass(
            radius: 28,
            blur: 18,
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _GradientIconChip(icon: Icons.people_outline, size: 52),
                const SizedBox(height: 14),
                Text(
                  'community_hub_artists_empty_title'.tr(),
                  style: const TextStyle(
                    color: _LAB.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'community_hub_artists_empty_subtitle'.tr(),
                  style: const TextStyle(
                    color: _LAB.textSecondary,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                HudButton.primary(
                  onPressed: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute<bool>(
                        builder: (context) => const ArtistOnboardingScreen(),
                      ),
                    );
                    if (result == true && mounted) _loadArtists();
                  },
                  text: 'community_hub_artists_empty_cta'.tr(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadArtists,
      color: _LAB.teal,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: CommissionArtistsBrowser(onCommissionRequest: _loadArtists),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'All Artists',
                style: TextStyle(
                  color: _LAB.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final artist = _filteredArtists[index];
                return MiniArtistCard(
                  artist: artist,
                  onTap: () => _handleArtistTap(artist),
                  onFollow: (isFollowing) => _handleFollow(artist, isFollowing),
                );
              }, childCount: _filteredArtists.length),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

class GroupsTab extends StatefulWidget {
  final ArtCommunityService communityService;
  final String searchQuery;

  const GroupsTab({
    super.key,
    required this.communityService,
    this.searchQuery = '',
  });

  @override
  State<GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<GroupsTab> {
  List<GroupModel> _groups = [];
  List<GroupModel> _filteredGroups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void didUpdateWidget(GroupsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      _filterGroups();
    }
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);
    try {
      final groupsSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .orderBy('memberCount', descending: true)
          .limit(20)
          .get();

      final groups = groupsSnapshot.docs.map((DocumentSnapshot doc) {
        final data = doc.data() as Map<String, dynamic>;
        return GroupModel(
          id: doc.id,
          name: data['name'] as String? ?? 'Unknown',
          description: data['description'] as String? ?? '',
          iconUrl: data['iconUrl'] as String? ?? '',
          memberCount: data['memberCount'] as int? ?? 0,
          postCount: data['postCount'] as int? ?? 0,
          createdBy: data['createdBy'] as String? ?? '',
          color: data['color'] as String? ?? '#8B5CF6',
        );
      }).toList();

      if (mounted) {
        setState(() {
          _groups = groups;
          _filteredGroups = groups;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _groups = [];
          _filteredGroups = [];
          _isLoading = false;
        });
      }
    }
  }

  void _filterGroups() {
    setState(() {
      if (widget.searchQuery.isEmpty) {
        _filteredGroups = _groups;
      } else {
        _filteredGroups = _groups
            .where(
              (group) =>
                  group.name.toLowerCase().contains(
                    widget.searchQuery.toLowerCase(),
                  ) ||
                  group.description.toLowerCase().contains(
                    widget.searchQuery.toLowerCase(),
                  ),
            )
            .toList();
      }
    });
  }

  void _handleGroupTap(GroupModel group) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            GroupFeedScreen(groupId: group.id, groupName: group.name),
      ),
    );
  }

  void _showCreateGroupDialog() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => const CreateGroupDialog(),
    ).then((_) => _loadGroups());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_LAB.teal),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGroups,
      color: _LAB.teal,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: _Glass(
                      radius: 22,
                      blur: 16,
                      padding: EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Groups',
                            style: TextStyle(
                              color: _LAB.textPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Join communities and share your art',
                            style: TextStyle(
                              color: _LAB.textSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_LAB.purple, _LAB.teal, _LAB.green],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: _LAB.purple.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: _showCreateGroupDialog,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            children: [
                              Icon(Icons.add, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Create',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_filteredGroups.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: _Glass(
                    radius: 28,
                    blur: 18,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _GradientIconChip(
                          icon: Icons.group_outlined,
                          size: 52,
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'No groups found',
                          style: TextStyle(
                            color: _LAB.textPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Be the first to create a group!',
                          style: TextStyle(
                            color: _LAB.textSecondary,
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_LAB.purple, _LAB.teal, _LAB.green],
                            ),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(22),
                              onTap: _showCreateGroupDialog,
                              child: const Center(
                                child: Text(
                                  'Create First Group',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.82,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final group = _filteredGroups[index];
                  return _GroupGlassCard(
                    group: group,
                    onTap: () => _handleGroupTap(group),
                  );
                }, childCount: _filteredGroups.length),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ],
      ),
    );
  }
}

class _GroupGlassCard extends StatelessWidget {
  const _GroupGlassCard({required this.group, required this.onTap});
  final GroupModel group;
  final VoidCallback onTap;

  Color _parseColor(String hex, Color fallback) {
    try {
      final clean = hex.replaceFirst('#', '');
      return Color(int.parse(clean, radix: 16) + 0xFF000000);
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _parseColor(group.color, _LAB.purple);

    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: _Glass(
        radius: 26,
        blur: 16,
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: accent.withValues(alpha: 0.28)),
              ),
              child: group.iconUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.network(
                        group.iconUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.group, color: accent),
                      ),
                    )
                  : Icon(Icons.group, color: accent, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              group.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _LAB.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
            if (group.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                group.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _LAB.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _statPill('${group.memberCount}', Icons.people, _LAB.teal),
                const SizedBox(width: 8),
                _statPill('${group.postCount}', Icons.article, _LAB.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statPill(String value, IconData icon, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: _LAB.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 6),
          Icon(icon, size: 14, color: accent),
        ],
      ),
    );
  }
}

/// Model for group data
class GroupModel {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final int memberCount;
  final int postCount;
  final String createdBy;
  final String color;

  const GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.memberCount,
    required this.postCount,
    required this.createdBy,
    required this.color,
  });

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unknown',
      description: map['description'] as String? ?? '',
      iconUrl: map['iconUrl'] as String? ?? '',
      memberCount: map['memberCount'] as int? ?? 0,
      postCount: map['postCount'] as int? ?? 0,
      createdBy: map['createdBy'] as String? ?? '',
      color: map['color'] as String? ?? '#8B5CF6',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'iconUrl': iconUrl,
    'memberCount': memberCount,
    'postCount': postCount,
    'createdBy': createdBy,
    'color': color,
  };
}

/// Dialog for creating new groups – themed glass
class CreateGroupDialog extends StatefulWidget {
  const CreateGroupDialog({super.key});

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to create a group')),
        );
        return;
      }

      final groupRef = await FirebaseFirestore.instance
          .collection('groups')
          .add({
            'name': _nameController.text.trim(),
            'description': _descriptionController.text.trim(),
            'createdBy': user.uid,
            'memberCount': 1,
            'postCount': 0,
            'color': '#8B5CF6',
            'createdAt': FieldValue.serverTimestamp(),
          });

      await FirebaseFirestore.instance.collection('groupMembers').add({
        'groupId': groupRef.id,
        'userId': user.uid,
        'role': 'admin',
        'joinedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group created successfully!')),
        );
      }
    } catch (e) {
      AppLogger.error('Error creating group: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create group. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: _Glass(
        radius: 26,
        blur: 18,
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const _GradientIconChip(icon: Icons.group_add, size: 42),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Create New Group',
                    style: TextStyle(
                      color: _LAB.textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: _LAB.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _Glass(
              radius: 18,
              blur: 14,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: _nameController,
                maxLength: 50,
                enableInteractiveSelection: false,
                style: const TextStyle(
                  color: _LAB.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  counterStyle: TextStyle(color: _LAB.textTertiary),
                  labelText: 'Group Name',
                  labelStyle: TextStyle(
                    color: _LAB.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                  hintText: 'Enter group name',
                  hintStyle: TextStyle(color: _LAB.textTertiary),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _Glass(
              radius: 18,
              blur: 14,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: _descriptionController,
                maxLength: 200,
                maxLines: 3,
                enableInteractiveSelection: false,
                style: const TextStyle(
                  color: _LAB.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  counterStyle: TextStyle(color: _LAB.textTertiary),
                  labelText: 'Description (optional)',
                  labelStyle: TextStyle(
                    color: _LAB.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                  hintText: 'Describe your group',
                  hintStyle: TextStyle(color: _LAB.textTertiary),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: _LAB.textSecondary,
                      textStyle: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_LAB.purple, _LAB.teal, _LAB.green],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: _isLoading ? null : _createGroup,
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Create',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// Art Battle tab – dedicated space for artwork battles
/// ------------------------------------------------------------
class ArtBattleTab extends StatefulWidget {
  const ArtBattleTab({super.key});

  @override
  State<ArtBattleTab> createState() => _ArtBattleTabState();
}

class _ArtBattleTabState extends State<ArtBattleTab> {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _Glass(
              radius: 18,
              blur: 14,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const _GradientIconChip(
                        icon: Icons.sports_kabaddi,
                        size: 40,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Art Battle',
                              style: TextStyle(
                                color: _LAB.textPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              'Vote on head-to-head artwork battles',
                              style: TextStyle(
                                color: _LAB.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/art-battle'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _LAB.teal,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Start Battle'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        // Add current battles list here
        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: _Glass(
              radius: 18,
              blur: 14,
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Current battles will be displayed here',
                  style: TextStyle(color: _LAB.textSecondary),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
