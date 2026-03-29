import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/index.dart';
import '../services/store_preview_read_service.dart';
import 'secure_network_image.dart';

/// Widget for displaying featured artist content and articles in a row
class FeaturedContentRowWidget extends StatelessWidget {
  final String zipCode;
  final VoidCallback? onSeeAllPressed;

  const FeaturedContentRowWidget({
    super.key,
    required this.zipCode,
    this.onSeeAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Featured Content', style: theme.textTheme.headlineMedium),
              TextButton(
                onPressed: onSeeAllPressed,
                child: Text(
                  'See All',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: ArtbeatColors.primaryPurple,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 260,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: context
                .read<StorePreviewReadService>()
                .watchFeaturedContent(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ArtbeatColors.primaryPurple,
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: ArtbeatColors.error,
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'No featured content available',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: ArtbeatColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }

              final featuredContent = snapshot.data!;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: featuredContent.length,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                itemBuilder: (context, index) {
                  final content = featuredContent[index];

                  return GestureDetector(
                    onTap: () {
                      if (content['type'] == 'article') {
                        // Open article
                      } else if (content['type'] == 'artist') {
                        Navigator.pushNamed(
                          context,
                          '/artist/public-profile',
                          arguments: {'artistId': content['artistId']},
                        );
                      }
                    },
                    child: Container(
                      width: 260,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A000000), // 0.1 opacity black
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12.0),
                              ),
                              child: SecureNetworkImage(
                                imageUrl: content['imageUrl'] as String,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorWidget: Container(
                                  height: 150,
                                  color: ArtbeatColors.backgroundSecondary,
                                  child: const Icon(
                                    Icons.article,
                                    size: 40,
                                    color: ArtbeatColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: content['type'] == 'article'
                                          ? const Color(
                                              0x335BC6FF,
                                            ) // 0.2 opacity info color
                                          : const Color(
                                              0x338C52FF,
                                            ), // 0.2 opacity primaryPurple
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                    child: Text(
                                      (content['type'] as String? ?? 'FEATURED')
                                          .toUpperCase(),
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            fontSize: 10,
                                            color: content['type'] == 'article'
                                                ? ArtbeatColors.info
                                                : ArtbeatColors.primaryPurple,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    content['title'] as String,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    content['author'] as String? ??
                                        'ARTbeat Staff',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: ArtbeatColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
