import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show
        AppLogger,
        GlassCard,
        GlassInputDecoration,
        GradientCTAButton,
        HudTopBar,
        MainLayout,
        SecureNetworkImage,
        WorldBackground;
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
  late final ArtworkService _artworkService;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  String _selectedLocation = 'All';
  String _selectedMedium = 'All';
  List<String> _selectedStyles = [];
  double? _minPrice;
  double? _maxPrice;
  DateTime? _startDate;
  DateTime? _endDate;
  bool? _isForSale;
  bool? _isFeatured;

  List<ArtworkModel> _searchResults = [];
  List<String> _searchSuggestions = [];
  List<Map<String, dynamic>> _savedSearches = [];
  bool _isLoading = false;
  bool _showFilters = false;

  final List<String> _locations = [
    'All',
    'New York',
    'Los Angeles',
    'Chicago',
    'Miami',
    'Online',
  ];
  final List<String> _mediums = [
    'All',
    'Painting',
    'Sculpture',
    'Digital',
    'Photography',
    'Mixed Media',
  ];

  @override
  void initState() {
    super.initState();
    _artworkService = context.read<ArtworkService>();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
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
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedSearches() async {
    try {
      final savedSearches = await _artworkService.getSavedSearches();
      if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        _searchSuggestions = suggestions;
      });
    } catch (e) {
      AppLogger.error('Error loading search suggestions: $e');
    }
  }

  Future<void> _performAdvancedSearch() async {
    setState(() => _isLoading = true);

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

      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Error performing advanced search: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('advanced_search_error'.tr())));
    }
  }

  Future<void> _saveCurrentSearch() async {
    final searchNameController = TextEditingController();
    await showDialog<void>(
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
                try {
                  await _artworkService.saveSearch(
                    searchNameController.text,
                    criteria,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  await _loadSavedSearches();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('advanced_search_saved_success'.tr()),
                    ),
                  );
                } catch (_) {
                  if (!context.mounted) return;
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

  Future<void> _applySavedSearch(Map<String, dynamic> savedSearch) async {
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
      _minPriceController.text = _minPrice?.toString() ?? '';
      _maxPriceController.text = _maxPrice?.toString() ?? '';
    });

    await _artworkService.updateSavedSearchUsage(savedSearch['id'] as String);
    await _performAdvancedSearch();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 0,
      appBar: HudTopBar(
        title: 'advanced_search_title'.tr(),
        subtitle: '',
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).maybePop(),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt, color: Colors.white),
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
      child: WorldBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              GlassCard(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.all(14),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  cursorColor: const Color(0xFF22D3EE),
                  decoration: GlassInputDecoration.search(
                    hintText: 'advanced_search_hint'.tr(),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white70),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
                  ),
                  onSubmitted: (_) => _performAdvancedSearch(),
                ),
              ),
              if (_searchController.text.isEmpty &&
                  _searchSuggestions.isNotEmpty)
                _buildSuggestionStrip(),
              if (_savedSearches.isNotEmpty) _buildSavedSearchStrip(),
              if (_showFilters) _buildFiltersPanel(),
              if (!_isLoading && _searchController.text.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
                  child: Row(
                    children: [
                      Text(
                        '${_searchResults.length} result${_searchResults.length == 1 ? '' : 's'}',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      if (_hasActiveFilters)
                        TextButton(
                          onPressed: _clearAllFilters,
                          child: const Text('Clear filters'),
                        ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: GradientCTAButton(
                  text: _isLoading
                      ? 'art_walk_search_button_searching'.tr()
                      : 'advanced_search_button'.tr(),
                  icon: Icons.search,
                  onPressed: _performAdvancedSearch,
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _searchController.text.isEmpty && _savedSearches.isEmpty
                    ? Center(
                        child: Text(
                          'advanced_search_empty_state'.tr(),
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white70,
                          ),
                        ),
                      )
                    : _buildSearchResults(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionStrip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'advanced_search_popular'.tr(),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _searchSuggestions.take(6).map((suggestion) {
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
    );
  }

  Widget _buildSavedSearchStrip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'advanced_search_saved'.tr(),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _savedSearches.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final savedSearch = _savedSearches[index];
                  return ActionChip(
                    label: Text(savedSearch['name'] as String),
                    onPressed: () => _applySavedSearch(savedSearch),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'advanced_search_filters_title'.tr(),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'advanced_search_location'.tr(),
                    value: _selectedLocation,
                    options: _locations,
                    onChanged: (value) =>
                        setState(() => _selectedLocation = value),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDropdown(
                    label: 'advanced_search_medium'.tr(),
                    value: _selectedMedium,
                    options: _mediums,
                    onChanged: (value) =>
                        setState(() => _selectedMedium = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minPriceController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: GlassInputDecoration.glass(
                      hintText: 'Min \$',
                      prefixIcon: const Icon(Icons.attach_money, size: 18),
                    ),
                    onChanged: (value) => _minPrice = double.tryParse(value),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _maxPriceController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: GlassInputDecoration.glass(
                      hintText: 'Max \$',
                      prefixIcon: const Icon(Icons.attach_money, size: 18),
                    ),
                    onChanged: (value) => _maxPrice = double.tryParse(value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) setState(() => _startDate = date);
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _startDate != null
                          ? '${_startDate!.month}/${_startDate!.day}/${_startDate!.year}'
                          : 'Start Date',
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) setState(() => _endDate = date);
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _endDate != null
                          ? '${_endDate!.month}/${_endDate!.day}/${_endDate!.year}'
                          : 'End Date',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: const Color(0xFF07060F),
      style: const TextStyle(color: Colors.white),
      decoration: GlassInputDecoration.glass(labelText: label),
      onChanged: (newValue) {
        if (newValue != null) {
          onChanged(newValue);
        }
      },
      items: options
          .map(
            (option) => DropdownMenuItem<String>(
              value: option,
              child: Text(option, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          'art_walk_no_artwork_found_matching_criteria'.tr(),
          style: GoogleFonts.spaceGrotesk(color: Colors.white70),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final artwork = _searchResults[index];
        return GlassCard(
          padding: EdgeInsets.zero,
          radius: 18,
          onTap: () => _navigateToArtworkDetail(artwork.id),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: SecureNetworkImage(
                    imageUrl: artwork.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    enableThumbnailFallback: true,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artwork.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      artwork.medium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    if (artwork.isForSale && artwork.price != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '\$${artwork.price!.toStringAsFixed(2)}',
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF34D399),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
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

  bool get _hasActiveFilters {
    return _selectedLocation != 'All' ||
        _selectedMedium != 'All' ||
        _selectedStyles.isNotEmpty ||
        _minPrice != null ||
        _maxPrice != null ||
        _startDate != null ||
        _endDate != null ||
        _isForSale != null ||
        _isFeatured != null;
  }

  void _clearAllFilters() {
    _minPriceController.clear();
    _maxPriceController.clear();
    setState(() {
      _selectedLocation = 'All';
      _selectedMedium = 'All';
      _selectedStyles = <String>[];
      _minPrice = null;
      _maxPrice = null;
      _startDate = null;
      _endDate = null;
      _isForSale = null;
      _isFeatured = null;
    });
    _performAdvancedSearch();
  }
}
