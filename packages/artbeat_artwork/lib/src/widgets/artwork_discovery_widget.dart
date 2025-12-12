import 'package:flutter/material.dart';
import '../models/artwork_model.dart';
import '../services/artwork_discovery_service.dart';
import 'package:easy_localization/easy_localization.dart';

/// Widget for displaying artwork discovery recommendations
class ArtworkDiscoveryWidget extends StatefulWidget {
  final String? userId;
  final int limit;
  final String title;
  final VoidCallback? onSeeAllPressed;

  const ArtworkDiscoveryWidget({
    super.key,
    this.userId,
    this.limit = 10,
    this.title = 'Discover Artworks',
    this.onSeeAllPressed,
  });

  @override
  State<ArtworkDiscoveryWidget> createState() => _ArtworkDiscoveryWidgetState();
}

class _ArtworkDiscoveryWidgetState extends State<ArtworkDiscoveryWidget> {
  final ArtworkDiscoveryService _discoveryService = ArtworkDiscoveryService();
  List<ArtworkModel> _recommendations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    try {
      setState(() => _isLoading = true);
      final recommendations = await _discoveryService.getDiscoveryFeed(
        limit: widget.limit,
        userId: widget.userId,
      );
      setState(() {
        _recommendations = recommendations.cast<ArtworkModel>();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(height: 8),
              Text('art_walk_failed_to_load_recommendations'
                  .tr()
                  .replaceAll('{error}', _error ?? 'Unknown error')),
              TextButton(
                onPressed: _loadRecommendations,
                child: Text('art_walk_retry'.tr()),
              ),
            ],
          ),
        ),
      );
    }

    if (_recommendations.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.palette_outlined, color: Colors.grey),
              const SizedBox(height: 8),
              Text('art_walk_no_recommendations_available'.tr()),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (widget.onSeeAllPressed != null)
                TextButton(
                  onPressed: widget.onSeeAllPressed,
                  child: Text('art_walk_see_all'.tr()),
                ),
            ],
          ),
        ),

        // Recommendations list
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _recommendations.length,
            itemBuilder: (context, index) {
              final artwork = _recommendations[index];
              return _buildArtworkCard(artwork);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildArtworkCard(ArtworkModel artwork) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artwork image
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  image: DecorationImage(
                    image: NetworkImage(artwork.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // Artwork details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      artwork.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 2),

                    // Artist
                    Text(
                      'by Artist', // Could be enhanced to show actual artist name
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 2),

                    // Medium
                    Text(
                      artwork.medium,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Price if for sale
                    if (artwork.isForSale && artwork.price != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '\$${artwork.price!.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
