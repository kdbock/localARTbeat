import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/artbeat_event.dart';
import '../services/event_service.dart';
import '../widgets/event_card.dart';
import '../screens/event_details_screen.dart';
import '../screens/create_event_screen.dart';

enum EventListMode { all, myEvents, myTickets }

/// Screen for displaying a list of events with filtering and search
class EventsListScreen extends StatefulWidget {
  final String? title;
  final String? artistId; // Filter by specific artist
  final List<String>? tags; // Filter by tags
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

class _EventsListScreenState extends State<EventsListScreen>
    with TickerProviderStateMixin {
  final EventService _eventService = EventService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  List<ArtbeatEvent> _allEvents = [];
  List<ArtbeatEvent> _filteredEvents = [];
  bool _isLoading = true;
  String? _error;

  late TabController _tabController;
  int _currentTabIndex = 0;

  late List<String> _filterTabs;

  @override
  void initState() {
    super.initState();
    _filterTabs = [
      'events_list_tab_all'.tr(),
      'events_list_tab_upcoming'.tr(),
      'events_list_tab_today'.tr(),
      'events_list_tab_this_week'.tr(),
    ];
    _tabController = TabController(length: _filterTabs.length, vsync: this);
    _loadEvents();
  }

  Future<void> _refreshEvents() async {
    await _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
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
          _error = null;
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

  void _filterEvents() {
    var filtered = List<ArtbeatEvent>.from(_allEvents);

    // Apply category filter
    if (_selectedCategory != 'All') {
      filtered = filtered
          .where((event) => event.category == _selectedCategory)
          .toList();
    }

    // Apply search filter
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

    // Apply tab filter
    switch (_currentTabIndex) {
      case 1: // Upcoming
        filtered = filtered
            .where((event) => event.dateTime.isAfter(DateTime.now()))
            .toList();
        break;
      case 2: // Today
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
      case 3: // This Week
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

  Widget _buildSearchAndFilter() {
    final categories = [
      ('events_list_category_all'.tr(), 'events_list_category_all'),
      ('events_list_category_art_show'.tr(), 'events_list_category_art_show'),
      ('events_list_category_workshop'.tr(), 'events_list_category_workshop'),
      (
        'events_list_category_exhibition'.tr(),
        'events_list_category_exhibition',
      ),
      (
        'events_list_category_gallery_opening'.tr(),
        'events_list_category_gallery_opening',
      ),
      ('events_list_category_other'.tr(), 'events_list_category_other'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'events_list_search_hint'.tr(),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (_) => _filterEvents(),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _selectedCategory,
            items: categories
                .map(
                  (category) => DropdownMenuItem(
                    value: category.$2,
                    child: Text(category.$1),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCategory = value;
                  _filterEvents();
                });
              }
            },
          ),
        ],
      ),
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

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 4, // Events index
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 4),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE74C3C), // Red
                Color(0xFF3498DB), // Light Blue
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: EnhancedUniversalHeader(
            title: _getTitle(),
            showLogo: false,
            showBackButton: widget.showBackButton,
            onBackPressed: () => Navigator.of(context).pop(),
            backgroundColor: Colors.transparent,
            // Removed foregroundColor to use deep purple default
            actions: [
              if (widget.showCreateButton)
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateEventScreen(),
                        fullscreenDialog: true,
                      ),
                    );
                    if (result == true && mounted) {
                      _loadEvents();
                    }
                  },
                ),
            ],
          ),
        ),
      ),
      child: Scaffold(backgroundColor: Colors.transparent, body: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEvents,
              child: Text('events_list_retry'.tr()),
            ),
          ],
        ),
      );
    }

    if (_filteredEvents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildEmptyStateIcon(),
              const SizedBox(height: 24),
              Text(
                _getEmptyStateTitle(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _getEmptyStateMessage(),
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildEmptyStateActions(),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshEvents,
      child: Column(
        children: [
          _buildSearchAndFilter(),
          TabBar(
            controller: _tabController,
            tabs: _filterTabs.map((tab) => Tab(text: tab)).toList(),
            onTap: _onTabChanged,
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredEvents.length,
              itemBuilder: (context, index) {
                final event = _filteredEvents[index];
                return EventCard(
                  event: event,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventDetailsScreen(eventId: event.id),
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

  /// Build context-appropriate empty state icon
  Widget _buildEmptyStateIcon() {
    final title = widget.title?.toLowerCase() ?? '';

    if (title.contains('near') || title.contains('location')) {
      return const Icon(Icons.location_on, size: 64, color: Colors.blue);
    } else if (title.contains('trending')) {
      return const Icon(Icons.trending_up, size: 64, color: Colors.orange);
    } else if (title.contains('weekend')) {
      return const Icon(Icons.calendar_today, size: 64, color: Colors.purple);
    } else if (title.contains('ticket') ||
        widget.mode == EventListMode.myTickets) {
      return const Icon(
        Icons.confirmation_number,
        size: 64,
        color: Colors.teal,
      );
    } else {
      return const Icon(Icons.event_available, size: 64, color: Colors.grey);
    }
  }

  /// Get context-appropriate empty state title
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

  /// Get context-appropriate empty state message
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

  /// Build context-appropriate empty state actions
  Widget _buildEmptyStateActions() {
    final title = widget.title?.toLowerCase() ?? '';

    if (title.contains('ticket') || widget.mode == EventListMode.myTickets) {
      return Column(
        children: [
          ElevatedButton.icon(
            onPressed: () => Navigator.pushReplacementNamed(context, '/events'),
            icon: const Icon(Icons.explore),
            label: Text('events_list_discover_events'.tr()),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateEventScreen()),
            ),
            icon: const Icon(Icons.add),
            label: Text('events_list_create_event'.tr()),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          if (widget.showCreateButton)
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateEventScreen()),
              ),
              icon: const Icon(Icons.add),
              label: Text('events_list_create_event'.tr()),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushReplacementNamed(context, '/events'),
            icon: const Icon(Icons.refresh),
            label: Text('events_list_view_all_events'.tr()),
          ),
        ],
      );
    }
  }
}
