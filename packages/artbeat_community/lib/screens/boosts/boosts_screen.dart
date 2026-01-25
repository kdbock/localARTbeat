import 'package:artbeat_core/artbeat_core.dart' hide GradientBadge;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import '../../widgets/widgets.dart';
import 'boost_rules_screen.dart';

class ViewReceivedBoostsScreen extends StatefulWidget {
  const ViewReceivedBoostsScreen({super.key});

  @override
  State<ViewReceivedBoostsScreen> createState() =>
      _ViewReceivedBoostsScreenState();
}

class _ViewReceivedBoostsScreenState extends State<ViewReceivedBoostsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ArtistBoostService _boostService = ArtistBoostService();
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
  List<ArtistBoostModel> _boosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBoosts();
  }

  Future<void> _loadBoosts() async {
    setState(() => _isLoading = true);
    try {
      final querySnapshot = await _firestore
          .collection('boosts')
          .limit(20)
          .get();
      final boosts = querySnapshot.docs
          .map((doc) => ArtistBoostModel.fromFirestore(doc))
          .toList();
      setState(() {
        _boosts = boosts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'community_boosts.error'.tr(namedArgs: {'error': e.toString()}),
          ),
        ),
      );
    }
  }

  void _handleSendBoost(ArtistBoostModel boost) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('community_boosts.processing'.tr()),
        duration: const Duration(seconds: 1),
      ),
    );

    final success = await _boostService.purchaseQuickBoost(boost.recipientId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'community_boosts.success'.tr()
              : 'community_boosts.failure'.tr(),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openBoostRules() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const BoostRulesScreen()));
  }

  void _showBoostDetails(ArtistBoostModel boost) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BoostDetailSheet(
        boost: boost,
        formattedAmount: _formatCurrency(boost.amount),
        onSendBoost: () => _handleSendBoost(boost),
      ),
    );
  }

  double get _totalBoostValue =>
      _boosts.fold<double>(0, (sum, boost) => sum + boost.amount);

  int get _pendingBoostCount =>
      _boosts.where((boost) => boost.isPending).length;

  int get _uniqueSenderCount => _boosts
      .map((boost) => boost.senderId)
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
        title: 'community_boosts.title'.tr(),
        glassBackground: true,
        actions: [
          IconButton(
            tooltip: 'community_boosts.actions.refresh'.tr(),
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoading ? null : _loadBoosts,
          ),
          IconButton(
            tooltip: 'community_boosts.actions.rules'.tr(),
            icon: const Icon(Icons.rule_rounded, color: Colors.white),
            onPressed: _openBoostRules,
          ),
        ],
        subtitle: '',
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
      onRefresh: _loadBoosts,
      color: _BoostsPalette.accentTeal,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(child: _buildHeroCard()),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          if (_boosts.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyState())
          else ...[
            SliverToBoxAdapter(child: _buildSectionHeader()),
            SliverPadding(
              padding: const EdgeInsets.only(top: 12),
              sliver: _buildBoostGrid(),
            ),
          ],
          SliverToBoxAdapter(child: SizedBox(height: bottomInset + 24)),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    final totalValueLabel = _formatCurrency(_totalBoostValue);
    final totalBoosts = _boosts.length;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      showAccentGlow: true,
      accentColor: _BoostsPalette.accentTeal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientBadge(
            text: 'community_boosts.hero_badge'.tr(),
            icon: Icons.auto_awesome,
          ),
          const SizedBox(height: 16),
          Text(
            'community_boosts.hero_title'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _BoostsPalette.textPrimary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'community_boosts.hero_subtitle'.tr(
              namedArgs: {
                'count': totalBoosts.toString(),
                'senders': _uniqueSenderCount.toString(),
              },
            ),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: _BoostsPalette.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _BoostStatPill(
                label: 'community_boosts.stat.received'.tr(),
                value: totalBoosts.toString(),
              ),
              _BoostStatPill(
                label: 'community_boosts.stat.value'.tr(),
                value: totalValueLabel,
              ),
              _BoostStatPill(
                label: 'community_boosts.stat.pending'.tr(),
                value: _pendingBoostCount.toString(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GradientCTAButton(
            text: 'community_boosts.cta.rules'.tr(),
            icon: Icons.bolt,
            onPressed: _openBoostRules,
          ),
          const SizedBox(height: 12),
          HudButton.secondary(
            onPressed: _isLoading ? null : _loadBoosts,
            text: 'community_boosts.actions.refresh'.tr(),
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
            'community_boosts.list.title'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _BoostsPalette.textPrimary,
            ),
          ),
          Text(
            '${_boosts.length}'.padLeft(2, '0'),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _BoostsPalette.textSecondary,
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
          const Icon(Icons.bolt, color: _BoostsPalette.accentPink, size: 32),
          const SizedBox(height: 16),
          Text(
            'community_boosts.empty.title'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _BoostsPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'community_boosts.empty.subtitle'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: _BoostsPalette.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          GradientCTAButton(
            text: 'community_boosts.empty.cta'.tr(),
            icon: Icons.rule_folder,
            onPressed: _openBoostRules,
          ),
        ],
      ),
    );
  }

  SliverGrid _buildBoostGrid() {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final boost = _boosts[index];
        return Semantics(
          button: true,
          label: '${boost.boostType} ${_formatCurrency(boost.amount)}',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _showBoostDetails(boost),
            child: ArtistBoostCardWidget(
              boost: boost,
              onSendBoost: () => _handleSendBoost(boost),
            ),
          ),
        );
      }, childCount: _boosts.length),
    );
  }
}

class _BoostStatPill extends StatelessWidget {
  const _BoostStatPill({required this.label, required this.value});

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
              color: _BoostsPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _BoostsPalette.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _BoostDetailSheet extends StatelessWidget {
  const _BoostDetailSheet({
    required this.boost,
    required this.formattedAmount,
    required this.onSendBoost,
  });

  final ArtistBoostModel boost;
  final String formattedAmount;
  final VoidCallback onSendBoost;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _BoostsPalette.accentTeal.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: _BoostsPalette.accentTeal,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      boost.boostType,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: _BoostsPalette.textPrimary,
                      ),
                    ),
                    Text(
                      'community_boosts.detail.received_on'.tr(
                        args: [intl.DateFormat.yMMMd().format(boost.timestamp)],
                      ),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        color: _BoostsPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildInfoRow(
            'community_boosts.detail.from'.tr(),
            (boost.senderName ?? '').isEmpty ? 'Anonymous' : boost.senderName!,
          ),
          const SizedBox(height: 16),
          _buildInfoRow('community_boosts.detail.amount'.tr(), formattedAmount),
          const SizedBox(height: 16),
          _buildInfoRow(
            'community_boosts.detail.status'.tr(),
            boost.isPending ? 'Pending' : 'Completed',
            valueColor: boost.isPending ? Colors.orange : Colors.green,
          ),
          if (boost.message?.isNotEmpty ?? false) ...[
            const SizedBox(height: 24),
            Text(
              'community_boosts.detail.message'.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _BoostsPalette.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                boost.message ?? '',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  color: _BoostsPalette.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ],
          const SizedBox(height: 40),
          HudButton(
            onPressed: () {
              Navigator.pop(context);
              onSendBoost();
            },
            text: 'community_boosts.detail.send_back'.tr(),
            icon: Icons.bolt,
            height: 56,
          ),
          const SizedBox(height: 16),
          HudButton.secondary(
            onPressed: () => Navigator.pop(context),
            text: 'community_boosts.detail.close'.tr(),
            height: 56,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _BoostsPalette.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: valueColor ?? _BoostsPalette.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _BoostsPalette {
  static const Color accentTeal = Color(0xFF22D3EE);
  static const Color accentPink = Color(0xFFF472B6);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF94A3B8);
}
