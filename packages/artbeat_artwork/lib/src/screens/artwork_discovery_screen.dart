import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/artwork_model.dart';
import '../services/artwork_discovery_service.dart';

/// Screen for displaying artwork discovery features
class ArtworkDiscoveryScreen extends StatefulWidget {
  const ArtworkDiscoveryScreen({super.key});

  @override
  State<ArtworkDiscoveryScreen> createState() => _ArtworkDiscoveryScreenState();
}

class _ArtworkDiscoveryScreenState extends State<ArtworkDiscoveryScreen>
    with SingleTickerProviderStateMixin {
  final ArtworkDiscoveryService _discoveryService = ArtworkDiscoveryService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late TabController _tabController;
  List<ArtworkModel> _trendingArtworks = [];
  List<ArtworkModel> _personalizedArtworks = [];
  List<ArtworkModel> _similarArtworks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDiscoveryContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDiscoveryContent() async {
    try {
      setState(() => _isLoading = true);

      final userId = _auth.currentUser?.uid;

      // Load different types of recommendations in parallel
      final results = await Future.wait([
        _discoveryService.getTrendingArtworks(limit: 20),
        if (userId != null)
          _discoveryService.getPersonalizedRecommendations(
            limit: 20,
            userId: userId,
          )
        else
          Future.value(<ArtworkModel>[]),
        // For similar artworks, we'll use a placeholder - in real usage this would be based on current artwork
        _discoveryService.getDiscoveryFeed(limit: 20, userId: userId),
      ]);

      setState(() {
        _trendingArtworks = results[0].cast<ArtworkModel>();
        _personalizedArtworks = results[1].cast<ArtworkModel>();
        _similarArtworks = results[2].cast<ArtworkModel>();
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
    return Scaffold(
      appBar: AppBar(
        title: Text('artwork_discovery_title'.tr()),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
                text: 'artwork_personalized_tab'.tr(),
                icon: const Icon(Icons.person)),
            Tab(
                text: 'artwork_trending_tab'.tr(),
                icon: const Icon(Icons.trending_up)),
            Tab(
                text: 'artwork_similar_tab'.tr(),
                icon: const Icon(Icons.shuffle)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDiscoveryContent,
            tooltip: 'artwork_discover_loading'.tr(),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('artwork_discover_loading'.tr())
                ]))
          : _error != null
              ? _buildErrorView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPersonalizedTab(),
                    _buildTrendingTab(),
                    _buildSimilarTab(),
                  ],
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'artwork_discover_error'.tr(),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'common_error'.tr(),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadDiscoveryContent,
            child: Text('common_retry'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalizedTab() {
    final userId = _auth.currentUser?.uid;

    if (userId == null) {
      return _buildSignInPrompt();
    }

    if (_personalizedArtworks.isEmpty) {
      return _buildEmptyState(
        'No personalized recommendations yet',
        'Like some artworks to get better recommendations!',
      );
    }

    return _buildArtworkGrid(_personalizedArtworks, 'Personalized for You');
  }

  Widget _buildTrendingTab() {
    if (_trendingArtworks.isEmpty) {
      return _buildEmptyState(
        'No trending artworks',
        'Check back later for trending content!',
      );
    }

    return _buildArtworkGrid(_trendingArtworks, 'Trending Now');
  }

  Widget _buildSimilarTab() {
    if (_similarArtworks.isEmpty) {
      return _buildEmptyState(
        'No similar artworks found',
        'Explore more artworks to see similar recommendations!',
      );
    }

    return _buildArtworkGrid(_similarArtworks, 'You Might Like');
  }

  Widget _buildSignInPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.login, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Sign in to get personalized recommendations',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Your likes and preferences help us find the perfect artworks for you',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Navigate to sign in screen
              Navigator.of(context).pushNamed('/auth/login');
            },
            child: Text('art_walk_sign_in'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.palette_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildArtworkGrid(List<ArtworkModel> artworks, String title) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
        SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final artwork = artworks[index];
              return _buildArtworkCard(artwork);
            },
            childCount: artworks.length,
          ),
        ),
      ],
    );
  }

  Widget _buildArtworkCard(ArtworkModel artwork) {
    return GestureDetector(
      onTap: () {
        // Navigate to artwork detail screen
        Navigator.pushNamed(
          context,
          '/artwork/detail',
          arguments: {'artworkId': artwork.id},
        );
      },
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
                child: Stack(
                  children: [
                    // Tap hint overlay
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/artwork/detail',
                              arguments: {'artworkId': artwork.id},
                            );
                          },
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.touch_app,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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

                    // Comment count for engagement
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.comment,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${artwork.commentCount}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.visibility,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${artwork.viewCount}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
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
