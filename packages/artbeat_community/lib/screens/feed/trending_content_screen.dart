import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../widgets/post_card.dart';
import '../../widgets/community_drawer.dart';
import 'comments_screen.dart';
import '../../services/community_service.dart';

class TrendingContentScreen extends StatefulWidget {
  const TrendingContentScreen({super.key});

  @override
  State<TrendingContentScreen> createState() => _TrendingContentScreenState();
}

class _TrendingContentScreenState extends State<TrendingContentScreen> {
  final ScrollController _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late CommunityService _communityService;
  List<PostModel> _trendingPosts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  DocumentSnapshot? _lastDocument;
  static const int _postsPerPage = 10;

  // Filter options
  String _selectedTimeFrame = 'Week';
  String _selectedCategory = 'All';

  static const List<_FilterOption> _timeFrames = [
    _FilterOption('Day', 'trending_content.timeframe_day'),
    _FilterOption('Week', 'trending_content.timeframe_week'),
    _FilterOption('Month', 'trending_content.timeframe_month'),
    _FilterOption('All Time', 'trending_content.timeframe_all'),
  ];

  static const List<_FilterOption> _categories = [
    _FilterOption('All', 'trending_content.category_all'),
    _FilterOption('Painting', 'trending_content.category_painting'),
    _FilterOption('Digital', 'trending_content.category_digital'),
    _FilterOption('Photography', 'trending_content.category_photography'),
    _FilterOption('Sculpture', 'trending_content.category_sculpture'),
    _FilterOption('Mixed Media', 'trending_content.category_mixed_media'),
  ];

  @override
  void initState() {
    super.initState();
    _communityService = context.read<CommunityService>();
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
      final result = await _communityService.getTrendingPosts(
        timeFrame: _selectedTimeFrame,
        category: _selectedCategory,
        limit: _postsPerPage,
      );

      if (result.posts.isNotEmpty) {
        _lastDocument = result.lastDocument;

        if (!mounted) return;
        setState(() {
          _trendingPosts = result.posts;
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
      final result = await _communityService.getTrendingPosts(
        timeFrame: _selectedTimeFrame,
        category: _selectedCategory,
        limit: _postsPerPage,
        lastDocument: _lastDocument,
      );

      if (result.posts.isNotEmpty) {
        _lastDocument = result.lastDocument;

        if (!mounted) return;
        setState(() {
          _trendingPosts.addAll(result.posts);
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

  Future<void> _openCommentsScreen(PostModel post) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => CommentsScreen(post: post)),
    );
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
            tooltip: 'trending_content.tooltip_open_navigation'.tr(),
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
                  'trending_content.screen_subtitle'.tr(),
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
            tooltip: 'trending_content.tooltip_refresh'.tr(),
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
                currentUserId: _communityService.currentUserId ?? '',
                comments:
                    const [], // Empty list since we don't load comments here
                onUserTap: (userId) {
                  AppLogger.info('Navigate to user profile: $userId');
                },
                onComment: (_) => _openCommentsScreen(post),
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
    final storiesValue = _trendingPosts.isEmpty
        ? 'trending_content.loading'.tr()
        : _trendingPosts.length.toString();

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: _Palette.primaryGradient,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
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
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'trending_content.hero_badge_title'.tr(),
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
            'trending_content.hero_headline'.tr(),
            style: GoogleFonts.spaceGrotesk(
              color: _Palette.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'trending_content.hero_subheadline'.tr(),
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
              _buildBadge(
                'trending_content.hero_badge_timeframe'.tr(),
                _localizedOptionValue(_selectedTimeFrame, _timeFrames),
              ),
              _buildBadge(
                'trending_content.hero_badge_category'.tr(),
                _localizedOptionValue(_selectedCategory, _categories),
              ),
              _buildBadge(
                'trending_content.hero_badge_stories'.tr(),
                storiesValue,
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
            'trending_content.filters_title'.tr(),
            style: GoogleFonts.spaceGrotesk(
              color: _Palette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'trending_content.filters_description'.tr(),
            style: GoogleFonts.spaceGrotesk(
              color: _Palette.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          _buildFilterGroup(
            labelKey: 'trending_content.filters_timeframe_label',
            options: _timeFrames,
            selectedValue: _selectedTimeFrame,
            onSelected: _onTimeFrameSelected,
          ),
          const SizedBox(height: 12),
          _buildFilterGroup(
            labelKey: 'trending_content.filters_category_label',
            options: _categories,
            selectedValue: _selectedCategory,
            onSelected: _onCategorySelected,
          ),
          const SizedBox(height: 16),
          HudButton.primary(
            onPressed: _applyFilters,
            text: 'trending_content.filters_refresh_button'.tr(),
            icon: Icons.bolt,
            height: 48,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterGroup({
    required String labelKey,
    required List<_FilterOption> options,
    required String selectedValue,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelKey.tr(),
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
                  selected: option.value == selectedValue,
                  onTap: () => onSelected(option.value),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required _FilterOption option,
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
          option.labelKey.tr(),
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

  String _localizedOptionValue(String value, List<_FilterOption> options) {
    final match = options.firstWhere(
      (option) => option.value == value,
      orElse: () => options.first,
    );
    return match.labelKey.tr();
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
            'trending_content.empty_title'.tr(),
            style: GoogleFonts.spaceGrotesk(
              color: _Palette.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'trending_content.empty_subtitle'.tr(),
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
            text: 'trending_content.empty_refresh_button'.tr(),
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
        child: CircularProgressIndicator(color: _Palette.teal, strokeWidth: 3),
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

class _FilterOption {
  final String value;
  final String labelKey;

  const _FilterOption(this.value, this.labelKey);
}
