import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:artbeat_events/src/models/artbeat_event.dart';
import 'package:artbeat_events/src/services/event_moderation_service.dart';
import 'package:artbeat_events/src/services/event_service.dart';

/// Admin screen for moderating events
/// Relocated to artbeat_admin for unified administration
class EventModerationDashboardScreen extends StatefulWidget {
  const EventModerationDashboardScreen({super.key});

  @override
  State<EventModerationDashboardScreen> createState() =>
      _EventModerationDashboardScreenState();
}

class _EventModerationDashboardScreenState
    extends State<EventModerationDashboardScreen>
    with SingleTickerProviderStateMixin {
  final EventModerationService _moderationService = EventModerationService();
  final EventService _eventService = EventService();

  late TabController _tabController;
  List<Map<String, dynamic>> _flaggedEvents = [];
  List<ArtbeatEvent> _pendingEvents = [];
  List<ArtbeatEvent> _approvedEvents = [];
  Map<String, dynamic>? _analytics;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final futures = await Future.wait([
        _moderationService.getFlaggedEventsWithDetails(),
        _moderationService.getPendingEvents(),
        _moderationService.getApprovedEvents(),
        _moderationService.getModerationAnalytics(),
      ]);

      setState(() {
        _flaggedEvents = futures[0] as List<Map<String, dynamic>>;
        _pendingEvents = futures[1] as List<ArtbeatEvent>;
        _approvedEvents = futures[2] as List<ArtbeatEvent>;
        _analytics = futures[3] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('event_mod_title'.tr()),
        backgroundColor: Colors.white.withValues(alpha: 0.1),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'event_mod_flagged_events'.tr()),
            Tab(text: 'event_mod_pending_review'.tr()),
            Tab(text: 'event_mod_approved_events'.tr()),
            Tab(text: 'event_mod_analytics'.tr()),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFlaggedEventsTab(),
                    _buildPendingEventsTab(),
                    _buildApprovedEventsTab(),
                    _buildAnalyticsTab(),
                  ],
                ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(_errorMessage ?? 'Error loading events',
              style: const TextStyle(color: Colors.white)),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildFlaggedEventsTab() {
    if (_flaggedEvents.isEmpty)
      return const Center(
          child:
              Text('No flagged events', style: TextStyle(color: Colors.white)));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _flaggedEvents.length,
      itemBuilder: (context, index) =>
          _buildFlaggedEventCard(_flaggedEvents[index]),
    );
  }

  Widget _buildFlaggedEventCard(Map<String, dynamic> data) {
    final event = data['event'] as ArtbeatEvent;
    final flag = data['flag'] as Map<String, dynamic>;
    final flagId = data['flagId'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(event.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          const SizedBox(height: 8),
          Text('Reason: ${flag['reason']}',
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _dismissFlag(flagId, event.id),
                child: const Text('Dismiss Flag',
                    style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _deleteEvent(event.id),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete Event'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingEventsTab() {
    if (_pendingEvents.isEmpty)
      return const Center(
          child:
              Text('No pending events', style: TextStyle(color: Colors.white)));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingEvents.length,
      itemBuilder: (context, index) =>
          _buildPendingEventCard(_pendingEvents[index]),
    );
  }

  Widget _buildPendingEventCard(ArtbeatEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(event.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          const SizedBox(height: 8),
          Text(event.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _reviewEvent(event.id, false),
                child: const Text('Reject',
                    style: TextStyle(color: Colors.redAccent)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _reviewEvent(event.id, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Approve'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApprovedEventsTab() {
    if (_approvedEvents.isEmpty)
      return const Center(
          child: Text('No approved events',
              style: TextStyle(color: Colors.white)));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _approvedEvents.length,
      itemBuilder: (context, index) =>
          _buildApprovedEventCard(_approvedEvents[index]),
    );
  }

  Widget _buildApprovedEventCard(ArtbeatEvent event) {
    return ListTile(
      title: Text(event.title, style: const TextStyle(color: Colors.white)),
      subtitle:
          Text(event.location, style: const TextStyle(color: Colors.white70)),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
        onPressed: () => _deleteEvent(event.id),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    if (_analytics == null)
      return const Center(
          child:
              Text('No analytics data', style: TextStyle(color: Colors.white)));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatCard(
              'Total Reviews', _analytics!['totalReviews']?.toString() ?? '0'),
          const SizedBox(height: 12),
          _buildStatCard('Approval Rate',
              '${((_analytics!['approvalRate'] ?? 0) * 100).toStringAsFixed(1)}%'),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _reviewEvent(String eventId, bool approve) async {
    try {
      await _moderationService.reviewEvent(eventId, approve);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error reviewing event: $e')));
      }
    }
  }

  Future<void> _dismissFlag(String flagId, String eventId) async {
    try {
      await _moderationService.dismissFlag(flagId, eventId);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error dismissing flag: $e')));
      }
    }
  }

  Future<void> _deleteEvent(String eventId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _eventService.deleteEvent(eventId);
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error deleting event: $e')));
        }
      }
    }
  }
}
