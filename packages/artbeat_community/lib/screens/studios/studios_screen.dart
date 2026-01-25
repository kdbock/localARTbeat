import 'package:artbeat_core/artbeat_core.dart' show MainLayout;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/studio_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/widgets.dart';
import 'create_studio_screen.dart';
import 'studio_chat_screen.dart';

class StudiosScreen extends StatefulWidget {
  const StudiosScreen({super.key});

  @override
  State<StudiosScreen> createState() => _StudiosScreenState();
}

class _StudiosScreenState extends State<StudiosScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  List<StudioModel> _studios = [];
  List<StudioModel> _filteredStudios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudios();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudios() async {
    setState(() => _isLoading = true);
    try {
      final studios = await _firestoreService.getStudios();
      setState(() {
        _studios = studios;
        _filteredStudios = studios;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'community_studios.load_error'.tr(
              namedArgs: {'error': e.toString()},
            ),
          ),
        ),
      );
    }
  }

  void _performSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStudios = _studios;
      } else {
        _filteredStudios = _studios.where((studio) {
          final name = studio.name.toLowerCase();
          final description = studio.description.toLowerCase();
          final searchLower = query.toLowerCase();

          return name.contains(searchLower) ||
              description.contains(searchLower);
        }).toList();
      }
    });
  }

  void _openCreateStudio() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const CreateStudioScreen()));
    if (mounted) _loadStudios();
  }

  void _openStudio(StudioModel studio) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            StudioChatScreen(studioId: studio.id, studio: studio),
      ),
    );
  }

  int get _totalMembers =>
      _studios.fold(0, (sum, studio) => sum + studio.memberList.length);

  int get _uniqueTagsCount =>
      _studios.expand((studio) => studio.tags).toSet().length;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return MainLayout(
      scaffoldKey: scaffoldKey,
      currentIndex: 3,
      appBar: HudTopBar(
        title: 'screen_title_studios'.tr(),
        showBackButton: false,
        glassBackground: true,
        actions: [
          IconButton(
            tooltip: 'community_studios.refresh_cta'.tr(),
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoading ? null : _loadStudios,
          ),
        ],
        subtitle: '',
      ),
      child: WorldBackground(
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _isLoading
                ? _buildLoadingState()
                : _buildContent(bottomInset),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(_StudiosPalette.accentTeal),
      ),
    );
  }

  Widget _buildContent(double bottomInset) {
    return RefreshIndicator(
      onRefresh: _loadStudios,
      color: _StudiosPalette.accentTeal,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(child: _buildHeroCard()),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(child: _buildSearchField()),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          _filteredStudios.isEmpty
              ? SliverToBoxAdapter(child: _buildEmptyState())
              : SliverPadding(
                  padding: const EdgeInsets.only(bottom: 8),
                  sliver: _buildStudioGrid(),
                ),
          SliverToBoxAdapter(child: SizedBox(height: bottomInset + 16)),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _StudiosPalette.accentPurple,
                      _StudiosPalette.accentTeal,
                      _StudiosPalette.accentGreen,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: _StudiosPalette.accentPurple.withValues(
                        alpha: 0.28,
                      ),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.groups_3_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'community_studios.hero_title'.tr(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: _StudiosPalette.textPrimary,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'community_studios.hero_subtitle'.tr(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _StudiosPalette.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildMetricChip(
                icon: Icons.wifi_tethering,
                label: 'community_studios.stat_studios'.tr(
                  namedArgs: {'count': _studios.length.toString()},
                ),
              ),
              _buildMetricChip(
                icon: Icons.groups_outlined,
                label: 'community_studios.stat_members'.tr(
                  namedArgs: {'count': _totalMembers.toString()},
                ),
              ),
              _buildMetricChip(
                icon: Icons.style_rounded,
                label: 'community_studios.stat_tags'.tr(
                  namedArgs: {'count': _uniqueTagsCount.toString()},
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GradientCTAButton(
                  text: 'community_studios.create_cta'.tr(),
                  onPressed: _openCreateStudio,
                  icon: Icons.add_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: HudButton.secondary(
                  text: 'community_studios.refresh_cta'.tr(),
                  icon: Icons.refresh,
                  onPressed: _isLoading ? null : _loadStudios,
                  height: 52,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return GlassTextField(
      controller: _searchController,
      hintText: 'community_studios.search_hint'.tr(),
      prefixIcon: Icon(
        Icons.search_rounded,
        color: Colors.white.withValues(alpha: 0.82),
      ),
      onChanged: _performSearch,
      decoration: GlassInputDecoration.search(
        hintText: 'community_studios.search_hint'.tr(),
      ),
    );
  }

  SliverGrid _buildStudioGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1100
        ? 3
        : screenWidth > 720
        ? 2
        : 1;

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: crossAxisCount == 1 ? 1.9 : 1.1,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final studio = _filteredStudios[index];
        return _buildStudioCard(studio);
      }, childCount: _filteredStudios.length),
    );
  }

  Widget _buildStudioCard(StudioModel studio) {
    final isPublic = studio.privacyType.toLowerCase() == 'public';
    final privacyLabel = isPublic
        ? 'community_studios.privacy_public'.tr()
        : 'community_studios.privacy_private'.tr();
    final description = studio.description.trim().isNotEmpty
        ? studio.description.trim()
        : 'community_studios.description_fallback'.tr();

    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      borderRadius: 24,
      onTap: () => _openStudio(studio),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _StudiosPalette.glassFill(0.16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: Icon(
                  isPublic ? Icons.public_rounded : Icons.lock_rounded,
                  color: isPublic
                      ? _StudiosPalette.accentTeal
                      : _StudiosPalette.accentPurple,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studio.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _StudiosPalette.textPrimary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GradientBadge(
                          text: privacyLabel,
                          icon: isPublic ? Icons.explore : Icons.shield_rounded,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          fontSize: 11,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'community_studios.members_label'.tr(
                            namedArgs: {
                              'count': studio.memberList.length.toString(),
                            },
                          ),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _StudiosPalette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Text(
              description,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.5,
                color: _StudiosPalette.textSecondary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),
          if (studio.tags.isNotEmpty) ...[
            Text(
              'community_studios.tags_label'.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: _StudiosPalette.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: studio.tags.take(3).map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _StudiosPalette.glassFill(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Text(
                    '#$tag',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _StudiosPalette.textPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'community_studios.empty_title'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: _StudiosPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'community_studios.empty_subtitle'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _StudiosPalette.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          GradientCTAButton(
            text: 'community_studios.create_cta'.tr(),
            onPressed: _openCreateStudio,
            icon: Icons.add_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({required String label, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _StudiosPalette.glassFill(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: _StudiosPalette.accentTeal, size: 18),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _StudiosPalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudiosPalette {
  static const Color textPrimary = Color(0xF2FFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color accentTeal = Color(0xFF22D3EE);
  static const Color accentPurple = Color(0xFF7C4DFF);
  static const Color accentGreen = Color(0xFF34D399);

  static Color glassFill([double alpha = 0.1]) =>
      Colors.white.withValues(alpha: alpha);
}
