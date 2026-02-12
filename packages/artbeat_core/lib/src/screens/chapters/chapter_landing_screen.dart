import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart';

class ChapterLandingScreen extends StatefulWidget {
  final String chapterId;
  const ChapterLandingScreen({super.key, required this.chapterId});

  @override
  State<ChapterLandingScreen> createState() => _ChapterLandingScreenState();
}

class _ChapterLandingScreenState extends State<ChapterLandingScreen> {
  final ChapterPartnerService _chapterService = ChapterPartnerService();
  List<ChapterQuest> _quests = [];
  bool _isLoadingQuests = true;

  @override
  void initState() {
    super.initState();
    _loadChapterData();
  }

  Future<void> _loadChapterData() async {
    setState(() => _isLoadingQuests = true);
    try {
      final quests = await _chapterService.getQuestsForChapter(widget.chapterId);
      setState(() {
        _quests = quests;
        _isLoadingQuests = false;
      });
      
      // Track view
      if (!mounted) return;
      final userProvider = context.read<UserService>();
      if (userProvider.currentUser != null) {
        await _chapterService.trackChapterView(widget.chapterId, userProvider.currentUser!.uid);
      }
    } catch (e) {
      AppLogger.error('Error loading chapter data: $e');
      setState(() => _isLoadingQuests = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chapterProvider = context.watch<ChapterPartnerProvider>();
    final chapter = chapterProvider.currentChapter;

    if (chapter == null) {
      return const Scaffold(
        body: Center(child: Text('No Chapter Selected')),
      );
    }

    final branding = chapter.brandingConfig;
    // Parse colors from hex if possible, fallback to theme colors
    final primaryColor = _parseColor(branding.primaryColor, ArtbeatColors.primaryPurple);

    return Scaffold(
      backgroundColor: ArtbeatColors.backgroundDark,
      body: CustomScrollView(
        slivers: [
          _buildHeroBanner(chapter, branding),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPartnerInfo(chapter, branding),
                  const SizedBox(height: 24),
                  _buildQuestsSection(primaryColor),
                  const SizedBox(height: 24),
                  _buildFeaturedSection('Upcoming Events', chapter.id),
                  const SizedBox(height: 24),
                  _buildFeaturedSection('Featured Art', chapter.id),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(ChapterPartner chapter, BrandingConfig branding) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (branding.bannerImageUrl.isNotEmpty)
              Image.network(branding.bannerImageUrl, fit: BoxFit.cover)
            else
              Container(color: ArtbeatColors.primaryPurple.withValues(alpha: 0.3)),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    ArtbeatColors.backgroundDark.withValues(alpha: 0.8),
                    ArtbeatColors.backgroundDark,
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    branding.heroHeadline,
                    style: ArtbeatTypography.h1.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    branding.shortDescription,
                    style: ArtbeatTypography.body.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.read<ChapterPartnerProvider>().switchToRegional(),
      ),
    );
  }

  Widget _buildPartnerInfo(ChapterPartner chapter, BrandingConfig branding) {
    return Row(
      children: [
        if (branding.partnerLogoUrl.isNotEmpty)
          CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage(branding.partnerLogoUrl),
            backgroundColor: Colors.transparent,
          ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(chapter.name, style: ArtbeatTypography.h2),
              Text(chapter.partnerType.value.toUpperCase(), style: ArtbeatTypography.badge),
            ],
          ),
        ),
        if (branding.sponsorBadgeEnabled)
          const Icon(Icons.verified, color: ArtbeatColors.accentYellow),
      ],
    );
  }

  Widget _buildQuestsSection(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Active Quests', style: ArtbeatTypography.h3),
            TextButton(
              onPressed: () {},
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoadingQuests)
          const Center(child: CircularProgressIndicator())
        else if (_quests.isEmpty)
          const Text('No active quests for this chapter.')
        else
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _quests.length,
              itemBuilder: (context, index) => _buildQuestCard(_quests[index], primaryColor),
            ),
          ),
      ],
    );
  }

  Widget _buildQuestCard(ChapterQuest quest, Color primaryColor) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getQuestIcon(quest.badgeIcon), color: primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    quest.title,
                    style: ArtbeatTypography.h4,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ArtbeatColors.accentYellow.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('+${quest.xpReward} XP', style: ArtbeatTypography.badge),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              quest.description,
              style: ArtbeatTypography.helper,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: HudButton(
                text: 'Start Quest',
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedSection(String title, String chapterId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: ArtbeatTypography.h3),
            TextButton(
              onPressed: () {},
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Placeholder for filtered content
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Center(
            child: Text(
              'Showing ${title.toLowerCase()} in this chapter...',
              style: ArtbeatTypography.helper,
            ),
          ),
        ),
      ],
    );
  }

  Color _parseColor(String hex, Color fallback) {
    try {
      if (hex.startsWith('#')) {
        return Color(int.parse(hex.replaceFirst('#', '0xFF')));
      }
      return fallback;
    } catch (e) {
      return fallback;
    }
  }

  IconData _getQuestIcon(String iconName) {
    switch (iconName) {
      case 'map': return Icons.map;
      case 'camera': return Icons.camera_alt;
      case 'walk': return Icons.directions_walk;
      default: return Icons.flag;
    }
  }
}
