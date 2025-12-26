import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart';

class FullBrowseScreen extends StatefulWidget {
  const FullBrowseScreen({super.key});

  @override
  State<FullBrowseScreen> createState() => _FullBrowseScreenState();
}

class _FullBrowseScreenState extends State<FullBrowseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 1,
      drawer: const ArtbeatDrawer(),
      appBar: EnhancedUniversalHeader(
        title: 'browse_title'.tr(),
        showBackButton: false,
        showSearch: true,
        showDeveloperTools: false,
        onSearchPressed: (query) => Navigator.pushNamed(context, '/search'),
        onMenuPressed: () => Scaffold.of(context).openDrawer(),
      ),
      child: Stack(
        children: [
          _buildWorldBackground(),
          Positioned.fill(
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildGlassTabBar(),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCapturesTab(),
                      _buildArtwalksTab(),
                      _buildArtistsTab(),
                      _buildArtworkTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
            colors: [Color(0xFF05030D), Color(0xFF0B1330), Color(0xFF041C16)],
          ),
        ),
        child: Stack(
          children: [
            _buildGlow(const Offset(-120, -80), Colors.purpleAccent),
            _buildGlow(const Offset(140, 160), Colors.tealAccent),
            _buildGlow(const Offset(-40, 320), Colors.pinkAccent),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.1,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
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
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.18),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 90,
              spreadRadius: 12,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              color: Colors.white.withValues(alpha: 0.07),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF7C4DFF),
                    Color(0xFF22D3EE),
                    Color(0xFF34D399),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 0.3,
              ),
              unselectedLabelStyle: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              tabs: [
                _buildTab('browse_captures'.tr(), Icons.camera_alt_rounded),
                _buildTab('browse_art_walks'.tr(), Icons.route_rounded),
                _buildTab('browse_artists'.tr(), Icons.people_alt_rounded),
                _buildTab('browse_artwork'.tr(), Icons.image_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Tab _buildTab(String label, IconData icon) {
    return Tab(
      height: 60,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildCapturesTab() => _buildTabContent(
    title: 'Photo Captures',
    subtitle: 'Discover amazing photo captures from the community',
    icon: Icons.camera_alt_rounded,
    accent: ArtbeatColors.primaryBlue,
    actions: [
      _buildQuickActionCard(
        'Nearby Captures',
        'Find captures near you',
        Icons.location_on_rounded,
        () => Navigator.pushNamed(context, '/capture/nearby'),
      ),
      _buildQuickActionCard(
        'Popular Captures',
        'Most liked captures',
        Icons.favorite_rounded,
        () => Navigator.pushNamed(context, '/capture/popular'),
      ),
      _buildQuickActionCard(
        'My Captures',
        'View your captures',
        Icons.person_rounded,
        () => Navigator.pushNamed(context, '/capture/my-captures'),
      ),
    ],
    ctaTitle: 'Browse All Captures',
    ctaSubtitle: 'Explore the full collection of community captures',
    onCtaTap: () => Navigator.pushNamed(context, '/capture/browse'),
  );

  Widget _buildArtwalksTab() => _buildTabContent(
    title: 'Art Walks',
    subtitle: 'Explore curated art walking experiences',
    icon: Icons.map_rounded,
    accent: ArtbeatColors.primaryGreen,
    actions: [
      _buildQuickActionCard(
        'Nearby Walks',
        'Art walks in your area',
        Icons.near_me_rounded,
        () => Navigator.pushNamed(context, '/art-walk/nearby'),
      ),
      _buildQuickActionCard(
        'Featured Walks',
        'Curated experiences',
        Icons.star_rounded,
        () => Navigator.pushNamed(context, '/art-walk/explore'),
      ),
      _buildQuickActionCard(
        'Create Walk',
        'Design your own walk',
        Icons.add_location_rounded,
        () => Navigator.pushNamed(context, '/art-walk/create'),
      ),
    ],
    ctaTitle: 'Browse All Art Walks',
    ctaSubtitle: 'Discover all available art walking experiences',
    onCtaTap: () => Navigator.pushNamed(context, '/art-walk/list'),
  );

  Widget _buildArtistsTab() => _buildTabContent(
    title: 'Artists',
    subtitle: 'Connect with talented artists in your community',
    icon: Icons.people_rounded,
    accent: ArtbeatColors.primaryPurple,
    actions: [
      _buildQuickActionCard(
        'Featured Artists',
        'Highlighted creators',
        Icons.star_rounded,
        () => Navigator.pushNamed(context, '/artist/featured'),
      ),
      _buildQuickActionCard(
        'Local Artists',
        'Artists near you',
        Icons.location_on_rounded,
        () => Navigator.pushNamed(context, '/community/artists'),
      ),
      _buildQuickActionCard(
        'New Artists',
        'Recently joined',
        Icons.new_releases_rounded,
        () => Navigator.pushNamed(context, '/artist/browse'),
      ),
    ],
    ctaTitle: 'Browse All Artists',
    ctaSubtitle: 'Explore our community of talented artists',
    onCtaTap: () => Navigator.pushNamed(context, '/artist/browse'),
  );

  Widget _buildArtworkTab() => _buildTabContent(
    title: 'Artwork',
    subtitle: 'Discover beautiful artwork from our community',
    icon: Icons.image_rounded,
    accent: ArtbeatColors.accentOrange,
    actions: [
      _buildQuickActionCard(
        'Recent Artwork',
        'Latest uploads',
        Icons.schedule_rounded,
        () => Navigator.pushNamed(context, '/artwork/recent'),
      ),
      _buildQuickActionCard(
        'Trending',
        'Popular artwork',
        Icons.trending_up_rounded,
        () => Navigator.pushNamed(context, '/artwork/trending'),
      ),
      _buildQuickActionCard(
        'Featured',
        'Curated selections',
        Icons.star_rounded,
        () => Navigator.pushNamed(context, '/artwork/featured'),
      ),
    ],
    ctaTitle: 'Browse All Artwork',
    ctaSubtitle: 'Explore the complete artwork collection',
    onCtaTap: () => Navigator.pushNamed(context, '/artwork/browse'),
  );

  Widget _buildTabContent({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required List<Widget> actions,
    required String ctaTitle,
    required String ctaSubtitle,
    required VoidCallback onCtaTap,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
      child: Column(
        children: [
          _buildTabHeader(title, subtitle, icon, accent),
          const SizedBox(height: 20),
          _buildQuickActions(actions),
          const SizedBox(height: 20),
          _buildBrowseButton(ctaTitle, ctaSubtitle, onCtaTap),
        ],
      ),
    );
  }

  Widget _buildTabHeader(
    String title,
    String subtitle,
    IconData icon,
    Color accent,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            color: Colors.white.withValues(alpha: 0.04),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 32,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: 0.8),
                      accent.withValues(alpha: 0.4),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.5),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
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

  Widget _buildQuickActions(List<Widget> actions) {
    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          Expanded(child: actions[i]),
          if (i < actions.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _buildQuickActionCard(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            color: Colors.white.withValues(alpha: 0.03),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrowseButton(String title, String subtitle, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE), Color(0xFF34D399)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
