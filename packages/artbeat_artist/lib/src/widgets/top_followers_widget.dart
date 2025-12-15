import 'package:artbeat_core/artbeat_core.dart';
import 'package:flutter/material.dart';
import '../models/top_follower_model.dart';
import '../services/subscription_service.dart' as artist_subscription;
import 'package:easy_localization/easy_localization.dart';

/// Widget that displays top engaged followers (MySpace-style top 8)
class TopFollowersWidget extends StatefulWidget {
  final String artistProfileId;
  final String? artistUserId;
  final VoidCallback? onFollowerTapped;
  final int limit;

  const TopFollowersWidget({
    super.key,
    required this.artistProfileId,
    this.artistUserId,
    this.onFollowerTapped,
    this.limit = 8,
  });

  @override
  State<TopFollowersWidget> createState() => _TopFollowersWidgetState();
}

class _TopFollowersWidgetState extends State<TopFollowersWidget> {
  final artist_subscription.SubscriptionService _subscriptionService =
      artist_subscription.SubscriptionService();
  late Future<List<TopFollowerModel>> _topFollowersFuture;

  @override
  void initState() {
    super.initState();
    _topFollowersFuture = _subscriptionService.getTopFollowers(
      artistProfileId: widget.artistProfileId,
      limit: widget.limit,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TopFollowerModel>>(
      future: _topFollowersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState();
        }

        final topFollowers = snapshot.data ?? [];

        if (topFollowers.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    tr('art_walk_top_fans'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${topFollowers.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                itemCount: topFollowers.length,
                itemBuilder: (context, index) {
                  final follower = topFollowers[index];
                  return _buildFollowerCard(context, follower, index);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFollowerCard(
    BuildContext context,
    TopFollowerModel follower,
    int index,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        left: index == 0 ? 4.0 : 4.0,
        right: 4.0,
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/artist/profile',
            arguments: {'userId': follower.followerId},
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.amber,
                      width: 2,
                    ),
                    image: ImageUrlValidator.isValidImageUrl(
                            follower.followerAvatarUrl)
                        ? DecorationImage(
                            image: ImageUrlValidator.safeNetworkImage(
                                follower.followerAvatarUrl)!,
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: !ImageUrlValidator.isValidImageUrl(
                          follower.followerAvatarUrl)
                      ? const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.grey,
                        )
                      : null,
                ),
                if (follower.isVerified)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '#${index + 1}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 100,
              child: Text(
                follower.followerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            Text(
              '${follower.engagementScore} pts',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                tr('art_walk_top_fans'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 80,
                        height: 12,
                        color: Colors.grey[300],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                tr('art_walk_top_fans'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              tr('art_walk_error_loading_top_fans'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                tr('art_walk_top_fans'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              tr('art_walk_no_engaged_followers_yet'),
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}
