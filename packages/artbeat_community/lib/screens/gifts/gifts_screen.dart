import 'package:artbeat_core/artbeat_core.dart' hide GradientBadge;
import 'package:artbeat_core/src/services/in_app_gift_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import '../../widgets/widgets.dart';
import 'gift_rules_screen.dart';

class ViewReceivedGiftsScreen extends StatefulWidget {
  const ViewReceivedGiftsScreen({super.key});

  @override
  State<ViewReceivedGiftsScreen> createState() =>
      _ViewReceivedGiftsScreenState();
}

class _ViewReceivedGiftsScreenState extends State<ViewReceivedGiftsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final InAppGiftService _giftService = InAppGiftService();
  final intl.NumberFormat _fullCurrency = intl.NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );
  final intl.NumberFormat _compactCurrency =
      intl.NumberFormat.compactSimpleCurrency(decimalDigits: 0);
  final intl.NumberFormat _zeroDecimalCurrency = intl.NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 0,
  );
  List<GiftModel> _gifts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGifts();
  }

  Future<void> _loadGifts() async {
    setState(() => _isLoading = true);
    try {
      final querySnapshot = await _firestore
          .collection('gifts')
          .limit(20)
          .get();
      final gifts = querySnapshot.docs
          .map((doc) => GiftModel.fromFirestore(doc))
          .toList();
      setState(() {
        _gifts = gifts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'community_gifts.error'.tr(namedArgs: {'error': e.toString()}),
          ),
        ),
      );
    }
  }

  void _handleSendGift(GiftModel gift) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('community_gifts.processing'.tr()),
        duration: const Duration(seconds: 1),
      ),
    );

    final success = await _giftService.purchaseQuickGift(gift.recipientId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'community_gifts.success'.tr()
              : 'community_gifts.failure'.tr(),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openGiftRules() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const GiftRulesScreen()));
  }

  void _showGiftDetails(GiftModel gift) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _GiftDetailSheet(
        gift: gift,
        formattedAmount: _formatCurrency(gift.amount),
        onSendGift: () => _handleSendGift(gift),
      ),
    );
  }

  double get _totalGiftValue =>
      _gifts.fold<double>(0, (sum, gift) => sum + gift.amount);

  int get _pendingGiftCount => _gifts.where((gift) => gift.isPending).length;

  int get _uniqueSenderCount => _gifts
      .map((gift) => gift.senderId)
      .where((id) => id.isNotEmpty)
      .toSet()
      .length;

  String _formatCurrency(double value) {
    if (value >= 1000) {
      return _compactCurrency.format(value);
    }
    if (value == value.roundToDouble()) {
      return _zeroDecimalCurrency.format(value);
    }
    return _fullCurrency.format(value);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: HudTopBar(
        title: 'community_gifts.title'.tr(),
        glassBackground: true,
        actions: [
          IconButton(
            tooltip: 'community_gifts.actions.refresh'.tr(),
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoading ? null : _loadGifts,
          ),
          IconButton(
            tooltip: 'community_gifts.actions.rules'.tr(),
            icon: const Icon(Icons.rule_rounded, color: Colors.white),
            onPressed: _openGiftRules,
          ),
        ], subtitle: '',
      ),
      body: WorldBackground(
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildBody(bottomInset),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(double bottomInset) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadGifts,
      color: _GiftsPalette.accentTeal,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(child: _buildHeroCard()),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          if (_gifts.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyState())
          else ...[
            SliverToBoxAdapter(child: _buildSectionHeader()),
            SliverPadding(
              padding: const EdgeInsets.only(top: 12),
              sliver: _buildGiftGrid(),
            ),
          ],
          SliverToBoxAdapter(child: SizedBox(height: bottomInset + 24)),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    final totalValueLabel = _formatCurrency(_totalGiftValue);
    final totalGifts = _gifts.length;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      showAccentGlow: true,
      accentColor: _GiftsPalette.accentTeal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientBadge(
            text: 'community_gifts.hero_badge'.tr(),
            icon: Icons.auto_awesome,
          ),
          const SizedBox(height: 16),
          Text(
            'community_gifts.hero_title'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _GiftsPalette.textPrimary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'community_gifts.hero_subtitle'.tr(
              namedArgs: {
                'count': totalGifts.toString(),
                'senders': _uniqueSenderCount.toString(),
              },
            ),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: _GiftsPalette.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _GiftStatPill(
                label: 'community_gifts.stat.received'.tr(),
                value: totalGifts.toString(),
              ),
              _GiftStatPill(
                label: 'community_gifts.stat.value'.tr(),
                value: totalValueLabel,
              ),
              _GiftStatPill(
                label: 'community_gifts.stat.pending'.tr(),
                value: _pendingGiftCount.toString(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GradientCTAButton(
            text: 'community_gifts.cta.rules'.tr(),
            icon: Icons.card_giftcard,
            onPressed: _openGiftRules,
          ),
          const SizedBox(height: 12),
          HudButton.secondary(
            onPressed: _isLoading ? null : _loadGifts,
            text: 'community_gifts.actions.refresh'.tr(),
            icon: Icons.refresh,
            height: 48,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'community_gifts.list.title'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _GiftsPalette.textPrimary,
            ),
          ),
          Text(
            '${_gifts.length}'.padLeft(2, '0'),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _GiftsPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.card_giftcard,
            color: _GiftsPalette.accentPink,
            size: 32,
          ),
          const SizedBox(height: 16),
          Text(
            'community_gifts.empty.title'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _GiftsPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'community_gifts.empty.subtitle'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: _GiftsPalette.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          GradientCTAButton(
            text: 'community_gifts.empty.cta'.tr(),
            icon: Icons.rule_folder,
            onPressed: _openGiftRules,
          ),
        ],
      ),
    );
  }

  SliverGrid _buildGiftGrid() {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final gift = _gifts[index];
        return Semantics(
          button: true,
          label: '${gift.giftType} ${_formatCurrency(gift.amount)}',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _showGiftDetails(gift),
            child: GiftCardWidget(
              gift: gift,
              onSendGift: () => _handleSendGift(gift),
            ),
          ),
        );
      }, childCount: _gifts.length),
    );
  }
}

class _GiftStatPill extends StatelessWidget {
  const _GiftStatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: _GiftsPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: _GiftsPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _GiftsPalette {
  static const Color textPrimary = Color(0xFFF8FAFF);
  static const Color textSecondary = Color(0xFFBBD1FF);
  static const Color accentTeal = Color(0xFF22D3EE);
  static const Color accentPink = Color(0xFFFF3D8D);
}

class _GiftDetailSheet extends StatelessWidget {
  const _GiftDetailSheet({
    required this.gift,
    required this.formattedAmount,
    required this.onSendGift,
  });

  final GiftModel gift;
  final String formattedAmount;
  final VoidCallback onSendGift;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final sentOn = intl.DateFormat(
      'MMM d, yyyy • h:mm a',
    ).format(gift.createdAt.toDate());

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [
                        _GiftsPalette.accentTeal,
                        _GiftsPalette.accentPink,
                      ],
                    ),
                  ),
                  child: const Icon(Icons.card_giftcard, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gift.giftType,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _GiftsPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedAmount,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _GiftsPalette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _DetailRow(
              label: 'community_gifts.detail.sent_on'.tr(
                namedArgs: {'date': sentOn},
              ),
              icon: Icons.schedule,
            ),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'community_gifts.detail.status'.tr(
                namedArgs: {'status': gift.status},
              ),
              icon: Icons.verified_user,
            ),
            if (gift.message != null && gift.message!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'community_gifts.detail.message'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _GiftsPalette.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                gift.message!,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  color: _GiftsPalette.textPrimary,
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                'community_gifts.detail.no_message'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _GiftsPalette.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 24),
            GradientCTAButton(
              text: 'community_gifts.detail.cta'.tr(),
              icon: Icons.card_giftcard,
              onPressed: () {
                Navigator.of(context).maybePop();
                onSendGift();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _GiftsPalette.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
