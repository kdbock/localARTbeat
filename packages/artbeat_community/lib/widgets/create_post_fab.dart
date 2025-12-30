import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/group_models.dart';
import '../screens/feed/create_group_post_screen.dart';
import 'glass_card.dart';

/// Floating Action Button for creating posts in different groups
class CreatePostFAB extends StatelessWidget {
  final GroupType groupType;
  final VoidCallback? onPostCreated;

  const CreatePostFAB({super.key, required this.groupType, this.onPostCreated});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showCreatePostOptions(context),
      backgroundColor: const Color(0xFF22D3EE),
      foregroundColor: Colors.white,
      icon: Icon(_getGroupIcon()),
      label: Text(_getCreateLabel().tr()),
    );
  }

  void _showCreatePostOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        builder: (context, scrollController) => GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF70FFFFFF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22D3EE).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getGroupIcon(),
                        color: const Color(0xFF22D3EE),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'create_group_post'.tr(args: [groupType.title]),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF92FFFFFF),
                            ),
                          ),
                          Text(
                            _getCreateDescription().tr(),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF70FFFFFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Create options
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: _buildCreateOptions(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCreateOptions(BuildContext context) {
    switch (groupType) {
      case GroupType.artist:
        return [
          _buildCreateOption(
            context: context,
            icon: Icons.photo_camera,
            title: 'share_artwork'.tr(),
            subtitle: 'post_photos_latest_creation'.tr(),
            color: const Color(0xFF22D3EE),
            postType: 'artwork',
          ),
          _buildCreateOption(
            context: context,
            icon: Icons.video_camera_back,
            title: 'process_video'.tr(),
            subtitle: 'share_creative_process'.tr(),
            color: const Color(0xFF34D399),
            postType: 'process',
          ),
          _buildCreateOption(
            context: context,
            icon: Icons.text_fields,
            title: 'artist_update'.tr(),
            subtitle: 'share_thoughts_updates'.tr(),
            color: const Color(0xFF22D3EE),
            postType: 'update',
          ),
        ];

      case GroupType.event:
        return [
          _buildCreateOption(
            context: context,
            icon: Icons.event_seat,
            title: 'hosting_event'.tr(),
            subtitle: 'share_event_organizing'.tr(),
            color: const Color(0xFF34D399),
            postType: 'hosting',
          ),
          _buildCreateOption(
            context: context,
            icon: Icons.event_available,
            title: 'attending_event'.tr(),
            subtitle: 'share_event_attending'.tr(),
            color: const Color(0xFF22D3EE),
            postType: 'attending',
          ),
          _buildCreateOption(
            context: context,
            icon: Icons.photo_camera,
            title: 'event_photos'.tr(),
            subtitle: 'share_photos_from_event'.tr(),
            color: const Color(0xFFFFC857),
            postType: 'photos',
          ),
        ];

      case GroupType.artWalk:
        return [
          _buildCreateOption(
            context: context,
            icon: Icons.add_a_photo,
            title: 'share_art_walk'.tr(),
            subtitle: 'post_up_to_5_photos'.tr(),
            color: const Color(0xFF22D3EE),
            postType: 'artwalk',
          ),
          _buildCreateOption(
            context: context,
            icon: Icons.map,
            title: 'create_route'.tr(),
            subtitle: 'design_new_art_route'.tr(),
            color: const Color(0xFF7C4DFF),
            postType: 'route',
          ),
        ];

      case GroupType.artistWanted:
        return [
          _buildCreateOption(
            context: context,
            icon: Icons.work_outline,
            title: 'post_project'.tr(),
            subtitle: 'looking_for_artist'.tr(),
            color: const Color(0xFFFFC857),
            postType: 'project',
          ),
          _buildCreateOption(
            context: context,
            icon: Icons.person_add,
            title: 'offer_services'.tr(),
            subtitle: 'share_availability_skills'.tr(),
            color: const Color(0xFF34D399),
            postType: 'services',
          ),
        ];
    }
  }

  Widget _buildCreateOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String postType,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute<bool>(
                builder: (context) => CreateGroupPostScreen(
                  groupType: groupType,
                  postType: postType,
                ),
              ),
            ).then((result) {
              if (result == true) {
                onPostCreated?.call();
              }
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22D3EE).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFF22D3EE), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF92FFFFFF),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF70FFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFF22D3EE),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getGroupIcon() {
    switch (groupType) {
      case GroupType.artist:
        return Icons.palette;
      case GroupType.event:
        return Icons.event;
      case GroupType.artWalk:
        return Icons.directions_walk;
      case GroupType.artistWanted:
        return Icons.work;
    }
  }

  String _getCreateLabel() {
    switch (groupType) {
      case GroupType.artist:
        return 'share_art';
      case GroupType.event:
        return 'add_event';
      case GroupType.artWalk:
        return 'share_walk';
      case GroupType.artistWanted:
        return 'post_job';
    }
  }

  String _getCreateDescription() {
    switch (groupType) {
      case GroupType.artist:
        return 'share_artwork_community';
      case GroupType.event:
        return 'share_art_events';
      case GroupType.artWalk:
        return 'share_art_discovery';
      case GroupType.artistWanted:
        return 'find_artists_services';
    }
  }
}
