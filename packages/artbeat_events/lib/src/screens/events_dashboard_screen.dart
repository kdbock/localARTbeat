// Local ARTbeat — EventsDashboardScreen theme refresh (matches the new “glass + neon” design)
//
// What changed (no logic/features removed):
// ✅ Dark/ink background + subtle aurora gradients
// ✅ Glass hero header + glass search pill
// ✅ Glass stat cards + gradient icon chips
// ✅ Category chips become “pill” chips (glassy selected state)
// ✅ Featured + list cards become glass cards with image/gradient, tighter typography
// ✅ Keeps your EventsDrawer + navigation intact
// ✅ Fixes category filter bug (previously compared to literal 'All' while list was localized)
//
// Drop-in replace this whole file.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/artbeat_event.dart';
import '../widgets/events_drawer.dart';
import 'events_list_screen.dart';
import 'my_tickets_screen.dart';

class EventsDashboardScreen extends StatefulWidget {
  const EventsDashboardScreen({super.key});

  @override
  State<EventsDashboardScreen> createState() => _EventsDashboardScreenState();
}

class _EventsDashboardScreenState extends State<EventsDashboardScreen>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  List<ArtbeatEvent> _events = [];
  List<ArtbeatEvent> _filteredEvents = [];
  String? _error;

  late List<String> _categories;
  late String _allCategory;
  late String _selectedCategory;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _categories = [
      'events_all_categories'.tr(),
      'events_exhibition'.tr(),
      'events_workshop'.tr(),
      'events_tour'.tr(),
      'events_concert'.tr(),
      'events_gallery'.tr(),
      'events_other'.tr(),
    ];
    _allCategory = _categories.first;
    _selectedCategory = _allCategory;

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _loadEvents();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final now = DateTime.now();
      final query = await _firestore
          .collection('events')
          .where('isPublic', isEqualTo: true)
          .where('dateTime', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('dateTime', descending: false)
          .limit(50)
          .get();

      final events = query.docs.map(ArtbeatEvent.fromFirestore).toList();

      if (!mounted) return;
      setState(() {
        _events = events;
        _filteredEvents = events;
        _isLoading = false;
      });

      _fadeController.forward(from: 0);
      _applyFilters();
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '${'events_error_loading'.tr()}${e.toString()}';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'events_error_unknown'.tr();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredEvents = _events.where((event) {
        final selected = _selectedCategory.toLowerCase();
        final category = event.category.toLowerCase();
        final guessed = _getCategoryFromDescription(event.description).toLowerCase();

        final categoryMatch =
            _selectedCategory == _allCategory || category == selected || guessed == selected;

        return categoryMatch;
      }).toList();
    });
  }

  String _getCategoryFromDescription(String description) {
    final desc = description.toLowerCase();
    if (desc.contains('business') || desc.contains('exhibition')) return 'Exhibition';
    if (desc.contains('tour') || desc.contains('walk')) return 'Tour';
    if (desc.contains('music') || desc.contains('concert')) return 'Concert';
    if (desc.contains('workshop') || desc.contains('class')) return 'Workshop';
    if (desc.contains('gallery')) return 'Gallery';
    return 'Other';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF070A12),
      drawer: const EventsDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF05060A),
              Color(0xFF0B1220),
              Color(0xFF05060A),
            ],
          ),
        ),
        child: _isLoading
            ? _buildLoadingState()
            : (_error != null)
                ? _buildErrorState()
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: CustomScrollView(
                      slivers: [
                        _buildHeroHeader(currentUser),
                        SliverToBoxAdapter(child: _buildStatsSection()),
                        SliverToBoxAdapter(child: _buildCategoryFilter()),
                        if (_filteredEvents.isNotEmpty)
                          SliverToBoxAdapter(child: _buildFeaturedSection()),
                        SliverToBoxAdapter(child: _buildQuickActionsGrid(currentUser)),
                        SliverToBoxAdapter(
                          child: _buildSectionHeader(
                            'events_upcoming_title'.tr(),
                            'events_upcoming_subtitle'.tr().replaceAll(
                              '{count}',
                              '${_filteredEvents.length}',
                            ),
                          ),
                        ),
                        _buildEventsList(),
                        const SliverToBoxAdapter(child: SizedBox(height: 110)),
                      ],
                    ),
                  ),
      ),
      floatingActionButton: currentUser != null
          ? Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE), Color(0xFF34D399)],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C4DFF).withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: () => Navigator.pushNamed(context, '/events/create'),
                backgroundColor: Colors.transparent,
                elevation: 0,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: Text('events_create_event'.tr()),
              ),
            )
          : null,
    );
  }

  // ==================== HERO HEADER ====================

  Widget _buildHeroHeader(User? currentUser) {
    final userName = currentUser?.displayName?.split(' ').first ?? 'Explorer';
    final greeting = _getDynamicGreeting();

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: _Glass(
          radius: 22,
          blur: 18,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF7C4DFF).withValues(alpha: 0.20),
                  const Color(0xFF22D3EE).withValues(alpha: 0.14),
                  const Color(0xFF34D399).withValues(alpha: 0.12),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Builder(
                          builder: (context) => _IconPillButton(
                            icon: Icons.menu,
                            onTap: () => Scaffold.of(context).openDrawer(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const _GradientIconChip(
                          icon: Icons.celebration,
                          gradient: [Color(0xFFFF3D8D), Color(0xFF7C4DFF)],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$greeting, $userName!',
                                style: const TextStyle(
                                  color: Color(0xF2FFFFFF),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'events_header_subtitle'.tr(),
                                style: const TextStyle(
                                  color: Color(0xB3FFFFFF),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Search pill
                    GestureDetector(
                      onTap: () => _showSearchModal(context),
                      child: _Glass(
                        radius: 18,
                        blur: 14,
                        fillAlpha: 0.10,
                        shadow: false,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Color(0xB3FFFFFF), size: 22),
                            const SizedBox(width: 10),
                            Text(
                              'events_search_placeholder'.tr(),
                              style: const TextStyle(
                                color: Color(0x73FFFFFF),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.tune, color: Colors.white.withValues(alpha: 0.35), size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getDynamicGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'events_greeting_morning'.tr();
    if (hour < 17) return 'events_greeting_afternoon'.tr();
    return 'events_greeting_evening'.tr();
  }

  // ==================== STATS ====================

  Widget _buildStatsSection() {
    final todayEvents = _events.where((e) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final eventDate = DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day);
      return eventDate == today;
    }).length;

    final thisWeekEvents = _events.where((e) {
      final now = DateTime.now();
      final weekEnd = now.add(const Duration(days: 7));
      return e.dateTime.isAfter(now) && e.dateTime.isBefore(weekEnd);
    }).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
      child: Row(
        children: [
          Expanded(
            child: _StatGlassCard(
              icon: Icons.today,
              gradient: const [Color(0xFFFFC857), Color(0xFFFF3D8D)],
              value: '$todayEvents',
              label: 'events_stat_today'.tr(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatGlassCard(
              icon: Icons.calendar_month,
              gradient: const [Color(0xFF34D399), Color(0xFF22D3EE)],
              value: '$thisWeekEvents',
              label: 'events_stat_this_week'.tr(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatGlassCard(
              icon: Icons.event_available,
              gradient: const [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
              value: '${_events.length}',
              label: 'events_stat_upcoming'.tr(),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== CATEGORY FILTER ====================

  Widget _buildCategoryFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Browse',
            style: TextStyle(
              color: Color(0xF2FFFFFF),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final category = _categories[i];
                final selected = _selectedCategory == category;

                return InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () {
                    setState(() => _selectedCategory = category);
                    _applyFilters();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: selected
                          ? Colors.white.withValues(alpha: 0.16)
                          : Colors.white.withValues(alpha: 0.06),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF22D3EE).withValues(alpha: 0.55)
                            : Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: selected ? const Color(0xF2FFFFFF) : const Color(0xB3FFFFFF),
                        fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
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

  // ==================== FEATURED ====================

  Widget _buildFeaturedSection() {
    final featured = _filteredEvents.take(3).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'events_featured_title'.tr(),
                        style: const TextStyle(
                          color: Color(0xF2FFFFFF),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'events_featured_subtitle'.tr(),
                        style: const TextStyle(
                          color: Color(0x73FFFFFF),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/events/all'),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF22D3EE)),
                  child: Text('events_see_all'.tr()),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 270,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: featured.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _buildFeaturedEventCard(featured[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedEventCard(ArtbeatEvent event) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/events/detail',
        arguments: {'eventId': event.id},
      ),
      child: SizedBox(
        width: 290,
        child: _Glass(
          radius: 22,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                child: SizedBox(
                  height: 158,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _eventBanner(event, fallbackIconSize: 50),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.00),
                              Colors.black.withValues(alpha: 0.50),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: _badge(
                          text: _getCategoryFromDescription(event.description),
                          fg: const Color(0xFF0B1220),
                          bg: const Color(0xF2FFFFFF),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: _badge(
                          text: '${event.attendeeIds.length} • ${'events_attending'.tr()}',
                          fg: const Color(0xF2FFFFFF),
                          bg: Colors.black.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xF2FFFFFF),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _metaRow(Icons.schedule, _formatEventDate(event.dateTime)),
                    const SizedBox(height: 6),
                    _metaRow(Icons.location_on, event.location),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _eventBanner(ArtbeatEvent event, {double fallbackIconSize = 36}) {
    final url = event.eventBannerUrl;
    final ok = url.isNotEmpty &&
        !url.contains('placeholder') &&
        (url.startsWith('http://') || url.startsWith('https://'));

    if (!ok) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE), Color(0xFF34D399)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Icon(
            _getEventIcon(event.description),
            size: fallbackIconSize,
            color: Colors.white,
          ),
        ),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE), Color(0xFF34D399)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Icon(
              _getEventIcon(event.description),
              size: fallbackIconSize,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _badge({required String text, required Color fg, required Color bg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w900),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xB3FFFFFF)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xB3FFFFFF),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ==================== QUICK ACTIONS ====================

  Widget _buildQuickActionsGrid(User? currentUser) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'events_discover_title'.tr(),
            style: const TextStyle(
              color: Color(0xF2FFFFFF),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _QuickActionGlass(
                  icon: Icons.location_on,
                  title: 'events_quick_near_me'.tr(),
                  gradient: const [Color(0xFF34D399), Color(0xFF22D3EE)],
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
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionGlass(
                  icon: Icons.trending_up,
                  title: 'events_quick_trending'.tr(),
                  gradient: const [Color(0xFFFFC857), Color(0xFFFF3D8D)],
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
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _QuickActionGlass(
                  icon: Icons.calendar_today,
                  title: 'events_quick_this_weekend'.tr(),
                  gradient: const [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
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
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionGlass(
                  icon: Icons.confirmation_number,
                  title: 'events_quick_my_tickets'.tr(),
                  gradient: const [Color(0xFF22D3EE), Color(0xFF34D399)],
                  onTap: () {
                    final u = FirebaseAuth.instance.currentUser;
                    if (u != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => MyTicketsScreen(userId: u.uid),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('events_sign_in_to_view_tickets'.tr())),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== SECTION HEADER ====================

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xF2FFFFFF),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0x73FFFFFF),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== EVENTS LIST ====================

  Widget _buildEventsList() {
    if (_filteredEvents.isEmpty) return SliverToBoxAdapter(child: _buildEmptyState());

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildEventListCard(_filteredEvents[index]),
          ),
          childCount: _filteredEvents.length,
        ),
      ),
    );
  }

  Widget _buildEventListCard(ArtbeatEvent event) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/events/detail',
        arguments: {'eventId': event.id},
      ),
      child: _Glass(
        radius: 18,
        blur: 14,
        fillAlpha: 0.07,
        borderAlpha: 0.12,
        shadow: false,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
              child: SizedBox(
                width: 108,
                height: 108,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _eventBanner(event, fallbackIconSize: 34),
                    Container(
                      color: Colors.black.withValues(alpha: 0.20),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _badge(
                      text: _getCategoryFromDescription(event.description),
                      fg: const Color(0xF2FFFFFF),
                      bg: Colors.white.withValues(alpha: 0.10),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xF2FFFFFF),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _metaRow(Icons.schedule, _formatEventDate(event.dateTime)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.people, size: 14, color: Color(0xB3FFFFFF)),
                        const SizedBox(width: 6),
                        Text(
                          'events_attending_count'.tr().replaceAll(
                            '{count}',
                            '${event.attendeeIds.length}',
                          ),
                          style: const TextStyle(
                            color: Color(0xB3FFFFFF),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== EMPTY / LOADING / ERROR ====================

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: _Glass(
        radius: 22,
        fillAlpha: 0.06,
        borderAlpha: 0.12,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const _GradientIconChip(
                icon: Icons.event_busy,
                gradient: [Color(0xFF7C4DFF), Color(0xFFFF3D8D)],
              ),
              const SizedBox(height: 14),
              Text(
                'events_empty_title'.tr(),
                style: const TextStyle(
                  color: Color(0xF2FFFFFF),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'events_empty_message'.tr(),
                style: const TextStyle(
                  color: Color(0xB3FFFFFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () {
                  setState(() => _selectedCategory = _allCategory);
                  _applyFilters();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22D3EE),
                  foregroundColor: const Color(0xFF0B1220),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('events_clear_filters'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: _Glass(
        radius: 22,
        blur: 18,
        fillAlpha: 0.06,
        borderAlpha: 0.12,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.3,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22D3EE)),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'events_loading'.tr(),
                style: const TextStyle(
                  color: Color(0xB3FFFFFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _Glass(
          radius: 22,
          blur: 18,
          fillAlpha: 0.06,
          borderAlpha: 0.12,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _GradientIconChip(
                  icon: Icons.error_outline,
                  gradient: [Color(0xFFFF3D8D), Color(0xFFFFC857)],
                ),
                const SizedBox(height: 12),
                Text(
                  'events_error_title'.tr(),
                  style: const TextStyle(
                    color: Color(0xF2FFFFFF),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _error ?? 'events_error_unknown'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xB3FFFFFF),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: _loadEvents,
                  icon: const Icon(Icons.refresh),
                  label: Text('events_try_again'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C4DFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== SEARCH MODAL ====================

  void _showSearchModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        maxChildSize: 0.92,
        minChildSize: 0.35,
        builder: (context, scrollController) => _Glass(
          radius: 24,
          blur: 18,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF7C4DFF).withValues(alpha: 0.14),
                  const Color(0xFF22D3EE).withValues(alpha: 0.10),
                  const Color(0xFF34D399).withValues(alpha: 0.08),
                ],
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: Row(
                    children: [
                      const _GradientIconChip(
                        icon: Icons.search,
                        gradient: [Color(0xFF22D3EE), Color(0xFF34D399)],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'events_search_modal_title'.tr(),
                              style: const TextStyle(
                                color: Color(0xF2FFFFFF),
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'events_search_modal_subtitle'.tr(),
                              style: const TextStyle(
                                color: Color(0x73FFFFFF),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _IconPillButton(
                        icon: Icons.close,
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                    children: [
                      _searchOption(
                        icon: Icons.event,
                        title: 'events_search_find_events'.tr(),
                        subtitle: 'events_search_find_events_subtitle'.tr(),
                        gradient: const [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/events/search');
                        },
                      ),
                      _searchOption(
                        icon: Icons.location_on,
                        title: 'events_search_nearby'.tr(),
                        subtitle: 'events_search_nearby_subtitle'.tr(),
                        gradient: const [Color(0xFF34D399), Color(0xFF22D3EE)],
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
                      _searchOption(
                        icon: Icons.trending_up,
                        title: 'events_search_popular_events'.tr(),
                        subtitle: 'events_search_popular_subtitle'.tr(),
                        gradient: const [Color(0xFFFFC857), Color(0xFFFF3D8D)],
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
                      _searchOption(
                        icon: Icons.business,
                        title: 'events_search_venues'.tr(),
                        subtitle: 'events_search_venues_subtitle'.tr(),
                        gradient: const [Color(0xFF22D3EE), Color(0xFF7C4DFF)],
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
      ),
    );
  }

  Widget _searchOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _Glass(
        radius: 18,
        blur: 14,
        fillAlpha: 0.06,
        borderAlpha: 0.12,
        shadow: false,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _GradientIconChip(icon: icon, gradient: gradient),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xF2FFFFFF),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0x73FFFFFF),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.45)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== HELPERS ====================

  String _formatEventDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final eventDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (eventDate == today) return '${'events_time_today'.tr()}, ${_formatTime(dateTime)}';
    if (eventDate == tomorrow) return '${'events_time_tomorrow'.tr()}, ${_formatTime(dateTime)}';
    return '${_formatDate(dateTime)}, ${_formatTime(dateTime)}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour < 12 ? 'events_time_am'.tr() : 'events_time_pm'.tr();
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $period';
  }

  String _formatDate(DateTime dateTime) {
    final months = [
      'events_month_jan'.tr(),
      'events_month_feb'.tr(),
      'events_month_mar'.tr(),
      'events_month_apr'.tr(),
      'events_month_may'.tr(),
      'events_month_jun'.tr(),
      'events_month_jul'.tr(),
      'events_month_aug'.tr(),
      'events_month_sep'.tr(),
      'events_month_oct'.tr(),
      'events_month_nov'.tr(),
      'events_month_dec'.tr(),
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}';
  }

  IconData _getEventIcon(String description) {
    final desc = description.toLowerCase();
    if (desc.contains('business') || desc.contains('exhibition')) return Icons.museum;
    if (desc.contains('tour') || desc.contains('walk')) return Icons.directions_walk;
    if (desc.contains('music') || desc.contains('concert')) return Icons.music_note;
    if (desc.contains('workshop') || desc.contains('class')) return Icons.build;
    if (desc.contains('art') || desc.contains('paint')) return Icons.palette;
    return Icons.event;
  }
}

// ==================== REUSABLE UI (same system you’re using elsewhere) ====================

class _Glass extends StatelessWidget {
  const _Glass({
    required this.child,
    this.padding,
    this.radius = 20,
    this.blur = 16,
    this.fillAlpha = 0.08,
    this.borderAlpha = 0.14,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsets? padding;
  final double radius;
  final double blur;
  final double fillAlpha;
  final double borderAlpha;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: fillAlpha),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: borderAlpha)),
            boxShadow: shadow
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 26,
                      offset: const Offset(0, 14),
                    ),
                  ]
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GradientIconChip extends StatelessWidget {
  const _GradientIconChip({required this.icon, required this.gradient});
  final IconData icon;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.20),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

class _IconPillButton extends StatelessWidget {
  const _IconPillButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Icon(icon, color: Colors.white.withValues(alpha: 0.9)),
        ),
      ),
    );
  }
}

class _StatGlassCard extends StatelessWidget {
  const _StatGlassCard({
    required this.icon,
    required this.gradient,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final List<Color> gradient;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 18,
      blur: 14,
      fillAlpha: 0.07,
      borderAlpha: 0.12,
      shadow: false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _GradientIconChip(icon: icon, gradient: gradient),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xF2FFFFFF),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0x73FFFFFF),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionGlass extends StatelessWidget {
  const _QuickActionGlass({
    required this.icon,
    required this.title,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 18,
      blur: 14,
      fillAlpha: 0.07,
      borderAlpha: 0.12,
      shadow: false,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _GradientIconChip(icon: icon, gradient: gradient),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xF2FFFFFF),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
