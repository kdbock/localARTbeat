import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';import 'package:artbeat_core/artbeat_core.dart' hide EventModel;
import '../models/event_model_internal.dart';
import '../services/event_service_adapter.dart';

/// Screen showing upcoming events
class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final EventServiceAdapter _eventService = EventServiceAdapter();
  List<EventModel> _events = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final events = await _eventService.getLocalEvents();
      if (!mounted) return;

      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading events: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 2, // Events tab in bottom navigation
      appBar: EnhancedUniversalHeader(
        title: 'Events',
        showBackButton: false,
        showSearch: true,
        showDeveloperTools: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, '/events/create'),
          ),
        ],
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEvents,
              child: _events.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.event_busy,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(tr('art_walk_no_events_found'),
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(tr('art_walk_create_your_first_event_by_tapping_the___button'),
                              style: TextStyle(color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _events.length,
                      padding: const EdgeInsets.all(8.0),
                      itemBuilder: (context, index) {
                        final event = _events[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 4.0),
                          child: ListTile(
                            leading: event.imageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      event.imageUrl!,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        width: 56,
                                        height: 56,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.event),
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(Icons.event),
                                  ),
                            title: Text(
                              event.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  event.endDate != null
                                      ? '${event.startDate.day}/${event.startDate.month}/${event.startDate.year} - ${event.endDate!.day}/${event.endDate!.month}/${event.endDate!.year}'
                                      : '${event.startDate.day}/${event.startDate.month}/${event.startDate.year}',
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  event.location,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/events/detail',
                              arguments: {'eventId': event.id},
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
