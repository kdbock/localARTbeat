import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/artbeat_event.dart';
import '../services/event_service.dart';
import '../widgets/event_card.dart';
import '../widgets/glass_kit.dart';
import '../screens/event_details_screen.dart';
import '../screens/create_event_screen.dart';

enum EventListMode { all, myEvents, myTickets }

class EventsListScreen extends StatefulWidget {
  final String? title;
  final String? artistId;
  final List<String>? tags;
  final bool showCreateButton;
  final EventListMode mode;
  final bool showBackButton;

  const EventsListScreen({
    super.key,
    this.title,
    this.artistId,
    this.tags,
    this.showCreateButton = false,
    this.mode = EventListMode.all,
    this.showBackButton = true,
  });

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  final EventService _eventService = EventService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  List<ArtbeatEvent> _allEvents = [];
  List<ArtbeatEvent> _filteredEvents = [];
  bool _isLoading = true;
  String? _error;
  int _currentTabIndex = 0;
  late List<String> _timeFilters;

  @override
  void initState() {
    super.initState();
    _timeFilters = [
      'events_list_tabs_all'.tr(),
      'events_list_tabs_upcoming'.tr(),
      'events_list_tabs_today'.tr(),
      'events_list_tabs_week'.tr(),
    ];
    _loadEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final events = await _eventService.getEvents(
        artistId: widget.artistId,
        tags: widget.tags,
        onlyMine: widget.mode == EventListMode.myEvents,
        onlyMyTickets: widget.mode == EventListMode.myTickets,
      );

      if (mounted) {
        setState(() {
          _allEvents = events;
          _filterEvents();
          _isLoading = false;
        });
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.code == 'permission-denied'
              ? 'events_list_error_permission'.tr()
              : 'events_list_error_load'.tr(
                  namedArgs: {'message': e.message ?? ''},
                );
          _isLoading = false;
        });
      }
    } on Exception {
      if (mounted) {
        setState(() {
          _error = 'events_list_error_unexpected'.tr();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshEvents() async {
    await _loadEvents();
  }

  void _filterEvents() {
    var filtered = List<ArtbeatEvent>.from(_allEvents);

    if (_selectedCategory != 'All') {
      filtered = filtered
          .where(
            (event) =>
                event.category.toLowerCase() == _selectedCategory.toLowerCase(),
          )
          .toList();
    }

    final searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (event) =>
                event.title.toLowerCase().contains(searchQuery) ||
                event.description.toLowerCase().contains(searchQuery),
          )
          .toList();
    }

    switch (_currentTabIndex) {
      case 1:
        filtered = filtered
            .where((event) => event.dateTime.isAfter(DateTime.now()))
            .toList();
        break;
      case 2:
        final now = DateTime.now();
        filtered = filtered
            .where(
              (event) =>
                  event.dateTime.year == now.year &&
                  event.dateTime.month == now.month &&
                  event.dateTime.day == now.day,
            )
            .toList();
        break;
      case 3:
        final now = DateTime.now();
        final weekEnd = now.add(const Duration(days: 7));
        filtered = filtered
            .where(
              (event) =>
                  event.dateTime.isAfter(now) &&
                  event.dateTime.isBefore(weekEnd),
            )
            .toList();
        break;
    }

    if (mounted) {
      setState(() {
        _filteredEvents = filtered;
      });
    }
  }

  void _onTabChanged(int index) {
    if (mounted) {
      setState(() {
        _currentTabIndex = index;
        _filterEvents();
      });
    }
  }

  void _selectCategory(String value) {
    if (mounted) {
      setState(() {
        _selectedCategory = value;
        _filterEvents();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: widget.showCreateButton
          ? _buildCreateFab(context)
          : null,
      body: Stack(
        children: [
          const WorldBackdrop(),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
      child: Row(
        children: [
          GlassIconButton(
            icon: widget.showBackButton
                ? Icons.arrow_back
                : Icons.explore_outlined,
            onTap: widget.showBackButton
                ? () => Navigator.of(context).maybePop()
                : () => Navigator.pushNamed(context, '/events/discover'),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTitle(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xF2FFFFFF),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'events_header_subtitle'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GlassIconButton(
            icon: Icons.search,
            onTap: () => Navigator.pushNamed(context, '/events/search'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF22D3EE)),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      color: const Color(0xFF22D3EE),
      onRefresh: _refreshEvents,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(child: _buildSearchSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 18)),
          SliverToBoxAdapter(child: _buildTimeFilters()),
          if (_filteredEvents.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final event = _filteredEvents[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == _filteredEvents.length - 1 ? 0 : 18,
                    ),
                    child: EventCard(
                      event: event,
                      showTicketInfo: widget.mode == EventListMode.myTickets,
                      onTap: () => _openEventDetails(event),
                    ),
                  );
                }, childCount: _filteredEvents.length),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          GlassSurface(
            radius: 22,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.search, color: Color(0xB3FFFFFF), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => _filterEvents(),
                    cursorColor: const Color(0xFF22D3EE),
                    style: const TextStyle(
                      color: Color(0xF2FFFFFF),
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'events_list_search_hint'.tr(),
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: Color(0xB3FFFFFF),
                      size: 18,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _filterEvents();
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categoryFilters.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final filter = _categoryFilters[index];
                final selected = _selectedCategory == filter.value;
                return GestureDetector(
                  onTap: () => _selectCategory(filter.value),
                  child: GlassSurface(
                    radius: 20,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    fillOpacity: selected ? 0.18 : 0.08,
                    borderColor: selected
                        ? const Color(0xFF22D3EE).withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.12),
                    child: Text(
                      filter.label,
                      style: TextStyle(
                        color: selected
                            ? const Color(0xF2FFFFFF)
                            : Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: List.generate(_timeFilters.length, (index) {
          final selected = _currentTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => _onTabChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(left: index == 0 ? 0 : 10),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: selected
                      ? Colors.white.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.06),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF22D3EE).withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  _timeFilters[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xF2FFFFFF)
                        : Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 32, 18, 80),
      child: GlassSurface(
        radius: 26,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildEmptyStateIcon(),
            const SizedBox(height: 18),
            Text(
              _getEmptyStateTitle(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xF2FFFFFF),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _getEmptyStateMessage(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            _buildEmptyStateActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassSurface(
          radius: 24,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.white70, size: 48),
              const SizedBox(height: 12),
              Text(
                _error ?? 'Error',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xF2FFFFFF),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loadEvents,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22D3EE),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text('events_list_retry'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateIcon() {
    final title = widget.title?.toLowerCase() ?? '';

    IconData icon;
    if (title.contains('near') || title.contains('location')) {
      icon = Icons.location_on;
    } else if (title.contains('trending')) {
      icon = Icons.trending_up;
    } else if (title.contains('weekend')) {
      icon = Icons.calendar_month;
    } else if (title.contains('ticket') ||
        widget.mode == EventListMode.myTickets) {
      icon = Icons.confirmation_number;
    } else {
      icon = Icons.event_available;
    }

    return Icon(icon, size: 62, color: Colors.white.withValues(alpha: 0.8));
  }

  String _getEmptyStateTitle() {
    final title = widget.title?.toLowerCase() ?? '';

    if (title.contains('near') || title.contains('location')) {
      return 'events_list_empty_near_you'.tr();
    } else if (title.contains('trending')) {
      return 'events_list_empty_trending'.tr();
    } else if (title.contains('weekend')) {
      return 'events_list_empty_weekend'.tr();
    } else if (title.contains('ticket') ||
        widget.mode == EventListMode.myTickets) {
      return 'events_list_empty_tickets'.tr();
    } else {
      return 'events_list_empty_default'.tr();
    }
  }

  String _getEmptyStateMessage() {
    final title = widget.title?.toLowerCase() ?? '';

    if (title.contains('near') || title.contains('location')) {
      return 'events_list_empty_msg_near_you'.tr();
    } else if (title.contains('trending')) {
      return 'events_list_empty_msg_trending'.tr();
    } else if (title.contains('weekend')) {
      return 'events_list_empty_msg_weekend'.tr();
    } else if (title.contains('ticket') ||
        widget.mode == EventListMode.myTickets) {
      return 'events_list_empty_msg_tickets'.tr();
    } else {
      return 'events_list_empty_msg_default'.tr();
    }
  }

  Widget _buildEmptyStateActions() {
    final title = widget.title?.toLowerCase() ?? '';

    if (title.contains('ticket') || widget.mode == EventListMode.myTickets) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/events'),
              icon: const Icon(Icons.explore),
              label: Text('events_list_discover_events'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22D3EE),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateEventScreen()),
              ),
              icon: const Icon(Icons.add),
              label: Text('events_list_create_event'.tr()),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          if (widget.showCreateButton)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateEventScreen()),
                ),
                icon: const Icon(Icons.add),
                label: Text('events_list_create_event'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C4DFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          if (widget.showCreateButton) const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/events'),
              icon: const Icon(Icons.refresh),
              label: Text('events_list_view_all_events'.tr()),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildCreateFab(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE), Color(0xFF34D399)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C4DFF).withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add),
        label: Text('events_create_event'.tr()),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateEventScreen()),
          );
          if (result == true) {
            _loadEvents();
          }
        },
      ),
    );
  }

  void _openEventDetails(ArtbeatEvent event) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventDetailsScreen(eventId: event.id)),
    );
  }

  String _getTitle() {
    if (widget.title != null) return widget.title!;

    switch (widget.mode) {
      case EventListMode.all:
        return 'events_list_title_events'.tr();
      case EventListMode.myEvents:
        return 'events_list_title_my_events'.tr();
      case EventListMode.myTickets:
        return 'events_list_title_my_tickets'.tr();
    }
  }

  List<_CategoryFilter> get _categoryFilters => [
    _CategoryFilter(value: 'All', label: 'events_all_categories'.tr()),
    _CategoryFilter(value: 'Exhibition', label: 'events_exhibition'.tr()),
    _CategoryFilter(value: 'Workshop', label: 'events_workshop'.tr()),
    _CategoryFilter(value: 'Tour', label: 'events_tour'.tr()),
    _CategoryFilter(value: 'Concert', label: 'events_concert'.tr()),
    _CategoryFilter(value: 'Gallery', label: 'events_gallery'.tr()),
    _CategoryFilter(value: 'Other', label: 'events_other'.tr()),
  ];
}

class _CategoryFilter {
  final String value;
  final String label;

  const _CategoryFilter({required this.value, required this.label});
}
