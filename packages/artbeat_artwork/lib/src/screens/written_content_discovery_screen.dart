import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart';
import 'package:artbeat_core/artbeat_core.dart' hide ArtworkModel;

/// Screen for discovering written content (books, stories, etc.)
class WrittenContentDiscoveryScreen extends StatefulWidget {
  const WrittenContentDiscoveryScreen({super.key});

  @override
  State<WrittenContentDiscoveryScreen> createState() =>
      _WrittenContentDiscoveryScreenState();
}

class _WrittenContentDiscoveryScreenState
    extends State<WrittenContentDiscoveryScreen>
    with SingleTickerProviderStateMixin {
  final ArtworkService _artworkService = ArtworkService();
  final ArtistService _artistService = ArtistService();

  late TabController _tabController;
  List<ArtworkModel> _allWrittenContent = [];
  List<ArtworkModel> _serializedStories = [];
  List<ArtworkModel> _completedBooks = [];
  bool _isLoading = true;
  String? _error;

  // Cache for artist names
  final Map<String, String> _artistNameCache = {};

  // Filter options
  String _selectedGenre = 'All';
  String _selectedSort = 'Newest';
  bool _showOnlyFree = false;

  final List<String> _genres = [
    'All',
    'Fiction',
    'Non-Fiction',
    'Romance',
    'Mystery',
    'Science Fiction',
    'Fantasy',
    'Biography',
    'Poetry',
    'Horror',
    'Thriller',
    'Historical',
    'Self-Help',
    'Children',
    'Other'
  ];

  final List<String> _sortOptions = [
    'Newest',
    'Oldest',
    'Most Popular',
    'Highest Rated',
    'Most Viewed'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadWrittenContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWrittenContent() async {
    try {
      setState(() => _isLoading = true);

      // Load different types of written content in parallel
      final results = await Future.wait([
        _artworkService.getWrittenContent(
            limit: 50, includeSerialized: true, includeCompleted: true),
        _artworkService.getWrittenContent(
            limit: 30, includeSerialized: true, includeCompleted: false),
        _artworkService.getWrittenContent(
            limit: 30, includeSerialized: false, includeCompleted: true),
      ]);

      setState(() {
        _allWrittenContent = results[0];
        _serializedStories = results[1];
        _completedBooks = results[2];
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<ArtworkModel> _getFilteredContent(List<ArtworkModel> content) {
    var filtered = content;

    // Apply genre filter
    if (_selectedGenre != 'All') {
      filtered = filtered.where((artwork) {
        final tags = artwork.tags ?? <String>[];
        final styles = artwork.styles;
        return tags.contains(_selectedGenre) || styles.contains(_selectedGenre);
      }).toList();
    }

    // Apply free content filter
    if (_showOnlyFree) {
      filtered =
          filtered.where((artwork) => artwork.isForSale == false).toList();
    }

    // Apply sorting
    switch (_selectedSort) {
      case 'Newest':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Oldest':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'Most Popular':
        filtered.sort((a, b) {
          final aTotal = a.engagementStats.likeCount +
              a.engagementStats.commentCount +
              a.engagementStats.shareCount +
              a.engagementStats.seenCount +
              a.engagementStats.followCount;
          final bTotal = b.engagementStats.likeCount +
              b.engagementStats.commentCount +
              b.engagementStats.shareCount +
              b.engagementStats.seenCount +
              b.engagementStats.followCount;
          return bTotal.compareTo(aTotal);
        });
        break;
      case 'Highest Rated':
        // If averageRating is not available, fallback to likeCount or another metric
        filtered.sort((a, b) =>
            b.engagementStats.likeCount.compareTo(a.engagementStats.likeCount));
        break;
      case 'Most Viewed':
        filtered.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('written_content_discovery_title'.tr()),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'written_content_discovery_tab_all'.tr()),
            Tab(text: 'written_content_discovery_tab_serialized'.tr()),
            Tab(text: 'written_content_discovery_tab_completed'.tr()),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.artworkSearch,
                arguments: {'query': ''},
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildContentGrid(_getFilteredContent(_allWrittenContent)),
                    _buildContentGrid(_getFilteredContent(_serializedStories)),
                    _buildContentGrid(_getFilteredContent(_completedBooks)),
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
            'written_content_discovery_error'.tr(),
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
            onPressed: _loadWrittenContent,
            child: Text('common_retry'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildContentGrid(List<ArtworkModel> content) {
    if (content.isEmpty) {
      return _buildEmptyState(
        'written_content_discovery_empty_title'.tr(),
        'written_content_discovery_empty_message'.tr(),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: content.length,
      itemBuilder: (context, index) {
        final artwork = content[index];
        return _buildContentCard(artwork);
      },
    );
  }

  Future<String> _getArtistName(String artistProfileId) async {
    if (_artistNameCache.containsKey(artistProfileId)) {
      return _artistNameCache[artistProfileId]!;
    }

    final profile = await _artistService.getArtistProfileById(artistProfileId);
    final name = profile?.displayName ?? 'Unknown Author';
    _artistNameCache[artistProfileId] = name;
    return name;
  }

  Widget _buildContentCard(ArtworkModel artwork) {
    return FutureBuilder<String>(
      future: _getArtistName(artwork.artistProfileId),
      builder: (context, snapshot) {
        final authorName = snapshot.data ?? 'Loading...';
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _navigateToDetail(artwork),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover image
                Expanded(
                  flex: 3,
                  child: artwork.imageUrl.isNotEmpty
                      ? Image.network(
                          artwork.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            child: const Icon(Icons.book, size: 48),
                          ),
                        )
                      : Container(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: const Icon(Icons.book, size: 48),
                        ),
                ),

                // Content info
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          artwork.title,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        // Author
                        Text(
                          authorName,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const Spacer(),

                        // Status indicators
                        Row(
                          children: [
                            if (artwork.isSerializing == true) ...[
                              Icon(
                                Icons.schedule,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Ongoing',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ] else ...[
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Complete',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                            const Spacer(),
                            if (artwork.isForSale == true)
                              Icon(
                                Icons.attach_money,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
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
      },
    );
  }

  Widget _buildEmptyState(String title, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.library_books, size: 64, color: Colors.grey),
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

  void _showFilterDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('written_content_discovery_filters'.tr()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Genre filter
                Text(
                  'written_content_discovery_genre'.tr(),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedGenre,
                  items: _genres.map((genre) {
                    return DropdownMenuItem(
                      value: genre,
                      child: Text(genre),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedGenre = value!);
                  },
                ),

                const SizedBox(height: 16),

                // Sort filter
                Text(
                  'written_content_discovery_sort'.tr(),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedSort,
                  items: _sortOptions.map((sort) {
                    return DropdownMenuItem(
                      value: sort,
                      child: Text(sort),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedSort = value!);
                  },
                ),

                const SizedBox(height: 16),

                // Free content filter
                CheckboxListTile(
                  title: Text('written_content_discovery_free_only'.tr()),
                  value: _showOnlyFree,
                  onChanged: (value) {
                    setState(() => _showOnlyFree = value ?? false);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('common_cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                this.setState(() {}); // Trigger rebuild with new filters
              },
              child: Text('common_apply'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(ArtworkModel artwork) {
    Navigator.of(context).push(
      MaterialPageRoute<dynamic>(
        builder: (context) => WrittenContentDetailScreen(artworkId: artwork.id),
      ),
    );
  }
}
