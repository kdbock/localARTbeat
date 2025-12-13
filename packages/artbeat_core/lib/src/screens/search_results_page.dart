import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../controllers/search_controller.dart' as search_controller;
import '../models/known_entity_model.dart';
import '../theme/artbeat_colors.dart';
import '../widgets/enhanced_universal_header.dart';
import '../widgets/main_layout.dart';
import '../widgets/artbeat_gradient_background.dart';
import '../services/search/search_history.dart';
export '../controllers/search_controller.dart' show SearchSortOption;

/// Unified search results page that displays all search results
class SearchResultsPage extends StatefulWidget {
  /// Initial search query from URL parameters
  final String? initialQuery;

  const SearchResultsPage({super.key, this.initialQuery});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  late final TextEditingController _searchController;
  late final search_controller.SearchController _searchProvider;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchProvider = context.read<search_controller.SearchController>();

    // Initialize with query from URL if provided
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchProvider.search(widget.initialQuery!);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ArtbeatGradientBackground(
      intensity: 0.3,
      child: MainLayout(
        currentIndex: 1, // Search tab
        appBar: const EnhancedUniversalHeader(
          title: 'Search',
          showLogo: false,
          showSearch: false,
          showBackButton: true,
        ),
        child: Column(
          children: [
            _buildSearchBar(),
            Consumer<search_controller.SearchController>(
              builder: (context, searchProvider, child) {
                if (searchProvider.query.isNotEmpty &&
                    !searchProvider.isEmpty) {
                  return _buildFiltersAndSort(searchProvider);
                }
                return const SizedBox.shrink();
              },
            ),
            Expanded(
              child: Consumer<search_controller.SearchController>(
                builder: (context, searchProvider, child) {
                  return _buildContent(searchProvider);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF5F5F5)],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: ArtbeatColors.primaryPurple.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            blurRadius: 4,
            offset: const Offset(-2, -2),
          ),
          BoxShadow(
            color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'search_hint'.tr(),
          hintStyle: TextStyle(
            color: ArtbeatColors.textSecondary.withValues(alpha: 0.7),
            fontSize: 16,
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(8),
            child: Container(
              decoration: BoxDecoration(
                gradient: ArtbeatColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.search, color: Colors.white, size: 20),
            ),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: ArtbeatColors.textSecondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.clear,
                      color: ArtbeatColors.textSecondary,
                      size: 18,
                    ),
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _searchProvider.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 16,
          ),
        ),
        style: const TextStyle(
          fontSize: 16,
          color: ArtbeatColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        onChanged: (value) {
          _searchProvider.updateQuery(value);
        },
        onSubmitted: (value) {
          _searchProvider.search(value);
        },
      ),
    );
  }

  Widget _buildFiltersAndSort(
    search_controller.SearchController searchProvider,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // "All" chip to clear filters
                GestureDetector(
                  onTap: searchProvider.hasActiveFilters
                      ? searchProvider.clearFilters
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      gradient: searchProvider.hasActiveFilters
                          ? null
                          : ArtbeatColors.primaryGradient,
                      color: searchProvider.hasActiveFilters
                          ? Colors.transparent
                          : null,
                      border: Border.all(
                        color: ArtbeatColors.primaryPurple.withValues(
                          alpha: 0.3,
                        ),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'search_filter_all'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: searchProvider.hasActiveFilters
                            ? ArtbeatColors.primaryPurple
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
                // Entity type filter chips
                ...KnownEntityType.values
                    .where((type) => type != KnownEntityType.unknown)
                    .map((type) {
                      final isSelected = searchProvider.selectedFilters
                          .contains(type);
                      return GestureDetector(
                        onTap: () => searchProvider.toggleFilter(type),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? ArtbeatColors.primaryGradient
                                : null,
                            color: isSelected
                                ? null
                                : ArtbeatColors.primaryPurple.withValues(
                                    alpha: 0.1,
                                  ),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : ArtbeatColors.primaryPurple.withValues(
                                      alpha: 0.3,
                                    ),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            type.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : ArtbeatColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    })
                    .toList(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Sort options
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  'Sort: ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ArtbeatColors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
                ...search_controller.SearchSortOption.values.map((option) {
                  final isSelected = searchProvider.sortOption == option;
                  return GestureDetector(
                    onTap: () => searchProvider.setSortOption(option),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? ArtbeatColors.primaryPurple.withValues(alpha: 0.2)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? ArtbeatColors.primaryPurple
                              : ArtbeatColors.textSecondary.withValues(
                                  alpha: 0.2,
                                ),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _sortOptionLabel(option),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? ArtbeatColors.primaryPurple
                              : ArtbeatColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _sortOptionLabel(search_controller.SearchSortOption option) {
    switch (option) {
      case search_controller.SearchSortOption.relevant:
        return 'search_sort_relevant'.tr();
      case search_controller.SearchSortOption.recent:
        return 'search_sort_recent'.tr();
      case search_controller.SearchSortOption.popular:
        return 'search_sort_popular'.tr();
    }
  }

  Widget _buildContent(search_controller.SearchController searchProvider) {
    if (searchProvider.query.isEmpty) {
      return _buildEmptyState();
    }

    if (searchProvider.isLoading) {
      return _buildLoadingState();
    }

    if (searchProvider.hasError) {
      return _buildErrorState(searchProvider);
    }

    if (searchProvider.isEmpty) {
      return _buildNoResultsState(searchProvider.query);
    }

    return _buildResultsList(searchProvider.results);
  }

  Widget _buildEmptyState() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SearchHistory().getSearchHistory(),
      builder: (context, snapshot) {
        final hasHistory = snapshot.hasData && snapshot.data!.isNotEmpty;
        final recentSearches = hasHistory
            ? snapshot.data!.take(5).toList()
            : <Map<String, dynamic>>[];

        return SingleChildScrollView(
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFF8F9FA)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.9),
                    blurRadius: 4,
                    offset: const Offset(-2, -2),
                  ),
                  BoxShadow(
                    color: ArtbeatColors.primaryPurple.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: ArtbeatColors.primaryGradient,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Icon(
                      Icons.search,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'search_empty_title'.tr(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ArtbeatColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'search_empty_desc'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      color: ArtbeatColors.textSecondary.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (hasHistory) ...[
                    const SizedBox(height: 32),
                    Text(
                      'search_recent_searches'.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ArtbeatColors.textSecondary.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...recentSearches.map((search) {
                          final query = search['query'] as String? ?? '';
                          return GestureDetector(
                            onTap: query.isNotEmpty
                                ? () {
                                    _searchController.text = query;
                                    _searchProvider.search(query);
                                  }
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: ArtbeatColors.primaryGradient,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                query,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        await SearchHistory().clearHistory();
                        setState(() {});
                      },
                      child: Text(
                        'Clear History',
                        style: TextStyle(
                          fontSize: 12,
                          color: ArtbeatColors.error.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF8F9FA)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: ArtbeatColors.primaryPurple.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.9),
              blurRadius: 4,
              offset: const Offset(-2, -2),
            ),
            BoxShadow(
              color: ArtbeatColors.primaryPurple.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: ArtbeatColors.primaryGradient,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'search_loading'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ArtbeatColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(search_controller.SearchController searchProvider) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFFFF5F5)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: ArtbeatColors.error.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.9),
              blurRadius: 4,
              offset: const Offset(-2, -2),
            ),
            BoxShadow(
              color: ArtbeatColors.error.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ArtbeatColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: ArtbeatColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'search_error_title'.tr(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ArtbeatColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              searchProvider.errorMessage,
              style: TextStyle(
                fontSize: 14,
                color: ArtbeatColors.textSecondary.withValues(alpha: 0.8),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: ArtbeatColors.primaryGradient,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: ArtbeatColors.primaryPurple.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => searchProvider.retry(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  'search_try_again'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(String query) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF8F9FA)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: ArtbeatColors.textSecondary.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.9),
              blurRadius: 4,
              offset: const Offset(-2, -2),
            ),
            BoxShadow(
              color: ArtbeatColors.textSecondary.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ArtbeatColors.textSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(
                Icons.search_off,
                size: 48,
                color: ArtbeatColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'search_no_results'.tr(namedArgs: {'query': query}),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ArtbeatColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'search_no_results_hint'.tr(),
              style: TextStyle(
                fontSize: 14,
                color: ArtbeatColors.textSecondary.withValues(alpha: 0.8),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(List<KnownEntity> results) {
    // Group results by type for better organization
    final resultsByType = <KnownEntityType, List<KnownEntity>>{};

    for (final entity in results) {
      resultsByType.putIfAbsent(entity.type, () => []).add(entity);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: resultsByType.length,
      itemBuilder: (context, index) {
        final type = resultsByType.keys.elementAt(index);
        final entities = resultsByType[type]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) const SizedBox(height: 24),
            _buildSectionHeader(type, entities.length),
            const SizedBox(height: 8),
            ...entities.map((entity) => _buildResultItem(entity)),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(KnownEntityType type, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(_getTypeIcon(type), size: 20, color: _getTypeColor(type)),
          const SizedBox(width: 8),
          Text(
            type.label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ArtbeatColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getTypeColor(type).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _getTypeColor(type),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(KnownEntity entity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFAFAFA)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getTypeColor(entity.type).withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            blurRadius: 3,
            offset: const Offset(-1, -1),
          ),
          BoxShadow(
            color: _getTypeColor(entity.type).withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _buildResultImage(entity),
        title: Text(
          entity.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ArtbeatColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: entity.subtitle.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  entity.subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: ArtbeatColors.textSecondary.withValues(alpha: 0.8),
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : null,
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getTypeColor(entity.type).withValues(alpha: 0.1),
                _getTypeColor(entity.type).withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.chevron_right,
            color: _getTypeColor(entity.type),
            size: 20,
          ),
        ),
        onTap: () => _handleResultTap(entity),
      ),
    );
  }

  Widget _buildResultImage(KnownEntity entity) {
    if (entity.imageUrl != null && entity.imageUrl!.isNotEmpty) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getTypeColor(entity.type).withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _getTypeColor(entity.type).withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            entity.imageUrl!,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildDefaultIcon(entity.type),
          ),
        ),
      );
    }

    return _buildDefaultIcon(entity.type);
  }

  Widget _buildDefaultIcon(KnownEntityType type) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getTypeColor(type).withValues(alpha: 0.2),
            _getTypeColor(type).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getTypeColor(type).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Icon(_getTypeIcon(type), color: _getTypeColor(type), size: 28),
    );
  }

  IconData _getTypeIcon(KnownEntityType type) {
    switch (type) {
      case KnownEntityType.artist:
        return Icons.person;
      case KnownEntityType.artwork:
        return Icons.palette;
      case KnownEntityType.event:
        return Icons.event;
      case KnownEntityType.artWalk:
        return Icons.directions_walk;
      case KnownEntityType.location:
        return Icons.location_on;
      case KnownEntityType.community:
        return Icons.group;
      case KnownEntityType.unknown:
        return Icons.help_outline;
    }
  }

  Color _getTypeColor(KnownEntityType type) {
    switch (type) {
      case KnownEntityType.artist:
        return Colors.blue;
      case KnownEntityType.artwork:
        return Colors.purple;
      case KnownEntityType.event:
        return Colors.orange;
      case KnownEntityType.artWalk:
        return Colors.green;
      case KnownEntityType.location:
        return Colors.red;
      case KnownEntityType.community:
        return Colors.indigo;
      case KnownEntityType.unknown:
        return ArtbeatColors.textSecondary;
    }
  }

  void _handleResultTap(KnownEntity entity) {
    // Navigate to appropriate detail page based on entity type
    switch (entity.type) {
      case KnownEntityType.artist:
        Navigator.pushNamed(
          context,
          '/artist/public-profile',
          arguments: {'artistId': entity.id},
        );
        break;
      case KnownEntityType.artwork:
        Navigator.pushNamed(
          context,
          '/artwork/detail',
          arguments: {'artworkId': entity.id},
        );
        break;
      case KnownEntityType.event:
        Navigator.pushNamed(
          context,
          '/events/detail',
          arguments: {'eventId': entity.id},
        );
        break;
      case KnownEntityType.artWalk:
        Navigator.pushNamed(
          context,
          '/art-walk/detail',
          arguments: {'walkId': entity.id},
        );
        break;
      case KnownEntityType.location:
        // Handle location navigation
        break;
      case KnownEntityType.community:
        // Handle community navigation
        break;
      case KnownEntityType.unknown:
        break;
    }
  }
}
