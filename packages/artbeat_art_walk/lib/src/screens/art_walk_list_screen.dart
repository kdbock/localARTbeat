import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';

class ArtWalkListScreen extends StatefulWidget {
  const ArtWalkListScreen({super.key});

  @override
  State<ArtWalkListScreen> createState() => _ArtWalkListScreenState();
}

class _ArtWalkListScreenState extends State<ArtWalkListScreen> {
  late final ArtWalkService _artWalkService;
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
    _artWalkService = context.read<ArtWalkService>();
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
        gradient: ArtWalkDesignSystem.backgroundGradient,
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Enter zip code or city',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                      hintStyle: TextStyle(color: Colors.white70),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: onLocationChanged,
                    controller: TextEditingController(text: tempLocation ?? ''),
                  ),
                  const SizedBox(height: 16),

                  // Art pieces range
                  const Text(
                    'Number of Art Pieces',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.terrain),
                      hintStyle: TextStyle(color: Colors.white70),
                    ),
                    style: const TextStyle(color: Colors.white),
                    initialValue: tempDifficulty,
                    hint: Text(
                      'art_walk_art_walk_list_text_select_difficulty'.tr(),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    items: ['Easy', 'Medium', 'Hard']
                        .map(
                          (difficulty) => DropdownMenuItem(
                            value: difficulty,
                            child: Text(
                              difficulty,
                              style: const TextStyle(color: Colors.white),
                            ),
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
                          color: Colors.white,
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.sort),
                      hintStyle: TextStyle(color: Colors.white70),
                    ),
                    style: const TextStyle(color: Colors.white),
                    initialValue: tempSortBy,
                    hint: Text(
                      'art_walk_art_walk_list_text_select_sorting'.tr(),
                      style: const TextStyle(color: Colors.white70),
                    ),
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
                                child: Text(
                                  sort,
                                  style: const TextStyle(color: Colors.white),
                                ),
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
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white70),
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            'art_walk_art_walk_list_text_clear_all'.tr(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onApplyFilters,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ArtbeatColors.primaryPurple,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            'art_walk_art_walk_list_text_apply_filters'.tr(),
                          ),
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

  Future<void> _showSearchDialog() async {
    final TextEditingController searchController = TextEditingController(
      text: _searchQuery,
    );

    final result = await showDialog<String?>(
      context: context,
      builder: (BuildContext context) {
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
              onPressed: () => Navigator.of(context).pop(''),
              child: Text('admin_admin_settings_text_clear'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(searchController.text),
              child: Text('art_walk_art_walk_list_hint_search'.tr()),
            ),
          ],
        );
      },
    );

    searchController.dispose();

    if (!mounted || result == null) return;

    setState(() => _searchQuery = result);
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '🔄 ArtWalkListScreen: Building UI, _isLoading = $_isLoading, _filteredWalks.length = ${_filteredWalks.length}',
    );
    return Scaffold(
      key: _scaffoldKey,
      appBar: ArtWalkDesignSystem.buildAppBar(
        title: 'art_walk_art_walk_list_text_art_walks'.tr(),
        showBackButton: true,
        scaffoldKey: _scaffoldKey,
        showSearch: false,
        showChat: false,
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ArtbeatColors.primaryPurple,
                        ),
                      ),
                      const SizedBox(height: ArtWalkDesignSystem.paddingM),
                      Text(
                        'art_walk_art_walk_list_text_loading_art_walks'.tr(),
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
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'art_walk_art_walk_list_hint_search_art_walks'.tr(),
                hintStyle: const TextStyle(color: Colors.black54),
                prefixIcon: const Icon(Icons.search, color: Colors.black87),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(
                  ArtWalkDesignSystem.paddingM,
                ),
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
                    selectedColor: ArtbeatColors.primaryPurple.withValues(
                      alpha: 0.1,
                    ),
                    checkmarkColor: ArtbeatColors.primaryPurple,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? ArtbeatColors.primaryPurple
                          : ArtbeatColors.textPrimary,
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
                backgroundColor: ArtbeatColors.primaryPurple,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: ArtWalkDesignSystem.buildGlassCard(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        borderRadius: 24,
        child: InkWell(
          onTap: () => _navigateToWalkDetail(walk.id),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 120,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Thumbnail image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
                    ),
                    child: Builder(
                      builder: (context) {
                        // Try cover image first
                        if (walk.coverImageUrl != null &&
                            walk.coverImageUrl!.isNotEmpty) {
                          return CachedNetworkImage(
                            imageUrl: walk.coverImageUrl!,
                            fit: BoxFit.cover,
                            memCacheWidth: 176,
                            memCacheHeight: 176,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  ArtbeatColors.primaryPurple,
                                ),
                                strokeWidth: 2,
                              ),
                            ),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.map,
                              color: ArtbeatColors.primaryPurple,
                              size: 32,
                            ),
                          );
                        }

                        // Try first image URL if cover image is not available
                        if (walk.imageUrls.isNotEmpty &&
                            walk.imageUrls.first.isNotEmpty) {
                          return CachedNetworkImage(
                            imageUrl: walk.imageUrls.first,
                            fit: BoxFit.cover,
                            memCacheWidth: 176,
                            memCacheHeight: 176,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  ArtbeatColors.primaryPurple,
                                ),
                                strokeWidth: 2,
                              ),
                            ),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.map,
                              color: ArtbeatColors.primaryPurple,
                              size: 32,
                            ),
                          );
                        }

                        // Fallback to placeholder
                        return const Icon(
                          Icons.map,
                          color: ArtbeatColors.primaryPurple,
                          size: 32,
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Title and location
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            walk.title,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.92),
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  walk.zipCode ?? 'Location not specified',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Stats row
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Art pieces
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: ArtbeatColors.primaryPurple.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.image,
                                    size: 12,
                                    color: ArtbeatColors.primaryPurple,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${walk.artworkIds.length}',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: ArtbeatColors.primaryPurple,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Duration
                            if (walk.estimatedDuration != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: ArtbeatColors.primaryGreen.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.schedule,
                                      size: 12,
                                      color: ArtbeatColors.primaryGreen,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${walk.estimatedDuration!.round()}m',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: ArtbeatColors.primaryGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(width: 8),

                            // Distance
                            if (walk.estimatedDistance != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: ArtbeatColors.secondaryTeal.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.straighten,
                                      size: 12,
                                      color: ArtbeatColors.secondaryTeal,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${walk.estimatedDistance!.toStringAsFixed(1)}mi',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: ArtbeatColors.secondaryTeal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Difficulty badge
                            if (walk.difficulty != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getDifficultyColor(
                                    walk.difficulty!,
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _getDifficultyColor(
                                      walk.difficulty!,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  walk.difficulty!,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: _getDifficultyColor(
                                      walk.difficulty!,
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

                // Arrow indicator
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return ArtbeatColors.primaryGreen;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return ArtbeatColors.textSecondary;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            size: 64,
            color: ArtbeatColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'art_walk_art_walk_list_text_no_art_walks_found'.tr()
                : 'art_walk_art_walk_list_text_no_art_walks_available'.tr(),
            style: GoogleFonts.spaceGrotesk(
              color: ArtbeatColors.textSecondary.withValues(alpha: 0.92),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'art_walk_art_walk_list_text_try_adjusting_search'.tr()
                : 'art_walk_art_walk_list_text_create_first_art_walk'.tr(),
            style: GoogleFonts.spaceGrotesk(
              color: ArtbeatColors.textSecondary.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
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
                backgroundColor: ArtbeatColors.primaryPurple,
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
