import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:artbeat_core/artbeat_core.dart' hide GradientCTAButton;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/widgets.dart';

import '../models/artbeat_event.dart';
import '../services/event_moderation_service.dart';
import '../services/event_service.dart';
import 'create_event_screen.dart';

// ignore: implementation_imports

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
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: WorldBackground(
        child: SafeArea(
          child: Column(
            children: [
              EventsHudTopBar(
                title: 'event_mod_title'.tr(),
                showBack: true,
                onBack: () => Navigator.pop(context),
              ),

              SizedBox(
                height: 48,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: ArtbeatColors.primaryPurple,
                  labelStyle: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  tabs: [
                    Tab(text: 'event_mod_flagged_events'.tr()),
                    Tab(text: 'event_mod_pending_review'.tr()),
                    Tab(text: 'event_mod_approved_events'.tr()),
                    Tab(text: 'event_mod_analytics'.tr()),
                  ],
                ),
              ),

              Expanded(
                child: _isLoading
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error, color: Colors.red[300], size: 48),
            const SizedBox(height: 12),
            Text(
              'event_mod_error_loading'.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            GradientCTAButton(
              text: 'event_mod_retry'.tr(),
              onPressed: _loadData,
            ),
          ],
        ),
      ),
    );
  }

  // ---------- FLAGGED EVENTS ----------
  Widget _buildFlaggedEventsTab() {
    if (_flaggedEvents.isEmpty) {
      return _emptyState(
        icon: Icons.check_circle,
        title: 'event_mod_no_flagged'.tr(),
        subtitle: 'event_mod_all_clear'.tr(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _flaggedEvents.length,
        itemBuilder: (context, index) =>
            _buildFlaggedEventCard(_flaggedEvents[index]),
      ),
    );
  }

  Widget _buildFlaggedEventCard(Map<String, dynamic> flaggedEventData) {
    final flag = flaggedEventData['flag'] as Map<String, dynamic>;
    final event = flaggedEventData['event'] as ArtbeatEvent;
    final flagId = flaggedEventData['flagId'] as String;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
                _buildFlagTypeChip(flag['flagType'] ?? 'other'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${'event_mod_reason_label'.tr()}: ${flag['reason']}',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${'event_mod_flagged_label'.tr()}: ${_formatTimestamp(flag['timestamp'])}',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white60,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: GradientCTAButton(
                    text: 'event_mod_review'.tr(),
                    onPressed: () => _viewEventDetails(event),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white70),
                  onPressed: () => _editEvent(event),
                  tooltip: 'Edit Event',
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => _deleteEvent(event.id),
                  tooltip: 'Delete Event',
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: () => _dismissFlag(flagId),
                  child: Text(
                    'event_mod_dismiss'.tr(),
                    style: GoogleFonts.spaceGrotesk(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------- PENDING EVENTS ----------
  Widget _buildPendingEventsTab() {
    if (_pendingEvents.isEmpty) {
      return _emptyState(
        icon: Icons.check_circle,
        title: 'event_mod_all_reviewed'.tr(),
        subtitle: '',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingEvents.length,
        itemBuilder: (context, i) => _buildPendingEventCard(_pendingEvents[i]),
      ),
    );
  }

  Widget _buildPendingEventCard(ArtbeatEvent event) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              event.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(color: Colors.white70),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white60, size: 16),
                const SizedBox(width: 4),
                Text(
                  event.location,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                _buildStatusChip('pending'),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                TextButton(
                  onPressed: () => _reviewEvent(event.id, false),
                  child: Text(
                    'event_mod_reject'.tr(),
                    style: GoogleFonts.spaceGrotesk(color: Colors.redAccent),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white70),
                  onPressed: () => _editEvent(event),
                  tooltip: 'Edit Event',
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => _deleteEvent(event.id),
                  tooltip: 'Delete Event',
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: GradientCTAButton(
                    text: 'event_mod_approve'.tr(),
                    onPressed: () => _reviewEvent(event.id, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------- APPROVED EVENTS ----------
  Widget _buildApprovedEventsTab() {
    if (_approvedEvents.isEmpty) {
      return _emptyState(
        icon: Icons.event_available,
        title: 'event_mod_no_approved'.tr(),
        subtitle: '',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _approvedEvents.length,
        itemBuilder: (context, i) =>
            _buildApprovedEventCard(_approvedEvents[i]),
      ),
    );
  }

  Widget _buildApprovedEventCard(ArtbeatEvent event) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              event.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(color: Colors.white70),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white60, size: 16),
                const SizedBox(width: 4),
                Text(
                  event.location,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                _buildStatusChip('approved'),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                TextButton(
                  onPressed: () => _reviewEvent(event.id, false),
                  child: Text(
                    'event_mod_unapprove'.tr(),
                    style: GoogleFonts.spaceGrotesk(color: Colors.redAccent),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white70),
                  onPressed: () => _editEvent(event),
                  tooltip: 'Edit Event',
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => _deleteEvent(event.id),
                  tooltip: 'Delete Event',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------- ANALYTICS ----------
  Widget _buildAnalyticsTab() {
    if (_analytics == null ||
        _analytics is! Map<String, dynamic> ||
        _analytics!['flags'] == null ||
        _analytics!['events'] == null) {
      return _emptyState(
        icon: Icons.analytics,
        title: 'event_mod_analytics_not_available'.tr(),
        subtitle: '',
      );
    }

    final flags = _analytics!['flags'] as Map<String, dynamic>?;
    final events = _analytics!['events'] as Map<String, dynamic>?;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'event_mod_analytics'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _analyticsCard(
                  'Total Flags',
                  flags != null && flags['total'] != null
                      ? '${flags['total']}'
                      : '-',
                  Icons.flag,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _analyticsCard(
                  'Pending Flags',
                  flags != null && flags['pending'] != null
                      ? '${flags['pending']}'
                      : '-',
                  Icons.pending,
                  Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _analyticsCard(
                  'Total Events',
                  events != null && events['total'] != null
                      ? '${events['total']}'
                      : '-',
                  Icons.event,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _analyticsCard(
                  'Flagged',
                  events != null && events['flagged'] != null
                      ? '${events['flagged']}'
                      : '-',
                  Icons.warning,
                  Colors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- Shared UI helpers ----------
  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.white70),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: GoogleFonts.spaceGrotesk(color: Colors.white70),
              ),
          ],
        ),
      ),
    );
  }

  Widget _analyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return GlassCard(
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.spaceGrotesk(color: Colors.white70),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Chip _buildFlagTypeChip(String type) {
    final colors = {
      'spam': Colors.red,
      'inappropriate_content': Colors.orange,
      'misinformation': Colors.purple,
      'intellectual_property': Colors.blue,
      'other': Colors.grey,
    };

    return Chip(
      label: Text(
        type.replaceAll('_', ' ').toUpperCase(),
        style: GoogleFonts.spaceGrotesk(fontSize: 10),
      ),
      // ignore: deprecated_member_use
      backgroundColor: colors[type]?.withValues(alpha: 0.25),
      side: BorderSide(color: colors[type] ?? Colors.grey),
    );
  }

  Chip _buildStatusChip(String status) {
    final colors = {
      'pending': Colors.orange,
      'under_review': Colors.blue,
      'flagged': Colors.red,
      'approved': Colors.green,
      'rejected': Colors.red,
    };

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: GoogleFonts.spaceGrotesk(fontSize: 10),
      ),
      backgroundColor: colors[status]?.withValues(alpha: 0.25),
      side: BorderSide(color: colors[status] ?? Colors.grey),
    );
  }

  String _formatTimestamp(dynamic t) {
    try {
      final date = t is DateTime ? t : (t as Timestamp).toDate();
      return intl.DateFormat('MMM dd, yyyy HH:mm').format(date);
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return 'Unknown';
    }
  }

  Future<void> _reviewEvent(String id, bool approved) async {
    await _moderationService.reviewEvent(id, approved);
    _loadData();
  }

  Future<void> _dismissFlag(String id) async {
    await _moderationService.dismissFlag(id, 'dismissed');
    _loadData();
  }

  void _viewEventDetails(ArtbeatEvent event) {
    // keep your dialog or replace later with GlassBottomSheet version
  }

  void _editEvent(ArtbeatEvent event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEventScreen(editEvent: event),
      ),
    ).then((_) => _loadData());
  }

  Future<void> _deleteEvent(String eventId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'event_mod_delete_confirm_title'.tr(),
          style: GoogleFonts.spaceGrotesk(color: Colors.white),
        ),
        content: Text(
          'event_mod_delete_confirm_desc'.tr(),
          style: GoogleFonts.spaceGrotesk(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('event_mod_cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'event_mod_delete'.tr(),
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _eventService.deleteEvent(eventId);
      _loadData();
    }
  }
}
