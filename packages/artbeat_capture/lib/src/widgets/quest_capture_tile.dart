import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/artbeat_core.dart'; // for CaptureModel
import 'glass_card.dart';

class QuestCaptureTile extends StatelessWidget {
  final CaptureModel capture;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  const QuestCaptureTile({
    super.key,
    required this.capture,
    required this.onTap,
    this.onEdit,
  });

  Color _statusColor(CaptureStatus status) {
    switch (status) {
      case CaptureStatus.approved:
        return const Color(0xFF34D399);
      case CaptureStatus.pending:
        return const Color(0xFFFFC857);
      case CaptureStatus.rejected:
        return const Color(0xFFFF3D8D);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(capture.status);

    return GlassCard(
      radius: 20,
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 180,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  SecureNetworkImage(
                    imageUrl: capture.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      color: const Color.fromRGBO(255, 255, 255, 0.06),
                      child: const Icon(
                        Icons.broken_image_rounded,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color.fromRGBO(0, 0, 0, 0.78),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                  right: 10,
                  bottom: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((capture.title ?? '').isNotEmpty)
                        Text(
                          capture.title!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.20),
                              blurRadius: 14,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Text(
                          capture.status.value.toUpperCase(),
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.black.withValues(alpha: 0.88),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                      if (onEdit != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(
                              Icons.edit,
                              size: 18,
                              color: Colors.white70,
                            ),
                            tooltip: 'Edit',
                            onPressed: onEdit,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
