import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart';

class ChapterSelectionWidget extends StatelessWidget {
  const ChapterSelectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final chapterProvider = context.watch<ChapterPartnerProvider>();
    final currentChapter = chapterProvider.currentChapter;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: GestureDetector(
        onTap: () => _showSelectionSheet(context),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderRadius: 16,
          child: Row(
            children: [
              const Icon(Icons.location_on, color: ArtbeatColors.accentOrange),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentChapter == null ? 'REGIONAL VIEW' : currentChapter.name.toUpperCase(),
                      style: ArtbeatTypography.badge,
                    ),
                    Text(
                      currentChapter == null ? 'Select your ARTbeat' : 'Viewing Chapter',
                      style: ArtbeatTypography.helper.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }

  void _showSelectionSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const ChapterSelectionSheet(),
    );
  }
}

class ChapterSelectionSheet extends StatelessWidget {
  const ChapterSelectionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final chapterProvider = context.watch<ChapterPartnerProvider>();
    final chapters = chapterProvider.availableChapters;

    return Container(
      decoration: const BoxDecoration(
        color: ArtbeatColors.backgroundDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Select Your ARTbeat', style: ArtbeatTypography.h2),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Choose a chapter to see curated art, quests, and events for that area.',
            style: ArtbeatTypography.body.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          
          // Regional Option
          _buildOption(
            context,
            null,
            chapterProvider.currentChapter == null,
            () {
              chapterProvider.selectChapter(null);
              Navigator.pop(context);
            },
          ),
          
          const Divider(color: Colors.white12, height: 32),
          
          if (chapterProvider.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (chapters.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text('No active chapters found nearby.', style: ArtbeatTypography.helper),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: chapters.length,
                itemBuilder: (context, index) {
                  final chapter = chapters[index];
                  return _buildOption(
                    context,
                    chapter,
                    chapterProvider.currentChapter?.id == chapter.id,
                    () {
                      chapterProvider.selectChapter(chapter);
                      Navigator.pop(context);
                      // Navigate to chapter landing page
                      Navigator.pushNamed(
                        context, 
                        AppRoutes.chapterLanding,
                        arguments: {'chapterId': chapter.id},
                      );
                    },
                  );
                },
              ),
            ),
          
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: HudButton(
              text: 'Auto-detect Location',
              onPressed: () => chapterProvider.autoDetectChapter(),
              icon: Icons.my_location,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, ChapterPartner? chapter, bool isSelected, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? ArtbeatColors.primaryPurple : Colors.white12,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          chapter == null ? Icons.map : Icons.location_city,
          color: isSelected ? Colors.white : Colors.white70,
        ),
      ),
      title: Text(
        chapter?.name ?? 'Regional View (Default)',
        style: ArtbeatTypography.h4.copyWith(
          color: isSelected ? ArtbeatColors.accentYellow : Colors.white,
        ),
      ),
      subtitle: Text(
        chapter?.partnerType.value.toUpperCase() ?? 'All surrounding areas',
        style: ArtbeatTypography.badge.copyWith(fontSize: 10),
      ),
      trailing: isSelected ? const Icon(Icons.check_circle, color: ArtbeatColors.accentYellow) : null,
    );
  }
}
