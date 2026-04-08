import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
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
  late final ArtworkService _artworkService;
  late final ArtistService _artistService;
  late final TabController _tabController;

  List<ArtworkModel> _allWrittenContent = [];
  List<ArtworkModel> _serializedStories = [];
  List<ArtworkModel> _completedBooks = [];
  bool _isLoading = true;
  String? _error;

  final Map<String, String> _artistNameCache = {};

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
    'Other',
  ];

  final List<String> _sortOptions = [
    'Newest',
    'Oldest',
    'Most Popular',
    'Highest Rated',
    'Most Viewed',
  ];

  @override
  void initState() {
    super.initState();
    _artworkService = context.read<ArtworkService>();
    _artistService = context.read<ArtistService>();
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

      final results = await Future.wait([
        _artworkService.getWrittenContent(
          limit: 50,
          includeSerialized: true,
          includeCompleted: true,
        ),
        _artworkService.getWrittenContent(
          limit: 30,
          includeSerialized: true,
          includeCompleted: false,
        ),
        _artworkService.getWrittenContent(
          limit: 30,
          includeSerialized: false,
          includeCompleted: true,
        ),
      ]);

      if (!mounted) return;
      setState(() {
        _allWrittenContent = results[0];
        _serializedStories = results[1];
        _completedBooks = results[2];
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<ArtworkModel> _getFilteredContent(List<ArtworkModel> content) {
    var filtered = content;

    if (_selectedGenre != 'All') {
      filtered = filtered.where((artwork) {
        final tags = artwork.tags ?? <String>[];
        return tags.contains(_selectedGenre) ||
            artwork.styles.contains(_selectedGenre);
      }).toList();
    }

    if (_showOnlyFree) {
      filtered = filtered
          .where((artwork) => artwork.isForSale == false)
          .toList();
    }

    switch (_selectedSort) {
      case 'Newest':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Oldest':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'Most Popular':
        filtered.sort((a, b) {
          final aTotal =
              a.engagementStats.likeCount +
              a.engagementStats.commentCount +
              a.engagementStats.shareCount +
              a.engagementStats.seenCount +
              a.engagementStats.followCount;
          final bTotal =
              b.engagementStats.likeCount +
              b.engagementStats.commentCount +
              b.engagementStats.shareCount +
              b.engagementStats.seenCount +
              b.engagementStats.followCount;
          return bTotal.compareTo(aTotal);
        });
        break;
      case 'Highest Rated':
        filtered.sort(
          (a, b) => b.engagementStats.likeCount.compareTo(
            a.engagementStats.likeCount,
          ),
        );
        break;
      case 'Most Viewed':
        filtered.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1,
      appBar: HudTopBar(
        title: 'written_content_discovery_title'.tr(),
        subtitle: '',
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).maybePop(),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
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
      child: WorldBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              GlassCard(
                margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                padding: const EdgeInsets.symmetric(vertical: 6),
                radius: 22,
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: [
                    Tab(text: 'written_content_discovery_tab_all'.tr()),
                    Tab(text: 'written_content_discovery_tab_serialized'.tr()),
                    Tab(text: 'written_content_discovery_tab_completed'.tr()),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? _buildErrorView()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildContentGrid(
                            _getFilteredContent(_allWrittenContent),
                          ),
                          _buildContentGrid(
                            _getFilteredContent(_serializedStories),
                          ),
                          _buildContentGrid(
                            _getFilteredContent(_completedBooks),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: GlassCard(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.white70),
            const SizedBox(height: 12),
            Text(
              'written_content_discovery_error'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'common_error'.tr(),
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            GradientCTAButton(
              text: 'common_retry'.tr(),
              icon: Icons.refresh,
              onPressed: _loadWrittenContent,
            ),
          ],
        ),
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
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: content.length,
      itemBuilder: (context, index) => _buildContentCard(content[index]),
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
        return GlassCard(
          padding: EdgeInsets.zero,
          radius: 16,
          onTap: () => _navigateToDetail(artwork),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: artwork.imageUrl.isNotEmpty
                      ? SecureNetworkImage(
                          imageUrl: artwork.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        )
                      : Container(
                          color: Colors.white10,
                          child: const Center(
                            child: Icon(
                              Icons.book,
                              size: 42,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artwork.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            artwork.isSerializing == true
                                ? Icons.schedule
                                : Icons.check_circle,
                            size: 14,
                            color: artwork.isSerializing == true
                                ? const Color(0xFF22D3EE)
                                : const Color(0xFF34D399),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            artwork.isSerializing == true
                                ? 'Ongoing'
                                : 'Complete',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                          const Spacer(),
                          if (artwork.isForSale == true)
                            const Icon(
                              Icons.attach_money,
                              size: 14,
                              color: Color(0xFF34D399),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String message) {
    return Center(
      child: GlassCard(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.library_books, size: 56, color: Colors.white54),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    String dialogGenre = _selectedGenre;
    String dialogSort = _selectedSort;
    bool dialogFreeOnly = _showOnlyFree;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('written_content_discovery_filters'.tr()),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('written_content_discovery_genre'.tr()),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: dialogGenre,
                    items: _genres
                        .map(
                          (genre) => DropdownMenuItem(
                            value: genre,
                            child: Text(genre),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => dialogGenre = value!),
                  ),
                  const SizedBox(height: 16),
                  Text('written_content_discovery_sort'.tr()),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: dialogSort,
                    items: _sortOptions
                        .map(
                          (sort) =>
                              DropdownMenuItem(value: sort, child: Text(sort)),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => dialogSort = value!),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: Text('written_content_discovery_free_only'.tr()),
                    value: dialogFreeOnly,
                    onChanged: (value) =>
                        setDialogState(() => dialogFreeOnly = value ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common_cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedGenre = dialogGenre;
                _selectedSort = dialogSort;
                _showOnlyFree = dialogFreeOnly;
              });
              Navigator.of(context).pop();
            },
            child: Text('common_apply'.tr()),
          ),
        ],
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
