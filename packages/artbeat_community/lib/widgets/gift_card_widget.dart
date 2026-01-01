import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/shared_widgets.dart';

class GiftCardWidget extends StatelessWidget {
  final GiftModel gift;
  final VoidCallback? onSendGift;

  const GiftCardWidget({super.key, required this.gift, this.onSendGift});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              gift.giftType,
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: const Color(0xFF92FFFFFF),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'amount'.tr(args: [gift.amount.toStringAsFixed(2)]),
              style: GoogleFonts.spaceGrotesk(
                color: const Color(0xFF70FFFFFF),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (onSendGift != null)
              HudButton(onPressed: onSendGift, text: 'send_gift'.tr()),
          ],
        ),
      ),
    );
  }
}
