import 'package:artbeat_art_walk/src/models/search_criteria_model.dart';
import 'package:artbeat_art_walk/src/widgets/glass_secondary_button.dart';
import 'package:artbeat_art_walk/src/widgets/typography.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:artbeat_core/shared_widgets.dart';

class PublicArtSearchFilter extends StatefulWidget {
  final PublicArtSearchCriteria initialCriteria;
  final ValueChanged<PublicArtSearchCriteria> onCriteriaChanged;
  final VoidCallback? onClearFilters;
  final List<String> availableArtTypes;
  final List<String> availableTags;
  final List<String> availableZipCodes;

  const PublicArtSearchFilter({
    super.key,
    required this.initialCriteria,
    required this.onCriteriaChanged,
    this.onClearFilters,
    this.availableArtTypes = const [],
    this.availableTags = const [],
    this.availableZipCodes = const [],
  });

  @override
  State<PublicArtSearchFilter> createState() => _PublicArtSearchFilterState();
}

class _PublicArtSearchFilterState extends State<PublicArtSearchFilter> {
  late PublicArtSearchCriteria _criteria;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _artistController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();

  final List<String> _defaultArtTypes = const [
    'Mural',
    'Sculpture',
    'Installation',
    'Street Art',
    'Graffiti',
    'Monument',
    'Fountain',
  ];

  final Map<String, String> _artTypeLabelKeys = const {
    'mural': 'art_walk_public_art_search_filter_art_type_mural',
    'sculpture': 'art_walk_public_art_search_filter_art_type_sculpture',
    'installation': 'art_walk_public_art_search_filter_art_type_installation',
    'street art': 'art_walk_public_art_search_filter_art_type_street_art',
    'graffiti': 'art_walk_public_art_search_filter_art_type_graffiti',
    'monument': 'art_walk_public_art_search_filter_art_type_monument',
    'fountain': 'art_walk_public_art_search_filter_art_type_fountain',
  };

  final List<_SortOption> _sortOptions = const [
    _SortOption(
      value: 'popular',
      labelKey: 'art_walk_public_art_search_filter_sort_popular',
      icon: Icons.trending_up,
    ),
    _SortOption(
      value: 'newest',
      labelKey: 'art_walk_public_art_search_filter_sort_newest',
      icon: Icons.fiber_new,
    ),
    _SortOption(
      value: 'rating',
      labelKey: 'art_walk_public_art_search_filter_sort_rating',
      icon: Icons.star_rate,
    ),
    _SortOption(
      value: 'title',
      labelKey: 'art_walk_public_art_search_filter_sort_title',
      icon: Icons.sort_by_alpha,
    ),
    _SortOption(
      value: 'distance',
      labelKey: 'art_walk_public_art_search_filter_sort_distance',
      icon: Icons.place,
    ),
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
        searchQuery: searchQuery ?? _criteria.searchQuery,
        artistName: artistName ?? _criteria.artistName,
        artTypes: artTypes ?? _criteria.artTypes,
        tags: tags ?? _criteria.tags,
        isVerified: isVerified ?? _criteria.isVerified,
        minRating: minRating ?? _criteria.minRating,
        maxDistanceKm: maxDistanceKm ?? _criteria.maxDistanceKm,
        zipCode: zipCode ?? _criteria.zipCode,
        sortBy: sortBy ?? _criteria.sortBy,
        sortDescending: sortDescending ?? _criteria.sortDescending,
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
    widget.onClearFilters?.call();
  }

  List<String> get _availableArtTypes {
    final types = <String>{..._defaultArtTypes, ...widget.availableArtTypes};
    final list = types.toList();
    list.sort();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = _criteria.hasActiveFilters;
    final sortedTags = widget.availableTags.toSet().toList()..sort();
    final zipSuggestions = widget.availableZipCodes.take(5).toList();

    return WorldBackground(
      withBlobs: false,
      child: GlassCard(
        borderRadius: 32,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(hasActiveFilters),
              const SizedBox(height: 24),
              _buildInputField(
                controller: _searchController,
                hint: 'art_walk_public_art_search_filter_hint_query'.tr(),
                icon: Icons.search,
                onChanged: (value) => _updateCriteria(searchQuery: value),
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _artistController,
                hint: 'art_walk_public_art_search_filter_hint_artist'.tr(),
                icon: Icons.person,
                onChanged: (value) => _updateCriteria(artistName: value),
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _zipCodeController,
                hint: 'art_walk_art_walk_search_filter_hint_zip'.tr(),
                icon: Icons.location_on,
                keyboardType: TextInputType.number,
                onChanged: (value) => _updateCriteria(zipCode: value),
              ),
              if (zipSuggestions.isNotEmpty) ...[
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: zipSuggestions
                        .map(
                          (zip) => Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: _SelectablePill(
                              label: 'art_walk_art_walk_card_text_zip'.tr(
                                namedArgs: {'zip': zip},
                              ),
                              icon: Icons.pin_drop,
                              selected: _criteria.zipCode == zip,
                              onTap: () {
                                _zipCodeController.text = zip;
                                _updateCriteria(zipCode: zip);
                              },
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _buildSectionTitle(
                'art_walk_public_art_search_filter_section_types'.tr(),
                icon: Icons.palette,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _availableArtTypes.map((type) {
                  final currentTypes = List<String>.from(
                    _criteria.artTypes ?? [],
                  );
                  final selected = currentTypes.contains(type);
                  return _SelectablePill(
                    label: _localizeArtType(type),
                    icon: Icons.category,
                    selected: selected,
                    onTap: () {
                      if (selected) {
                        currentTypes.remove(type);
                      } else {
                        currentTypes.add(type);
                      }
                      _updateCriteria(
                        artTypes: currentTypes.isEmpty ? null : currentTypes,
                      );
                    },
                  );
                }).toList(),
              ),
              if (sortedTags.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildSectionTitle(
                  'art_walk_public_art_search_filter_section_tags'.tr(),
                  icon: Icons.local_offer,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: sortedTags.map((tag) {
                    final currentTags = List<String>.from(_criteria.tags ?? []);
                    final selected = currentTags.contains(tag);
                    return _SelectablePill(
                      label: tag,
                      icon: Icons.tag,
                      selected: selected,
                      onTap: () {
                        if (selected) {
                          currentTags.remove(tag);
                        } else {
                          currentTags.add(tag);
                        }
                        _updateCriteria(
                          tags: currentTags.isEmpty ? null : currentTags,
                        );
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 24),
              _buildSectionTitle(
                'art_walk_public_art_search_filter_section_quality'.tr(),
                icon: Icons.verified,
              ),
              const SizedBox(height: 16),
              _ToggleCard(
                title: 'art_walk_public_art_search_filter_text_verified_only'
                    .tr(),
                subtitle:
                    'art_walk_public_art_search_filter_text_show_only_verified_artwork'
                        .tr(),
                value: _criteria.isVerified ?? false,
                onChanged: (value) => _updateCriteria(isVerified: value),
              ),
              const SizedBox(height: 16),
              _SliderCard(
                icon: Icons.star,
                label: 'art_walk_public_art_search_filter_label_min_rating'.tr(
                  namedArgs: {
                    'rating': (_criteria.minRating ?? 0).toStringAsFixed(1),
                  },
                ),
                value: _criteria.minRating ?? 0,
                min: 0,
                max: 5,
                divisions: 10,
                onChanged: (value) => _updateCriteria(minRating: value),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(
                'art_walk_public_art_search_filter_section_distance'.tr(),
                icon: Icons.map,
              ),
              const SizedBox(height: 16),
              _SliderCard(
                icon: Icons.spatial_audio_off,
                label: 'art_walk_public_art_search_filter_label_search_radius'
                    .tr(
                      namedArgs: {
                        'kilometers': (_criteria.maxDistanceKm ?? 10)
                            .toStringAsFixed(1),
                      },
                    ),
                value: _criteria.maxDistanceKm ?? 10,
                min: 1,
                max: 50,
                divisions: 49,
                onChanged: (value) => _updateCriteria(maxDistanceKm: value),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(
                'art_walk_public_art_search_filter_section_sort'.tr(),
                icon: Icons.sort,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _sortOptions.map((option) {
                  final selected = _criteria.sortBy == option.value;
                  return _SelectablePill(
                    label: option.labelKey.tr(),
                    icon: option.icon,
                    selected: selected,
                    onTap: () =>
                        _updateCriteria(sortBy: selected ? null : option.value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SelectablePill(
                      label: 'art_walk_text_ascending'.tr(),
                      icon: Icons.arrow_upward,
                      selected: (_criteria.sortDescending ?? true) == false,
                      onTap: () => _updateCriteria(sortDescending: false),
                      fullWidth: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SelectablePill(
                      label: 'art_walk_text_descending'.tr(),
                      icon: Icons.arrow_downward,
                      selected: _criteria.sortDescending ?? true,
                      onTap: () => _updateCriteria(sortDescending: true),
                      fullWidth: true,
                    ),
                  ),
                ],
              ),
              if (hasActiveFilters) ...[
                const SizedBox(height: 24),
                _buildSectionTitle(
                  'art_walk_public_art_search_filter_section_active_filters'
                      .tr(),
                  icon: Icons.filter_alt,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _buildActiveFilterChips(),
                ),
              ],
              const SizedBox(height: 24),
              GradientCTAButton(
                label: 'art_walk_public_art_search_filter_button_apply'.tr(),
                icon: Icons.check_circle,
                onPressed: () => widget.onCriteriaChanged(_criteria),
              ),
              const SizedBox(height: 12),
              GlassSecondaryButton(
                label: 'art_walk_button_clear_all'.tr(),
                icon: Icons.refresh,
                onTap: _clearAllFilters,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool hasActiveFilters) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
            ),
          ),
          child: const Icon(Icons.tune, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'art_walk_public_art_search_filter_title'.tr(),
                style: AppTypography.screenTitle(),
              ),
              const SizedBox(height: 8),
              Text(
                'art_walk_public_art_search_filter_subtitle'.tr(),
                style: AppTypography.helper(),
              ),
            ],
          ),
        ),
        if (hasActiveFilters)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withValues(alpha: 0.1),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Text(
              'art_walk_public_art_search_filter_badge_active'.tr(),
              style: AppTypography.badge(),
            ),
          ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              style: AppTypography.body(),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTypography.helper(
                  Colors.white.withValues(alpha: 0.7),
                ),
                border: InputBorder.none,
              ),
              keyboardType: keyboardType,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String label, {required IconData icon}) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 18),
        const SizedBox(width: 8),
        Text(label, style: AppTypography.sectionLabel()),
      ],
    );
  }

  List<Widget> _buildActiveFilterChips() {
    final tokens = <String>[];

    if (_criteria.searchQuery?.isNotEmpty ?? false) {
      tokens.add(
        'art_walk_public_art_search_filter_summary_search'.tr(
          namedArgs: {'query': _criteria.searchQuery!},
        ),
      );
    }
    if (_criteria.artistName?.isNotEmpty ?? false) {
      tokens.add(
        'art_walk_public_art_search_filter_summary_artist'.tr(
          namedArgs: {'artist': _criteria.artistName!},
        ),
      );
    }
    if (_criteria.artTypes?.isNotEmpty ?? false) {
      tokens.add(
        'art_walk_public_art_search_filter_summary_types'.tr(
          namedArgs: {'types': _criteria.artTypes!.join(', ')},
        ),
      );
    }
    if (_criteria.isVerified == true) {
      tokens.add('art_walk_public_art_search_filter_summary_verified'.tr());
    }
    if (_criteria.minRating != null && _criteria.minRating! > 0) {
      tokens.add(
        'art_walk_public_art_search_filter_summary_rating'.tr(
          namedArgs: {'rating': _criteria.minRating!.toStringAsFixed(1)},
        ),
      );
    }
    if (_criteria.tags?.isNotEmpty ?? false) {
      tokens.add(
        'art_walk_public_art_search_filter_summary_tags'.tr(
          namedArgs: {'tags': _criteria.tags!.join(', ')},
        ),
      );
    }
    if (_criteria.zipCode?.isNotEmpty ?? false) {
      tokens.add(
        'art_walk_public_art_search_filter_summary_zip'.tr(
          namedArgs: {'zip': _criteria.zipCode!},
        ),
      );
    }

    return tokens.map((token) => _FilterBadge(label: token)).toList();
  }

  String _localizeArtType(String type) {
    final key = _artTypeLabelKeys[type.toLowerCase()] ?? type.toLowerCase();
    return key.startsWith('art_walk_') ? key.tr() : type;
  }
}

class _SortOption {
  final String value;
  final String labelKey;
  final IconData icon;

  const _SortOption({
    required this.value,
    required this.labelKey,
    required this.icon,
  });
}

class _SelectablePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool fullWidth;

  const _SelectablePill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final background = selected
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
          )
        : null;

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: Semantics(
        label: label,
        button: true,
        selected: selected,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: background,
              color: background == null
                  ? Colors.white.withValues(alpha: 0.05)
                  : null,
              border: Border.all(
                color: selected
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(
                      selected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.body()),
                const SizedBox(height: 6),
                Text(subtitle, style: AppTypography.helper()),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: const Color(0xFF22D3EE),
            activeThumbColor: const Color(0xFF22D3EE),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SliderCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _SliderCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: AppTypography.body())),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF22D3EE),
              inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
              thumbColor: const Color(0xFF7C4DFF),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBadge extends StatelessWidget {
  final String label;

  const _FilterBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        style: AppTypography.helper(Colors.white.withValues(alpha: 0.85)),
      ),
    );
  }
}
