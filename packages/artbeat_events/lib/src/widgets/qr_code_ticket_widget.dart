import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/ticket_purchase.dart';
import '../models/artbeat_event.dart';
import '../utils/event_utils.dart';

class QRCodeTicketWidget extends StatelessWidget {
  final TicketPurchase ticket;
  final ArtbeatEvent event;

  const QRCodeTicketWidget({
    super.key,
    required this.ticket,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1,
      child: Scaffold(
        backgroundColor: const Color(0xFF07060F), // World background
        appBar: EnhancedUniversalHeader(
          title: 'Event Ticket',
          showLogo: false,
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              onPressed: () => _shareTicket(context),
              icon: const Icon(Icons.share, color: Colors.white),
            ),
          ],
        ),
        body: Center(
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(28)),
            child: GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 8),
                  _buildDivider(),
                  _buildBody(),
                  const SizedBox(height: 8),
                  _buildDivider(),
                  _buildQRCode(),
                  const SizedBox(height: 8),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        gradient: LinearGradient(
          colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.event, color: Color(0xFF6366F1)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'ARTbeat Event',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _infoRow(
            Icons.calendar_today,
            'Date',
            EventUtils.formatEventDate(event.dateTime),
          ),
          _infoRow(
            Icons.access_time,
            'Time',
            EventUtils.formatEventTime(event.dateTime),
          ),
          _infoRow(Icons.location_on, 'Location', event.location),
          _infoRow(
            Icons.confirmation_number,
            'Tickets',
            '${ticket.quantity} ticket${ticket.quantity > 1 ? 's' : ''}',
          ),
          _infoRow(Icons.person, 'Name', ticket.userName),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white70),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCode() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            'Scan for Entry',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: QrImageView(
              data: ticket.qrCodeData,
              size: 200,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ticket ID: ${_formatTicketId(ticket.id)}',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _footerRow(
            'Purchase Date',
            intl.DateFormat('MMM d, y').format(ticket.purchaseDate),
          ),
          const SizedBox(height: 12),
          _footerRow(
            'Status',
            ticket.status.displayName,
            status: true,
            color: Colors.green.shade100,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50.withValues(alpha: 0.1),
              border: Border.all(
                color: Colors.blue.shade200.withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '⚠️ Important',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.tealAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Keep this QR code safe and present it at the event entrance. Screenshots are acceptable.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerRow(
    String label,
    String value, {
    bool status = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        if (status)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color ?? Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          )
        else
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1),
        color: Colors.white.withValues(alpha: 0.08),
      ),
    );
  }

  String _formatTicketId(String id) {
    if (id.length > 8) {
      return '${id.substring(0, 4)}-${id.substring(4, 8)}-${id.substring(8, 12)}';
    }
    return id;
  }

  void _shareTicket(BuildContext context) {
    final shareText =
        'Here is my ARTbeat event ticket for ${event.title} on '
        '${EventUtils.formatEventDate(event.dateTime)} at ${event.location}.\n'
        'Ticket ID: ${_formatTicketId(ticket.id)}\n'
        'Show this QR code at the entrance!';
    SharePlus.instance.share(ShareParams(text: shareText));
  }
}
