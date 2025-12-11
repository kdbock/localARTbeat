import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/artbeat_event.dart';
import 'events_list_screen.dart';
import 'my_tickets_screen.dart';
import 'dart:developer' as developer;

/// Central events dashboard screen - entry point for events tab
/// This is a placeholder that redirects to the comprehensive events system
class EventsDashboardScreen extends StatefulWidget {
  const EventsDashboardScreen({super.key});

  @override
  State<EventsDashboardScreen> createState() => _EventsDashboardScreenState();
}

class _EventsDashboardScreenState extends State<EventsDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<ArtbeatEvent> _events = [];
  List<ArtbeatEvent> _filteredEvents = [];
  String? _error;
  String _selectedCategory = 'All';
  String _selectedTimeFilter = 'All';
  final List<String> _categories = [
    'All',
    'Exhibition',
    'Workshop',
    'Tour',
    'Concert',
    'Gallery',
    'Other',
  ];
  final List<String> _timeFilters = ['All', 'Today', 'This Week', 'This Month'];
  final bool _showFilters = false;
  final bool _debugMode = false;

  void _debugLog(String message) {
    if (_debugMode) {
      developer.log('DEBUG: $message');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Query for upcoming public events
      final now = DateTime.now();
      _debugLog('Current time: $now');

      // First, let's try a simple query to see if we get any events at all
      final allEventsQuery = await _firestore
          .collection('events')
          .limit(5)
          .get();

      _debugLog(
        'All events query returned ${allEventsQuery.docs.length} documents',
      );

      // Now try with just the isPublic filter
      final publicEventsQuery = await _firestore
          .collection('events')
          .where('isPublic', isEqualTo: true)
          .limit(5)
          .get();

      _debugLog(
        'Public events query returned ${publicEventsQuery.docs.length} documents',
      );

      // Finally, try the full query
      final query = await _firestore
          .collection('events')
          .where('isPublic', isEqualTo: true)
          .where('dateTime', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('dateTime', descending: false)
          .limit(10)
          .get();

      _debugLog('Query returned ${query.docs.length} documents');

      final events = query.docs.map((doc) {
        _debugLog('Processing document ${doc.id}');
        final data = doc.data();
        _debugLog('Document data: $data');
        return ArtbeatEvent.fromFirestore(doc);
      }).toList();

      _debugLog('Processed ${events.length} events');
      for (final event in events) {
        _debugLog('Event: ${event.title} at ${event.dateTime}');
      }

      setState(() {
        _events = events;
        _filteredEvents = events;
        _isLoading = false;
      });
      _applyFilters();
    } on FirebaseException catch (e) {
      _debugLog('Error loading events: $e');
      setState(() {
        _error = 'Failed to load events: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredEvents = _events.where((event) {
        // Category filter
        final bool categoryMatch =
            _selectedCategory == 'All' ||
            event.category.toLowerCase() == _selectedCategory.toLowerCase() ||
            _getCategoryFromDescription(event.description).toLowerCase() ==
                _selectedCategory.toLowerCase();

        // Time filter
        bool timeMatch = true;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final eventDate = DateTime(
          event.dateTime.year,
          event.dateTime.month,
          event.dateTime.day,
        );

        switch (_selectedTimeFilter) {
          case 'Today':
            timeMatch = eventDate == today;
            break;
          case 'This Week':
            final weekEnd = today.add(const Duration(days: 7));
            timeMatch =
                event.dateTime.isAfter(now) && event.dateTime.isBefore(weekEnd);
            break;
          case 'This Month':
            final monthEnd = DateTime(now.year, now.month + 1);
            timeMatch =
                event.dateTime.isAfter(now) &&
                event.dateTime.isBefore(monthEnd);
            break;
          default:
            timeMatch = true;
        }

        return categoryMatch && timeMatch;
      }).toList();
    });
  }

  String _getCategoryFromDescription(String description) {
    final desc = description.toLowerCase();
    if (desc.contains('business') || desc.contains('exhibition')) {
      return 'Exhibition';
    }
    if (desc.contains('tour') || desc.contains('walk')) return 'Tour';
    if (desc.contains('music') || desc.contains('concert')) return 'Concert';
    if (desc.contains('workshop') || desc.contains('class')) return 'Workshop';
    if (desc.contains('business')) return 'Gallery';
    return 'Other';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF5F5), // Very light red tint
              Color(0xFFF0F8FF), // Very light blue tint
            ],
          ),
        ),
        child: SafeArea(child: _buildEventsDashboard(context, currentUser)),
      ),
      floatingActionButton: currentUser != null
          ? FloatingActionButton(
              onPressed: () => Navigator.pushNamed(context, '/events/create'),
              backgroundColor: const Color(0xFFE74C3C), // Red
              foregroundColor: Colors.white,
              tooltip: 'Create Event',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EnhancedProfileMenu(),
    );
  }

  void _showSearchModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: ArtbeatColors.primaryPurple,
                      size: 24,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Search Events',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: ArtbeatColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Find events, venues, and organizers',
                            style: TextStyle(
                              fontSize: 14,
                              color: ArtbeatColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Search options
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildSearchOption(
                      icon: Icons.event,
                      title: 'Find Events',
                      subtitle: 'Search by name, category, or location',
                      color: ArtbeatColors.primaryPurple,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const EventsListScreen(
                              title: 'All Events',
                              showCreateButton: true,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildSearchOption(
                      icon: Icons.location_on,
                      title: 'Nearby Events',
                      subtitle: 'Discover events in your area',
                      color: ArtbeatColors.primaryGreen,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const EventsListScreen(
                              title: 'Events Near You',
                              tags: ['nearby'],
                            ),
                          ),
                        );
                      },
                    ),
                    _buildSearchOption(
                      icon: Icons.trending_up,
                      title: 'Popular Events',
                      subtitle: 'See what\'s trending now',
                      color: ArtbeatColors.secondaryTeal,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const EventsListScreen(
                              title: 'Popular Events',
                              tags: ['popular', 'trending'],
                            ),
                          ),
                        );
                      },
                    ),
                    _buildSearchOption(
                      icon: Icons.business,
                      title: 'Venues',
                      subtitle: 'Find event venues and locations',
                      color: ArtbeatColors.accentYellow,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const EventsListScreen(
                              title: 'Event Venues',
                              tags: ['venue', 'location'],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ArtbeatColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: ArtbeatColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatEventDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final eventDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (eventDate == today) {
      return 'Today, ${_formatTime(dateTime)}';
    } else if (eventDate == tomorrow) {
      return 'Tomorrow, ${_formatTime(dateTime)}';
    } else {
      return '${_formatDate(dateTime)}, ${_formatTime(dateTime)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $period';
  }

  String _formatDate(DateTime dateTime) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}';
  }

  IconData _getEventIcon(String description) {
    // Simple keyword matching for event types based on description
    final desc = description.toLowerCase();
    if (desc.contains('business') || desc.contains('exhibition')) {
      return Icons.museum;
    } else if (desc.contains('tour') || desc.contains('walk')) {
      return Icons.directions_walk;
    } else if (desc.contains('music') || desc.contains('concert')) {
      return Icons.music_note;
    } else if (desc.contains('workshop') || desc.contains('class')) {
      return Icons.build;
    } else if (desc.contains('art') || desc.contains('paint')) {
      return Icons.palette;
    } else {
      return Icons.event;
    }
  }

  Widget _buildEventsDashboard(BuildContext context, User? currentUser) {
    return Column(
      children: [
        // Filter Bar
        if (_showFilters) _buildFilterBar(),

        // Main Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Section with Stats
                _buildHeroSection(context, currentUser),
                const SizedBox(height: 16),

                // Events & Experiences Zone ad placement
                
                const SizedBox(height: 24),

                // Quick Actions
                _buildModernQuickActions(context, currentUser),
                const SizedBox(height: 24),

                // Featured Events Section
                if (_filteredEvents.isNotEmpty) ...[
                  _buildSectionHeader('Featured Events', 'Trending now'),
                  const SizedBox(height: 16),
                  _buildFeaturedEventsCarousel(),
                  const SizedBox(height: 16),
                ],

                // All Events Section
                _buildSectionHeader(
                  'All Events',
                  '${_filteredEvents.length} events found',
                ),
                const SizedBox(height: 16),
                _buildModernEventsList(context, currentUser),
                const SizedBox(height: 16),

                // Artist CTA widget
                const CompactArtistCTAWidget(),
                const SizedBox(height: 24),

                // Getting Started (for new users)
                if (currentUser == null) _buildGettingStarted(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Category Filter
          Row(
            children: [
              const Icon(
                Icons.category,
                size: 20,
                color: ArtbeatColors.textSecondary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Category:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((category) {
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                            _applyFilters();
                          },
                          backgroundColor: Colors.grey[100],
                          selectedColor: ArtbeatColors.primaryPurple.withValues(
                            alpha: 0.2,
                          ),
                          checkmarkColor: ArtbeatColors.primaryPurple,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? ArtbeatColors.primaryPurple
                                : ArtbeatColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Time Filter
          Row(
            children: [
              const Icon(
                Icons.schedule,
                size: 20,
                color: ArtbeatColors.textSecondary,
              ),
              const SizedBox(width: 8),
              const Text(
                'When:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _timeFilters.map((timeFilter) {
                      final isSelected = _selectedTimeFilter == timeFilter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(timeFilter),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedTimeFilter = timeFilter;
                            });
                            _applyFilters();
                          },
                          backgroundColor: Colors.grey[100],
                          selectedColor: ArtbeatColors.primaryGreen.withValues(
                            alpha: 0.2,
                          ),
                          checkmarkColor: ArtbeatColors.primaryGreen,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? ArtbeatColors.primaryGreen
                                : ArtbeatColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, User? currentUser) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE74C3C).withValues(alpha: 0.1), // Red
            const Color(0xFF3498DB).withValues(alpha: 0.1), // Light Blue
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE74C3C).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentUser != null
                          ? 'Welcome back!'
                          : 'Discover Art Events',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: ArtbeatColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentUser != null
                          ? 'Find your next creative experience'
                          : 'Explore galleries, workshops, and exhibitions',
                      style: const TextStyle(
                        fontSize: 16,
                        color: ArtbeatColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Profile Icon
              if (currentUser != null)
                IconButton(
                  icon: const Icon(
                    Icons.account_circle,
                    size: 32,
                    color: ArtbeatColors.primaryPurple,
                  ),
                  onPressed: () => _showProfileMenu(context),
                  tooltip: 'Profile',
                ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.palette,
                  size: 32,
                  color: ArtbeatColors.primaryPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Stats Row
          Row(
            children: [
              _buildStatCard('${_events.length}', 'Total Events', Icons.event),
              const SizedBox(width: 16),
              _buildStatCard(
                '${_filteredEvents.length}',
                'Filtered',
                Icons.filter_list,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                '${_events.where((e) => e.dateTime.isAfter(DateTime.now()) && e.dateTime.isBefore(DateTime.now().add(const Duration(days: 7)))).length}',
                'This Week',
                Icons.calendar_today,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFE74C3C), size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ArtbeatColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: ArtbeatColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: ArtbeatColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: ArtbeatColors.textSecondary,
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE74C3C), // Red
                Color(0xFF3498DB), // Light Blue
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/events/all'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'View All',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedEventsCarousel() {
    final featuredEvents = _filteredEvents.take(5).toList();

    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: featuredEvents.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 16,
              right: index == featuredEvents.length - 1 ? 0 : 0,
            ),
            child: _buildFeaturedEventCard(featuredEvents[index]),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedEventCard(ArtbeatEvent event) {
    return SizedBox(
      width: 280,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(
            context,
            '/events/detail',
            arguments: {'eventId': event.id},
          ),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Image
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ArtbeatColors.primaryPurple.withValues(alpha: 0.8),
                          ArtbeatColors.primaryGreen.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Event Banner Image
                        if (event.eventBannerUrl.isNotEmpty &&
                            !event.eventBannerUrl.contains('placeholder') &&
                            (event.eventBannerUrl.startsWith('http://') ||
                                event.eventBannerUrl.startsWith('https://')))
                          SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: Image.network(
                              event.eventBannerUrl,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: ArtbeatColors.primaryPurple
                                          .withValues(alpha: 0.1),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value:
                                              loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                              : null,
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                Color
                                              >(ArtbeatColors.primaryPurple),
                                        ),
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: ArtbeatColors.primaryPurple.withValues(
                                    alpha: 0.1,
                                  ),
                                  child: Icon(
                                    _getEventIcon(event.description),
                                    size: 48,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          )
                        else
                          // Fallback to icon if no banner image or placeholder URL
                          SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: Icon(
                              _getEventIcon(event.description),
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                        // Gradient overlay for better text readability
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.3),
                              ],
                            ),
                          ),
                        ),
                        // Category Badge
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getCategoryFromDescription(event.description),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: ArtbeatColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        // Attendee Count
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.people,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${event.attendeeIds.length}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Event Details
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ArtbeatColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _formatEventDate(event.dateTime),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.location,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernQuickActions(BuildContext context, User? currentUser) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Discover Events',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ArtbeatColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        // First row - Near Me and Trending
        Row(
          children: [
            Expanded(
              child: _buildModernActionCard(
                context,
                icon: Icons.location_on,
                title: 'Near Me',
                subtitle: 'Events nearby',
                color: ArtbeatColors.primaryGreen,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const EventsListScreen(
                        title: 'Events Near You',
                        tags: ['nearby'],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildModernActionCard(
                context,
                icon: Icons.trending_up,
                title: 'Trending',
                subtitle: 'Popular now',
                color: ArtbeatColors.secondaryTeal,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const EventsListScreen(
                        title: 'Trending Events',
                        tags: ['popular', 'trending'],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Second row - This Weekend and My Tickets (if authenticated)
        Row(
          children: [
            Expanded(
              child: _buildModernActionCard(
                context,
                icon: Icons.weekend,
                title: 'This Weekend',
                subtitle: 'Weekend events',
                color: ArtbeatColors.primaryPurple,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const EventsListScreen(
                        title: 'This Weekend',
                        tags: ['weekend'],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: currentUser != null
                  ? _buildModernActionCard(
                      context,
                      icon: Icons.confirmation_number,
                      title: 'My Tickets',
                      subtitle: 'Your purchases',
                      color: const Color(0xFFE74C3C), // Red
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                MyTicketsScreen(userId: currentUser.uid),
                          ),
                        );
                      },
                    )
                  : _buildModernActionCard(
                      context,
                      icon: Icons.search,
                      title: 'Find Events',
                      subtitle: 'Search & filter',
                      color: const Color(0xFFE74C3C), // Red
                      onTap: () => _showSearchModal(context),
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ArtbeatColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: ArtbeatColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernEventsList(BuildContext context, User? currentUser) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Color(0xFFE74C3C), // Red
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Error loading events',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEvents,
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtbeatColors.primaryPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('events_retry'.tr()),
            ),
          ],
        ),
      );
    }

    if (_filteredEvents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _selectedCategory == 'All' && _selectedTimeFilter == 'All'
                  ? 'No upcoming events'
                  : 'No events match your filters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedCategory == 'All' && _selectedTimeFilter == 'All'
                  ? 'Check back later for new events'
                  : 'Try adjusting your filters',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            if (_selectedCategory != 'All' || _selectedTimeFilter != 'All') ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedCategory = 'All';
                    _selectedTimeFilter = 'All';
                  });
                  _applyFilters();
                },
                child: const Text('events_clear_filters'.tr()),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: _filteredEvents
          .map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildModernEventCard(context, event),
            ),
          )
          .toList(),
    );
  }

  Widget _buildModernEventCard(BuildContext context, ArtbeatEvent event) {
    final bool isHappeningNow =
        event.dateTime.isBefore(DateTime.now().add(const Duration(hours: 1))) &&
        event.dateTime.isAfter(
          DateTime.now().subtract(const Duration(hours: 2)),
        );

    final bool isPopular = event.attendeeIds.length > 10;
    final category = _getCategoryFromDescription(event.description);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          '/events/detail',
          arguments: {'eventId': event.id},
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: isHappeningNow
                ? Border.all(
                    color: ArtbeatColors.primaryPurple.withValues(alpha: 0.3),
                    width: 2,
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Header with Image
              Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getCategoryColor(category).withValues(alpha: 0.8),
                      _getCategoryColor(category).withValues(alpha: 0.6),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Event Banner Image
                    if (event.eventBannerUrl.isNotEmpty &&
                        !event.eventBannerUrl.contains('placeholder') &&
                        (event.eventBannerUrl.startsWith('http://') ||
                            event.eventBannerUrl.startsWith('https://')))
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: Image.network(
                            event.eventBannerUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: _getCategoryColor(
                                  category,
                                ).withValues(alpha: 0.1),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                        : null,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _getCategoryColor(category),
                                    ),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: _getCategoryColor(
                                  category,
                                ).withValues(alpha: 0.1),
                                child: Icon(
                                  _getEventIcon(event.description),
                                  size: 40,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              );
                            },
                          ),
                        ),
                      )
                    else
                      // Fallback to icon if no banner image or placeholder URL
                      SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: Icon(
                          _getEventIcon(event.description),
                          size: 40,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    // Gradient overlay for better badge visibility
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.2),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                    ),
                    // Status badges
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Row(
                        children: [
                          // Category badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _getCategoryColor(category),
                              ),
                            ),
                          ),
                          if (isHappeningNow) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: ArtbeatColors.error.withValues(
                                  alpha: 0.9,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'LIVE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                          if (isPopular) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: ArtbeatColors.accentYellow.withValues(
                                  alpha: 0.9,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'POPULAR',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: ArtbeatColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Attendee count
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.people,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${event.attendeeIds.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Event Details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and description
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ArtbeatColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: ArtbeatColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    // Event metadata
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _formatEventDate(event.dateTime),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      event.location,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Action buttons
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: ArtbeatColors.primaryPurple.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.arrow_forward,
                                size: 16,
                                color: ArtbeatColors.primaryPurple,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Tags
                    if (event.tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: event.tags.take(3).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '#$tag',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'exhibition':
        return const Color(0xFFE74C3C); // Red
      case 'workshop':
        return const Color(0xFF3498DB); // Light Blue
      case 'tour':
        return const Color(0xFF5DADE2); // Lighter Blue
      case 'concert':
        return const Color(0xFFE67E22); // Orange
      case 'business':
        return const Color(0xFFE74C3C); // Red
      default:
        return ArtbeatColors.textSecondary;
    }
  }

  Widget _buildGettingStarted(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Getting Started',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 32),
                const SizedBox(height: 12),
                const Text(
                  'Sign in to unlock all features:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('events_feature_purchase_tickets'.tr()),
                    Text('events_feature_manage_events'.tr()),
                    Text('events_feature_view_history'.tr()),
                    Text('events_feature_reminders'.tr()),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    child: const Text('events_sign_in_now'.tr()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
