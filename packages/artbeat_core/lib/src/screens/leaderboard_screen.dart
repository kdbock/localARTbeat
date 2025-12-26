import 'dart:ui';

import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/leaderboard_service.dart';
import '../utils/logger.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LeaderboardService _leaderboardService = LeaderboardService();
  final RewardsService _rewardsService = RewardsService();

  Map<LeaderboardCategory, List<LeaderboardEntry>> _leaderboards = {};
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  final List<LeaderboardCategory> _categories = [
    LeaderboardCategory.totalXP,
    LeaderboardCategory.capturesCreated,
    LeaderboardCategory.artWalksCompleted,
    LeaderboardCategory.artWalksCreated,
    LeaderboardCategory.level,
    LeaderboardCategory.highestRatedCapture,
    LeaderboardCategory.highestRatedArtWalk,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadLeaderboards();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboards() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final leaderboards = await _leaderboardService.getMultipleLeaderboards(
        categories: _categories,
        limit: 50,
      );
      final stats = await _leaderboardService.getLeaderboardStats();

      if (!mounted) return;
      setState(() {
        _leaderboards = leaderboards;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Error loading leaderboards: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'leaderboard_title'.tr(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadLeaderboards,
            icon: const Icon(Icons.refresh, color: Colors.white70),
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildWorldBackground(),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 120, 16, 24),
              child: Column(
                children: [
                  _buildHeroSection(),
                  const SizedBox(height: 18),
                  _buildTabSwitcher(),
                  const SizedBox(height: 16),
                  Expanded(child: _buildTabContent()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    final totalUsers = _stats?['totalUsers'] as int?;
    final totalXp = _stats?['totalXP'] as int?;
    final averageXp = _stats?['averageXP'] as int?;

    return _buildGlassPanel(
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Global Creator Leaderboard',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Visibility gifts, promo ads, and fan subscriptions power every rank you see here.',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatChip(
                icon: Icons.people,
                label: 'Creators',
                value: totalUsers != null ? _formatNumber(totalUsers) : '--',
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                icon: Icons.flash_on,
                label: 'Total XP',
                value: totalXp != null ? _formatNumber(totalXp) : '--',
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                icon: Icons.trending_up,
                label: 'Avg Level',
                value: averageXp != null ? '${(averageXp / 100).round()}' : '--',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          color: Colors.white.withValues(alpha: 0.04),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            color: Colors.white.withValues(alpha: 0.04),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE), Color(0xFF34D399)],
              ),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
            unselectedLabelStyle:
                GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
            tabs: _categories
                .map(
                  (category) => Tab(
                    icon: Text(category.icon, style: const TextStyle(fontSize: 18)),
                    text: category.displayName,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_isLoading) {
      return Center(
        child: _buildGlassPanel(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white70),
              const SizedBox(width: 12),
              Text(
                'Syncing leaderboards...',
                style: GoogleFonts.spaceGrotesk(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            color: Colors.white.withValues(alpha: 0.02),
          ),
          child: TabBarView(
            controller: _tabController,
            children:
                _categories.map((category) => _buildLeaderboardTab(category)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardTab(LeaderboardCategory category) {
    final entries = _leaderboards[category] ?? [];

    final emptyState = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.emoji_events, color: Colors.white38, size: 48),
        const SizedBox(height: 12),
        Text(
          'No data available',
          style: GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 14),
        ),
        Text(
          'Be the first to earn points in this category',
          style: GoogleFonts.spaceGrotesk(color: Colors.white54, fontSize: 12),
        ),
      ],
    );

    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: Colors.black,
      onRefresh: _loadLeaderboards,
      child: entries.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 160),
                emptyState,
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
              itemCount: entries.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildCategoryHeader(category);
                }
                if (index == 1) {
                  return _buildCurrentUserRank(category);
                }
                final entry = entries[index - 2];
                return _buildLeaderboardCard(entry, category);
              },
            ),
    );
  }

  Widget _buildCategoryHeader(LeaderboardCategory category) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _buildGlassPanel(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Text(category.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.displayName,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getCategoryDescription(category),
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white70,
                      fontSize: 12,
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

  Widget _buildCurrentUserRank(LeaderboardCategory category) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _leaderboardService.getCurrentUserLeaderboardInfo(category),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }
        final currentUserEntry =
            snapshot.data!['currentUser'] as LeaderboardEntry;
        return _buildLeaderboardCard(
          currentUserEntry,
          category,
          isCurrentUser: true,
        );
      },
    );
  }

  Widget _buildLeaderboardCard(
    LeaderboardEntry entry,
    LeaderboardCategory category, {
    bool isCurrentUser = false,
  }) {
    final gradient = isCurrentUser
        ? const [Color(0xFF22D3EE), Color(0xFF34D399)]
        : _rankGradient(entry.rank);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isCurrentUser
              ? Colors.white.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.1),
        ),
        gradient: LinearGradient(
          colors: [
            gradient[0].withValues(alpha: 0.2),
            gradient[1].withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: gradient),
                  ),
                  child: Center(
                    child: Text(
                      '#${entry.rank}',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                CircleAvatar(
                  radius: 22,
                  backgroundImage: entry.profileImageUrl != null
                      ? CachedNetworkImageProvider(entry.profileImageUrl!)
                      : null,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  child: entry.profileImageUrl == null
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
              ],
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.displayName,
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (isCurrentUser)
                        const Icon(Icons.workspace_premium, color: Colors.white70),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Level ${entry.level} • ${_rewardsService.getLevelTitle(entry.level)}',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  if (category != LeaderboardCategory.totalXP &&
                      category != LeaderboardCategory.level)
                    Text(
                      '${entry.experiencePoints} total XP',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatValue(entry.value, category),
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  _getValueLabel(category),
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _rankGradient(int rank) {
    switch (rank) {
      case 1:
        return const [Color(0xFFFFD700), Color(0xFFFFA726)];
      case 2:
        return const [Color(0xFFE0E0E0), Color(0xFFB0BEC5)];
      case 3:
        return const [Color(0xFFBCAAA4), Color(0xFFA1887F)];
      default:
        return const [Color(0xFFFFFFFF), Color(0xFFFFFFFF)];
    }
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
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
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
            colors: [
              Color(0xFF03050F),
              Color(0xFF09122B),
              Color(0xFF021B17),
            ],
          ),
        ),
        child: Stack(
          children: [
            _buildGlow(const Offset(-140, -60), Colors.blueAccent),
            _buildGlow(const Offset(140, 220), Colors.purpleAccent),
            _buildGlow(const Offset(-20, 380), Colors.tealAccent),
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
          color: color.withValues(alpha: 0.18),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 120,
              spreadRadius: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryDescription(LeaderboardCategory category) {
    switch (category) {
      case LeaderboardCategory.totalXP:
        return 'Total experience across every action';
      case LeaderboardCategory.capturesCreated:
        return 'Art captures added to the map';
      case LeaderboardCategory.artWalksCompleted:
        return 'Curated walks fans have finished';
      case LeaderboardCategory.artWalksCreated:
        return 'Art walks published for the community';
      case LeaderboardCategory.level:
        return 'Highest verified creator level';
      case LeaderboardCategory.highestRatedCapture:
        return 'Best-rated capture this season';
      case LeaderboardCategory.highestRatedArtWalk:
        return 'Best-rated walk this season';
    }
  }

  String _formatValue(int value, LeaderboardCategory category) {
    if (category == LeaderboardCategory.totalXP) {
      return _formatNumber(value);
    }
    if (category == LeaderboardCategory.highestRatedCapture ||
        category == LeaderboardCategory.highestRatedArtWalk) {
      if (value >= 1 && value <= 5) {
        return '$value⭐';
      }
      if (value == 0) {
        return 'No rating';
      }
    }
    return value.toString();
  }

  String _getValueLabel(LeaderboardCategory category) {
    switch (category) {
      case LeaderboardCategory.totalXP:
        return 'XP';
      case LeaderboardCategory.capturesCreated:
        return 'captures';
      case LeaderboardCategory.artWalksCompleted:
        return 'completed';
      case LeaderboardCategory.artWalksCreated:
        return 'created';
      case LeaderboardCategory.level:
        return 'level';
      case LeaderboardCategory.highestRatedCapture:
        return 'stars';
      case LeaderboardCategory.highestRatedArtWalk:
        return 'stars';
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
