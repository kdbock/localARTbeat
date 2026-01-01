
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart' as intl;
import 'package:artbeat_core/artbeat_core.dart';

import '../models/artbeat_event.dart';

class EventCard extends StatelessWidget {
  final ArtbeatEvent event;
  final VoidCallback? onTap;
  final bool showTicketInfo;
  final bool showArtistInfo;
  final bool compact;

  static final intl.DateFormat _fullDate = intl.DateFormat('EEE, MMM d • h:mm a');

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.showTicketInfo = false,
    this.showArtistInfo = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final hostName = _hostName;
    final radius = compact ? 20.0 : 24.0;
    final tags = event.tags
        .where((t) => t.trim().isNotEmpty)
        .take(compact ? 2 : 4)
        .toList();

    return GlassCard(
      radius: radius,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroImage(event: event, compact: compact),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: compact ? 16 : 18,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _fullDate.format(event.dateTime),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 10),
                _MetaRow(
                  icon: Icons.location_on_outlined,
                  text: event.location,
                ),
                if (event.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    event.description.trim(),
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                ],
                if (showArtistInfo && hostName != null && hostName.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _HostRow(
                    name: hostName,
                    avatarUrl: event.artistHeadshotUrl,
                  ),
                ],
              ],
            ),
          ),
          if (showTicketInfo)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
              child: _TicketInfo(event: event),
            ),
          if (tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final tag in tags) _TagChip(label: tag.tr()),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: ContentEngagementBar(
              contentId: event.id,
              contentType: 'event',
              initialStats: EngagementStats(
                lastUpdated: DateTime.now(),
                likeCount: event.likeCount,
                shareCount: event.shareCount,
              ),
              isCompact: true,
            ),
          ),
        ],
      ),
    );
  }

  String? get _hostName {
    final metadata = event.metadata ?? {};
    final name = metadata['organizerName'] ?? metadata['artistName'];
    if (name is String && name.trim().isNotEmpty) return name.trim();
    return null;
  }
}

class _HeroImage extends StatelessWidget {
  final ArtbeatEvent event;
  final bool compact;

  const _HeroImage({required this.event, required this.compact});

  static final intl.DateFormat _monthDay = intl.DateFormat('MMM d');
  static final intl.DateFormat _time = intl.DateFormat('h:mm a');

  @override
  Widget build(BuildContext context) {
    final height = compact ? 160.0 : 200.0;
    final imageUrl = event.imageUrls.isNotEmpty
        ? event.imageUrls.first
        : event.eventBannerUrl;

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          OptimizedImage(
            imageUrl: imageUrl,
            width: double.infinity,
            height: height,
          ),

          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.0),
                  Colors.black.withValues(alpha: 0.65),
                ],
              ),
            ),
          ),

          Positioned(
            left: 12,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _monthDay.format(event.dateTime),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _time.format(event.dateTime),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.75)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }
}

class _HostRow extends StatelessWidget {
  final String name;
  final String avatarUrl;

  const _HostRow({required this.name, required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final hasImage = ImageUrlValidator.isValidImageUrl(avatarUrl);

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.white.withValues(alpha: 0.12),
          backgroundImage: hasImage ? NetworkImage(avatarUrl) : null,
          child: hasImage
              ? null
              : const Icon(Icons.person, size: 18, color: Colors.white70),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

class _TicketInfo extends StatelessWidget {
  final ArtbeatEvent event;

  const _TicketInfo({required this.event});

  @override
  Widget build(BuildContext context) {
    final available = (event.totalAvailableTickets - event.totalTicketsSold).clamp(0, 9999);
    final hasPaid = event.hasPaidTickets;
    final hasFreeOnly = event.hasFreeTickets && !hasPaid;
    final lowestPrice = _lowestPaidPrice();

    String label;
    if (hasFreeOnly) {
      label = 'Free Event'.tr();
    } else if (hasPaid) {
      label = '${'Tickets from'.tr()} \$${lowestPrice.toStringAsFixed(2)}';
    } else {
      label = 'No tickets available'.tr();
    }

    final availabilityText = available > 0
        ? '$available ${'left'.tr()}'
        : 'Sold out'.tr();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF102039), Color(0xFF0F172A)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
              ),
            ),
            child: const Icon(
              Icons.confirmation_number_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  availabilityText,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: available > 0
                        ? const Color(0xFF34D399)
                        : Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          if (available > 0)
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.white.withValues(alpha: 0.7),
            ),
        ],
      ),
    );
  }

  double _lowestPaidPrice() {
    double? lowest;
    for (final ticket in event.ticketTypes) {
      if (ticket.price <= 0) continue;
      if (lowest == null || ticket.price < lowest) lowest = ticket.price;
    }
    return lowest ?? 0;
  }
}
