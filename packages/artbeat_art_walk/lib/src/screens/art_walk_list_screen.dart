import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';

class ArtWalkListScreen extends StatefulWidget {
  const ArtWalkListScreen({super.key});

  @override
  State<ArtWalkListScreen> createState() => _ArtWalkListScreenState();
}

class _ArtWalkListScreenState extends State<ArtWalkListScreen> {
  final ArtWalkService _artWalkService = ArtWalkService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<ArtWalkModel> _artWalks = [];
  List<ArtWalkModel> _filteredWalks = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'All';

  // Pagination state
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _loadedCount = 0;
  static const int _pageSize = 20;

  // New filter state variables
  String? _selectedLocation;
  RangeValues? _artPieceRange;
  RangeValues? _durationRange;
  RangeValues? _distanceRange;
  String? _selectedDifficulty;
  bool? _isAccessibleOnly;
  String? _selectedSortBy;

  final List<String> _filterOptions = [
    'All',
    'My Walks',
    'Popular',
    'Nearby',
    'Recent',
    'Easy',
    'Medium',
    'Hard',
    'Short (< 30 min)',
    'Medium (30-60 min)',
    'Long (> 60 min)',
    'Accessible',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    debugPrint(
      '🔄 ArtWalkListScreen: Starting to load data, _isLoading = true',
    );

    try {
      await _loadArtWalks();
    } catch (e) {
      debugPrint('❌ ArtWalkListScreen: Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint(
          '✅ ArtWalkListScreen: Finished loading data, _isLoading = false',
        );
      }
    }
  }

  Future<void> _loadArtWalks() async {
    try {
      debugPrint('🔍 ArtWalkListScreen: Calling getPopularArtWalks...');
      final walks = await _artWalkService.getPopularArtWalks(
        limit: _pageSize,
      ); // Reduced limit for better performance
      debugPrint('📋 ArtWalkListScreen: Loaded ${walks.length} art walks');
      if (mounted) {
        setState(() {
          _artWalks = walks;
          _loadedCount = walks.length;
          _hasMoreData = walks.length == _pageSize;
          debugPrint(
            '🔄 ArtWalkListScreen: Set state with ${walks.length} walks',
          );
        });
        _applyFilters();
        debugPrint(
          '📋 ArtWalkListScreen: Applied filters, filtered: ${_filteredWalks.length}',
        );
      }
    } catch (e) {
      debugPrint('❌ ArtWalkListScreen: Error loading art walks: $e');
    }
  }

  Future<void> _loadMoreArtWalks() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() => _isLoadingMore = true);
    debugPrint('🔄 ArtWalkListScreen: Loading more art walks...');

    try {
      // Load more by increasing the limit
      final moreWalks = await _artWalkService.getPopularArtWalks(
        limit: _loadedCount + _pageSize,
      );
      final newWalks = moreWalks.skip(_loadedCount).take(_pageSize).toList();

      if (mounted && newWalks.isNotEmpty) {
        setState(() {
          _artWalks.addAll(newWalks);
          _loadedCount += newWalks.length;
          _hasMoreData = newWalks.length == _pageSize;
          debugPrint(
            '📋 ArtWalkListScreen: Added ${newWalks.length} more walks, total: ${_artWalks.length}',
          );
        });
        _applyFilters();
      } else {
        _hasMoreData = false;
      }
    } catch (e) {
      debugPrint('❌ ArtWalkListScreen: Error loading more art walks: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _applyFilters() {
    debugPrint(
      '🔍 ArtWalkListScreen: Applying filters to ${_artWalks.length} walks',
    );
    List<ArtWalkModel> filtered = _artWalks;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (walk) =>
                walk.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                walk.description.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                (walk.tags?.any(
                      (tag) => tag.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ),
                    ) ??
                    false),
          )
          .toList();
    }

    // Apply category filter
    switch (_selectedFilter) {
      case 'My Walks':
        final userId = _artWalkService.getCurrentUserId();
        if (userId != null) {
          filtered = filtered.where((walk) => walk.userId == userId).toList();
        }
        break;
      case 'Popular':
        filtered.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        break;
      case 'Nearby':
        // For now, just show all - could be enhanced with location filtering
        break;
      case 'Recent':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Easy':
        filtered = filtered.where((walk) => walk.difficulty == 'Easy').toList();
        break;
      case 'Medium':
        filtered = filtered
            .where((walk) => walk.difficulty == 'Medium')
            .toList();
        break;
      case 'Hard':
        filtered = filtered.where((walk) => walk.difficulty == 'Hard').toList();
        break;
      case 'Short (< 30 min)':
        filtered = filtered
            .where(
              (walk) =>
                  walk.estimatedDuration != null &&
                  walk.estimatedDuration! < 30,
            )
            .toList();
        break;
      case 'Medium (30-60 min)':
        filtered = filtered
            .where(
              (walk) =>
                  walk.estimatedDuration != null &&
                  walk.estimatedDuration! >= 30 &&
                  walk.estimatedDuration! <= 60,
            )
            .toList();
        break;
      case 'Long (> 60 min)':
        filtered = filtered
            .where(
              (walk) =>
                  walk.estimatedDuration != null &&
                  walk.estimatedDuration! > 60,
            )
            .toList();
        break;
      case 'Accessible':
        filtered = filtered.where((walk) => walk.isAccessible == true).toList();
        break;
    }

    // Apply location filter
    if (_selectedLocation != null && _selectedLocation!.isNotEmpty) {
      filtered = filtered
          .where(
            (walk) =>
                walk.zipCode?.toLowerCase().contains(
                  _selectedLocation!.toLowerCase(),
                ) ??
                false,
          )
          .toList();
    }

    // Apply art piece count filter
    if (_artPieceRange != null) {
      filtered = filtered
          .where(
            (walk) =>
                walk.artworkIds.length >= _artPieceRange!.start &&
                walk.artworkIds.length <= _artPieceRange!.end,
          )
          .toList();
    }

    // Apply duration filter
    if (_durationRange != null) {
      filtered = filtered
          .where(
            (walk) =>
                walk.estimatedDuration != null &&
                walk.estimatedDuration! >= _durationRange!.start &&
                walk.estimatedDuration! <= _durationRange!.end,
          )
          .toList();
    }

    // Apply distance filter
    if (_distanceRange != null) {
      filtered = filtered
          .where(
            (walk) =>
                walk.estimatedDistance != null &&
                walk.estimatedDistance! >= _distanceRange!.start &&
                walk.estimatedDistance! <= _distanceRange!.end,
          )
          .toList();
    }

    // Apply difficulty filter
    if (_selectedDifficulty != null && _selectedDifficulty!.isNotEmpty) {
      filtered = filtered
          .where((walk) => walk.difficulty == _selectedDifficulty)
          .toList();
    }

    // Apply accessibility filter
    if (_isAccessibleOnly == true) {
      filtered = filtered.where((walk) => walk.isAccessible == true).toList();
    }

    // Apply sorting
    if (_selectedSortBy != null) {
      switch (_selectedSortBy) {
        case 'Popularity':
          filtered.sort((a, b) => b.viewCount.compareTo(a.viewCount));
          break;
        case 'Recent':
          filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case 'Duration':
          filtered.sort((a, b) {
            final aDuration = a.estimatedDuration ?? double.maxFinite;
            final bDuration = b.estimatedDuration ?? double.maxFinite;
            return aDuration.compareTo(bDuration);
          });
          break;
        case 'Distance':
          filtered.sort((a, b) {
            final aDistance = a.estimatedDistance ?? double.maxFinite;
            final bDistance = b.estimatedDistance ?? double.maxFinite;
            return aDistance.compareTo(bDistance);
          });
          break;
        case 'Art Pieces':
          filtered.sort(
            (a, b) => b.artworkIds.length.compareTo(a.artworkIds.length),
          );
          break;
      }
    }

    debugPrint('📋 ArtWalkListScreen: Filtered to ${filtered.length} walks');
    setState(() => _filteredWalks = filtered);
    debugPrint(
      '✅ ArtWalkListScreen: Applied filters, _filteredWalks now has ${_filteredWalks.length} items',
    );
  }

  void _showAdvancedFilters() {
    // Create temporary filter values for the modal
    String? tempLocation = _selectedLocation;
    RangeValues? tempArtPieceRange = _artPieceRange;
    RangeValues? tempDurationRange = _durationRange;
    RangeValues? tempDistanceRange = _distanceRange;
    String? tempDifficulty = _selectedDifficulty;
    bool? tempAccessibleOnly = _isAccessibleOnly;
    String? tempSortBy = _selectedSortBy;

    showModalBottomSheet<Widget>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => _buildAdvancedFiltersSheet(
          tempLocation: tempLocation,
          tempArtPieceRange: tempArtPieceRange,
          tempDurationRange: tempDurationRange,
          tempDistanceRange: tempDistanceRange,
          tempDifficulty: tempDifficulty,
          tempAccessibleOnly: tempAccessibleOnly,
          tempSortBy: tempSortBy,
          onLocationChanged: (value) => tempLocation = value,
          onArtPieceRangeChanged: (value) => tempArtPieceRange = value,
          onDurationRangeChanged: (value) => tempDurationRange = value,
          onDistanceRangeChanged: (value) => tempDistanceRange = value,
          onDifficultyChanged: (value) => tempDifficulty = value,
          onAccessibleChanged: (value) => tempAccessibleOnly = value,
          onSortByChanged: (value) => tempSortBy = value,
          onApplyFilters: () {
            setState(() {
              _selectedLocation = tempLocation;
              _artPieceRange = tempArtPieceRange;
              _durationRange = tempDurationRange;
              _distanceRange = tempDistanceRange;
              _selectedDifficulty = tempDifficulty;
              _isAccessibleOnly = tempAccessibleOnly;
              _selectedSortBy = tempSortBy;
            });
            _applyFilters();
            Navigator.pop(context);
          },
          onClearFilters: () {
            setModalState(() {
              tempLocation = null;
              tempArtPieceRange = null;
              tempDurationRange = null;
              tempDistanceRange = null;
              tempDifficulty = null;
              tempAccessibleOnly = null;
              tempSortBy = null;
            });
          },
        ),
      ),
    );
  }

  Widget _buildAdvancedFiltersSheet({
    required String? tempLocation,
    required RangeValues? tempArtPieceRange,
    required RangeValues? tempDurationRange,
    required RangeValues? tempDistanceRange,
    required String? tempDifficulty,
    required bool? tempAccessibleOnly,
    required String? tempSortBy,
    required void Function(String?) onLocationChanged,
    required void Function(RangeValues?) onArtPieceRangeChanged,
    required void Function(RangeValues?) onDurationRangeChanged,
    required void Function(RangeValues?) onDistanceRangeChanged,
    required void Function(String?) onDifficultyChanged,
    required void Function(bool?) onAccessibleChanged,
    required void Function(String?) onSortByChanged,
    required VoidCallback onApplyFilters,
    required VoidCallback onClearFilters,
  }) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: ArtWalkDesignSystem.headerGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Text(
                  'art_walk_filter_text_advanced_filters'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Filters content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location filter
                  const Text(
                    'Location',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Enter zip code or city',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    onChanged: onLocationChanged,
                    controller: TextEditingController(text: tempLocation ?? ''),
                  ),
                  const SizedBox(height: 16),

                  // Art pieces range
                  const Text(
                    'Number of Art Pieces',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  RangeSlider(
                    values: tempArtPieceRange ?? const RangeValues(0, 50),
                    min: 0,
                    max: 50,
                    divisions: 50,
                    labels: RangeLabels(
                      (tempArtPieceRange?.start ?? 0).round().toString(),
                      (tempArtPieceRange?.end ?? 50).round().toString(),
                    ),
                    onChanged: onArtPieceRangeChanged,
                  ),

                  // Duration range
                  const Text(
                    'Duration (minutes)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  RangeSlider(
                    values: tempDurationRange ?? const RangeValues(15, 180),
                    min: 15,
                    max: 180,
                    divisions: 33,
                    labels: RangeLabels(
                      '${(tempDurationRange?.start ?? 15).round()} min',
                      '${(tempDurationRange?.end ?? 180).round()} min',
                    ),
                    onChanged: onDurationRangeChanged,
                  ),

                  // Distance range
                  const Text(
                    'Distance (miles)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  RangeSlider(
                    values: tempDistanceRange ?? const RangeValues(0.5, 10),
                    min: 0.5,
                    max: 10,
                    divisions: 19,
                    labels: RangeLabels(
                      '${(tempDistanceRange?.start ?? 0.5).toStringAsFixed(1)} mi',
                      '${(tempDistanceRange?.end ?? 10).toStringAsFixed(1)} mi',
                    ),
                    onChanged: onDistanceRangeChanged,
                  ),

                  // Difficulty
                  const Text(
                    'Difficulty',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.terrain),
                    ),
                    initialValue: tempDifficulty,
                    hint: Text('art_walk_art_walk_list_text_select_difficulty'.tr()),
                    items: ['Easy', 'Medium', 'Hard']
                        .map(
                          (difficulty) => DropdownMenuItem(
                            value: difficulty,
                            child: Text(difficulty),
                          ),
                        )
                        .toList(),
                    onChanged: onDifficultyChanged,
                  ),

                  // Accessibility
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'Accessible Only',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: tempAccessibleOnly ?? false,
                        onChanged: onAccessibleChanged,
                      ),
                    ],
                  ),

                  // Sort by
                  const SizedBox(height: 16),
                  const Text(
                    'Sort By',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.sort),
                    ),
                    initialValue: tempSortBy,
                    hint: Text('art_walk_art_walk_list_text_select_sorting'.tr()),
                    items:
                        [
                              'Popularity',
                              'Recent',
                              'Duration',
                              'Distance',
                              'Art Pieces',
                            ]
                            .map(
                              (sort) => DropdownMenuItem(
                                value: sort,
                                child: Text(sort),
                              ),
                            )
                            .toList(),
                    onChanged: onSortByChanged,
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onClearFilters,
                          child: Text('art_walk_art_walk_list_text_clear_all'.tr()),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onApplyFilters,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ArtWalkColors.primaryTeal,
                          ),
                          child: Text('art_walk_art_walk_list_text_apply_filters'.tr()),
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
    );
  }

  void _showSearchDialog() {
    final TextEditingController searchController = TextEditingController(
      text: _searchQuery,
    );

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('art_walk_art_walk_list_hint_search_art_walks'.tr()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search by title, description, tags...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(
                        () {},
                      ); // Trigger rebuild for real-time filtering preview
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Search in: Title, Description, Tags, Difficulty, Location',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _applyFilters();
                    });
                    searchController.dispose();
                    Navigator.of(context).pop();
                  },
                  child: Text('admin_admin_settings_text_clear'.tr()),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = searchController.text;
                      _applyFilters();
                    });
                    searchController.dispose();
                    Navigator.of(context).pop();
                  },
                  child: Text('art_walk_art_walk_list_hint_search'.tr()),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      searchController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '🔄 ArtWalkListScreen: Building UI, _isLoading = $_isLoading, _filteredWalks.length = ${_filteredWalks.length}',
    );
    return Scaffold(
      key: _scaffoldKey,
      appBar: ArtWalkDesignSystem.buildAppBar(
        title: 'Art Walks',
        showBackButton: true,
        scaffoldKey: _scaffoldKey,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: _showSearchDialog,
            tooltip: 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.message, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pushNamed('/messaging');
            },
            tooltip: 'Messages',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showAdvancedFilters,
            tooltip: 'Advanced Filters',
          ),
        ],
      ),
      drawer: const ArtWalkDrawer(),
      body: ArtWalkDesignSystem.buildScreenContainer(
        child: _isLoading
            ? Center(
                child: ArtWalkDesignSystem.buildGlassCard(
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ArtWalkDesignSystem.primaryTeal,
                        ),
                      ),
                      SizedBox(height: ArtWalkDesignSystem.paddingM),
                      Text(
                        'Loading art walks...',
                        style: ArtWalkDesignSystem.cardTitleStyle,
                      ),
                    ],
                  ),
                ),
              )
            : _buildContent(),
      ),
      floatingActionButton: ArtWalkDesignSystem.buildFloatingActionButton(
        onPressed: _navigateToCreateWalk,
        icon: Icons.add_location,
        tooltip: 'Create Art Walk',
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSearchAndFilterBar(),
        _filteredWalks.isEmpty ? _buildEmptyState() : _buildWalksList(),
      ],
    );
  }

  Widget _buildSearchAndFilterBar() {
    return ArtWalkDesignSystem.buildGlassCard(
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: ArtWalkDesignSystem.cardDecoration(),
            child: TextField(
              style: ArtWalkDesignSystem.cardTitleStyle,
              decoration: const InputDecoration(
                hintText: 'Search art walks...',
                hintStyle: ArtWalkDesignSystem.cardSubtitleStyle,
                prefixIcon: Icon(
                  Icons.search,
                  color: ArtWalkDesignSystem.primaryTeal,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(ArtWalkDesignSystem.paddingM),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _applyFilters();
              },
            ),
          ),
          const SizedBox(height: ArtWalkDesignSystem.paddingM),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filterOptions.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedFilter = filter);
                      _applyFilters();
                    },
                    backgroundColor: Colors.white,
                    selectedColor: ArtWalkColors.primaryTeal.withValues(
                      alpha: 0.1,
                    ),
                    checkmarkColor: ArtWalkColors.primaryTeal,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? ArtWalkColors.primaryTeal
                          : ArtWalkColors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalksList() {
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _filteredWalks.length,
          itemBuilder: (context, index) {
            final walk = _filteredWalks[index];
            return _buildWalkCard(walk);
          },
        ),
        if (_hasMoreData)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isLoadingMore ? null : _loadMoreArtWalks,
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtWalkColors.primaryTeal,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: _isLoadingMore
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text('art_walk_art_walk_list_text_load_more_art'.tr()),
            ),
          ),
      ],
    );
  }

  Widget _buildWalkCard(ArtWalkModel walk) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToWalkDetail(walk.id),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image with overlay
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  // Cover image - robust loading with error handling
                  Builder(
                    builder: (context) {
                      // Try cover image first
                      if (walk.coverImageUrl != null &&
                          walk.coverImageUrl!.isNotEmpty) {
                        return CachedNetworkImage(
                          imageUrl: walk.coverImageUrl!,
                          fit: BoxFit.cover,
                          memCacheWidth:
                              400, // Limit cache size for performance
                          memCacheHeight: 225,
                          placeholder: (context, url) => Container(
                            decoration: BoxDecoration(
                              color: ArtWalkColors.primaryTeal.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  ArtWalkColors.primaryTeal,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            decoration: BoxDecoration(
                              color: ArtWalkColors.primaryTeal.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.map,
                                color: ArtWalkColors.primaryTeal,
                                size: 48,
                              ),
                            ),
                          ),
                        );
                      }

                      // Try first image URL if cover image is not available
                      if (walk.imageUrls.isNotEmpty &&
                          walk.imageUrls.first.isNotEmpty) {
                        return CachedNetworkImage(
                          imageUrl: walk.imageUrls.first,
                          fit: BoxFit.cover,
                          memCacheWidth: 400,
                          memCacheHeight: 225,
                          placeholder: (context, url) => Container(
                            decoration: BoxDecoration(
                              color: ArtWalkColors.primaryTeal.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  ArtWalkColors.primaryTeal,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            decoration: BoxDecoration(
                              color: ArtWalkColors.primaryTeal.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.map,
                                color: ArtWalkColors.primaryTeal,
                                size: 48,
                              ),
                            ),
                          ),
                        );
                      }

                      // Fallback to placeholder
                      return Container(
                        decoration: BoxDecoration(
                          color: ArtWalkColors.primaryTeal.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.map,
                            color: ArtWalkColors.primaryTeal,
                            size: 48,
                          ),
                        ),
                      );
                    },
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                  // Title and stats overlay
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          walk.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                walk.zipCode ?? 'Location not specified',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Text(
                    walk.description,
                    style: const TextStyle(
                      color: ArtWalkColors.textSecondary,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Stats and actions
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      // Art pieces count
                      _buildStatItem(
                        icon: Icons.image,
                        label: '${walk.artworkIds.length} pieces',
                      ),
                      // Views count
                      _buildStatItem(
                        icon: Icons.visibility,
                        label: '${walk.viewCount} views',
                      ),
                      // Duration
                      if (walk.estimatedDuration != null)
                        _buildStatItem(
                          icon: Icons.schedule,
                          label: '${walk.estimatedDuration!.round()} min',
                        ),
                      // Distance
                      if (walk.estimatedDistance != null)
                        _buildStatItem(
                          icon: Icons.straighten,
                          label:
                              '${walk.estimatedDistance!.toStringAsFixed(1)} mi',
                        ),
                      // Difficulty
                      if (walk.difficulty != null)
                        _buildStatItem(
                          icon: Icons.terrain,
                          label: walk.difficulty!,
                        ),
                      // Accessibility
                      if (walk.isAccessible == true)
                        _buildStatItem(
                          icon: Icons.accessible,
                          label: 'Accessible',
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Action button
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToWalkDetail(walk.id),
                      icon: const Icon(Icons.explore, size: 16),
                      label: Text('art_walk_art_walk_list_text_explore'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ArtWalkColors.primaryTeal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: ArtWalkColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: ArtWalkColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            size: 64,
            color: ArtWalkColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No art walks found for "$_searchQuery"'
                : 'No art walks available',
            style: const TextStyle(
              color: ArtWalkColors.textSecondary,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'Create your first art walk to get started',
            style: TextStyle(
              color: ArtWalkColors.textSecondary.withValues(alpha: 0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToCreateWalk,
              icon: const Icon(Icons.add),
              label: Text('art_walk_art_walk_list_text_create_art_walk'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtWalkColors.primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToWalkDetail(String walkId) {
    Navigator.pushNamed(
      context,
      '/art-walk/detail',
      arguments: {'walkId': walkId},
    );
  }

  void _navigateToCreateWalk() {
    Navigator.pushNamed(context, '/art-walk/create');
  }
}
