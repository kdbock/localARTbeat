import 'package:flutter/material.dart';
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
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 1, // Browse tab is selected
      drawer: const ArtbeatDrawer(),
      appBar: EnhancedUniversalHeader(
        title: 'browse_title'.tr(),
        showBackButton:
            false, // Browse is a main destination, no back button needed
        showSearch: true,
        showDeveloperTools: false,
        backgroundColor: ArtbeatColors.primary,
        onSearchPressed: (query) => Navigator.pushNamed(context, '/search'),
        onMenuPressed: () => Scaffold.of(context).openDrawer(),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ArtbeatColors.backgroundSecondary,
              ArtbeatColors.backgroundPrimary,
            ],
          ),
        ),
        child: Column(
          children: [
            // Modern Tab Bar
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: TabBar(
                  controller: _tabController,
                  labelColor: ArtbeatColors.primary,
                  unselectedLabelColor: ArtbeatColors.textSecondary,
                  indicatorColor: ArtbeatColors.primary,
                  indicatorWeight: 3,
                  indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                  tabs: [
                    _buildModernTab(
                      'browse_captures'.tr(),
                      Icons.camera_alt_rounded,
                    ),
                    _buildModernTab('browse_art_walks'.tr(), Icons.map_rounded),
                    _buildModernTab(
                      'browse_artists'.tr(),
                      Icons.people_rounded,
                    ),
                    _buildModernTab('browse_artwork'.tr(), Icons.image_rounded),
                  ],
                ),
              ),
            ),

            // Tab Content
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
    );
  }

  Widget _buildModernTab(String label, IconData icon) {
    return Tab(
      height: 60,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildCapturesTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header with search
          _buildTabHeader(
            'Photo Captures',
            'Discover amazing photo captures from the community',
            Icons.camera_alt_rounded,
            ArtbeatColors.primaryBlue,
          ),
          const SizedBox(height: 16),

          // Quick actions
          _buildQuickActions([
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
          ]),

          const SizedBox(height: 16),

          // Browse button
          _buildBrowseButton(
            'Browse All Captures',
            'Explore the full collection of community captures',
            () => Navigator.pushNamed(context, '/capture/browse'),
          ),
        ],
      ),
    );
  }

  Widget _buildArtwalksTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          _buildTabHeader(
            'Art Walks',
            'Explore curated art walking experiences',
            Icons.map_rounded,
            ArtbeatColors.primaryGreen,
          ),
          const SizedBox(height: 16),

          // Quick actions
          _buildQuickActions([
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
          ]),

          const SizedBox(height: 16),

          // Browse button
          _buildBrowseButton(
            'Browse All Art Walks',
            'Discover all available art walking experiences',
            () => Navigator.pushNamed(context, '/art-walk/list'),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistsTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          _buildTabHeader(
            'Artists',
            'Connect with talented artists in your community',
            Icons.people_rounded,
            ArtbeatColors.primaryPurple,
          ),
          const SizedBox(height: 16),

          // Quick actions
          _buildQuickActions([
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
          ]),

          const SizedBox(height: 16),

          // Browse button
          _buildBrowseButton(
            'Browse All Artists',
            'Explore our community of talented artists',
            () => Navigator.pushNamed(context, '/artist/browse'),
          ),
        ],
      ),
    );
  }

  Widget _buildArtworkTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          _buildTabHeader(
            'Artwork',
            'Discover beautiful artwork from our community',
            Icons.image_rounded,
            ArtbeatColors.accentOrange,
          ),
          const SizedBox(height: 16),

          // Quick actions
          _buildQuickActions([
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
          ]),

          const SizedBox(height: 16),

          // Browse button
          _buildBrowseButton(
            'Browse All Artwork',
            'Explore the complete artwork collection',
            () => Navigator.pushNamed(context, '/artwork/browse'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabHeader(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ArtbeatColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
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
    );
  }

  Widget _buildQuickActions(List<Widget> actions) {
    return Row(
      children:
          actions
              .map((action) => Expanded(child: action))
              .expand((widget) => [widget, const SizedBox(width: 8)])
              .toList()
            ..removeLast(), // Remove last spacer
    );
  }

  Widget _buildQuickActionCard(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ArtbeatColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: ArtbeatColors.primary, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ArtbeatColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: ArtbeatColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowseButton(String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ArtbeatColors.primary,
              ArtbeatColors.primary.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: ArtbeatColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
