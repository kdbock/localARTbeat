import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_capture/artbeat_capture.dart';


/// Enhanced Capture Dashboard Screen
///
/// This new capture dashboard combines the best elements from:
/// - Original Capture Dashboard (safety focus)
/// - Fluid Dashboard (smooth UX)
/// - Art Walk Dashboard (personalization & data integration)
///
/// Features:
/// - Personalized welcome message
/// - Recent captures showcase
/// - Capture stats and achievements
/// - Safety guidelines integration
/// - Community contribution highlights
/// - Quick action buttons
/// - Smooth scrolling experience
class EnhancedCaptureDashboardScreen extends StatefulWidget {
  const EnhancedCaptureDashboardScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedCaptureDashboardScreen> createState() =>
      _EnhancedCaptureDashboardScreenState();
}

class _EnhancedCaptureDashboardScreenState
    extends State<EnhancedCaptureDashboardScreen> {
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;

  // Data
  List<CaptureModel> _recentCaptures = [];
  List<CaptureModel> _communityCaptures = [];
  UserModel? _currentUser;
  int _totalUserCaptures = 0;
  int _totalCommunityViews = 0;

  // Services
  final CaptureService _captureService = CaptureService();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load user data
      final user = await _userService.getCurrentUserModel();

      // Load recent captures
      List<CaptureModel> recentCaptures = [];
      List<CaptureModel> communityCaptures = [];
      int totalUserCaptures = 0;
      int totalCommunityViews = 0;

      if (user != null) {
        // Get user's recent captures
        recentCaptures = await _captureService.getUserCaptures(
          userId: user.id,
          limit: 6,
        );

        // Get user's total capture count
        totalUserCaptures = await _captureService.getUserCaptureCount(user.id);

        // Get total community views of user's captures
        totalCommunityViews = await _captureService.getUserCaptureViews(
          user.id,
        );
      }

      // Get some community captures for inspiration
      communityCaptures = await _captureService.getAllCaptures(limit: 8);

      if (mounted) {
        setState(() {
          _currentUser = user;
          _recentCaptures = recentCaptures;
          _communityCaptures = communityCaptures;
          _totalUserCaptures = totalUserCaptures;
          _totalCommunityViews = totalCommunityViews;
          _isLoading = false;
        });
      }
    } catch (e) {
      // debugPrint('Error loading capture dashboard data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  void _openTermsAndConditionsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const TermsAndConditionsScreen(),
      ),
    );
  }

  void _showSearchModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
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
              const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: ArtbeatColors.primaryGreen,
                      size: 24,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'capture_dashboard_search_captures'.tr(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: ArtbeatColors.textPrimary,
                            ),
                          ),
                          Text(
                            'capture_dashboard_find_art'.tr(),
                            style: TextStyle(
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

              // Search options
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildSearchOption(
                      icon: Icons.camera_alt,
                      title: 'capture_dashboard_search_captures'.tr(),
                      subtitle: 'capture_dashboard_search_captures_subtitle'.tr(),
                      color: ArtbeatColors.primaryGreen,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/capture/search');
                      },
                    ),
                    _buildSearchOption(
                      icon: Icons.location_on,
                      title: 'capture_dashboard_nearby_art'.tr(),
                      subtitle: 'capture_dashboard_nearby_art_subtitle'.tr(),
                      color: ArtbeatColors.primaryPurple,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/capture/nearby');
                      },
                    ),
                    _buildSearchOption(
                      icon: Icons.trending_up,
                      title: 'capture_dashboard_popular_captures'.tr(),
                      subtitle: 'capture_dashboard_popular_captures_subtitle'.tr(),
                      color: ArtbeatColors.secondaryTeal,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/capture/popular');
                      },
                    ),
                    _buildSearchOption(
                      icon: Icons.person_search,
                      title: 'capture_dashboard_find_artists'.tr(),
                      subtitle: 'capture_dashboard_find_artists_subtitle'.tr(),
                      color: ArtbeatColors.accentYellow,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/artist/search');
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

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EnhancedProfileMenu(),
    );
  }

  Widget _buildSearchOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      drawer: const CaptureDrawer(),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 4),
        child: ArtbeatGradientBackground(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.topRight,
            colors: [ArtbeatColors.primaryPurple, Colors.pink],
          ),
          addShadow: true,
          child: EnhancedUniversalHeader(
            title: 'Art Capture',
            showLogo: false,
            showSearch: true,
            showDeveloperTools: true,
            showBackButton: false,
            onSearchPressed: (String query) => _showSearchModal(context),
            onProfilePressed: () => _showProfileMenu(context),
            backgroundColor: Colors.transparent,
            // Removed foregroundColor to use deep purple default
            elevation: 0,
          ),
        ),
      ),
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ArtbeatColors.primaryPurple.withValues(alpha: 0.05),
              Colors.white,
              ArtbeatColors.primaryGreen.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _refreshData,
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [


                      // Header Section
                      SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Welcome message
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      ArtbeatColors.primaryGreen.withValues(
                                        alpha: 0.1,
                                      ),
                                      ArtbeatColors.primaryPurple.withValues(
                                        alpha: 0.1,
                                      ),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: ArtbeatColors.primaryGreen
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.camera_alt,
                                      size: 48,
                                      color: ArtbeatColors.primaryGreen,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'capture_dashboard_ready_capture'.tr(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: ArtbeatColors.textPrimary,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'capture_dashboard_discover_document'.tr(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: ArtbeatColors.textSecondary,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Main action button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _openTermsAndConditionsScreen,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ArtbeatColors.primaryGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  icon: const Icon(
                                    Icons.assignment_turned_in,
                                    size: 24,
                                  ),
                                  label: Text(
                                    'capture_dashboard_start_capture'.tr(),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Stats section
                              if (_currentUser != null) ...[
                                Text(
                                  'capture_dashboard_your_impact'.tr(),
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: ArtbeatColors.textPrimary,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        title: 'capture_dashboard_stat_captures'.tr(),
                                        value: _totalUserCaptures.toString(),
                                        icon: Icons.camera_alt,
                                        color: ArtbeatColors.primaryGreen,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildStatCard(
                                        title: 'capture_dashboard_stat_community_views'.tr(),
                                        value: _totalCommunityViews.toString(),
                                        icon: Icons.visibility,
                                        color: ArtbeatColors.primaryPurple,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],


                            ],
                          ),
                        ),
                      ),

                      // Recent captures section
                      if (_recentCaptures.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'capture_dashboard_recent_captures'.tr(),
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: ArtbeatColors.textPrimary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Recent captures grid
                      if (_recentCaptures.isNotEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 1,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final capture = _recentCaptures[index];
                              return _buildCaptureCard(capture);
                            }, childCount: _recentCaptures.length),
                          ),
                        ),

                      // Ad placement beneath recent captures section


                      // Community inspiration section
                      if (_communityCaptures.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                Text(
                                  'capture_dashboard_community_inspiration'.tr(),
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: ArtbeatColors.textPrimary,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'capture_dashboard_see_others'.tr(),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: ArtbeatColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                              ),
                              itemCount: _communityCaptures.length,
                              itemBuilder: (context, index) {
                                final capture = _communityCaptures[index];
                                return Container(
                                  width: 160,
                                  margin: const EdgeInsets.only(right: 16),
                                  child: _buildCommunityCard(capture),
                                );
                              },
                            ),
                          ),
                        ),

                        // Artist CTA widget
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: CompactArtistCTAWidget(),
                          ),
                        ),

                        // Bottom padding
                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureCard(CaptureModel capture) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            SecureNetworkImage(
              imageUrl: capture.imageUrl,
              fit: BoxFit.cover,
              errorWidget: Container(
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),

            // Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),

            // Content
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (capture.title?.isNotEmpty == true)
                    Text(
                      capture.title!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(capture.status),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      capture.status.value.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityCard(CaptureModel capture) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            SecureNetworkImage(
              imageUrl: capture.imageUrl,
              fit: BoxFit.cover,
              errorWidget: Container(
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),

            // Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),

            // Content
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                capture.title ?? 'capture_dashboard_community_capture'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(CaptureStatus status) {
    switch (status) {
      case CaptureStatus.approved:
        return ArtbeatColors.primaryGreen;
      case CaptureStatus.pending:
        return ArtbeatColors.accentYellow;
      case CaptureStatus.rejected:
        return Colors.red;
    }
  }
}
