import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/shared_widgets.dart';

import '../../models/commission_dispute_model.dart';
import '../../services/commission_dispute_service.dart';

class CommissionDisputeScreen extends StatefulWidget {
  const CommissionDisputeScreen({
    super.key,
    required this.commissionId,
    required this.otherPartyId,
    required this.otherPartyName,
  });

  final String commissionId;
  final String otherPartyId;
  final String otherPartyName;

  @override
  State<CommissionDisputeScreen> createState() => _CommissionDisputeScreenState();
}

class _CommissionDisputeScreenState extends State<CommissionDisputeScreen> {
  final CommissionDisputeService _disputeService = CommissionDisputeService();
  final TextEditingController _descriptionController = TextEditingController();

  DisputeReason _selectedReason = DisputeReason.qualityIssue;
  bool _isLoading = false;

  final Map<DisputeReason, IconData> _reasonIcons = {
    DisputeReason.qualityIssue: Icons.palette,
    DisputeReason.nonDelivery: Icons.hourglass_bottom,
    DisputeReason.communicationFailure: Icons.chat_bubble_outline,
    DisputeReason.latenessIssue: Icons.schedule,
    DisputeReason.priceDispute: Icons.attach_money,
    DisputeReason.scopeChange: Icons.layers,
    DisputeReason.other: Icons.help_outline,
  };

  final Map<DisputeReason, Color> _reasonAccentColors = {
    DisputeReason.qualityIssue: const Color(0xFFFFC857),
    DisputeReason.nonDelivery: const Color(0xFFFF3D8D),
    DisputeReason.communicationFailure: const Color(0xFF22D3EE),
    DisputeReason.latenessIssue: const Color(0xFF7C4DFF),
    DisputeReason.priceDispute: const Color(0xFF34D399),
    DisputeReason.scopeChange: const Color(0xFFFF8F6B),
    DisputeReason.other: const Color(0xFFB3B8FF),
  };

  final List<String> _tipKeys = [
    'commission_dispute_tip_detail',
    'commission_dispute_tip_evidence',
    'commission_dispute_tip_response',
    'commission_dispute_tip_professional',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createDispute() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('commission_dispute_error_description_required'.tr()),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _disputeService.createDispute(
        commissionId: widget.commissionId,
        otherPartyId: widget.otherPartyId,
        otherPartyName: widget.otherPartyName,
        reason: _selectedReason,
        description: description,
        metadata: {
          'selectedReason': _selectedReason.name,
        },
      );

      _descriptionController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('commission_dispute_toast_success'.tr()),
        ),
      );
    } catch (e, stackTrace) {
      core.AppLogger.error(
        'Failed to create commission dispute: $e',
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'commission_dispute_toast_error'.tr(namedArgs: {'error': '$e'}),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _contactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('commission_dispute_support_toast'.tr()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WorldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: HudTopBar(
          title: 'commission_dispute_title'.tr(),
          glassBackground: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroCard(),
                const SizedBox(height: 16),
                _buildReasonCard(),
                const SizedBox(height: 16),
                _buildDescriptionCard(),
                const SizedBox(height: 16),
                _buildTipsCard(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: HudButton.secondary(
                  onPressed: _isLoading ? null : _contactSupport,
                  text: 'commission_dispute_action_support'.tr(),
                  icon: Icons.headset_mic,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: HudButton.primary(
                  onPressed: _isLoading ? null : _createDispute,
                  text: 'commission_dispute_action_submit'.tr(),
                  icon: Icons.flag,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      showAccentGlow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Text(
              'commission_dispute_badge_label'.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'commission_dispute_subtitle'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'commission_dispute_intro_subtitle'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
            'commission_dispute_other_party_label'.tr(),
            widget.otherPartyName.isEmpty
                ? 'commission_dispute_unknown_party'.tr()
                : widget.otherPartyName,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'commission_dispute_commission_label'.tr(),
            '#${widget.commissionId}',
          ),
        ],
      ),
    );
  }

  Widget _buildReasonCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'commission_dispute_reason_section_title'.tr(),
            'commission_dispute_reason_section_subtitle'.tr(),
          ),
          const SizedBox(height: 16),
          Column(
            children: DisputeReason.values
                .map(
                  (reason) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildReasonTile(reason),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'commission_dispute_description_title'.tr(),
            'commission_dispute_description_subtitle'.tr(),
          ),
          const SizedBox(height: 16),
          GlassTextField(
            controller: _descriptionController,
            hintText: 'commission_dispute_description_hint'.tr(),
            maxLines: 5,
          ),
          const SizedBox(height: 8),
          Text(
            'commission_dispute_description_helper'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'commission_dispute_tips_title'.tr(),
            'commission_dispute_tips_subtitle'.tr(),
          ),
          const SizedBox(height: 16),
          ..._tipKeys.map(
            (key) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: const Icon(Icons.check, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      key.tr(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonTile(DisputeReason reason) {
    final isSelected = _selectedReason == reason;
    final accent = _reasonAccentColors[reason] ?? Colors.white;

    return GestureDetector(
      onTap: () => setState(() => _selectedReason = reason),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected ? _DisputePalette.primaryGradient : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.15),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Icon(
                _reasonIcons[reason],
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _reasonTitle(reason),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _reasonDescription(reason),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.72),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  String _reasonTitle(DisputeReason reason) {
    return 'commission_dispute_reason_${reason.name}_title'.tr();
  }

  String _reasonDescription(DisputeReason reason) {
    return 'commission_dispute_reason_${reason.name}_description'.tr();
  }
}

class _DisputePalette {
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF7C4DFF),
      Color(0xFF22D3EE),
      Color(0xFF34D399),
    ],
  );
}
