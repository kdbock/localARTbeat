import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/ticket_purchase.dart';
import '../models/artbeat_event.dart';
import '../services/event_service.dart';
import '../utils/event_utils.dart';
import '../widgets/glass_kit.dart';
import '../widgets/qr_code_ticket_widget.dart';

/// Screen for displaying user's purchased tickets
class MyTicketsScreen extends StatefulWidget {
  final String userId;

  const MyTicketsScreen({super.key, required this.userId});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen>
    with TickerProviderStateMixin {
  final EventService _eventService = EventService();

  List<TicketPurchase> _allTickets = [];
  List<TicketPurchase> _filteredTickets = [];
  Map<String, ArtbeatEvent> _eventCache = {};
  bool _isLoading = true;
  String? _error;

  late TabController _tabController;
  int _currentTabIndex = 0;

  late final List<String> _filterTabs = [
    'tickets_tab_all'.tr(),
    'tickets_tab_upcoming'.tr(),
    'tickets_tab_past'.tr(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filterTabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
        _applyFilters();
      }
    });
    _loadTickets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final tickets = await _eventService.getUserTicketPurchases(widget.userId);

      // Load event details for each ticket
      final eventIds = tickets.map((t) => t.eventId).toSet();
      final events = <String, ArtbeatEvent>{};

      for (final eventId in eventIds) {
        try {
          final event = await _eventService.getEvent(eventId);
          if (event != null) {
            events[eventId] = event;
          }
        } on Exception {
          // Continue loading other events if one fails
          continue;
        }
      }

      if (mounted) {
        setState(() {
          _allTickets = tickets;
          _eventCache = events;
          _isLoading = false;
        });
        _applyFilters();
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

  void _applyFilters() {
    List<TicketPurchase> filtered = List.from(_allTickets);
    final now = DateTime.now();

    // Apply tab filter
    switch (_currentTabIndex) {
      case 1: // Upcoming
        filtered = filtered.where((ticket) {
          final event = _eventCache[ticket.eventId];
          return event != null && event.dateTime.isAfter(now);
        }).toList();
        break;
      case 2: // Past
        filtered = filtered.where((ticket) {
          final event = _eventCache[ticket.eventId];
          return event != null && event.dateTime.isBefore(now);
        }).toList();
        break;
    }

    // Sort by event date (upcoming first, then by date)
    filtered.sort((a, b) {
      final eventA = _eventCache[a.eventId];
      final eventB = _eventCache[b.eventId];

      if (eventA == null || eventB == null) return 0;

      final nowTime = DateTime.now();
      final aIsUpcoming = eventA.dateTime.isAfter(nowTime);
      final bIsUpcoming = eventB.dateTime.isAfter(nowTime);

      if (aIsUpcoming && !bIsUpcoming) return -1;
      if (!aIsUpcoming && bIsUpcoming) return 1;

      return eventA.dateTime.compareTo(eventB.dateTime);
    });

    setState(() {
      _filteredTickets = filtered;
    });
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
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildHeader(context),
                  _buildTicketsTabBar(),
                  Expanded(child: _buildBody()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final totalTickets = _allTickets.length;
    final now = DateTime.now();
    final upcomingTickets = _allTickets.where((ticket) {
      final event = _eventCache[ticket.eventId];
      return event != null && event.dateTime.isAfter(now);
    }).length;
    final pastTickets = totalTickets - upcomingTickets;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
      child: GlassSurface(
        radius: 26,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GlassIconButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.maybePop(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'tickets_title'.tr(),
                        style: const TextStyle(
                          color: Color(0xF2FFFFFF),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'events_header_subtitle'.tr(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GlassIconButton(icon: Icons.refresh, onTap: _loadTickets),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    label: 'tickets_tab_all'.tr(),
                    value: '$totalTickets',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    label: 'tickets_tab_upcoming'.tr(),
                    value: '$upcomingTickets',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    label: 'tickets_tab_past'.tr(),
                    value: '$pastTickets',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({required String label, required String value}) {
    return GlassSurface(
      radius: 20,
      fillOpacity: 0.12,
      borderColor: Colors.white.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xF2FFFFFF),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketsTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
      child: GlassSurface(
        radius: 24,
        padding: const EdgeInsets.all(4),
        borderColor: Colors.white.withValues(alpha: 0.12),
        child: TabBar(
          controller: _tabController,
          tabs: _filterTabs.map((tab) => Tab(text: tab)).toList(),
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
            ),
          ),
          indicatorPadding: const EdgeInsets.symmetric(
            horizontal: 2,
            vertical: 4,
          ),
          labelColor: const Color(0xF2FFFFFF),
          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
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
      return _buildErrorState();
    }

    if (_filteredTickets.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: const Color(0xFF22D3EE),
      onRefresh: _loadTickets,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
        itemCount: _filteredTickets.length,
        itemBuilder: (context, index) {
          final ticket = _filteredTickets[index];
          final event = _eventCache[ticket.eventId];

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildTicketCard(ticket, event),
          );
        },
      ),
    );
  }

  Widget _buildTicketCard(TicketPurchase ticket, ArtbeatEvent? event) {
    if (event == null) {
      return GlassSurface(
        radius: 24,
        padding: const EdgeInsets.all(18),
        child: Text(
          'tickets_error_loading'.tr(),
          style: const TextStyle(
            color: Color(0xF2FFFFFF),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final isUpcoming = event.dateTime.isAfter(DateTime.now());

    return GestureDetector(
      onTap: () => _showTicketDetails(ticket, event),
      child: GlassSurface(
        radius: 26,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      color: Color(0xF2FFFFFF),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _buildTicketStatusBadge(ticket, isUpcoming),
              ],
            ),
            const SizedBox(height: 12),
            _buildMetaRow(
              icon: Icons.calendar_today,
              label: EventUtils.formatEventDateTime(event.dateTime),
            ),
            const SizedBox(height: 6),
            _buildMetaRow(icon: Icons.location_on, label: event.location),
            const SizedBox(height: 12),
            GlassSurface(
              radius: 20,
              fillOpacity: 0.08,
              borderColor: Colors.white.withValues(alpha: 0.14),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${'tickets_quantity_label'.tr()}: ${ticket.quantity}',
                          style: const TextStyle(
                            color: Color(0xF2FFFFFF),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${'tickets_total_label'.tr()}: ${ticket.formattedAmount}',
                          style: const TextStyle(
                            color: Color(0xFF34D399),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isUpcoming && ticket.isActive)
                    const Icon(
                      Icons.qr_code_2,
                      color: Color(0xF2FFFFFF),
                      size: 24,
                    ),
                ],
              ),
            ),
            if (isUpcoming && ticket.isActive) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildGlassActionButton(
                      icon: Icons.qr_code,
                      label: 'tickets_qr_code_button'.tr(),
                      onTap: () => _showQRCode(ticket, event),
                    ),
                  ),
                  if (event.canRefund) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildGlassActionButton(
                        icon: Icons.money_off,
                        label: 'tickets_refund_button'.tr(),
                        onTap: () => _requestRefund(ticket, event),
                        color: const Color(0xFFFF3D8D),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xF2FFFFFF),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = const Color(0xFF22D3EE),
  }) {
    return GlassSurface(
      radius: 20,
      fillOpacity: 0.12,
      borderColor: color.withValues(alpha: 0.4),
      padding: EdgeInsets.zero,
      child: TextButton.icon(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xF2FFFFFF),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        ),
        icon: Icon(icon, size: 18, color: color),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildTicketStatusBadge(TicketPurchase ticket, bool isUpcoming) {
    String text;
    Color color;

    if (ticket.isRefunded) {
      text = 'tickets_status_refunded'.tr();
      color = const Color(0xFFFFC857);
    } else if (!isUpcoming) {
      text = 'tickets_status_past_event'.tr();
      color = const Color(0xFF94A3B8);
    } else if (ticket.isActive) {
      text = 'tickets_status_active'.tr();
      color = const Color(0xFF34D399);
    } else {
      text = ticket.status.displayName;
      color = const Color(0xFF22D3EE);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xF2FFFFFF),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: GlassSurface(
        radius: 26,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFFF3D8D), size: 36),
            const SizedBox(height: 12),
            Text(
              'tickets_error_loading'.tr(),
              style: const TextStyle(
                color: Color(0xF2FFFFFF),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 16),
            _buildGlassActionButton(
              icon: Icons.refresh,
              label: 'common_retry'.tr(),
              onTap: _loadTickets,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    String subtitle;

    switch (_currentTabIndex) {
      case 1:
        message = 'tickets_empty_upcoming'.tr();
        subtitle = 'tickets_empty_upcoming_desc'.tr();
        break;
      case 2:
        message = 'tickets_empty_past'.tr();
        subtitle = 'tickets_empty_past_desc'.tr();
        break;
      default:
        message = 'tickets_empty_default'.tr();
        subtitle = 'tickets_empty_default_desc'.tr();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: GlassSurface(
        radius: 26,
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.confirmation_number_outlined,
              size: 48,
              color: Color(0xFF22D3EE),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: const TextStyle(
                color: Color(0xF2FFFFFF),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTicketDetails(TicketPurchase ticket, ArtbeatEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.45,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF05060A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 46,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'events_my_tickets_title'.tr(),
                              style: const TextStyle(
                                color: Color(0xF2FFFFFF),
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 20),
                            GlassSurface(
                              radius: 24,
                              fillOpacity: 0.12,
                              borderColor: Colors.white.withValues(alpha: 0.12),
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.title,
                                    style: const TextStyle(
                                      color: Color(0xF2FFFFFF),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildMetaRow(
                                    icon: Icons.calendar_today,
                                    label: EventUtils.formatEventDateTime(
                                      event.dateTime,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  _buildMetaRow(
                                    icon: Icons.location_on,
                                    label: event.location,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            GlassSurface(
                              radius: 24,
                              borderColor: Colors.white.withValues(alpha: 0.12),
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                children: [
                                  _buildDetailRow(
                                    label: 'tickets_quantity_label'.tr(),
                                    value: '${ticket.quantity}',
                                  ),
                                  _buildDetailRow(
                                    label: 'tickets_total_label'.tr(),
                                    value: ticket.formattedAmount,
                                  ),
                                  _buildDetailRow(
                                    label: 'Ticket ID',
                                    value: ticket.id,
                                  ),
                                  _buildDetailRow(
                                    label: 'Status',
                                    value: ticket.status.displayName,
                                  ),
                                ],
                              ),
                            ),
                            if (ticket.isActive || event.canRefund) ...[
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  if (ticket.isActive) ...[
                                    Expanded(
                                      child: _buildGlassActionButton(
                                        icon: Icons.qr_code_2,
                                        label: 'tickets_qr_code_button'.tr(),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _showQRCode(ticket, event);
                                        },
                                      ),
                                    ),
                                  ],
                                  if (event.canRefund) ...[
                                    if (ticket.isActive)
                                      const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildGlassActionButton(
                                        icon: Icons.money_off,
                                        label: 'tickets_refund_button'.tr(),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _requestRefund(ticket, event);
                                        },
                                        color: const Color(0xFFFF3D8D),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xF2FFFFFF),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQRCode(TicketPurchase ticket, ArtbeatEvent event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRCodeTicketWidget(ticket: ticket, event: event),
      ),
    );
  }

  void _requestRefund(TicketPurchase ticket, ArtbeatEvent event) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('tickets_refund_dialog_title'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('tickets_refund_dialog_message'.tr()),
            const SizedBox(height: 16),
            Text(
              'tickets_refund_amount'.tr(
                namedArgs: {'amount': ticket.formattedAmount},
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'tickets_refund_policy'.tr(
                namedArgs: {'terms': event.refundPolicy.terms},
              ),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('tickets_refund_cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processRefund(ticket);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('tickets_refund_confirm'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _processRefund(TicketPurchase ticket) async {
    try {
      // Attempt to process refund with payment provider
      // NOTE: This assumes TicketPurchase has paymentId and amount fields
      if (ticket.paymentId == null || ticket.amount == null) {
        throw Exception('Missing payment information for refund.');
      }
      // This should be implemented in artbeat_core/services/payment_service.dart
      await PaymentService.refundPayment(
        paymentId: ticket.paymentId!,
        amount: ticket.amount!,
        reason: 'User requested refund',
      );

      // Update ticket status in backend
      await _eventService.refundTicketPurchase(ticket.id, 'mock_refund_id');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('tickets_refund_success'.tr()),
            backgroundColor: Colors.green,
          ),
        );

        _loadTickets();
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'tickets_refund_error'.tr(namedArgs: {'error': e.toString()}),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
