import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_sponsorships/artbeat_sponsorships.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/artbeat_event.dart';
import '../models/ticket_type.dart';
import '../services/event_service.dart';
import '../services/calendar_integration_service.dart';
import '../services/event_notification_service.dart';
import '../widgets/glass_kit.dart';
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
      currentIndex: 4,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            const WorldBackdrop(),
            Positioned.fill(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF22D3EE)),
      );
    }

    if (_error != null) {
      return _buildCenteredState(
        icon: Icons.error_outline,
        title: _error!,
        actionLabel: 'events_retry'.tr(),
        onAction: _loadEvent,
      );
    }

    if (_event == null) {
      return _buildCenteredState(
        icon: Icons.event_busy,
        title: 'event_not_found'.tr(),
      );
    }

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _buildHudBar(),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
              child: Column(
                children: [
                  _buildHeroSection(),

                  SponsorBanner(
                    placementKey: SponsorshipPlacements.eventHeader,
                    padding: const EdgeInsets.only(top: 16),
                    showPlaceholder: true,
                    onPlaceholderTap: () =>
                        Navigator.pushNamed(context, '/event-sponsorship'),
                  ),

                  const SizedBox(height: 18),
                  _buildSummaryCard(),
                  const SizedBox(height: 16),
                  _buildActionRow(),
                  if (_event!.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildDescriptionSection(),
                  ],
                  const SizedBox(height: 16),
                  _buildInfoGrid(),
                  if (_event!.ticketTypes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildTicketsSection(),
                  ],
                  if (_sanitizedTags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildTagsSection(),
                  ],
                  const SizedBox(height: 16),
                  _buildRefundSection(),
                  const SizedBox(height: 16),
                  _buildContactSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHudBar() {
    final event = _event;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
      child: Row(
        children: [
          GlassIconButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'events_event_details'.tr(),
                  style: const TextStyle(
                    color: Color(0xF2FFFFFF),
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                if (event != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (event != null) ...[
            const SizedBox(width: 12),
            GlassIconButton(icon: Icons.share, onTap: _shareEvent),
          ],
        ],
      ),
    );
  }

  BoxFit _getBoxFit(String fit) {
    switch (fit) {
      case 'cover':
        return BoxFit.cover;
      case 'contain':
        return BoxFit.contain;
      case 'fill':
        return BoxFit.fill;
      case 'fitWidth':
        return BoxFit.fitWidth;
      case 'fitHeight':
        return BoxFit.fitHeight;
      case 'scaleDown':
        return BoxFit.scaleDown;
      case 'none':
        return BoxFit.none;
      default:
        return BoxFit.cover;
    }
  }

  Widget _buildHeroSection() {
    final event = _event!;
    final bannerUrl = event.eventBannerUrl.isNotEmpty
        ? event.eventBannerUrl
        : (event.imageUrls.isNotEmpty ? event.imageUrls.first : '');

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 260,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (bannerUrl.isNotEmpty)
              OptimizedImage(
                imageUrl: bannerUrl,
                width: double.infinity,
                height: double.infinity,
                fit: _getBoxFit(event.eventBannerFit),
              )
            else
              _buildHeroFallback(event.category),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: _buildCategoryChip(event.category),
            ),
            Positioned(top: 16, right: 16, child: _buildCapacityChip(event)),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        EventUtils.formatEventDate(event.dateTime),
                        style: const TextStyle(
                          color: Color(0xF2FFFFFF),
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        EventUtils.formatEventTime(event.dateTime),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    EventUtils.getTimeUntilEvent(event.dateTime),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroFallback(String category) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE), Color(0xFF34D399)],
        ),
      ),
      child: Icon(
        _iconForCategory(category),
        color: Colors.white.withValues(alpha: 0.9),
        size: 48,
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final label = category.isEmpty ? 'events_event_details'.tr() : category;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF0B1220),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildCapacityChip(ArtbeatEvent event) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.people_alt, color: Color(0xF2FFFFFF), size: 16),
          const SizedBox(width: 6),
          Text(
            '${event.attendeeIds.length}/${event.maxAttendees}',
            style: const TextStyle(
              color: Color(0xF2FFFFFF),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final event = _event!;
    final status = EventUtils.getEventStatus(event);
    final hostName = _hostName;

    return GlassSurface(
      radius: 28,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.title,
            style: const TextStyle(
              color: Color(0xF2FFFFFF),
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildStatusChip(status),
              const SizedBox(width: 12),
              Text(
                EventUtils.getTimeUntilEvent(event.dateTime),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMetaRow(Icons.location_on_outlined, event.location),
          const SizedBox(height: 10),
          _buildMetaRow(
            Icons.category_outlined,
            event.category.isEmpty ? 'events_event_tags'.tr() : event.category,
          ),
          if (hostName != null) ...[
            const SizedBox(height: 16),
            _buildHostRow(hostName),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildHostRow(String name) {
    final event = _event!;
    final hasImage = ImageUrlValidator.isValidImageUrl(event.artistHeadshotUrl);

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.12),
            image: hasImage
                ? DecorationImage(
                    image:
                        ImageUrlValidator.safeNetworkImage(event.artistHeadshotUrl)!,
                    fit: _getBoxFit(event.artistHeadshotFit),
                  )
                : null,
          ),
          child: hasImage
              ? null
              : const Icon(Icons.person, color: Colors.white70, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xF2FFFFFF),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoGrid() {
    final event = _event!;
    return Row(
      children: [
        Expanded(
          child: _buildInfoTile(
            icon: Icons.calendar_today,
            label: 'events_date'.tr(),
            value: EventUtils.formatEventDate(event.dateTime),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoTile(
            icon: Icons.access_time,
            label: 'events_time'.tr(),
            value: EventUtils.formatEventTime(event.dateTime),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoTile(
            icon: Icons.people_alt,
            label: 'events_capacity'.tr(),
            value: '${event.attendeeIds.length}/${event.maxAttendees}',
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return GlassSurface(
      radius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 18),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xF2FFFFFF),
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickAction(
            icon: Icons.calendar_month,
            label: 'events_add_to_calendar'.tr(),
            onTap: _isProcessingAction
                ? null
                : () => _handleMenuAction('add_to_calendar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickAction(
            icon: Icons.notifications_active,
            label: 'events_set_reminder'.tr(),
            onTap: _isProcessingAction
                ? null
                : () => _handleMenuAction('set_reminder'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickAction(
            icon: Icons.flag_outlined,
            label: 'events_report_event'.tr(),
            onTap: _showReportDialog,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: GlassSurface(
          radius: 22,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          fillOpacity: 0.08,
          borderColor: Colors.white.withValues(alpha: 0.18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xF2FFFFFF), size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xF2FFFFFF),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return GlassSurface(
      radius: 26,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'events_about_event'.tr(),
            style: const TextStyle(
              color: Color(0xF2FFFFFF),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _event!.description.trim(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.5,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketsSection() {
    return GlassSurface(
      radius: 26,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'events_tickets'.tr(),
            style: const TextStyle(
              color: Color(0xF2FFFFFF),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          ..._event!.ticketTypes.map(
            (ticket) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTicketCard(ticket),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(TicketType ticket) {
    final isAvailable = ticket.isAvailable;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  ticket.name,
                  style: const TextStyle(
                    color: Color(0xF2FFFFFF),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    ticket.formattedPrice,
                    style: const TextStyle(
                      color: Color(0xFF34D399),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${ticket.remainingQuantity} ${'events_left'.tr()}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (ticket.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              ticket.description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          ],
          if (ticket.benefits.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'events_includes'.tr(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            ...ticket.benefits.map(
              (benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF34D399),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        benefit,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isAvailable
                  ? () => _showTicketPurchaseSheet(ticket)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isAvailable
                    ? const Color(0xFF22D3EE)
                    : Colors.white.withValues(alpha: 0.1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                isAvailable
                    ? 'events_select_tickets'.tr()
                    : 'events_sold_out'.tr(),
                style: TextStyle(
                  color: isAvailable
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    return GlassSurface(
      radius: 24,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'events_categories'.tr(),
            style: const TextStyle(
              color: Color(0xF2FFFFFF),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: _sanitizedTags.map(_buildTagChip).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          color: Color(0xF2FFFFFF),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildRefundSection() {
    return GlassSurface(
      radius: 24,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.policy_outlined,
                color: Color(0xF2FFFFFF),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'events_refund_policy'.tr(),
                style: const TextStyle(
                  color: Color(0xF2FFFFFF),
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _event!.refundPolicy.fullDescription,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.4,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    final event = _event!;
    return GlassSurface(
      radius: 24,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'events_contact_information'.tr(),
            style: const TextStyle(
              color: Color(0xF2FFFFFF),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 14),
          _buildMetaRow(Icons.email_outlined, event.contactEmail),
          if (event.contactPhone != null && event.contactPhone!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildMetaRow(Icons.phone_outlined, event.contactPhone!),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xF2FFFFFF),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCenteredState({
    required IconData icon,
    required String title,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassSurface(
          radius: 26,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 46),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xF2FFFFFF),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22D3EE),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(actionLabel),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<String> get _sanitizedTags => _event!.tags
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toList(growable: false);

  String? get _hostName {
    final metadata = _event!.metadata ?? {};
    final name = metadata['organizerName'] ?? metadata['artistName'];
    if (name is String && name.trim().isNotEmpty) {
      return name.trim();
    }
    return null;
  }

  IconData _iconForCategory(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('workshop')) return Icons.lightbulb_outline;
    if (lower.contains('tour')) return Icons.map_outlined;
    if (lower.contains('concert') || lower.contains('music')) {
      return Icons.music_note;
    }
    if (lower.contains('gallery') || lower.contains('exhibit')) {
      return Icons.museum_outlined;
    }
    return Icons.auto_awesome;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Ended':
        return Colors.grey;
      case 'Sold Out':
        return Colors.redAccent;
      case 'Almost Full':
        return Colors.orangeAccent;
      default:
        return const Color(0xFF34D399);
    }
  }

  void _shareEvent() {
    final eventUrl = 'https://artbeat.app/events/${_event!.id}';
    final message = 'events_share_text'.tr(namedArgs: {'url': eventUrl});
    // ignore: deprecated_member_use
    share_plus.Share.share(message);
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
