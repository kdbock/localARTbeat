import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_art_walk/src/models/search_criteria_model.dart';
import 'package:artbeat_art_walk/src/models/art_walk_model.dart';
import 'package:artbeat_art_walk/src/models/public_art_model.dart';
import 'package:artbeat_art_walk/src/services/art_walk_service.dart';
import 'package:artbeat_art_walk/src/widgets/art_walk_search_filter.dart';
import 'package:artbeat_art_walk/src/widgets/public_art_search_filter.dart';
import 'package:artbeat_art_walk/src/widgets/art_walk_card.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Comprehensive search results screen for both art walks and public art
///
/// **NOTE**: This screen provides specialized art walk and public art search functionality.
/// For general search across all content types, use core.SearchResultsPage instead.
class SearchResultsScreen extends StatefulWidget {
  final String? initialQuery;
  final String? searchType; // 'art_walks' or 'public_art'

  const SearchResultsScreen({
    Key? key,
    this.initialQuery,
    this.searchType = 'art_walks',
  }) : super(key: key);

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen>
    with TickerProviderStateMixin {
  // Services
  late final ArtWalkService _artWalkService;

  // Controllers
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();

  // State
  bool _isSearching = false;
  bool _isLoadingMore = false;
  bool _showFilters = false;
  int _currentTabIndex = 0;

  // Search Criteria
  ArtWalkSearchCriteria _artWalkCriteria = const ArtWalkSearchCriteria();
  PublicArtSearchCriteria _publicArtCriteria = const PublicArtSearchCriteria();

  // Results
  List<ArtWalkModel> _artWalkResults = [];
  List<PublicArtModel> _publicArtResults = [];
  SearchResult<ArtWalkModel>? _artWalkSearchResult;
  SearchResult<PublicArtModel>? _publicArtSearchResult;

  // Suggestions
  List<String> _searchSuggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();

    _artWalkService = context.read<ArtWalkService>();
    _tabController = TabController(length: 2, vsync: this);

    // Set initial tab based on search type
    if (widget.searchType == 'public_art') {
      _currentTabIndex = 1;
      _tabController.animateTo(1);
    }

    // Set initial query
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _artWalkCriteria = _artWalkCriteria.copyWith(
        searchQuery: widget.initialQuery,
      );
      _publicArtCriteria = _publicArtCriteria.copyWith(
        searchQuery: widget.initialQuery,
      );

      // Start initial search
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch();
      });
    }

    // Setup listeners
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchQueryChanged);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
          _showSuggestions = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreResults();
    }
  }

  void _onSearchQueryChanged() {
    final query = _searchController.text;

    if (query.length >= 2) {
      _loadSearchSuggestions(query);
    } else {
      setState(() {
        _showSuggestions = false;
        _searchSuggestions.clear();
      });
    }
  }

  Future<void> _loadSearchSuggestions(String query) async {
    try {
      final suggestions = await _artWalkService.getSearchSuggestions(query);
      setState(() {
        _searchSuggestions = suggestions;
        _showSuggestions = suggestions.isNotEmpty;
      });
    } catch (e) {
      AppLogger.error('Error loading search suggestions: $e');
    }
  }

  Future<void> _performSearch() async {
    if (_isSearching) return;

    setState(() {
      _isSearching = true;
      _showSuggestions = false;
    });

    try {
      if (_currentTabIndex == 0) {
        // Search art walks
        final result = await _artWalkService.searchArtWalks(_artWalkCriteria);
        setState(() {
          _artWalkSearchResult = result;
          _artWalkResults = result.results;
        });
      } else {
        // Search public art
        final result = await _artWalkService.searchPublicArt(
          _publicArtCriteria,
        );
        setState(() {
          _publicArtSearchResult = result;
          _publicArtResults = result.results;
        });
      }

      // Hide keyboard
      // ignore: use_build_context_synchronously
      FocusScope.of(context).unfocus();

      // Provide haptic feedback
      HapticFeedback.lightImpact();
    } catch (e) {
      AppLogger.error('Search error: $e');
      _showErrorSnackBar('Search failed. Please try again.');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _loadMoreResults() async {
    if (_isLoadingMore) return;

    final hasNextPage = _currentTabIndex == 0
        ? _artWalkSearchResult?.hasNextPage ?? false
        : _publicArtSearchResult?.hasNextPage ?? false;

    if (!hasNextPage) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      if (_currentTabIndex == 0) {
        // Load more art walks
        final nextCriteria = _artWalkCriteria.copyWith(
          lastDocument: _artWalkSearchResult?.lastDocument,
        );

        final result = await _artWalkService.searchArtWalks(nextCriteria);
        setState(() {
          _artWalkResults.addAll(result.results);
          _artWalkSearchResult = SearchResult<ArtWalkModel>(
            results: _artWalkResults,
            totalCount: _artWalkResults.length,
            hasNextPage: result.hasNextPage,
            lastDocument: result.lastDocument,
            searchQuery: result.searchQuery,
            searchDuration: result.searchDuration,
          );
        });
      } else {
        // Load more public art
        final nextCriteria = _publicArtCriteria.copyWith(
          lastDocument: _publicArtSearchResult?.lastDocument,
        );

        final result = await _artWalkService.searchPublicArt(nextCriteria);
        setState(() {
          _publicArtResults.addAll(result.results);
          _publicArtSearchResult = SearchResult<PublicArtModel>(
            results: _publicArtResults,
            totalCount: _publicArtResults.length,
            hasNextPage: result.hasNextPage,
            lastDocument: result.lastDocument,
            searchQuery: result.searchQuery,
            searchDuration: result.searchDuration,
          );
        });
      }
    } catch (e) {
      AppLogger.error('Load more error: $e');
      _showErrorSnackBar('Failed to load more results.');
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _applySearchSuggestion(String suggestion) {
    _searchController.text = suggestion;
    setState(() {
      _showSuggestions = false;
      if (_currentTabIndex == 0) {
        _artWalkCriteria = _artWalkCriteria.copyWith(searchQuery: suggestion);
      } else {
        _publicArtCriteria = _publicArtCriteria.copyWith(
          searchQuery: suggestion,
        );
      }
    });
    _performSearch();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _artWalkCriteria = _artWalkCriteria.copyWith(searchQuery: '');
      _publicArtCriteria = _publicArtCriteria.copyWith(searchQuery: '');
      _artWalkResults.clear();
      _publicArtResults.clear();
      _artWalkSearchResult = null;
      _publicArtSearchResult = null;
      _showSuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Search Art',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.textTheme.bodyLarge?.color,
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: _showFilters ? theme.primaryColor : null,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            tooltip: _showFilters ? 'Hide Filters' : 'Show Filters',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: theme.primaryColor,
          tabs: const [
            Tab(icon: Icon(Icons.route), text: 'Art Walks'),
            Tab(icon: Icon(Icons.palette), text: 'Public Art'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            color: theme.scaffoldBackgroundColor,
            child: Column(
              children: [
                // Main search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: _currentTabIndex == 0
                        ? 'Search art walks...'
                        : 'Search public art...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearSearch,
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(color: theme.primaryColor),
                    ),
                    filled: true,
                    fillColor: theme.cardColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),

                const SizedBox(height: 8),

                // Search button and results summary
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSearching ? null : _performSearch,
                        icon: _isSearching
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.search),
                        label: Text(_isSearching ? 'Searching...' : 'Search'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Results summary
                    if (_currentTabIndex == 0 && _artWalkSearchResult != null)
                      Text(
                        '${_artWalkResults.length} results',
                        style: theme.textTheme.bodySmall,
                      )
                    else if (_currentTabIndex == 1 &&
                        _publicArtSearchResult != null)
                      Text(
                        '${_publicArtResults.length} results',
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Search Suggestions
          if (_showSuggestions && _searchSuggestions.isNotEmpty)
            Container(
              color: theme.cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      'Suggestions',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchSuggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _searchSuggestions[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.search, size: 20),
                        title: Text(suggestion),
                        onTap: () => _applySearchSuggestion(suggestion),
                      );
                    },
                  ),
                ],
              ),
            ),

          // Filters (when expanded)
          if (_showFilters)
            Expanded(
              child: Container(
                color: Colors.grey.shade50,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: _currentTabIndex == 0
                      ? ArtWalkSearchFilter(
                          initialCriteria: _artWalkCriteria,
                          onCriteriaChanged: (criteria) {
                            setState(() {
                              _artWalkCriteria = criteria;
                            });
                          },
                          onClearFilters: () {
                            setState(() {
                              _artWalkCriteria = const ArtWalkSearchCriteria();
                              _artWalkResults.clear();
                              _artWalkSearchResult = null;
                            });
                          },
                        )
                      : PublicArtSearchFilter(
                          initialCriteria: _publicArtCriteria,
                          onCriteriaChanged: (criteria) {
                            setState(() {
                              _publicArtCriteria = criteria;
                            });
                          },
                          onClearFilters: () {
                            setState(() {
                              _publicArtCriteria =
                                  const PublicArtSearchCriteria();
                              _publicArtResults.clear();
                              _publicArtSearchResult = null;
                            });
                          },
                        ),
                ),
              ),
            )
          else
            // Search Results
            Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching &&
        ((_currentTabIndex == 0 && _artWalkResults.isEmpty) ||
            (_currentTabIndex == 1 && _publicArtResults.isEmpty))) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentTabIndex == 0) {
      return _buildArtWalkResults();
    } else {
      return _buildPublicArtResults();
    }
  }

  Widget _buildArtWalkResults() {
    if (_artWalkResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No art walks found',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search terms or filters',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      itemCount: _artWalkResults.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _artWalkResults.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final artWalk = _artWalkResults[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: ArtWalkCard(
            artWalk: artWalk,
            onTap: () {
              Navigator.of(context).pushNamed(
                '/art-walk/detail',
                arguments: {'artWalkId': artWalk.id},
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPublicArtResults() {
    if (_publicArtResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.palette, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No public art found',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search terms or filters',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _publicArtResults.length + (_isLoadingMore ? 2 : 0),
      itemBuilder: (context, index) {
        if (index >= _publicArtResults.length) {
          return const Card(child: Center(child: CircularProgressIndicator()));
        }

        final publicArt = _publicArtResults[index];
        return _buildPublicArtCard(publicArt);
      },
    );
  }

  Widget _buildPublicArtCard(PublicArtModel publicArt) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigate to public art detail
          Navigator.of(context).pushNamed(
            '/public-art/detail',
            arguments: {'publicArtId': publicArt.id},
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  color: Colors.grey.shade200,
                ),
                child:
                    ImageUrlValidator.safeCorrectedNetworkImage(
                          publicArt.imageUrl,
                        ) !=
                        null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image(
                          image: ImageUrlValidator.safeCorrectedNetworkImage(
                            publicArt.imageUrl,
                          )!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade300,
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey.shade500,
                                size: 32,
                              ),
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.palette,
                        color: Colors.grey.shade400,
                        size: 32,
                      ),
              ),
            ),

            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      publicArt.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (publicArt.artistName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'by ${publicArt.artistName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const Spacer(),

                    Row(
                      children: [
                        if (publicArt.isVerified) ...[
                          Icon(
                            Icons.verified,
                            size: 14,
                            color: theme.primaryColor,
                          ),
                          const SizedBox(width: 4),
                        ],

                        Icon(
                          Icons.remove_red_eye,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${publicArt.viewCount}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade500,
                          ),
                        ),

                        const Spacer(),

                        if (publicArt.artType != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              publicArt.artType!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.primaryColor,
                                fontSize: 10,
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
      ),
    );
  }
}
