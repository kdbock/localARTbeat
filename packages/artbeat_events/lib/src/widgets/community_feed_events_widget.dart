import 'package:flutter/material.dart';
import '../models/artbeat_event.dart';
import '../services/event_service.dart';
import 'event_card.dart';
import '../screens/event_details_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/glass_card.dart';

/// Widget that displays upcoming events in the community feed
class CommunityFeedEventsWidget extends StatefulWidget {
  final int? limit; // Optional limit on number of events to show
  final bool showHeader;
  final VoidCallback? onViewAllPressed;

  const CommunityFeedEventsWidget({
    super.key,
    this.limit,
    this.showHeader = true,
    this.onViewAllPressed,
  });

  @override
  State<CommunityFeedEventsWidget> createState() =>
      _CommunityFeedEventsWidgetState();
}

class _CommunityFeedEventsWidgetState extends State<CommunityFeedEventsWidget> {
  final EventService _eventService = EventService();
  List<ArtbeatEvent> _events = [];
  bool _isLoading = true;
  String? _error;

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

      final events = await _eventService.getUpcomingPublicEvents(
        limit: widget.limit,
      );

      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader) _buildHeader(),
        if (_isLoading) _buildLoadingState(),
        if (_error != null) _buildErrorState(),
        if (!_isLoading && _error == null && _events.isEmpty) _buildEmptyState(),
        if (!_isLoading && _error == null && _events.isNotEmpty) _buildEventsList(),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'events_upcoming_header'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          if (widget.onViewAllPressed != null)
            TextButton(
              onPressed: widget.onViewAllPressed,
              child: Text(
                'events_view_all'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF22D3EE),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GlassCard(
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            Text(
              'events_load_failed'.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _error!,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade300,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEvents,
              child: Text(
                'events_retry'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.event_busy, size: 64, color: Colors.white.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              Text(
                'events_none'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'events_check_back_later'.tr(),
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _events.length,
      itemBuilder: (context, index) {
        final event = _events[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: EventCard(
            event: event,
            onTap: () => _navigateToEventDetails(event),
            showTicketInfo: true,
          ),
        );
      },
    );
  }

  void _navigateToEventDetails(ArtbeatEvent event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailsScreen(eventId: event.id),
      ),
    );
  }
}
