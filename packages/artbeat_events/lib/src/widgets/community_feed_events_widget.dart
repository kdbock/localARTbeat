import 'package:flutter/material.dart';
import '../models/artbeat_event.dart';
import '../services/event_service.dart';
import 'event_card.dart';
import '../screens/event_details_screen.dart';
import 'package:easy_localization/easy_localization.dart';

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
        if (!_isLoading && _error == null && _events.isEmpty)
          _buildEmptyState(),
        if (!_isLoading && _error == null && _events.isNotEmpty)
          _buildEventsList(),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Upcoming Events',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (widget.onViewAllPressed != null)
            TextButton(
              onPressed: widget.onViewAllPressed,
              child: Text('events_view_all'.tr()),
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
      child: Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 8),
              Text(
                'Failed to load events',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _error!,
                style: TextStyle(color: Colors.red.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadEvents,
                child: Text('events_retry'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No upcoming events',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check back later for new events from artists in your community.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
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
