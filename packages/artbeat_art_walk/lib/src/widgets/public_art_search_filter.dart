import 'package:flutter/material.dart';
import '../models/search_criteria_model.dart';

/// Advanced filter widget for public art search
class PublicArtSearchFilter extends StatefulWidget {
  final PublicArtSearchCriteria initialCriteria;
  final ValueChanged<PublicArtSearchCriteria> onCriteriaChanged;
  final VoidCallback? onClearFilters;
  final List<String> availableArtTypes;
  final List<String> availableTags;
  final List<String> availableZipCodes;

  const PublicArtSearchFilter({
    Key? key,
    required this.initialCriteria,
    required this.onCriteriaChanged,
    this.onClearFilters,
    this.availableArtTypes = const [],
    this.availableTags = const [],
    this.availableZipCodes = const [],
  }) : super(key: key);

  @override
  State<PublicArtSearchFilter> createState() => _PublicArtSearchFilterState();
}

class _PublicArtSearchFilterState extends State<PublicArtSearchFilter> {
  late PublicArtSearchCriteria _criteria;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _artistController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();

  // Default art types
  final List<String> _defaultArtTypes = [
    'Mural',
    'Sculpture',
    'Installation',
    'Street Art',
    'Graffiti',
    'Monument',
    'Fountain',
  ];

  // Sort options
  final List<MapEntry<String, String>> _sortOptions = [
    const MapEntry('popular', 'Most Popular'),
    const MapEntry('newest', 'Newest First'),
    const MapEntry('rating', 'Highest Rated'),
    const MapEntry('title', 'Alphabetical'),
    const MapEntry('distance', 'Nearest First'),
  ];

  @override
  void initState() {
    super.initState();
    _criteria = widget.initialCriteria;
    _searchController.text = _criteria.searchQuery ?? '';
    _artistController.text = _criteria.artistName ?? '';
    _zipCodeController.text = _criteria.zipCode ?? '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _artistController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  void _updateCriteria({
    String? searchQuery,
    String? artistName,
    List<String>? artTypes,
    List<String>? tags,
    bool? isVerified,
    double? minRating,
    double? maxDistanceKm,
    String? zipCode,
    String? sortBy,
    bool? sortDescending,
  }) {
    setState(() {
      _criteria = _criteria.copyWith(
        searchQuery: searchQuery,
        artistName: artistName,
        artTypes: artTypes,
        tags: tags,
        isVerified: isVerified,
        minRating: minRating,
        maxDistanceKm: maxDistanceKm,
        zipCode: zipCode,
        sortBy: sortBy,
        sortDescending: sortDescending,
      );
    });

    widget.onCriteriaChanged(_criteria);
  }

  void _clearAllFilters() {
    _searchController.clear();
    _artistController.clear();
    _zipCodeController.clear();

    setState(() {
      _criteria = const PublicArtSearchCriteria();
    });

    widget.onCriteriaChanged(_criteria);
    if (widget.onClearFilters != null) {
      widget.onClearFilters!();
    }
  }

  List<String> get _availableArtTypes {
    final types = <String>{};
    types.addAll(_defaultArtTypes);
    types.addAll(widget.availableArtTypes);
    return types.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with clear button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.palette, color: theme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Art Filters',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_criteria.hasActiveFilters) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Active',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (_criteria.hasActiveFilters)
                TextButton.icon(
                  onPressed: _clearAllFilters,
                  icon: const Icon(Icons.clear, size: 16),
                  label: Text('art_walk_button_clear_all'.tr()),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Search query
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search art by title, description...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.primaryColor),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) => _updateCriteria(searchQuery: value),
          ),

          const SizedBox(height: 16),

          // Artist name
          TextField(
            controller: _artistController,
            decoration: InputDecoration(
              hintText: 'Artist name',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.primaryColor),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) => _updateCriteria(artistName: value),
          ),

          const SizedBox(height: 16),

          // Location filter
          TextField(
            controller: _zipCodeController,
            decoration: InputDecoration(
              hintText: 'ZIP code (e.g., 28204)',
              prefixIcon: const Icon(Icons.location_on),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.primaryColor),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) => _updateCriteria(zipCode: value),
          ),

          const SizedBox(height: 16),

          // Art Types
          _buildFilterSection(
            title: 'Art Types',
            icon: Icons.category,
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _availableArtTypes.map((artType) {
                final isSelected =
                    _criteria.artTypes?.contains(artType) ?? false;
                return FilterChip(
                  label: Text(artType),
                  selected: isSelected,
                  onSelected: (selected) {
                    final currentTypes = List<String>.from(
                      _criteria.artTypes ?? [],
                    );
                    if (selected) {
                      currentTypes.add(artType);
                    } else {
                      currentTypes.remove(artType);
                    }
                    _updateCriteria(
                      artTypes: currentTypes.isEmpty ? null : currentTypes,
                    );
                  },
                  selectedColor: theme.primaryColor.withValues(alpha: 0.2),
                  checkmarkColor: theme.primaryColor,
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Quality filters
          _buildFilterSection(
            title: 'Quality',
            icon: Icons.verified,
            child: Column(
              children: [
                CheckboxListTile(
                  title: Text('art_walk_public_art_search_filter_text_verified_only'.tr()),
                  subtitle: Text('art_walk_public_art_search_filter_text_show_only_verified_artwork'.tr()),
                  value: _criteria.isVerified ?? false,
                  onChanged: (value) => _updateCriteria(isVerified: value),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),

                // Min Rating
                Row(
                  children: [
                    const Icon(Icons.star, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Minimum Rating: ${_criteria.minRating?.toStringAsFixed(1) ?? "Any"}/5.0',
                            style: theme.textTheme.bodyMedium,
                          ),
                          Slider(
                            value: _criteria.minRating ?? 0.0,
                            min: 0.0,
                            max: 5.0,
                            divisions: 10,
                            label:
                                '${(_criteria.minRating ?? 0.0).toStringAsFixed(1)}',
                            onChanged: (value) =>
                                _updateCriteria(minRating: value),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Distance filter
          _buildFilterSection(
            title: 'Distance',
            icon: Icons.location_searching,
            child: Row(
              children: [
                const Icon(Icons.my_location, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Search Radius: ${_criteria.maxDistanceKm?.toStringAsFixed(1) ?? "10.0"} km',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Slider(
                        value: _criteria.maxDistanceKm ?? 10.0,
                        min: 1.0,
                        max: 50.0,
                        divisions: 49,
                        label:
                            '${(_criteria.maxDistanceKm ?? 10.0).toStringAsFixed(1)} km',
                        onChanged: (value) =>
                            _updateCriteria(maxDistanceKm: value),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Sort options
          _buildFilterSection(
            title: 'Sort By',
            icon: Icons.sort,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _criteria.sortBy,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: _sortOptions.map((option) {
                    return DropdownMenuItem<String>(
                      value: option.key,
                      child: Text(option.value),
                    );
                  }).toList(),
                  onChanged: (value) => _updateCriteria(sortBy: value),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Text('art_walk_text_order'.tr()),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('art_walk_text_ascending'.tr()),
                            icon: Icon(Icons.arrow_upward, size: 16),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('art_walk_text_descending'.tr()),
                            icon: Icon(Icons.arrow_downward, size: 16),
                          ),
                        ],
                        selected: {_criteria.sortDescending ?? true},
                        onSelectionChanged: (Set<bool> selection) {
                          _updateCriteria(sortDescending: selection.first);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Active filters summary
          if (_criteria.hasActiveFilters) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.primaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Active Filters',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _criteria.filterSummary,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: theme.primaryColor),
            const SizedBox(width: 6),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
