import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/artist_onboarding/artist_onboarding_data.dart';
import '../../viewmodels/artist_onboarding/artist_onboarding_view_model.dart';
import 'onboarding_widgets.dart';

/// Screen 5: Featured Artwork Selection
///
/// Features:
/// - Select up to 3 artworks to feature
/// - Drag-and-drop reordering
/// - Arrow button fallback
/// - Live preview panel
/// - Auto-skip if < 3 artworks
class FeaturedArtworkScreen extends StatefulWidget {
  const FeaturedArtworkScreen({super.key});

  @override
  State<FeaturedArtworkScreen> createState() => _FeaturedArtworkScreenState();
}

class _FeaturedArtworkScreenState extends State<FeaturedArtworkScreen> {
  @override
  void initState() {
    super.initState();

    // Auto-skip if less than 3 artworks
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<ArtistOnboardingViewModel>();

      if (viewModel.data.artworks.length < 3) {
        // Auto-select all artworks
        final allIds = viewModel.data.artworks.map((a) => a.id).toList();
        viewModel.setFeaturedArtworks(allIds);
      } else if (viewModel.data.artworks.length == 3 &&
          viewModel.data.featuredArtworkIds.isEmpty) {
        // Pre-select all 3
        final allIds = viewModel.data.artworks.map((a) => a.id).toList();
        viewModel.setFeaturedArtworks(allIds);
      }
    });
  }

  void _toggleSelection(String artworkId, ArtistOnboardingViewModel viewModel) {
    viewModel.toggleFeaturedArtwork(artworkId);
  }

  void _moveUp(int index, ArtistOnboardingViewModel viewModel) {
    if (index == 0) return;

    final featured = List<String>.from(viewModel.data.featuredArtworkIds);
    final temp = featured[index];
    featured[index] = featured[index - 1];
    featured[index - 1] = temp;
    viewModel.setFeaturedArtworks(featured);
  }

  void _moveDown(int index, ArtistOnboardingViewModel viewModel) {
    final featured = viewModel.data.featuredArtworkIds;
    if (index >= featured.length - 1) return;

    final list = List<String>.from(featured);
    final temp = list[index];
    list[index] = list[index + 1];
    list[index + 1] = temp;
    viewModel.setFeaturedArtworks(list);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ArtistOnboardingViewModel>(
      builder: (context, viewModel, child) {
        final artworks = viewModel.data.artworks;
        final featured = viewModel.data.featuredArtworkIds;
        final canProceed = featured.isNotEmpty || artworks.length <= 3;

        return OnboardingScaffold(
          currentStep: 4,
          canProceed: canProceed,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OnboardingHeader(
                title: 'Feature Your Best Work',
                subtitle:
                    'Choose up to 3 artworks to highlight on your profile',
              ),

              // Info banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00F5FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00F5FF).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF00F5FF),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Featured art gets 3x more views from collectors',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Selection counter
              Text(
                '${featured.length} of 3 selected',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF00F5FF),
                ),
              ),

              const SizedBox(height: 16),

              // Featured artworks (reorderable)
              if (featured.isNotEmpty) ...[
                Text(
                  'Featured Order (tap arrows to reorder):',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                _buildFeaturedList(viewModel, artworks, featured),
                const SizedBox(height: 24),
              ],

              // All artworks grid
              Text(
                'All Artworks (tap to select/deselect):',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 12),
              _buildArtworkGrid(viewModel, artworks, featured),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeaturedList(
    ArtistOnboardingViewModel viewModel,
    List<ArtworkDraft> allArtworks,
    List<String> featured,
  ) {
    return Column(
      children: List.generate(featured.length, (index) {
        final artworkId = featured[index];
        final artwork = allArtworks.firstWhere((a) => a.id == artworkId);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildFeaturedItem(
            artwork: artwork,
            position: index + 1,
            canMoveUp: index > 0,
            canMoveDown: index < featured.length - 1,
            onMoveUp: () => _moveUp(index, viewModel),
            onMoveDown: () => _moveDown(index, viewModel),
            onRemove: () => _toggleSelection(artworkId, viewModel),
          ),
        );
      }),
    );
  }

  Widget _buildFeaturedItem({
    required ArtworkDraft artwork,
    required int position,
    required bool canMoveUp,
    required bool canMoveDown,
    required VoidCallback onMoveUp,
    required VoidCallback onMoveDown,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00F5FF).withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Position badge
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF00F5FF),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$position',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: artwork.localImagePath != null
                ? Image.file(
                    File(artwork.localImagePath!),
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.white.withValues(alpha: 0.1),
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.white38,
                          size: 24,
                        ),
                      );
                    },
                  )
                : Container(
                    width: 60,
                    height: 60,
                    color: Colors.white.withValues(alpha: 0.1),
                    child: const Icon(Icons.image, color: Colors.white38),
                  ),
          ),

          const SizedBox(width: 12),

          // Title
          Expanded(
            child: Text(
              artwork.title ?? 'Untitled',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(width: 8),

          // Arrow buttons
          Column(
            children: [
              IconButton(
                onPressed: canMoveUp ? onMoveUp : null,
                icon: Icon(
                  Icons.arrow_upward,
                  color: canMoveUp ? Colors.white : Colors.white24,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                onPressed: canMoveDown ? onMoveDown : null,
                icon: Icon(
                  Icons.arrow_downward,
                  color: canMoveDown ? Colors.white : Colors.white24,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),

          // Remove button
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildArtworkGrid(
    ArtistOnboardingViewModel viewModel,
    List<ArtworkDraft> artworks,
    List<String> featured,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: artworks.length,
      itemBuilder: (context, index) {
        final artwork = artworks[index];
        final isSelected = featured.contains(artwork.id);
        final selectionNumber = isSelected
            ? featured.indexOf(artwork.id) + 1
            : null;

        return _buildArtworkTile(
          artwork: artwork,
          isSelected: isSelected,
          selectionNumber: selectionNumber,
          onTap: () => _toggleSelection(artwork.id, viewModel),
        );
      },
    );
  }

  Widget _buildArtworkTile({
    required ArtworkDraft artwork,
    required bool isSelected,
    required int? selectionNumber,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00F5FF)
                : Colors.white.withValues(alpha: 0.2),
            width: isSelected ? 3 : 2,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image with opacity
            Opacity(
              opacity: isSelected ? 1.0 : 0.7,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: artwork.localImagePath != null
                    ? Image.file(
                        File(artwork.localImagePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.white.withValues(alpha: 0.05),
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.white38,
                              size: 32,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.white.withValues(alpha: 0.05),
                        child: const Icon(Icons.image, color: Colors.white38),
                      ),
              ),
            ),

            // Selection badge
            if (isSelected && selectionNumber != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00F5FF),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00F5FF).withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$selectionNumber',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
