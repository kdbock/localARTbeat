import 'dart:ui';

import 'package:artbeat_core/artbeat_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'drawer_section.dart' as lab_drawer;

/// Targets that the HUD drawer can navigate to beyond switching tabs.
enum CommunityHudDestination {
  trending,
  artBattle,
  createPost,
  artworkBrowse,
  artistOnboarding,
  leaderboard,
  userPosts,
}

class CommunityHudDrawer extends StatelessWidget {
  const CommunityHudDrawer({
    super.key,
    required this.selectedTabIndex,
    required this.onTabSelected,
    required this.onNavigate,
    required this.closeDrawerAnd,
  });

  final int selectedTabIndex;
  final ValueChanged<int> onTabSelected;
  final ValueChanged<CommunityHudDestination> onNavigate;
  final void Function(VoidCallback action) closeDrawerAnd;

  @override
  Widget build(BuildContext context) {
    final footerTitle = 'community_hub_drawer_footer_title'.tr();
    final footerVersion = 'community_hub_drawer_version'.tr(args: ['v2.0.5']);

    return Drawer(
      backgroundColor: HudPalette.world0,
      child: SafeArea(
        child: HudWorldBackground(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: HudGlass(
                  radius: 26,
                  blur: 18,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const HudGradientIconChip(icon: Icons.people, size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'community_hub_drawer_brand_title'.tr(),
                              style: const TextStyle(
                                color: HudPalette.textPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'community_hub_drawer_brand_tagline'.tr(),
                              style: const TextStyle(
                                color: HudPalette.textSecondary,
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
                    HudPillTile(
                      icon: Icons.feed,
                      title: 'community_hub_drawer_item_feed_title'.tr(),
                      subtitle: 'community_hub_drawer_item_feed_subtitle'.tr(),
                      selected: selectedTabIndex == 0,
                      accent: HudPalette.teal,
                      onTap: () => closeDrawerAnd(() => onTabSelected(0)),
                    ),
                    HudPillTile(
                      icon: Icons.trending_up,
                      title: 'community_hub_drawer_item_trending_title'.tr(),
                      subtitle: 'community_hub_drawer_item_trending_subtitle'
                          .tr(),
                      accent: HudPalette.yellow,
                      onTap: () => closeDrawerAnd(
                        () => onNavigate(CommunityHudDestination.trending),
                      ),
                    ),
                    HudPillTile(
                      icon: Icons.sports_martial_arts,
                      title: 'community_hub_drawer_item_art_battle_title'.tr(),
                      subtitle: 'community_hub_drawer_item_art_battle_subtitle'
                          .tr(),
                      accent: HudPalette.pink,
                      onTap: () => closeDrawerAnd(
                        () => onNavigate(CommunityHudDestination.artBattle),
                      ),
                    ),
                    lab_drawer.DrawerSection(
                      title: 'community_hub_drawer_section_create'.tr(),
                    ),
                    HudPillTile(
                      icon: Icons.add_circle,
                      title: 'community_hub_drawer_item_create_post_title'.tr(),
                      subtitle: 'community_hub_drawer_item_create_post_subtitle'
                          .tr(),
                      accent: HudPalette.pink,
                      onTap: () => closeDrawerAnd(
                        () => onNavigate(CommunityHudDestination.createPost),
                      ),
                    ),
                    lab_drawer.DrawerSection(
                      title: 'community_hub_drawer_section_artists'.tr(),
                    ),
                    HudPillTile(
                      icon: Icons.palette,
                      title: 'community_hub_drawer_item_artists_gallery_title'
                          .tr(),
                      subtitle:
                          'community_hub_drawer_item_artists_gallery_subtitle'
                              .tr(),
                      selected: selectedTabIndex == 1,
                      accent: HudPalette.purple,
                      onTap: () => closeDrawerAnd(
                        () => onNavigate(CommunityHudDestination.artworkBrowse),
                      ),
                    ),
                    HudPillTile(
                      icon: Icons.person_add,
                      title: 'community_hub_drawer_item_artist_onboarding_title'
                          .tr(),
                      subtitle:
                          'community_hub_drawer_item_artist_onboarding_subtitle'
                              .tr(),
                      accent: HudPalette.teal,
                      onTap: () => closeDrawerAnd(
                        () => onNavigate(
                          CommunityHudDestination.artistOnboarding,
                        ),
                      ),
                    ),
                    lab_drawer.DrawerSection(
                      title: 'community_hub_drawer_section_discover'.tr(),
                    ),
                    HudPillTile(
                      icon: Icons.topic,
                      title: 'community_hub_drawer_item_topics_title'.tr(),
                      subtitle: 'community_hub_drawer_item_topics_subtitle'
                          .tr(),
                      selected: selectedTabIndex == 2,
                      accent: HudPalette.green,
                      onTap: () => closeDrawerAnd(() => onTabSelected(2)),
                    ),
                    HudPillTile(
                      icon: Icons.leaderboard,
                      title: 'community_hub_drawer_item_leaderboard_title'.tr(),
                      subtitle: 'community_hub_drawer_item_leaderboard_subtitle'
                          .tr(),
                      accent: HudPalette.green,
                      onTap: () => closeDrawerAnd(
                        () => onNavigate(CommunityHudDestination.leaderboard),
                      ),
                    ),
                    lab_drawer.DrawerSection(
                      title: 'community_hub_drawer_section_my_content'.tr(),
                    ),
                    HudPillTile(
                      icon: Icons.person,
                      title: 'community_hub_drawer_item_my_posts_title'.tr(),
                      subtitle: 'community_hub_drawer_item_my_posts_subtitle'
                          .tr(),
                      accent: HudPalette.teal,
                      onTap: () => closeDrawerAnd(
                        () => onNavigate(CommunityHudDestination.userPosts),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: HudGlass(
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
                        color: HudPalette.textTertiary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          footerTitle,
                          style: const TextStyle(
                            color: HudPalette.textSecondary,
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
                            color: HudPalette.textTertiary,
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
}

class HudWorldBackground extends StatelessWidget {
  const HudWorldBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return WorldBackground(child: child);
  }
}

class HudGlass extends StatelessWidget {
  const HudGlass({
    super.key,
    required this.child,
    this.radius = 20,
    this.blur = 16,
    this.fillAlpha = 0.08,
    this.borderAlpha = 0.14,
    this.padding,
  });

  final Widget child;
  final double radius;
  final double blur;
  final double fillAlpha;
  final double borderAlpha;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: fillAlpha),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: borderAlpha)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class HudGradientIconChip extends StatelessWidget {
  const HudGradientIconChip({super.key, required this.icon, required this.size});

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
          colors: [HudPalette.purple, HudPalette.teal, HudPalette.green],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: HudPalette.purple.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.55),
    );
  }
}

class HudPillTile extends StatelessWidget {
  const HudPillTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.selected = false,
    this.accent = HudPalette.teal,
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
        child: HudGlass(
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
                        color: HudPalette.textPrimary,
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
                          color: HudPalette.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: HudPalette.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class HudPalette {
  HudPalette._();

  static const Color world0 = Color(0xFF07060F);
  static const Color teal = Color(0xFF22D3EE);
  static const Color green = Color(0xFF34D399);
  static const Color purple = Color(0xFF7C4DFF);
  static const Color pink = Color(0xFFFF3D8D);
  static const Color yellow = Color(0xFFFFC857);

  static const Color textPrimary = Color(0xF2FFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color textTertiary = Color(0x73FFFFFF);

  static Color glassFill([double a = 0.08]) =>
      Colors.white
          .withValues(alpha: a.clamp(0.0, 1.0).toDouble());

  static Color glassBorder([double a = 0.14]) =>
      Colors.white
          .withValues(alpha: a.clamp(0.0, 1.0).toDouble());
}
