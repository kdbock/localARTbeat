import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show EnhancedUniversalHeader, MainLayout, AppLogger;
import '../models/artwork_model.dart';
import '../services/artwork_service.dart';

/// Advanced search screen with multiple filters and saved searches
class AdvancedArtworkSearchScreen extends StatefulWidget {
  final String? initialQuery;

  const AdvancedArtworkSearchScreen({super.key, this.initialQuery});

  @override
  State<AdvancedArtworkSearchScreen> createState() =>
      _AdvancedArtworkSearchScreenState();
}

class _AdvancedArtworkSearchScreenState
    extends State<AdvancedArtworkSearchScreen> {
  final ArtworkService _artworkService = ArtworkService();
  final TextEditingController _searchController = TextEditingController();

  // Filter values
  String _selectedLocation = 'All';
  String _selectedMedium = 'All';
  List<String> _selectedStyles = [];
  double? _minPrice;
  double? _maxPrice;
  DateTime? _startDate;
  DateTime? _endDate;
  bool? _isForSale;
  bool? _isFeatured;

  // UI state
  List<ArtworkModel> _searchResults = [];
  List<String> _searchSuggestions = [];
  List<Map<String, dynamic>> _savedSearches = [];
  bool _isLoading = false;
  bool _showFilters = false;

  // Available options
  final List<String> _locations = [
    'All',
    'New York',
    'Los Angeles',
    'Chicago',
    'Miami',
    'Online'
  ];
  final List<String> _mediums = [
    'All',
    'Painting',
    'Sculpture',
    'Digital',
    'Photography',
    'Mixed Media'
  ];

  @override
  void initState() {
    super.initState();
    // Set initial query if provided
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      // Auto-perform search with initial query
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performAdvancedSearch();
      });
    }
    _loadSavedSearches();
    _loadSearchSuggestions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedSearches() async {
    try {
      final savedSearches = await _artworkService.getSavedSearches();
      setState(() {
        _savedSearches = savedSearches;
      });
    } catch (e) {
      AppLogger.error('Error loading saved searches: $e');
    }
  }

  Future<void> _loadSearchSuggestions() async {
    try {
      final suggestions = await _artworkService.getSearchSuggestions();
      setState(() {
        _searchSuggestions = suggestions;
      });
    } catch (e) {
      AppLogger.error('Error loading search suggestions: $e');
    }
  }

  Future<void> _performAdvancedSearch() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _artworkService.advancedSearchArtwork(
        query: _searchController.text.isEmpty ? null : _searchController.text,
        location: _selectedLocation == 'All' ? null : _selectedLocation,
        medium: _selectedMedium == 'All' ? null : _selectedMedium,
        styles: _selectedStyles.isEmpty ? null : _selectedStyles,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        startDate: _startDate,
        endDate: _endDate,
        isForSale: _isForSale,
        isFeatured: _isFeatured,
      );

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Error performing advanced search: $e');
      setState(() {
        _isLoading = false;
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('advanced_search_error'.tr())),
      );
    }
  }

  Future<void> _saveCurrentSearch() async {
    final searchNameController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('advanced_search_save_dialog_title'.tr()),
        content: TextField(
          controller: searchNameController,
          decoration: InputDecoration(
            hintText: 'advanced_search_save_dialog_hint'.tr(),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('advanced_search_save_dialog_cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              if (searchNameController.text.isNotEmpty) {
                try {
                  final criteria = {
                    'query': _searchController.text,
                    'location': _selectedLocation,
                    'medium': _selectedMedium,
                    'styles': _selectedStyles,
                    'minPrice': _minPrice,
                    'maxPrice': _maxPrice,
                    'startDate': _startDate?.toIso8601String(),
                    'endDate': _endDate?.toIso8601String(),
                    'isForSale': _isForSale,
                    'isFeatured': _isFeatured,
                  };

                  await _artworkService.saveSearch(
                      searchNameController.text, criteria);
                  await _loadSavedSearches();
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context);
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('advanced_search_saved_success'.tr())),
                  );
                } catch (e) {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('advanced_search_save_error'.tr())),
                  );
                }
              }
            },
            child: Text('advanced_search_save_dialog_save'.tr()),
          ),
        ],
      ),
    );
  }

  void _applySavedSearch(Map<String, dynamic> savedSearch) async {
    final criteria = savedSearch['criteria'] as Map<String, dynamic>;

    setState(() {
      _searchController.text = (criteria['query'] as String?) ?? '';
      _selectedLocation = (criteria['location'] as String?) ?? 'All';
      _selectedMedium = (criteria['medium'] as String?) ?? 'All';
      _selectedStyles = criteria['styles'] != null
          ? List<String>.from(criteria['styles'] as List<dynamic>)
          : <String>[];
      _minPrice = criteria['minPrice'] as double?;
      _maxPrice = criteria['maxPrice'] as double?;
      _startDate = criteria['startDate'] != null
          ? DateTime.parse(criteria['startDate'] as String)
          : null;
      _endDate = criteria['endDate'] != null
          ? DateTime.parse(criteria['endDate'] as String)
          : null;
      _isForSale = criteria['isForSale'] as bool?;
      _isFeatured = criteria['isFeatured'] as bool?;
    });

    await _artworkService.updateSavedSearchUsage(savedSearch['id'] as String);
    await _performAdvancedSearch();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 0,
      appBar: EnhancedUniversalHeader(
        title: 'advanced_search_title'.tr(),
        showLogo: false,
        showBackButton: true,
        backgroundGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
          colors: [
            Color(0xFF7B2FF2), // Purple
            Color(0xFF00FF87), // Green
          ],
        ),
        titleGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
          colors: [
            Color(0xFF7B2FF2), // Purple
            Color(0xFF00FF87), // Green
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () => setState(() => _showFilters = !_showFilters),
            tooltip: 'advanced_search_toggle_filters'.tr(),
          ),
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _saveCurrentSearch,
            tooltip: 'advanced_search_save_button'.tr(),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'advanced_search_hint'.tr(),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
              ),
              onSubmitted: (_) => _performAdvancedSearch(),
            ),
          ),

          // Search suggestions
          if (_searchController.text.isEmpty && _searchSuggestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('advanced_search_popular'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8,
                    children: _searchSuggestions.take(5).map((suggestion) {
                      return ActionChip(
                        label: Text(suggestion),
                        onPressed: () {
                          _searchController.text = suggestion;
                          _performAdvancedSearch();
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          // Saved searches
          if (_savedSearches.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('advanced_search_saved'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _savedSearches.length,
                      itemBuilder: (context, index) {
                        final savedSearch = _savedSearches[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ActionChip(
                            label: Text(savedSearch['name'] as String),
                            onPressed: () => _applySavedSearch(savedSearch),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Filters panel
          if (_showFilters) _buildFiltersPanel(),

          // Search button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: _performAdvancedSearch,
              icon: const Icon(Icons.search),
              label: Text('advanced_search_button'.tr()),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchController.text.isEmpty && _savedSearches.isEmpty
                    ? Center(
                        child: Text('advanced_search_empty_state'.tr()))
                    : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('advanced_search_filters_title'.tr(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Location filter
              Text('advanced_search_location'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedLocation,
                items: _locations.map((location) {
                  return DropdownMenuItem(
                      value: location, child: Text(location));
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedLocation = value!),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),

              const SizedBox(height: 16),

              // Medium filter
              Text('advanced_search_medium'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedMedium,
                items: _mediums.map((medium) {
                  return DropdownMenuItem(value: medium, child: Text(medium));
                }).toList(),
                onChanged: (value) => setState(() => _selectedMedium = value!),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),

              const SizedBox(height: 16),

              // Price range
              Text('art_walk_price_range'.tr(),
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Min',
                        prefixText: '\$',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => _minPrice = double.tryParse(value),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Max',
                        prefixText: '\$',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => _maxPrice = double.tryParse(value),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Date range
              Text('art_walk_date_range'.tr(),
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) setState(() => _startDate = date);
                      },
                      child: Text(_startDate != null
                          ? '${_startDate!.month}/${_startDate!.day}/${_startDate!.year}'
                          : 'Start Date'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) setState(() => _endDate = date);
                      },
                      child: Text(_endDate != null
                          ? '${_endDate!.month}/${_endDate!.day}/${_endDate!.year}'
                          : 'End Date'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Additional filters
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: Text('art_walk_for_sale'.tr()),
                    selected: _isForSale == true,
                    onSelected: (selected) =>
                        setState(() => _isForSale = selected ? true : null),
                  ),
                  FilterChip(
                    label: Text('art_walk_featured'.tr()),
                    selected: _isFeatured == true,
                    onSelected: (selected) =>
                        setState(() => _isFeatured = selected ? true : null),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
          child: Text('art_walk_no_artwork_found_matching_criteria'.tr()));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final artwork = _searchResults[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          child: InkWell(
            onTap: () => _navigateToArtworkDetail(artwork.id),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Image.network(
                    artwork.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child:
                            Icon(Icons.image_not_supported, color: Colors.grey),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artwork.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        artwork.medium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.grey.shade700, fontSize: 12),
                      ),
                      if (artwork.isForSale && artwork.price != null)
                        Text(
                          '\$${artwork.price!.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToArtworkDetail(String artworkId) {
    Navigator.pushNamed(
      context,
      '/artist/artwork-detail',
      arguments: {'artworkId': artworkId},
    );
  }
}
