import 'package:flutter/material.dart';
import '../models/search_criteria_model.dart';

/// Advanced filter widget for art walk search
class ArtWalkSearchFilter extends StatefulWidget {
  final ArtWalkSearchCriteria initialCriteria;
  final ValueChanged<ArtWalkSearchCriteria> onCriteriaChanged;
  final VoidCallback? onClearFilters;
  final List<String> availableTags;
  final List<String> availableZipCodes;

  const ArtWalkSearchFilter({
    Key? key,
    required this.initialCriteria,
    required this.onCriteriaChanged,
    this.onClearFilters,
    this.availableTags = const [],
    this.availableZipCodes = const [],
  }) : super(key: key);

  @override
  State<ArtWalkSearchFilter> createState() => _ArtWalkSearchFilterState();
}

class _ArtWalkSearchFilterState extends State<ArtWalkSearchFilter> {
  late ArtWalkSearchCriteria _criteria;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();

  // Difficulty options
  final List<String> _difficultyLevels = ['Easy', 'Medium', 'Hard'];

  // Sort options
  final List<MapEntry<String, String>> _sortOptions = [
    const MapEntry('popular', 'Most Popular'),
    const MapEntry('newest', 'Newest First'),
    const MapEntry('title', 'Alphabetical'),
    const MapEntry('duration', 'Duration'),
    const MapEntry('distance', 'Distance'),
  ];

  @override
  void initState() {
    super.initState();
    _criteria = widget.initialCriteria;
    _searchController.text = _criteria.searchQuery ?? '';
    _zipCodeController.text = _criteria.zipCode ?? '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  void _updateCriteria({
    String? searchQuery,
    List<String>? tags,
    String? difficulty,
    bool? isAccessible,
    double? maxDistance,
    double? maxDuration,
    String? zipCode,
    bool? isPublic,
    String? sortBy,
    bool? sortDescending,
  }) {
    setState(() {
      _criteria = _criteria.copyWith(
        searchQuery: searchQuery,
        tags: tags,
        difficulty: difficulty,
        isAccessible: isAccessible,
        maxDistance: maxDistance,
        maxDuration: maxDuration,
        zipCode: zipCode,
        isPublic: isPublic,
        sortBy: sortBy,
        sortDescending: sortDescending,
      );
    });

    widget.onCriteriaChanged(_criteria);
  }

  void _clearAllFilters() {
    _searchController.clear();
    _zipCodeController.clear();

    setState(() {
      _criteria = const ArtWalkSearchCriteria();
    });

    widget.onCriteriaChanged(_criteria);
    if (widget.onClearFilters != null) {
      widget.onClearFilters!();
    }
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
                  Icon(Icons.filter_list, color: theme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Search Filters',
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
              hintText: 'Search art walks...',
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

          // Difficulty Level
          _buildFilterSection(
            title: 'Difficulty Level',
            icon: Icons.trending_up,
            child: Wrap(
              spacing: 8,
              children: _difficultyLevels.map((difficulty) {
                final isSelected = _criteria.difficulty == difficulty;
                return FilterChip(
                  label: Text(difficulty),
                  selected: isSelected,
                  onSelected: (selected) {
                    _updateCriteria(difficulty: selected ? difficulty : null);
                  },
                  selectedColor: theme.primaryColor.withValues(alpha: 0.2),
                  checkmarkColor: theme.primaryColor,
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Accessibility & Public filters
          _buildFilterSection(
            title: 'Options',
            icon: Icons.settings,
            child: Column(
              children: [
                CheckboxListTile(
                  title: Text('art_walk_art_walk_search_filter_text_accessible'.tr()),
                  subtitle: Text('art_walk_art_walk_search_filter_text_wheelchair_accessible_walks'.tr()),
                  value: _criteria.isAccessible ?? false,
                  onChanged: (value) => _updateCriteria(isAccessible: value),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: Text('art_walk_art_walk_search_filter_text_public_walks_only'.tr()),
                  subtitle: Text('art_walk_art_walk_search_filter_text_show_only_public_art_walks'.tr()),
                  value: _criteria.isPublic ?? false,
                  onChanged: (value) => _updateCriteria(isPublic: value),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Distance & Duration filters
          _buildFilterSection(
            title: 'Limits',
            icon: Icons.timer,
            child: Column(
              children: [
                // Max Distance
                Row(
                  children: [
                    const Icon(Icons.route, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Max Distance: ${_criteria.maxDistance?.toStringAsFixed(1) ?? "Any"} miles',
                            style: theme.textTheme.bodyMedium,
                          ),
                          Slider(
                            value: _criteria.maxDistance ?? 10.0,
                            min: 0.5,
                            max: 20.0,
                            divisions: 39,
                            label:
                                '${(_criteria.maxDistance ?? 10.0).toStringAsFixed(1)} mi',
                            onChanged: (value) =>
                                _updateCriteria(maxDistance: value),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Max Duration
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Max Duration: ${_criteria.maxDuration?.toInt() ?? "Any"} minutes',
                            style: theme.textTheme.bodyMedium,
                          ),
                          Slider(
                            value: _criteria.maxDuration ?? 120.0,
                            min: 15.0,
                            max: 300.0,
                            divisions: 19,
                            label:
                                '${(_criteria.maxDuration ?? 120.0).toInt()} min',
                            onChanged: (value) =>
                                _updateCriteria(maxDuration: value),
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
