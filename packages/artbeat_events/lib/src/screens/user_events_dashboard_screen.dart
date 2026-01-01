import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import 'package:artbeat_core/artbeat_core.dart' hide GradientCTAButton;
import 'package:artbeat_core/shared_widgets.dart' hide GradientCTAButton;
import '../widgets/widgets.dart';

import '../models/artbeat_event.dart';
import 'events_list_screen.dart';

// Shared widgets (local to events package)
import '../widgets/glass_bottom_sheet.dart';

/// User-focused events dashboard showcasing upcoming events
class UserEventsDashboardScreen extends StatefulWidget {
  const UserEventsDashboardScreen({super.key});

  @override
  State<UserEventsDashboardScreen> createState() =>
      _UserEventsDashboardScreenState();
}

class _UserEventsDashboardScreenState
    extends State<UserEventsDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  String? _error;

  List<ArtbeatEvent> _featuredEvents = [];
  List<ArtbeatEvent> _upcomingEvents = [];
  List<ArtbeatEvent> _todayEvents = [];
  List<ArtbeatEvent> _thisWeekEvents = [];

  @override
  void initState() {
    super.initState();
    _loadAllEvents();
  }

  Future<void> _loadAllEvents() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final endOfWeek = today.add(const Duration(days: 7));

      final query = await _firestore
          .collection('events')
          .where('isPublic', isEqualTo: true)
          .where('dateTime', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('dateTime')
          .limit(50)
          .get();

      final allEvents =
          query.docs.map(ArtbeatEvent.fromFirestore).toList();

      final featured = <ArtbeatEvent>[];
      final upcoming = <ArtbeatEvent>[];
      final todayEvents = <ArtbeatEvent>[];
      final thisWeekEvents = <ArtbeatEvent>[];

      for (final event in allEvents) {
        final eventDate = DateTime(
          event.dateTime.year,
          event.dateTime.month,
          event.dateTime.day,
        );

        if (eventDate == today) todayEvents.add(event);

        if (eventDate.isAfter(today) && eventDate.isBefore(endOfWeek)) {
          thisWeekEvents.add(event);
        }

        if (event.attendeeIds.length >= 10 ||
            event.tags.any(
              (t) => [
                'featured',
                'business',
                'exhibition',
                'opening',
              ].contains(t.toLowerCase()),
            )) {
          featured.add(event);
        }

        upcoming.add(event);
      }

      setState(() {
        _featuredEvents = featured.take(5).toList();
        _upcomingEvents = upcoming.take(10).toList();
        _todayEvents = todayEvents;
        _thisWeekEvents = thisWeekEvents.take(8).toList();
        _isLoading = false;
      });

      developer.log(
        'Loaded ${allEvents.length} events',
        name: 'UserEventsDashboard',
      );
    } on Exception catch (e) {
      developer.log('Error loading events: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 4,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: WorldBackground(
          child: SafeArea(
            child: Column(
              children: [
                EventsHudTopBar(
                  title: 'user_events_discover_title'.tr(),
                  showBack: true,
                  onBack: Navigator.of(context).pop,
                  onSearch: _openSearchSheet,
                  onProfile: _openProfileSheet,
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadAllEvents,
                    child: _buildContent(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor:
              AlwaysStoppedAnimation<Color>(ArtbeatColors.primaryPurple),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: 48),
              const SizedBox(height: 12),
              Text(
                'user_events_error_load'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              GradientCTAButton(
                text: 'common_retry'.tr(),
                onPressed: _loadAllEvents,
              ),
            ],
          ),
        ),
      );
    }

    final isEmpty = _todayEvents.isEmpty &&
        _featuredEvents.isEmpty &&
        _thisWeekEvents.isEmpty &&
        _upcomingEvents.isEmpty;

    if (isEmpty) return _buildEmptyState();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(),

          if (_todayEvents.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSectionHeader(
              'user_events_today_section'.tr(),
              Icons.today,
              ArtbeatColors.primaryGreen,
            ),
            const SizedBox(height: 12),
            _horizontalList(_todayEvents),
          ],

          if (_featuredEvents.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionHeader(
              'user_events_featured_section'.tr(),
              Icons.star,
              ArtbeatColors.accentYellow,
            ),
            const SizedBox(height: 12),
            _featuredList(_featuredEvents),
          ],

          if (_thisWeekEvents.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionHeader(
              'user_events_this_week_section'.tr(),
              Icons.calendar_today,
              ArtbeatColors.secondaryTeal,
            ),
            const SizedBox(height: 12),
            _gridEvents(_thisWeekEvents),
          ],

          if (_upcomingEvents.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionHeader(
              'user_events_upcoming_section'.tr(),
              Icons.event,
              ArtbeatColors.primaryPurple,
            ),
            const SizedBox(height: 12),
            _verticalList(_upcomingEvents),
          ],
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    final user = FirebaseAuth.instance.currentUser;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ArtbeatColors.primaryPurple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.palette,
              color: ArtbeatColors.primaryPurple,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user != null
                      ? 'common_welcome_back'.tr()
                      : 'user_events_discover_title'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'events_discover_subtitle'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    color: ArtbeatColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/events/all'),
          child: Text(
            'events_view_all'.tr(),
            style: const TextStyle(
              color: ArtbeatColors.primaryPurple,
            ),
          ),
        ),
      ],
    );
  }

  Widget _horizontalList(List<ArtbeatEvent> events) => SizedBox(
        height: 200,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: events.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, i) => SizedBox(
            width: 260,
            child: _compactCard(events[i]),
          ),
        ),
      );

  Widget _featuredList(List<ArtbeatEvent> events) => SizedBox(
        height: 240,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: events.length,
          separatorBuilder: (_, _) => const SizedBox(width: 16),
          itemBuilder: (_, i) => SizedBox(
            width: 300,
            child: _featuredCard(events[i]),
          ),
        ),
      );

  Widget _gridEvents(List<ArtbeatEvent> events) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: events.length.clamp(0, 4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.9,
        ),
        itemBuilder: (_, i) => _gridCard(events[i]),
      );

  Widget _verticalList(List<ArtbeatEvent> events) => Column(
        children: events.take(6).map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _listCard(e),
          );
        }).toList(),
      );

  Widget _emptyBadge(String text) => Text(
        text,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          color: Colors.grey[400],
        ),
      );

  Widget _emptyIcon(IconData icon) => Icon(
        icon,
        color: Colors.grey[400],
        size: 22,
      );

  Widget _buildEmptyState() {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'user_events_empty_title'.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'user_events_empty_subtitle'.tr(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GradientCTAButton(
              text: 'common_refresh'.tr(),
              onPressed: _loadAllEvents,
            ),
          ],
        ),
      ),
    );
  }

  IconData _eventIcon(String category) {
    switch (category.toLowerCase()) {
      case 'exhibition':
      case 'business':
        return Icons.museum;
      case 'workshop':
      case 'class':
        return Icons.build;
      case 'performance':
      case 'show':
        return Icons.theater_comedy;
      case 'tour':
      case 'walk':
        return Icons.directions_walk;
      case 'music':
      case 'concert':
        return Icons.music_note;
      case 'community':
        return Icons.groups;
      default:
        return Icons.event;
    }
  }

  String _formatDate(DateTime dt) =>
      intl.DateFormat('MMM dd, h:mm a').format(dt);

  Widget _compactCard(ArtbeatEvent e) => GlassCard(
        child: InkWell(
          onTap: () => Navigator.pushNamed(
            context,
            '/events/detail',
            arguments: {'eventId': e.id},
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_eventIcon(e.category),
                    color: ArtbeatColors.primaryPurple),
                const SizedBox(height: 6),
                Text(
                  e.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(_formatDate(e.dateTime)),
                const Spacer(),
                if (e.hasFreeTickets)
                  _emptyBadge('events_badge_free'.tr()),
              ],
            ),
          ),
        ),
      );

  Widget _featuredCard(ArtbeatEvent e) => GlassCard(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ArtbeatColors.primaryPurple.withValues(alpha: 0.15),
                ArtbeatColors.secondaryTeal.withValues(alpha: 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () => Navigator.pushNamed(
              context,
              '/events/detail',
              arguments: {'eventId': e.id},
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _emptyBadge('events_badge_featured'.tr()),
                  const SizedBox(height: 6),
                  Text(
                    e.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  Text(_formatDate(e.dateTime)),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _gridCard(ArtbeatEvent e) => GlassCard(
        child: InkWell(
          onTap: () => Navigator.pushNamed(
            context,
            '/events/detail',
            arguments: {'eventId': e.id},
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _emptyIcon(_eventIcon(e.category)),
                const SizedBox(height: 6),
                Text(
                  e.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Text(_formatDate(e.dateTime)),
              ],
            ),
          ),
        ),
      );

  Widget _listCard(ArtbeatEvent e) => GlassCard(
        child: ListTile(
          onTap: () => Navigator.pushNamed(
            context,
            '/events/detail',
            arguments: {'eventId': e.id},
          ),
          leading: _emptyIcon(_eventIcon(e.category)),
          title: Text(e.title),
          subtitle: Text(_formatDate(e.dateTime)),
          trailing: const Icon(Icons.chevron_right),
        ),
      );

  /// SHEETS

  void _openSearchSheet() {
    GlassBottomSheet.show(
      context: context,
      child: EventsListScreen(
        title: 'events_search_title'.tr(),
      ),
    );
  }

  void _openProfileSheet() {
    GlassBottomSheet.show(
      context: context,
      child: EventsListScreen(
        title: 'events_my_events_title'.tr(),
        tags: const ['mine'],
      ),
    );
  }
}
