import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/artbeat_event.dart';
import '../models/ticket_type.dart';
import '../services/event_service.dart';
import '../services/calendar_integration_service.dart';
import '../services/event_notification_service.dart';
import '../widgets/ticket_purchase_sheet.dart';
import '../utils/event_utils.dart';

/// Screen for displaying detailed event information
class EventDetailsScreen extends StatefulWidget {
  final String eventId;

  const EventDetailsScreen({super.key, required this.eventId});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final EventService _eventService = EventService();
  final CalendarIntegrationService _calendarService =
      CalendarIntegrationService();
  final EventNotificationService _notificationService =
      EventNotificationService();
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ArtbeatEvent? _event;
  bool _isLoading = true;
  String? _error;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _ticketsSectionKey = GlobalKey();
  bool _isProcessingAction = false;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final event = await _eventService.getEventById(widget.eventId);

      setState(() {
        _event = event;
        _isLoading = false;
      });
    } on Exception catch (e) {
      setState(() {
        _error = 'Failed to load event: $e';
        _isLoading = false;
      });
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
            title: _event?.title ?? 'Event Details',
            showLogo: false,
            actions: [
              if (_event != null) ...[
                IconButton(
                  onPressed: _shareEvent,
                  icon: const Icon(Icons.share),
                ),
                PopupMenuButton<String>(
                  onSelected: _handleMenuAction,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'add_to_calendar',
                      child: ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: Text('events_add_to_calendar'.tr()),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'set_reminder',
                      child: ListTile(
                        leading: const Icon(Icons.notifications),
                        title: Text('events_set_reminder'.tr()),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'report',
                      child: ListTile(
                        leading: const Icon(Icons.flag),
                        title: Text('events_report_event'.tr()),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      child: _buildBody(),
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
              onPressed: _loadEvent,
              child: Text('events_retry'.tr()),
            ),
          ],
        ),
      );
    }

    if (_event == null) {
      return Center(child: Text('event_not_found'.tr()));
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ArtbeatColors.primaryPurple.withAlpha(25),
            ArtbeatColors.backgroundPrimary,
            ArtbeatColors.primaryGreen.withAlpha(25),
          ],
        ),
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEventBanner(),
            _buildEventHeader(),
            _buildEventInfo(),
            _buildEventDescription(),
            _buildTicketTypes(),
            _buildEventTags(),
            _buildRefundPolicy(),
            _buildContactInfo(),
            const SizedBox(height: 100), // Space for floating action button
          ],
        ),
      ),
    );
  }

  Widget _buildEventBanner() {
    return SizedBox(
      height: 250,
      width: double.infinity,
      child: _event!.eventBannerUrl.isNotEmpty
          ? ImageManagementService().getOptimizedImage(
              imageUrl: _event!.eventBannerUrl,
              width: double.infinity,
              height: 250,
              errorWidget: _buildPlaceholderBanner(),
            )
          : _buildPlaceholderBanner(),
    );
  }

  Widget _buildPlaceholderBanner() {
    return Container(
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Event Banner',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildEventHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _event!.title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getStatusColor()),
                ),
                child: Text(
                  EventUtils.getEventStatus(_event!),
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                EventUtils.getTimeUntilEvent(_event!.dateTime),
                style: const TextStyle(
                  color: ArtbeatColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ArtbeatColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ArtbeatColors.border),
        boxShadow: [
          BoxShadow(
            color: ArtbeatColors.primaryPurple.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.calendar_today,
            'Date',
            EventUtils.formatEventDate(_event!.dateTime),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.access_time,
            'Time',
            EventUtils.formatEventTime(_event!.dateTime),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on, 'Location', _event!.location),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.people,
            'Capacity',
            '${_event!.attendeeIds.length} / ${_event!.maxAttendees} attendees',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: ArtbeatColors.primaryPurple),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: ArtbeatColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: ArtbeatColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventDescription() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About This Event',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            _event!.description,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketTypes() {
    if (_event!.ticketTypes.isEmpty) return const SizedBox.shrink();

    return Padding(
      key: _ticketsSectionKey,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tickets',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._event!.ticketTypes.map(_buildTicketTypeCard),
        ],
      ),
    );
  }

  Widget _buildTicketTypeCard(TicketType ticket) {
    final isAvailable = ticket.isAvailable;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (ticket.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          ticket.description,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      ticket.formattedPrice,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      '${ticket.remainingQuantity} left',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Benefits for VIP tickets
            if (ticket.benefits.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Includes:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 4),
              ...ticket.benefits.map(
                (benefit) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.check, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          benefit,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isAvailable
                    ? () => _showTicketPurchaseSheet(ticket)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAvailable ? null : Colors.grey.shade300,
                ),
                child: Text(
                  isAvailable ? 'Select Tickets' : 'Sold Out',
                  style: TextStyle(
                    color: isAvailable ? null : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTags() {
    if (_event!.tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Categories',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _event!.tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundPolicy() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.policy, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Refund Policy',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _event!.refundPolicy.fullDescription,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contact Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildContactRow(Icons.email, _event!.contactEmail),
              if (_event!.contactPhone != null &&
                  _event!.contactPhone!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildContactRow(Icons.phone, _event!.contactPhone!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Color _getStatusColor() {
    final status = EventUtils.getEventStatus(_event!);
    switch (status) {
      case 'Ended':
        return Colors.grey;
      case 'Sold Out':
        return Colors.red;
      case 'Almost Full':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  void _shareEvent() {
    final eventUrl = 'https://artbeat.app/events/${_event!.id}';
    // ignore: deprecated_member_use
    share_plus.Share.share('Check out this event on ARTbeat! $eventUrl');
  }

  Future<void> _handleMenuAction(String action) async {
    if (_isProcessingAction) return;

    setState(() => _isProcessingAction = true);

    try {
      switch (action) {
        case 'add_to_calendar':
          await _calendarService.addEventToCalendar(_event!);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('events_added_to_calendar'.tr())),
            );
          }
          break;

        case 'set_reminder':
          await _notificationService.scheduleEventReminders(_event!);
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('events_reminder_set'.tr())));
          }
          break;

        case 'report':
          _showReportDialog();
          break;
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'events_calendar_error'.tr(namedArgs: {'error': e.toString()}),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingAction = false);
      }
    }
  }

  void _showTicketPurchaseSheet(TicketType ticket) {
    final currentUser = _userService.currentUser;

    if (currentUser == null) {
      // Show login prompt if not authenticated
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('events_login_required'.tr()),
          content: Text('events_login_required_message'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('common_cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/login');
              },
              child: Text('auth_sign_in'.tr()),
            ),
          ],
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TicketPurchaseSheet(
        event: _event!,
        ticketType: ticket,
        onPurchaseComplete: () {
          Navigator.pop(context);
          _refreshEvent();

          // Show success dialog
          showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('events_tickets_purchased_title'.tr()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('events_tickets_purchased_message'.tr()),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/events/my-tickets');
                    },
                    child: Text('events_view_my_tickets'.tr()),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('events_close'.tr()),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _refreshEvent() async {
    try {
      final updatedEvent = await _eventService.getEvent(_event!.id);
      if (updatedEvent != null && mounted) {
        setState(() {
          _event = updatedEvent;
        });
      }
    } on Exception {
      // Handle error silently or show a subtle message
    }
  }

  void _showReportDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('events_report_event'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('events_report_reason_prompt'.tr()),
            const SizedBox(height: 16),
            _buildReportOption('Inappropriate content'),
            _buildReportOption('Misleading information'),
            _buildReportOption('Potential scam'),
            _buildReportOption('Other'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common_cancel'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildReportOption(String reason) {
    return ListTile(
      title: Text(reason),
      onTap: () {
        Navigator.pop(context);
        _submitReport(reason);
      },
    );
  }

  Future<void> _submitReport(String reason) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('events_login_to_report'.tr())));
        return;
      }

      // Submit report to Firestore
      await _firestore.collection('reports').add({
        'type': 'event',
        'targetId': widget.eventId,
        'reportedBy': currentUser.uid,
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'additionalInfo': {
          'eventTitle': _event?.title ?? 'Unknown Event',
          'eventType': _event?.category ?? 'Unknown',
        },
      });

      // Send notification to moderators
      await _firestore.collection('moderationQueue').add({
        'type': 'event_report',
        'eventId': widget.eventId,
        'reportedBy': currentUser.uid,
        'reason': reason,
        'priority': _getPriorityLevel(reason),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('events_report_submitted'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'events_report_failed'.tr(namedArgs: {'error': e.toString()}),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getPriorityLevel(String reason) {
    switch (reason.toLowerCase()) {
      case 'inappropriate content':
      case 'harassment':
      case 'spam':
        return 'high';
      case 'misleading information':
      case 'copyright violation':
        return 'medium';
      default:
        return 'low';
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
