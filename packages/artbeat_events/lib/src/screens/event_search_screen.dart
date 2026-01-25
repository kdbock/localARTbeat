import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/artbeat_event.dart';
import '../services/event_service.dart';
import '../widgets/event_card.dart';
import '../widgets/glass_kit.dart';
import 'event_details_screen.dart';

/// 🔍 Event Search Screen - Find Your Perfect Event!
///
/// Modern search screen with filters matching ArtBeat Events theme
/// Features:
/// - Real-time search with debouncing
/// - Category and date filters
/// - Location-based search
/// - Recent searches
/// - Search suggestions
class EventSearchScreen extends StatefulWidget {
  const EventSearchScreen({super.key});

  @override
  State<EventSearchScreen> createState() => _EventSearchScreenState();
}

class _EventSearchScreenState extends State<EventSearchScreen> {
  final EventService _eventService = EventService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Search state
  List<ArtbeatEvent> _searchResults = [];
  List<String> _recentSearches = [];
  final List<String> _searchSuggestions = [
    'Art Exhibition',
    'Live Music',
    'Workshop',
    'Gallery Opening',
    'Concert',
    'Art Tour',
  ];
  bool _isLoading = false;
  bool _hasSearched = false;

  // Filter state
  String _selectedCategory = 'All';
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedLocation;

  final List<String> _categories = [
    'All',
    'Exhibition',
    'Workshop',
    'Tour',
    'Concert',
    'Gallery',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList('recent_searches') ?? [];
    if (mounted) {
      setState(() {
        _recentSearches = searches;
      });
    }
  }

  Future<void> _saveRecentSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _recentSearches.remove(query);
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 5) {
        _recentSearches = _recentSearches.take(5).toList();
      }
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recent_searches', _recentSearches);
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      await _saveRecentSearch(query);

      // Get all search results
      final results = await _eventService.searchEvents(query);

      // Apply client-side filters
      var filteredResults = results;

      // Filter by category
      if (_selectedCategory != 'All') {
        filteredResults = filteredResults
            .where((event) => event.category == _selectedCategory)
            .toList();
      }

      // Filter by date range
      if (_startDate != null && _endDate != null) {
        filteredResults = filteredResults.where((event) {
          final eventDate = event.dateTime;
          return eventDate.isAfter(_startDate!) &&
              eventDate.isBefore(_endDate!.add(const Duration(days: 1)));
        }).toList();
      }

      if (mounted) {
        setState(() {
          _searchResults = filteredResults;
          _isLoading = false;
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'events_search_error'.tr(namedArgs: {'error': e.toString()}),
            ),
          ),
        );
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _hasSearched = false;
      _selectedCategory = 'All';
      _startDate = null;
      _endDate = null;
      _selectedLocation = null;
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ArtbeatColors.primaryPurple,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _performSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 4,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            const WorldBackdrop(),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildHeader(context),
                  _buildFilterRow(),
                  const SizedBox(height: 12),
                  Expanded(child: _buildContent()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
      child: GlassSurface(
        radius: 24,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GlassIconButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.maybePop(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'events_search_title'.tr(),
                        style: const TextStyle(
                          color: Color(0xF2FFFFFF),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'events_search_subtitle'.tr(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GlassIconButton(
                  icon: Icons.filter_alt,
                  onTap: _showCategoryPicker,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSearchField(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return GlassSurface(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xB3FFFFFF), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              cursorColor: const Color(0xFF22D3EE),
              style: const TextStyle(
                color: Color(0xF2FFFFFF),
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'events_search_hint'.tr(),
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w600,
                ),
              ),
              onChanged: (value) {
                setState(() {});
                Future.delayed(const Duration(milliseconds: 450), () {
                  if (_searchController.text == value) {
                    _performSearch();
                  }
                });
              },
              onSubmitted: (_) => _performSearch(),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, color: Color(0xB3FFFFFF), size: 18),
              onPressed: _clearSearch,
            ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    final bool hasActiveFilters =
        _selectedCategory != 'All' ||
        _startDate != null ||
        _selectedLocation != null;

    final chips = <Widget>[
      _buildFilterChip(
        label: _selectedCategory,
        icon: Icons.category,
        onTap: _showCategoryPicker,
      ),
      _buildFilterChip(
        label: _startDate != null && _endDate != null
            ? '${_startDate!.month}/${_startDate!.day} - ${_endDate!.month}/${_endDate!.day}'
            : 'events_search_date_filter'.tr(),
        icon: Icons.calendar_today,
        onTap: _selectDateRange,
      ),
    ];

    if (hasActiveFilters) {
      chips.add(
        _buildFilterChip(
          label: 'common_clear'.tr(),
          icon: Icons.refresh,
          onTap: () {
            setState(() {
              _selectedCategory = 'All';
              _startDate = null;
              _endDate = null;
              _selectedLocation = null;
            });
            _performSearch();
          },
          isAccent: true,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < chips.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              chips[i],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isAccent = false,
  }) {
    final Color borderColor = isAccent
        ? const Color(0xFF22D3EE).withValues(alpha: 0.7)
        : Colors.white.withValues(alpha: 0.14);

    return GestureDetector(
      onTap: onTap,
      child: GlassSurface(
        radius: 20,
        fillOpacity: isAccent ? 0.2 : 0.08,
        borderColor: borderColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isAccent
                  ? const Color(0xFF22D3EE)
                  : Colors.white.withValues(alpha: 0.75),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xF2FFFFFF),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF22D3EE)),
      );
    }

    if (!_hasSearched) {
      return _buildSearchSuggestions();
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState();
    }

    return _buildSearchResults();
  }

  Widget _buildSearchSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recentSearches.isNotEmpty) ...[
            GlassSurface(
              radius: 24,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'events_search_recent'.tr(),
                    style: const TextStyle(
                      color: Color(0xF2FFFFFF),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _recentSearches
                        .map(
                          (search) => _buildSuggestionChip(
                            label: search,
                            icon: Icons.history,
                            onTap: () {
                              _searchController.text = search;
                              _performSearch();
                            },
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],
          GlassSurface(
            radius: 24,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'events_search_popular'.tr(),
                  style: const TextStyle(
                    color: Color(0xF2FFFFFF),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _searchSuggestions
                      .map(
                        (suggestion) => _buildSuggestionChip(
                          label: suggestion,
                          icon: Icons.trending_up,
                          accent: true,
                          onTap: () {
                            _searchController.text = suggestion;
                            _performSearch();
                          },
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool accent = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassSurface(
        fillOpacity: accent ? 0.25 : 0.12,
        borderColor: accent
            ? const Color(0xFF7C4DFF).withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: accent
                  ? const Color(0xFF7C4DFF)
                  : Colors.white.withValues(alpha: 0.75),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xF2FFFFFF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: GlassSurface(
        radius: 26,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
                ),
              ),
              child: const Icon(
                Icons.search_off,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'events_search_no_results_title'.tr(),
              style: const TextStyle(
                color: Color(0xF2FFFFFF),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'events_search_no_results_desc'.tr(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
      physics: const BouncingScrollPhysics(),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final event = _searchResults[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: EventCard(
            event: event,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailsScreen(eventId: event.id),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'events_search_select_category'.tr(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...(_categories.map((category) {
                return RadioMenuButton<String>(
                  value: category,
                  groupValue: _selectedCategory,
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                    Navigator.pop(context);
                    _performSearch();
                  },
                  child: Text(category),
                );
              }).toList()),
            ],
          ),
        );
      },
    );
  }
}
