import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;

class CommunityArtistsScreen extends StatefulWidget {
  const CommunityArtistsScreen({super.key});

  @override
  State<CommunityArtistsScreen> createState() => _CommunityArtistsScreenState();
}

class _CommunityArtistsScreenState extends State<CommunityArtistsScreen> {
  late String title;
  late List<Map<String, dynamic>> artists;
  late Color color;
  late bool showFollowers;
  late bool showDistance;
  late bool showVerifiedBadge;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    title = args?['title']?.toString() ?? 'Artists';
    artists =
        (args?['artists'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
        [];
    color = args?['color'] as Color? ?? core.ArtbeatColors.primaryPurple;
    showFollowers = args?['showFollowers'] as bool? ?? false;
    showDistance = args?['showDistance'] as bool? ?? false;
    showVerifiedBadge = args?['showVerifiedBadge'] as bool? ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return core.MainLayout(
      scaffoldKey: scaffoldKey,
      currentIndex: -1, // Detail screen
      appBar: core.EnhancedUniversalHeader(title: title),
      child: Container(
        color: Colors.grey[50],
        child: SafeArea(
          child: artists.isEmpty
              ? Center(
                  child: Text(
                    'art_walk_community_artists_no_artists_available'
                        .tr()
                        .replaceAll('{title}', title.toLowerCase()),
                    style: const TextStyle(
                      fontSize: 16,
                      color: core.ArtbeatColors.textSecondary,
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: artists.length,
                  itemBuilder: (context, index) {
                    final artist = artists[index];
                    return _buildArtistCard(artist);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildArtistCard(Map<String, dynamic> artist) {
    return InkWell(
      onTap: () {
        // Navigate to artist feed screen
        final userId = artist['userId'] as String?;
        if (userId != null && userId.isNotEmpty) {
          Navigator.pushNamed(
            context,
            '/artist/feed',
            arguments: {'artistUserId': userId},
          );
        } else {
          // Fallback: show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'community_community_artists_text_unable_to_load'.tr(),
              ),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: core.ImageUrlValidator.safeNetworkImage(
                      artist['avatar']?.toString(),
                    ),
                    backgroundColor: color.withValues(alpha: 0.1),
                    child:
                        !core.ImageUrlValidator.isValidImageUrl(
                          artist['avatar']?.toString(),
                        )
                        ? Icon(Icons.person, size: 40, color: color)
                        : null,
                  ),
                  if (showVerifiedBadge && artist['isVerified'] == true)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  if (artist['isOnline'] == true)
                    Positioned(
                      bottom: 0,
                      right: showVerifiedBadge ? 24 : 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                artist['name']?.toString() ??
                    'art_walk_community_artists_unknown_artist'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (artist['specialty']?.toString().isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(
                  artist['specialty'].toString(),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const Spacer(),
              if (showFollowers && artist['followers'] != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${artist['followers']} followers',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              if (showDistance && artist['distance'] != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, size: 12, color: color),
                      const SizedBox(width: 4),
                      Text(
                        artist['distance'].toString(),
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
