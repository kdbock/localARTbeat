import 'package:artbeat_art_walk/src/models/search_criteria_model.dart';
import 'package:artbeat_art_walk/src/widgets/typography.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/shared_widgets.dart';

class ArtWalkSearchFilter extends StatefulWidget {
  final ArtWalkSearchCriteria initialCriteria;
  final ValueChanged<ArtWalkSearchCriteria> onCriteriaChanged;
  final VoidCallback? onClearFilters;
  final List<String> availableTags;
  final List<String> availableZipCodes;

  const ArtWalkSearchFilter({
    super.key,
    required this.initialCriteria,
    required this.onCriteriaChanged,
    this.onClearFilters,
    this.availableTags = const [],
    this.availableZipCodes = const [],
  });

  @override
  State<ArtWalkSearchFilter> createState() => _ArtWalkSearchFilterState();
}

class _ArtWalkSearchFilterState extends State<ArtWalkSearchFilter> {
  late ArtWalkSearchCriteria _criteria;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();

  final Map<String, String> _difficultyLabelKeys = const {
    'Easy': 'art_walk_art_walk_search_filter_difficulty_easy',
    'Medium': 'art_walk_art_walk_search_filter_difficulty_medium',
    'Hard': 'art_walk_art_walk_search_filter_difficulty_hard',
  };

  final List<_SortOption> _sortOptions = const [
    _SortOption(
      value: 'popular',
      labelKey: 'art_walk_art_walk_search_filter_sort_popular',
      icon: Icons.auto_awesome,
    ),
    _SortOption(
      value: 'newest',
      labelKey: 'art_walk_art_walk_search_filter_sort_newest',
      icon: Icons.fiber_new,
    ),
    _SortOption(
      value: 'title',
      labelKey: 'art_walk_art_walk_search_filter_sort_title',
      icon: Icons.sort_by_alpha,
    ),
    _SortOption(
      value: 'duration',
      labelKey: 'art_walk_art_walk_search_filter_sort_duration',
      icon: Icons.schedule,
    ),
    _SortOption(
      value: 'distance',
      labelKey: 'art_walk_art_walk_search_filter_sort_distance',
      icon: Icons.route,
    ),
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
    widget.onClearFilters?.call();
  }

  @override
  Widget build(BuildContext context) {
    final mergedTags = <String>{
      ...widget.availableTags,
      ...?_criteria.tags,
    }.toList()..sort();
    final zipSuggestions = widget.availableZipCodes.take(6).toList();

    return GlassCard(
      borderRadius: 28,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildInputField(
            controller: _searchController,
            hint: 'art_walk_art_walk_list_hint_search_art_walks'.tr(),
            icon: Icons.search,
            onChanged: (value) => _updateCriteria(searchQuery: value),
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
                        padding: const EdgeInsets.only(right: 16),
                        child: _SelectablePill(
                          label: 'art_walk_art_walk_card_text_zip'.tr(
                            namedArgs: {'zip': zip},
                          ),
                          icon: Icons.push_pin,
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
          if (mergedTags.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionTitle(
              'art_walk_art_walk_search_filter_section_tags'.tr(),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: mergedTags.map((tag) {
                final currentTags = List<String>.from(_criteria.tags ?? []);
                final isSelected = currentTags.contains(tag);
                return _SelectablePill(
                  label: tag,
                  icon: Icons.local_offer,
                  selected: isSelected,
                  onTap: () {
                    if (isSelected) {
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
            'art_walk_art_walk_search_filter_section_difficulty'.tr(),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: _difficultyLabelKeys.entries.map((entry) {
              final selected = _criteria.difficulty == entry.key;
              return _SelectablePill(
                label: entry.value.tr(),
                icon: Icons.trending_up,
                selected: selected,
                onTap: () =>
                    _updateCriteria(difficulty: selected ? null : entry.key),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(
            'art_walk_art_walk_search_filter_section_options'.tr(),
          ),
          const SizedBox(height: 16),
          _ToggleTile(
            icon: Icons.accessible_forward,
            title: 'art_walk_art_walk_search_filter_text_accessible'.tr(),
            subtitle:
                'art_walk_art_walk_search_filter_text_wheelchair_accessible_walks'
                    .tr(),
            value: _criteria.isAccessible ?? false,
            onToggle: (value) => _updateCriteria(isAccessible: value),
          ),
          const SizedBox(height: 16),
          _ToggleTile(
            icon: Icons.public,
            title: 'art_walk_art_walk_search_filter_text_public_walks_only'
                .tr(),
            subtitle:
                'art_walk_art_walk_search_filter_text_show_only_public_art_walks'
                    .tr(),
            value: _criteria.isPublic ?? false,
            onToggle: (value) => _updateCriteria(isPublic: value),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(
            'art_walk_art_walk_search_filter_section_limits'.tr(),
          ),
          const SizedBox(height: 16),
          _buildSliderCard(
            icon: Icons.route,
            label: 'art_walk_art_walk_search_filter_label_max_distance'.tr(
              namedArgs: {
                'miles': (_criteria.maxDistance ?? 10.0).toStringAsFixed(1),
              },
            ),
            value: _criteria.maxDistance ?? 10.0,
            min: 0.5,
            max: 20.0,
            divisions: 39,
            onChanged: (value) => _updateCriteria(maxDistance: value),
          ),
          const SizedBox(height: 16),
          _buildSliderCard(
            icon: Icons.timer,
            label: 'art_walk_art_walk_search_filter_label_max_duration'.tr(
              namedArgs: {
                'minutes': (_criteria.maxDuration ?? 120).toInt().toString(),
              },
            ),
            value: _criteria.maxDuration ?? 120.0,
            min: 15.0,
            max: 300.0,
            divisions: 19,
            onChanged: (value) => _updateCriteria(maxDuration: value),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(
            'art_walk_art_walk_search_filter_section_sort'.tr(),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
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
              const SizedBox(width: 16),
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
          if (_criteria.hasActiveFilters) ...[
            const SizedBox(height: 24),
            _buildSectionTitle(
              'art_walk_art_walk_search_filter_section_active_filters'.tr(),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: _buildActiveFilterChips(),
            ),
          ],
          const SizedBox(height: 24),
          GradientCTAButton(
            label: 'art_walk_art_walk_search_filter_button_apply'.tr(),
            icon: Icons.check,
            onPressed: () => widget.onCriteriaChanged(_criteria),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final hasActiveFilters = _criteria.hasActiveFilters;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
            ),
          ),
          child: const Icon(Icons.filter_alt, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'art_walk_art_walk_search_filter_title'.tr(),
                style: AppTypography.screenTitle(),
              ),
              const SizedBox(height: 8),
              Text(
                'art_walk_art_walk_search_filter_section_location'.tr(),
                style: AppTypography.helper(),
              ),
            ],
          ),
        ),
        if (hasActiveFilters) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withValues(alpha: 0.1),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Text(
              'art_walk_art_walk_search_filter_badge_active'.tr(),
              style: AppTypography.badge(),
            ),
          ),
          const SizedBox(width: 16),
          _GlassActionChip(
            icon: Icons.restart_alt,
            label: 'art_walk_button_clear_all'.tr(),
            onTap: _clearAllFilters,
          ),
        ],
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return SizedBox(
      height: 56,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: AppTypography.body(),
        onChanged: onChanged,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          hintText: hint,
          hintStyle: GoogleFonts.spaceGrotesk(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.7)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: Color(0xFF22D3EE), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildSliderCard({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: AppTypography.body())),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF22D3EE),
              inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
              thumbColor: const Color(0xFF7C4DFF),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              label: value.toStringAsFixed(1),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTypography.sectionLabel());
  }

  List<Widget> _buildActiveFilterChips() {
    final chips = <Widget>[];

    if (_criteria.searchQuery?.isNotEmpty ?? false) {
      chips.add(
        _ActiveFilterChip(
          icon: Icons.search,
          label: '"${_criteria.searchQuery}"',
        ),
      );
    }

    if (_criteria.difficulty != null) {
      final key = _difficultyLabelKeys[_criteria.difficulty!];
      chips.add(
        _ActiveFilterChip(
          icon: Icons.trending_up,
          label: key != null ? key.tr() : _criteria.difficulty!,
        ),
      );
    }

    if (_criteria.isAccessible == true) {
      chips.add(
        _ActiveFilterChip(
          icon: Icons.accessible_forward,
          label: 'art_walk_art_walk_search_filter_text_accessible'.tr(),
        ),
      );
    }

    if (_criteria.isPublic == true) {
      chips.add(
        _ActiveFilterChip(
          icon: Icons.public,
          label: 'art_walk_art_walk_search_filter_text_public_walks_only'.tr(),
        ),
      );
    }

    if (_criteria.maxDistance != null) {
      chips.add(
        _ActiveFilterChip(
          icon: Icons.route,
          label: 'art_walk_art_walk_search_filter_chip_distance'.tr(
            namedArgs: {'miles': _criteria.maxDistance!.toStringAsFixed(1)},
          ),
        ),
      );
    }

    if (_criteria.maxDuration != null) {
      chips.add(
        _ActiveFilterChip(
          icon: Icons.timer,
          label: 'art_walk_art_walk_search_filter_chip_duration'.tr(
            namedArgs: {'minutes': _criteria.maxDuration!.toInt().toString()},
          ),
        ),
      );
    }

    if (_criteria.tags?.isNotEmpty ?? false) {
      for (final tag in _criteria.tags!) {
        chips.add(_ActiveFilterChip(icon: Icons.local_offer, label: tag));
      }
    }

    if (_criteria.zipCode?.isNotEmpty ?? false) {
      chips.add(
        _ActiveFilterChip(
          icon: Icons.push_pin,
          label: 'art_walk_art_walk_card_text_zip'.tr(
            namedArgs: {'zip': _criteria.zipCode!},
          ),
        ),
      );
    }

    return chips;
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onToggle;

  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: value,
      label: title,
      child: GestureDetector(
        onTap: () => onToggle(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: value
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: value
                  ? const Color(0xFF22D3EE)
                  : Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value
                      ? const Color(0xFF22D3EE).withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.08),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.body()),
                    const SizedBox(height: 8),
                    Text(subtitle, style: AppTypography.helper()),
                  ],
                ),
              ),
              _GlassToggle(value: value, onChanged: onToggle),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectablePill extends StatelessWidget {
  final bool selected;
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool fullWidth;

  const _SelectablePill({
    required this.selected,
    required this.label,
    this.icon,
    this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisAlignment: fullWidth
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );

    final decorated = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: selected
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
              )
            : null,
        color: selected ? null : Colors.white.withValues(alpha: 0.06),
        border: Border.all(
          color: selected
              ? Colors.transparent
              : Colors.white.withValues(alpha: 0.14),
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: const Color(0xFF22D3EE).withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ]
            : [],
      ),
      child: content,
    );

    final child = fullWidth
        ? SizedBox(width: double.infinity, child: decorated)
        : decorated;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(onTap: onTap, child: child),
    );
  }
}

class _GlassActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GlassActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActiveFilterChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _GlassToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: value,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 64,
          height: 32,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: value
                ? const Color(0xFF22D3EE).withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.12),
            border: Border.all(
              color: value
                  ? const Color(0xFF22D3EE)
                  : Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: AnimatedAlign(
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            duration: const Duration(milliseconds: 200),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
