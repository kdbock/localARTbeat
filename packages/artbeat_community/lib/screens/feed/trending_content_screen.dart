import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../../models/post_model.dart';
import '../../widgets/post_card.dart';
import '../../widgets/community_drawer.dart';

class TrendingContentScreen extends StatefulWidget {
  const TrendingContentScreen({super.key});

  @override
  State<TrendingContentScreen> createState() => _TrendingContentScreenState();
}

class _TrendingContentScreenState extends State<TrendingContentScreen> {
  final ScrollController _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  List<PostModel> _trendingPosts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  DocumentSnapshot? _lastDocument;
  static const int _postsPerPage = 10;

  // Filter options
  String _selectedTimeFrame = 'Week';
  String _selectedCategory = 'All';

  final List<String> _timeFrames = ['Day', 'Week', 'Month', 'All Time'];
  final List<String> _categories = [
    'All',
    'Painting',
    'Digital',
    'Photography',
    'Sculpture',
    'Mixed Media',
  ];

  @override
  void initState() {
    super.initState();
    _loadTrendingContent();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _lastDocument != null) {
      _loadMoreTrendingContent();
    }
  }

  Future<void> _loadTrendingContent() async {
    setState(() {
      _isLoading = true;
      _trendingPosts = [];
      _lastDocument = null;
    });

    try {
      // Get cutoff date based on selected time frame
      DateTime cutoffDate;
      final now = DateTime.now();

      switch (_selectedTimeFrame) {
        case 'Day':
          cutoffDate = now.subtract(const Duration(days: 1));
          break;
        case 'Week':
          cutoffDate = now.subtract(const Duration(days: 7));
          break;
        case 'Month':
          cutoffDate = DateTime(now.year, now.month - 1, now.day);
          break;
        case 'All Time':
        default:
          cutoffDate = DateTime(2000); // Far in the past
          break;
      }

      Query query = FirebaseFirestore.instance
          .collection('posts')
          .where('isPublic', isEqualTo: true)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate),
          )
          .orderBy('createdAt', descending: true);

      // Apply category filter if not 'All'
      if (_selectedCategory != 'All') {
        query = query.where(
          'tags',
          arrayContains: _selectedCategory.toLowerCase(),
        );
      }

      // Order by applause count for trending
      query = query
          .orderBy('applauseCount', descending: true)
          .limit(_postsPerPage);

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;

        if (!mounted) return;
        setState(() {
          _trendingPosts = snapshot.docs
              .map((doc) => PostModel.fromFirestore(doc))
              .toList();
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading trending content: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreTrendingContent() async {
    if (_isLoadingMore || _lastDocument == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      // Get cutoff date based on selected time frame
      DateTime cutoffDate;
      final now = DateTime.now();

      switch (_selectedTimeFrame) {
        case 'Day':
          cutoffDate = now.subtract(const Duration(days: 1));
          break;
        case 'Week':
          cutoffDate = now.subtract(const Duration(days: 7));
          break;
        case 'Month':
          cutoffDate = DateTime(now.year, now.month - 1, now.day);
          break;
        case 'All Time':
        default:
          cutoffDate = DateTime(2000); // Far in the past
          break;
      }

      Query query = FirebaseFirestore.instance
          .collection('posts')
          .where('isPublic', isEqualTo: true)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate),
          )
          .orderBy('createdAt', descending: true);

      // Apply category filter if not 'All'
      if (_selectedCategory != 'All') {
        query = query.where(
          'tags',
          arrayContains: _selectedCategory.toLowerCase(),
        );
      }

      // Order by applause count for trending
      query = query
          .orderBy('applauseCount', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_postsPerPage);

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;

        final morePosts = snapshot.docs
            .map((doc) => PostModel.fromFirestore(doc))
            .toList();

        if (!mounted) return;
        setState(() {
          _trendingPosts.addAll(morePosts);
          _isLoadingMore = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading more trending content: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _applyFilters() {
    _loadTrendingContent();
  }

  void _onTimeFrameSelected(String value) {
    if (_selectedTimeFrame == value) return;
    setState(() => _selectedTimeFrame = value);
    _applyFilters();
  }

  void _onCategorySelected(String value) {
    if (_selectedCategory == value) return;
    setState(() => _selectedCategory = value);
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return MainLayout(
      currentIndex: 3, // Community tab in bottom navigation
      scaffoldKey: _scaffoldKey,
      drawer: const CommunityDrawer(),
      child: WorldBackground(
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Column(
              children: [
                _buildTopBar(context),
                const SizedBox(height: 16),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: _Palette.purple,
                          ),
                        )
                      : _buildContentList(bottomPadding),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      borderRadius: 24,
      showAccentGlow: true,
      accentColor: _Palette.teal,
      child: Row(
        children: [
          IconButton(
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            icon: const Icon(Icons.menu, color: Colors.white),
            tooltip: 'Open navigation',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'screen_title_trending_content'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    color: _Palette.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Exploration powered by applause + recency',
                  style: GoogleFonts.spaceGrotesk(
                    color: _Palette.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoading ? null : _loadTrendingContent,
          ),
        ],
      ),
    );
  }

  Widget _buildContentList(double bottomPadding) {
    return RefreshIndicator(
      color: _Palette.purple,
      onRefresh: _loadTrendingContent,
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: bottomPadding + 24),
        children: [
          _buildHeroCard(),
          const SizedBox(height: 12),
          _buildFiltersCard(),
          const SizedBox(height: 16),
          if (_trendingPosts.isEmpty) _buildEmptyState(),
          ..._trendingPosts.map(
            (post) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: PostCard(
                post: post,
                currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
                comments:
                    const [], // Empty list since we don't load comments here
                onUserTap: (userId) {
                  AppLogger.info('Navigate to user profile: $userId');
                },
                onComment: (postId) {
                  AppLogger.info('Navigate to comments for post: $postId');
                },
                onToggleExpand: () {
                  AppLogger.info('Toggle expand for post: ${post.id}');
                },
              ),
            ),
          ),
          if (_isLoadingMore) ...[
            const SizedBox(height: 12),
            _buildLoadMoreIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      showAccentGlow: true,
      accentColor: _Palette.purple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: _Palette.primaryGradient,
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.14)),
                  boxShadow: [
                    BoxShadow(
                      color: _Palette.teal.withValues(alpha: 0.2),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Trending Pulse',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Icon(Icons.explore, color: Colors.white.withValues(alpha: 0.8)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Curated by the community in real-time.',
            style: GoogleFonts.spaceGrotesk(
              color: _Palette.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Applause velocity + fresh posts = your creative radar.',
            style: GoogleFonts.spaceGrotesk(
              color: _Palette.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildBadge('Timeframe', _selectedTimeFrame),
              _buildBadge('Category', _selectedCategory),
              _buildBadge(
                'Stories',
                _trendingPosts.isEmpty
                    ? 'Loading'
                    : _trendingPosts.length.toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersCard() {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tune the signal',
            style: GoogleFonts.spaceGrotesk(
              color: _Palette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Blend freshness, applause, and category focus without leaving the vibe.',
            style: GoogleFonts.spaceGrotesk(
              color: _Palette.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          _buildFilterGroup(
            label: 'Time frame',
            options: _timeFrames,
            selected: _selectedTimeFrame,
            onSelected: _onTimeFrameSelected,
          ),
          const SizedBox(height: 12),
          _buildFilterGroup(
            label: 'Category',
            options: _categories,
            selected: _selectedCategory,
            onSelected: _onCategorySelected,
          ),
          const SizedBox(height: 16),
          HudButton.primary(
            onPressed: _applyFilters,
            text: 'Refresh trending',
            icon: Icons.bolt,
            height: 48,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterGroup({
    required String label,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            color: _Palette.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options
              .map(
                (option) => _buildFilterChip(
                  option: option,
                  selected: option == selected,
                  onTap: () => onSelected(option),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String option,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected ? _Palette.primaryGradient : null,
          color: selected
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.14),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _Palette.teal.withValues(alpha: 0.22),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Text(
          option,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.spaceGrotesk(
              color: _Palette.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              color: _Palette.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 26,
      showAccentGlow: true,
      accentColor: _Palette.teal,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _Palette.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: _Palette.pink.withValues(alpha: 0.26),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(Icons.trending_up, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 14),
          Text(
            'No trending content found',
            style: GoogleFonts.spaceGrotesk(
              color: _Palette.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a broader timeframe or peek back later.',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              color: _Palette.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          HudButton.secondary(
            onPressed: _applyFilters,
            text: 'Refresh feed',
            icon: Icons.refresh,
            height: 46,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(12.0),
        child: CircularProgressIndicator(
          color: _Palette.teal,
          strokeWidth: 3,
        ),
      ),
    );
  }
}

class _Palette {
  static const Color teal = Color(0xFF22D3EE);
  static const Color green = Color(0xFF34D399);
  static const Color purple = Color(0xFF7C4DFF);
  static const Color pink = Color(0xFFFF3D8D);
  static const Color textPrimary = Color(0xFFEAEAEA);
  static const Color textSecondary = Color(0xB3FFFFFF);

  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [purple, teal, green],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
