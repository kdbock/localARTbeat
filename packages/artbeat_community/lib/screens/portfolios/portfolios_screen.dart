import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/artbeat_core.dart' hide GradientBadge;

import '../../widgets/widgets.dart';

class PortfoliosScreen extends StatefulWidget {
  const PortfoliosScreen({super.key});

  @override
  State<PortfoliosScreen> createState() => _PortfoliosScreenState();
}

class _PortfoliosScreenState extends State<PortfoliosScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _portfolios = [];
  List<Map<String, dynamic>> _filteredPortfolios = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _searchQuery = '';
  String _selectedFilter = _PortfolioFilter.filters.first.key;

  @override
  void initState() {
    super.initState();
    _loadPortfolios();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPortfolios() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final querySnapshot = await _firestore
          .collection('artistProfiles')
          .where('isPortfolioPublic', isEqualTo: true)
          .orderBy('username')
          .limit(40)
          .get();

      final results = querySnapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();

      if (!mounted) return;

      setState(() {
        _portfolios = results;
        _applyFilters();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('community_portfolios.error_loading'.tr())),
      );
    }
  }

  void _applyFilters({String? query, String? filterKey}) {
    final nextQuery = query ?? _searchQuery;
    final nextFilter = filterKey ?? _selectedFilter;

    List<Map<String, dynamic>> results = List.of(_portfolios);
    final searchLower = nextQuery.trim().toLowerCase();

    if (searchLower.isNotEmpty) {
      results = results.where((portfolio) {
        final tokens = <String>[];
        void addToken(String? value) {
          if (value != null && value.trim().isNotEmpty) {
            tokens.add(value.toLowerCase());
          }
        }

        addToken(_PortfolioDataUtils.displayName(portfolio));
        addToken(portfolio['username'] as String?);
        addToken(portfolio['location'] as String?);
        addToken(portfolio['primaryMedium'] as String?);
        final mediums = _PortfolioDataUtils.mediums(portfolio);
        tokens.addAll(mediums.map((medium) => medium.toLowerCase()));

        return tokens.any((token) => token.contains(searchLower));
      }).toList();
    }

    results = _filterByType(results, nextFilter);

    results.sort((a, b) {
      final aScore = _PortfolioDataUtils.rankScore(a);
      final bScore = _PortfolioDataUtils.rankScore(b);
      return bScore.compareTo(aScore);
    });

    setState(() {
      _filteredPortfolios = results;
      _selectedFilter = nextFilter;
      _searchQuery = nextQuery;
    });
  }

  List<Map<String, dynamic>> _filterByType(
    List<Map<String, dynamic>> source,
    String filterKey,
  ) {
    switch (filterKey) {
      case 'featured':
        return source
            .where((portfolio) => _PortfolioDataUtils.isFeatured(portfolio))
            .toList();
      case 'commissions':
        return source
            .where(
              (portfolio) =>
                  _PortfolioDataUtils.acceptingCommissions(portfolio),
            )
            .toList();
      case 'verified':
        return source
            .where((portfolio) => _PortfolioDataUtils.isVerified(portfolio))
            .toList();
      default:
        return source;
    }
  }

  int get _featuredCount =>
      _portfolios.where(_PortfolioDataUtils.isFeatured).length;

  int get _commissionReadyCount =>
      _portfolios.where(_PortfolioDataUtils.acceptingCommissions).length;

  int get _verifiedCount =>
      _portfolios.where(_PortfolioDataUtils.isVerified).length;

  Set<String> get _mediumSet {
    final set = <String>{};
    for (final portfolio in _portfolios) {
      set.addAll(_PortfolioDataUtils.mediums(portfolio));
    }
    return set;
  }

  void _onFilterSelected(String key) {
    if (_selectedFilter == key) return;
    _applyFilters(filterKey: key);
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _clearSearch() {
    _searchController.clear();
    _applyFilters(query: '');
  }

  void _openPortfolio(Map<String, dynamic> portfolio) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _PortfolioDetailsScreen(portfolio: portfolio),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: HudTopBar(
        title: 'community_portfolios.title'.tr(),
        glassBackground: true,
        showBackButton: true,
        actions: [
          IconButton(
            tooltip: 'community_portfolios.actions.refresh'.tr(),
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoading ? null : _loadPortfolios,
          ),
        ],
        subtitle: '',
      ),
      body: WorldBackground(
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildBody(bottomInset),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(double bottomInset) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError && _portfolios.isEmpty) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      color: _PortfolioPalette.accentTeal,
      onRefresh: _loadPortfolios,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(child: _buildHeroCard()),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(child: _buildSearchAndFilters()),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(child: _buildStatsRow()),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          if (_filteredPortfolios.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 24),
              sliver: _buildPortfolioGrid(),
            ),
          SliverToBoxAdapter(child: SizedBox(height: bottomInset + 16)),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    final mediumsPreview = _mediumSet.take(3).join(' • ');

    return GlassCard(
      padding: const EdgeInsets.all(24),
      showAccentGlow: true,
      accentColor: _PortfolioPalette.accentPurple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientBadge(
            text: 'community_portfolios.hero_badge'.tr(),
            icon: Icons.auto_awesome,
          ),
          const SizedBox(height: 16),
          Text(
            'community_portfolios.hero_title'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
              color: _PortfolioPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'community_portfolios.hero_subtitle'.tr(
              namedArgs: {
                'count': _portfolios.length.toString(),
                'mediums': mediumsPreview.isEmpty
                    ? 'community_portfolios.card.mediums'.tr()
                    : mediumsPreview,
              },
            ),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: _PortfolioPalette.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _HeroStatPill(
                icon: Icons.collections_bookmark_outlined,
                label: 'community_portfolios.stats.total'.tr(),
                value: _portfolios.length.toString(),
              ),
              _HeroStatPill(
                icon: Icons.verified_outlined,
                label: 'community_portfolios.stats.verified'.tr(),
                value: _verifiedCount.toString(),
              ),
              _HeroStatPill(
                icon: Icons.handshake_outlined,
                label: 'community_portfolios.stats.commissions'.tr(),
                value: _commissionReadyCount.toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassTextField(
            controller: _searchController,
            hintText: 'community_portfolios.search_hint'.tr(),
            prefixIcon: const Icon(Icons.search, color: Colors.white),
            onChanged: (value) => _applyFilters(query: value),
            suffixIcon: _searchQuery.isEmpty
                ? null
                : IconButton(
                    onPressed: _clearSearch,
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: _PortfolioFilter.filters
                  .map(
                    (filter) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _FilterChip(
                        filter: filter,
                        isSelected: _selectedFilter == filter.key,
                        onTap: () => _onFilterSelected(filter.key),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _InsightCard(
            icon: Icons.auto_awesome_mosaic_outlined,
            label: 'community_portfolios.stats.featured'.tr(),
            value: _featuredCount.toString().padLeft(2, '0'),
            accent: _PortfolioPalette.accentPurple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InsightCard(
            icon: Icons.palette_outlined,
            label: 'community_portfolios.card.mediums'.tr(),
            value: _mediumSet.length.toString().padLeft(2, '0'),
            accent: _PortfolioPalette.accentTeal,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.hourglass_empty,
            color: _PortfolioPalette.accentPink,
          ),
          const SizedBox(height: 16),
          Text(
            'community_portfolios.empty.title'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _PortfolioPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'community_portfolios.empty.subtitle'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: _PortfolioPalette.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          HudButton.secondary(
            text: 'community_portfolios.actions.refresh'.tr(),
            icon: Icons.refresh,
            onPressed: _loadPortfolios,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      showAccentGlow: true,
      accentColor: _PortfolioPalette.accentPink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white),
          const SizedBox(height: 16),
          Text(
            'community_portfolios.error_loading'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          HudButton.primary(
            text: 'community_portfolios.actions.refresh'.tr(),
            icon: Icons.refresh,
            onPressed: _loadPortfolios,
          ),
        ],
      ),
    );
  }

  SliverGrid _buildPortfolioGrid() {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final portfolio = _filteredPortfolios[index];
        return _PortfolioCard(
          portfolio: portfolio,
          onTap: () => _openPortfolio(portfolio),
        );
      }, childCount: _filteredPortfolios.length),
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  const _PortfolioCard({required this.portfolio, required this.onTap});

  final Map<String, dynamic> portfolio;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayName =
        _PortfolioDataUtils.displayName(portfolio) ??
        'community_portfolios.labels.unknown_artist'.tr();
    final medium = _PortfolioDataUtils.primaryMedium(portfolio);
    final artworks = _PortfolioDataUtils.artworkCount(portfolio);
    final followers = _PortfolioDataUtils.followerCount(portfolio);
    final imageUrl = portfolio['coverImageUrl'] as String?;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      showAccentGlow: _PortfolioDataUtils.isFeatured(portfolio),
      accentColor: _PortfolioDataUtils.isFeatured(portfolio)
          ? _PortfolioPalette.accentPurple
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: imageUrl != null
                  ? ImageManagementService().getOptimizedImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      isThumbnail: true,
                    )
                  : Container(
                      color: Colors.white.withValues(alpha: 0.05),
                      child: const Icon(
                        Icons.collections,
                        color: Colors.white54,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (_PortfolioDataUtils.hasActiveBoost(portfolio)) ...[
                Tooltip(
                  message: 'boost_badge_tooltip'.tr(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _PortfolioPalette.accentTeal.withValues(
                        alpha: 0.18,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          size: 14,
                          color: _PortfolioPalette.accentTeal,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'boost_badge_label'.tr(),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _PortfolioPalette.accentTeal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              _PortfolioDataUtils.isVerified(portfolio)
                  ? const Icon(
                      Icons.verified,
                      color: _PortfolioPalette.accentTeal,
                      size: 18,
                    )
                  : const SizedBox(width: 0, height: 0),
              if (_PortfolioDataUtils.isVerified(portfolio))
                const SizedBox(width: 6),
              Expanded(
                child: Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _PortfolioPalette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            medium ?? 'community_portfolios.card.mediums'.tr(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _PortfolioPalette.textSecondary,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              _StatChip(
                icon: Icons.palette_outlined,
                label: 'community_portfolios.card.works'.tr(),
                value: artworks.toString(),
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.favorite_border,
                label: 'community_portfolios.card.followers'.tr(),
                value: followers.toString(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          HudButton.secondary(
            text: 'community_portfolios.card.view'.tr(),
            icon: Icons.open_in_new,
            height: 46,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}

class _PortfolioDetailsScreen extends StatelessWidget {
  const _PortfolioDetailsScreen({required this.portfolio});

  final Map<String, dynamic> portfolio;

  @override
  Widget build(BuildContext context) {
    final displayName =
        _PortfolioDataUtils.displayName(portfolio) ??
        'community_portfolios.labels.unknown_artist'.tr();
    final location =
        (portfolio['location'] as String?)?.trim().isNotEmpty == true
        ? portfolio['location'] as String
        : 'community_portfolios.labels.unknown_location'.tr();
    final bio = (portfolio['bio'] as String?)?.trim().isNotEmpty == true
        ? portfolio['bio'] as String
        : 'community_portfolios.labels.no_bio'.tr();
    final mediums = _PortfolioDataUtils.mediums(portfolio);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: HudTopBar(
        title: displayName,
        glassBackground: true,
        subtitle: '',
      ),
      body: WorldBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroSection(displayName),
                const SizedBox(height: 16),
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailRow(
                        icon: Icons.place_outlined,
                        label: 'community_portfolios.details.location'.tr(),
                        value: location,
                      ),
                      const SizedBox(height: 16),
                      _DetailRow(
                        icon: Icons.brush_outlined,
                        label: 'community_portfolios.details.mediums'.tr(),
                        value: mediums.isEmpty
                            ? 'community_portfolios.card.mediums'.tr()
                            : mediums.join(' • '),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'community_portfolios.details.bio'.tr(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _PortfolioPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bio,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          color: _PortfolioPalette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildMetricRow(),
                const SizedBox(height: 16),
                GradientCTAButton(
                  text: 'community_portfolios.details.actions.request'.tr(),
                  icon: Icons.handshake_outlined,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(String displayName) {
    final coverImage = portfolio['coverImageUrl'] as String?;
    final avatarImage =
        portfolio['profileImageUrl'] as String? ??
        portfolio['avatarUrl'] as String?;

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: coverImage != null
                  ? ImageManagementService().getOptimizedImage(
                      imageUrl: coverImage,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.white.withValues(alpha: 0.05),
                      child: const Icon(
                        Icons.collections,
                        color: Colors.white54,
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: ClipOval(
                    child: avatarImage != null
                        ? ImageManagementService().getOptimizedImage(
                            imageUrl: avatarImage,
                            fit: BoxFit.cover,
                            isProfile: true,
                          )
                        : const Icon(Icons.person, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: _PortfolioPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _PortfolioDataUtils.primaryMedium(portfolio) ??
                            'community_portfolios.card.mediums'.tr(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _PortfolioPalette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_PortfolioDataUtils.isVerified(portfolio))
                  const Icon(
                    Icons.verified,
                    color: _PortfolioPalette.accentTeal,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow() {
    final metrics = [
      _PortfolioMetric(
        label: 'community_portfolios.details.metrics.followers'.tr(),
        value: _PortfolioDataUtils.followerCount(portfolio).toString(),
        icon: Icons.favorite_border,
      ),
      _PortfolioMetric(
        label: 'community_portfolios.details.metrics.works'.tr(),
        value: _PortfolioDataUtils.artworkCount(portfolio).toString(),
        icon: Icons.palette_outlined,
      ),
      _PortfolioMetric(
        label: 'community_portfolios.details.metrics.commissions'.tr(),
        value: _PortfolioDataUtils.acceptingCommissions(portfolio) ? '✓' : '—',
        icon: Icons.handshake_outlined,
      ),
    ];

    return Row(
      children: metrics
          .map(
            (metric) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: metric == metrics.last ? 0 : 12,
                ),
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(metric.icon, color: _PortfolioPalette.accentTeal),
                      const SizedBox(height: 12),
                      Text(
                        metric.value,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: _PortfolioPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        metric.label,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _PortfolioPalette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _HeroStatPill extends StatelessWidget {
  const _HeroStatPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _PortfolioPalette.textPrimary,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _PortfolioPalette.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: _PortfolioPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _PortfolioPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _PortfolioPalette.textPrimary,
                    ),
                  ),
                  Text(
                    label,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _PortfolioPalette.textSecondary,
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
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.filter,
    required this.isSelected,
    required this.onTap,
  });

  final _PortfolioFilter filter;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: isSelected
                ? const LinearGradient(
                    colors: [
                      _PortfolioPalette.accentPurple,
                      _PortfolioPalette.accentTeal,
                    ],
                  )
                : null,
            color: isSelected ? null : Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: 0.16),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(filter.icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                filter.label.tr(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _PortfolioPalette.accentTeal),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _PortfolioPalette.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _PortfolioPalette.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PortfolioMetric {
  const _PortfolioMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _PortfolioFilter {
  const _PortfolioFilter({
    required this.key,
    required this.icon,
    required this.label,
  });

  final String key;
  final IconData icon;
  final String label;

  static const filters = [
    _PortfolioFilter(
      key: 'all',
      icon: Icons.blur_on,
      label: 'community_portfolios.filters.all',
    ),
    _PortfolioFilter(
      key: 'featured',
      icon: Icons.auto_awesome,
      label: 'community_portfolios.filters.featured',
    ),
    _PortfolioFilter(
      key: 'commissions',
      icon: Icons.handshake_outlined,
      label: 'community_portfolios.filters.commissions',
    ),
    _PortfolioFilter(
      key: 'verified',
      icon: Icons.verified_outlined,
      label: 'community_portfolios.filters.verified',
    ),
  ];
}

class _PortfolioDataUtils {
  static String? displayName(Map<String, dynamic> data) {
    return (data['displayName'] as String?) ??
        (data['name'] as String?) ??
        (data['username'] as String?);
  }

  static List<String> mediums(Map<String, dynamic> data) {
    final raw = data['mediums'];
    if (raw is List) {
      return raw
          .whereType<String>()
          .where((value) => value.isNotEmpty)
          .toList();
    }
    if (raw is String && raw.isNotEmpty) {
      return [raw];
    }
    return const [];
  }

  static String? primaryMedium(Map<String, dynamic> data) {
    final direct = data['primaryMedium'] as String?;
    if (direct != null && direct.isNotEmpty) return direct;
    final mediumsList = mediums(data);
    if (mediumsList.isNotEmpty) return mediumsList.first;
    return null;
  }

  static int followerCount(Map<String, dynamic> data) {
    final value = data['followerCount'] ?? data['followers'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  static int artworkCount(Map<String, dynamic> data) {
    final value = data['artworkCount'] ?? data['portfolioCount'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  static bool isFeatured(Map<String, dynamic> data) {
    return (data['isFeatured'] as bool?) ?? false;
  }

  static bool isVerified(Map<String, dynamic> data) {
    return (data['isVerified'] as bool?) ?? false;
  }

  static bool acceptingCommissions(Map<String, dynamic> data) {
    return (data['acceptingCommissions'] as bool?) ?? false;
  }

  static double boostScore(Map<String, dynamic> data) {
    final value =
        data['boostScore'] ?? data['artistMomentum'] ?? data['momentum'];
    if (value is num) return value.toDouble();
    return 0.0;
  }

  static DateTime? lastBoostAt(Map<String, dynamic> data) {
    final raw = data['lastBoostAt'] ?? data['boostedAt'];
    if (raw is Timestamp) return raw.toDate();
    return null;
  }

  static bool hasActiveBoost(Map<String, dynamic> data) {
    final score = boostScore(data);
    final lastBoost = lastBoostAt(data);
    if (score <= 0 || lastBoost == null) return false;
    return DateTime.now().difference(lastBoost).inDays <= 7;
  }

  static num rankScore(Map<String, dynamic> data) {
    final followers = followerCount(data);
    final artworks = artworkCount(data);
    final featuredBoost = isFeatured(data) ? 5000 : 0;
    final commissionBoost = acceptingCommissions(data) ? 2000 : 0;
    final boostWeight = boostScore(data) * 10;
    return (followers * 2) +
        (artworks * 12) +
        featuredBoost +
        commissionBoost +
        boostWeight;
  }
}

class _PortfolioPalette {
  static const Color textPrimary = Color(0xFFF8FAFF);
  static const Color textSecondary = Color(0xFFBBD1FF);
  static const Color accentTeal = Color(0xFF22D3EE);
  static const Color accentPurple = Color(0xFF7C4DFF);
  static const Color accentPink = Color(0xFFFF3D8D);
}
