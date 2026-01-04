import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/shared_widgets.dart';

import '../../models/direct_commission_model.dart';
import '../../services/commission_rating_service.dart';

class CommissionRatingScreen extends StatefulWidget {
  const CommissionRatingScreen({super.key, required this.commission});

  final DirectCommissionModel commission;

  @override
  State<CommissionRatingScreen> createState() => _CommissionRatingScreenState();
}

class _CommissionRatingScreenState extends State<CommissionRatingScreen> {
  late TextEditingController _commentController;
  double _overallRating = 5;
  double _qualityRating = 5;
  double _communicationRating = 5;
  double _timelinessRating = 5;
  bool _wouldRecommend = true;
  final Set<String> _selectedTags = <String>{};
  bool _isLoading = false;

  static const List<String> _availableTags = [
    'excellent-quality',
    'great-communication',
    'fast-delivery',
    'professional',
    'responsive',
    'attention-to-detail',
    'easy-to-work-with',
    'worth-the-price',
  ];

  static const Map<String, String> _tagLabelKeys = {
    'excellent-quality': 'commission_rating_tag_excellent_quality',
    'great-communication': 'commission_rating_tag_great_communication',
    'fast-delivery': 'commission_rating_tag_fast_delivery',
    'professional': 'commission_rating_tag_professional',
    'responsive': 'commission_rating_tag_responsive',
    'attention-to-detail': 'commission_rating_tag_attention_to_detail',
    'easy-to-work-with': 'commission_rating_tag_easy_to_work_with',
    'worth-the-price': 'commission_rating_tag_worth_the_price',
  };

  static const LinearGradient _primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF7C4DFF),
      Color(0xFF22D3EE),
      Color(0xFF34D399),
    ],
  );

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('commission_rating_error_comment_required'.tr())),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = CommissionRatingService();
      await service.submitRating(
        commissionId: widget.commission.id,
        ratedUserId: widget.commission.artistId,
        ratedUserName: widget.commission.artistName,
        overallRating: _overallRating,
        qualityRating: _qualityRating,
        communicationRating: _communicationRating,
        timelinessRating: _timelinessRating,
        comment: _commentController.text.trim(),
        wouldRecommend: _wouldRecommend,
        tags: _selectedTags.toList(),
        isArtistRating: false,
      );

      if (!mounted) return;
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('commission_rating_submit_success'.tr())),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'commission_rating_submit_error'.tr(namedArgs: {'error': '$e'}),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WorldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: HudTopBar(
          title: 'commission_rating_title'.tr(),
          glassBackground: true, subtitle: '',
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: Column(
              children: [
                _buildArtistSummary(),
                const SizedBox(height: 24),
                _buildRatingCard(),
                const SizedBox(height: 24),
                _buildFeedbackCard(),
                const SizedBox(height: 24),
                _buildCommentCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArtistSummary() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(
            title: 'commission_rating_artist_title'.tr(),
            subtitle: 'commission_rating_artist_subtitle'.tr(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: _primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 32,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.commission.artistName,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.commission.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.78),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(
            title: 'commission_rating_overall_title'.tr(),
            subtitle: 'commission_rating_overall_subtitle'.tr(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: _primaryGradient,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 32,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _overallRating.toStringAsFixed(1),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'commission_rating_overall_max'.tr(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    SliderTheme(
                      data: _sliderTheme(context),
                      child: Slider(
                        value: _overallRating,
                        min: 1,
                        max: 5,
                        divisions: 8,
                        label: _overallRating.toStringAsFixed(1),
                        onChanged: (value) =>
                            setState(() => _overallRating = value),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        5,
                        (index) => _buildStarButton(
                          value: index + 1.0,
                          currentRating: _overallRating,
                          onChanged: (value) =>
                              setState(() => _overallRating = value),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildDetailedRating(
            labelKey: 'commission_rating_quality_label',
            value: _qualityRating,
            onChanged: (value) => setState(() => _qualityRating = value),
          ),
          const SizedBox(height: 16),
          _buildDetailedRating(
            labelKey: 'commission_rating_communication_label',
            value: _communicationRating,
            onChanged: (value) => setState(() => _communicationRating = value),
          ),
          const SizedBox(height: 16),
          _buildDetailedRating(
            labelKey: 'commission_rating_timeliness_label',
            value: _timelinessRating,
            onChanged: (value) => setState(() => _timelinessRating = value),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(
            title: 'commission_rating_feedback_title'.tr(),
            subtitle: 'commission_rating_feedback_subtitle'.tr(),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'commission_rating_recommend_label'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ),
              Switch(
                value: _wouldRecommend,
                onChanged: (value) => setState(() => _wouldRecommend = value),
                thumbColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.7),
                ),
                trackColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? const Color(0xFF22D3EE)
                      : Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'commission_rating_tags_title'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'commission_rating_tags_subtitle'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: _availableTags.map(_buildTagPill).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(
            title: 'commission_rating_comment_title'.tr(),
            subtitle: 'commission_rating_comment_subtitle'.tr(),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _commentController,
            maxLines: 6,
            minLines: 5,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.5,
            ),
            cursorColor: const Color(0xFF22D3EE),
            decoration: GlassInputDecoration(
              hintText: 'commission_rating_comment_hint'.tr(),
            ),
          ),
          const SizedBox(height: 24),
          GradientCTAButton(
            text: 'commission_rating_submit_button'.tr(),
            onPressed: _isLoading ? null : _submitRating,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading({required String title, String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 0.4,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.78),
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailedRating({
    required String labelKey,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelKey.tr(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: _sliderTheme(context),
                child: Slider(
                  value: value,
                  min: 1,
                  max: 5,
                  divisions: 8,
                  label: value.toStringAsFixed(1),
                  onChanged: onChanged,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 56,
              height: 48,
              decoration: BoxDecoration(
                gradient: _primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  value.toStringAsFixed(1),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStarButton({
    required double value,
    required double currentRating,
    required ValueChanged<double> onChanged,
  }) {
    final isActive = currentRating >= value;
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        onPressed: () => onChanged(value),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        icon: Icon(
          isActive ? Icons.star_rounded : Icons.star_border_rounded,
          color: isActive
              ? const Color(0xFFFFC857)
              : Colors.white.withValues(alpha: 0.3),
          size: 28,
        ),
      ),
    );
  }

  Widget _buildTagPill(String tag) {
    final isSelected = _selectedTags.contains(tag);
    final labelKey = _tagLabelKeys[tag];
    final label = labelKey != null ? labelKey.tr() : tag;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedTags.remove(tag);
            } else {
              _selectedTags.add(tag);
            }
          });
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            gradient: isSelected ? _primaryGradient : null,
            color:
                isSelected ? null : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: 0.18),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  SliderThemeData _sliderTheme(BuildContext context) {
    final base = SliderTheme.of(context);
    return base.copyWith(
      trackHeight: 6,
      activeTrackColor: const Color(0xFF22D3EE),
      inactiveTrackColor: Colors.white.withValues(alpha: 0.18),
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
      thumbColor: Colors.white,
      overlayColor: const Color(0xFF22D3EE).withValues(alpha: 0.25),
      valueIndicatorColor: const Color(0xFF22D3EE),
      valueIndicatorTextStyle: GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }
}
