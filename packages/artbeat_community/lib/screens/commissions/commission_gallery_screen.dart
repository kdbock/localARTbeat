import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import 'package:artbeat_core/artbeat_core.dart';

import '../../models/direct_commission_model.dart';
import '../../services/direct_commission_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_badge.dart';
import '../../widgets/hud_button.dart';
import '../../widgets/hud_top_bar.dart';
import '../../widgets/world_background.dart';
import 'commission_detail_screen.dart';

class _GalleryPalette {
  static const Color textPrimary = Color(0xF2FFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color textTertiary = Color(0x73FFFFFF);
  static const Color accentPurple = Color(0xFF7C4DFF);
  static const Color accentTeal = Color(0xFF22D3EE);
}

class CommissionGalleryScreen extends StatefulWidget {
  const CommissionGalleryScreen({super.key, this.artistId});

  final String? artistId;

  @override
  State<CommissionGalleryScreen> createState() =>
      _CommissionGalleryScreenState();
}

class _CommissionGalleryScreenState extends State<CommissionGalleryScreen> {
  static const List<CommissionStatus> _galleryStatuses = [
    CommissionStatus.completed,
    CommissionStatus.delivered,
  ];

  final DirectCommissionService _commissionService = DirectCommissionService();
  final intl.NumberFormat _compactCurrencyFormatter =
      intl.NumberFormat.compactCurrency(symbol: '\$');
  final intl.NumberFormat _currencyFormatter = intl.NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 0,
  );
  final intl.DateFormat _dateFormatter = intl.DateFormat('MMM d, yyyy');

  final Map<CommissionStatus, String> _statusLabelKeys = {
    CommissionStatus.pending: 'commission_status_pending',
    CommissionStatus.quoted: 'commission_status_quoted',
    CommissionStatus.accepted: 'commission_status_accepted',
    CommissionStatus.inProgress: 'commission_status_in_progress',
    CommissionStatus.revision: 'commission_status_revision',
    CommissionStatus.completed: 'commission_status_completed',
    CommissionStatus.delivered: 'commission_status_delivered',
    CommissionStatus.cancelled: 'commission_status_cancelled',
    CommissionStatus.disputed: 'commission_status_disputed',
  };

  final Map<CommissionStatus, Color> _statusColors = {
    CommissionStatus.pending: const Color(0xFFFFC857),
    CommissionStatus.quoted: const Color(0xFF22D3EE),
    CommissionStatus.accepted: const Color(0xFF34D399),
    CommissionStatus.inProgress: const Color(0xFF7C4DFF),
    CommissionStatus.revision: const Color(0xFFFFA63D),
    CommissionStatus.completed: const Color(0xFF34D399),
    CommissionStatus.delivered: const Color(0xFF0FB9B1),
    CommissionStatus.cancelled: const Color(0xFFFF3D8D),
    CommissionStatus.disputed: const Color(0xFFFF5F6D),
  };

  final Map<CommissionStatus, IconData> _statusIcons = {
    CommissionStatus.pending: Icons.schedule,
    CommissionStatus.quoted: Icons.request_quote,
    CommissionStatus.accepted: Icons.handshake,
    CommissionStatus.inProgress: Icons.brush,
    CommissionStatus.revision: Icons.edit,
    CommissionStatus.completed: Icons.check_circle,
    CommissionStatus.delivered: Icons.local_shipping,
    CommissionStatus.cancelled: Icons.cancel,
    CommissionStatus.disputed: Icons.warning,
  };

  final Map<CommissionType, String> _typeLabelKeys = {
    CommissionType.digital: 'commission_type_digital',
    CommissionType.physical: 'commission_type_physical',
    CommissionType.portrait: 'commission_type_portrait',
    CommissionType.commercial: 'commission_type_commercial',
  };

  List<DirectCommissionModel> _commissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCommissions();
  }

  Future<void> _loadCommissions() async {
    final artistId = widget.artistId;
    if (artistId == null || artistId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _commissions = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final commissions = await _commissionService.getCommissionsByUser(
        artistId,
      );
      final filtered = commissions
          .where((c) => _galleryStatuses.contains(c.status))
          .toList();
      if (!mounted) return;
      setState(() {
        _commissions = _sortCommissions(filtered);
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load commissions: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'community_commission_gallery_error_loading'.tr(
              namedArgs: {'error': e.toString()},
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 1100 ? 3 : 2;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: HudTopBar(
        title: 'community_commission_gallery_app_bar'.tr(),
        glassBackground: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'community_commission_gallery_refresh_button'.tr(),
            onPressed: _isLoading ? null : _loadCommissions,
          ),
        ],
      ),
      body: WorldBackground(
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: _buildBody(crossAxisCount),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(int crossAxisCount) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (widget.artistId == null || widget.artistId!.isEmpty) {
      return _buildMissingArtistState();
    }

    if (_commissions.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: _GalleryPalette.accentPurple,
      onRefresh: _loadCommissions,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeroSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(child: _buildGalleryHeader()),
          SliverPadding(
            padding: const EdgeInsets.only(top: 12, bottom: 32),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate((context, index) {
                final commission = _commissions[index];
                return _buildCommissionCard(commission);
              }, childCount: _commissions.length),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.78,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: _GalleryPalette.accentTeal),
    );
  }

  Widget _buildMissingArtistState() {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_off, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              'community_commission_gallery_no_artist_title'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _GalleryPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'community_commission_gallery_no_artist_subtitle'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _GalleryPalette.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            HudButton.secondary(
              onPressed: () => Navigator.of(context).pop(),
              text: 'community_commission_gallery_empty_cta'.tr(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              'community_commission_gallery_empty_title'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _GalleryPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'community_commission_gallery_empty_subtitle'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _GalleryPalette.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            HudButton.primary(
              onPressed: _loadCommissions,
              text: 'community_commission_gallery_refresh_button'.tr(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    final totalPieces = _commissions.length;
    final totalValue = _commissions.fold<double>(
      0,
      (sum, commission) => sum + commission.totalPrice,
    );
    final averageValue = totalPieces == 0 ? 0 : totalValue / totalPieces;
    final lastDelivery = _commissions
        .map((c) => c.completedAt ?? c.acceptedAt ?? c.requestedAt)
        .whereType<DateTime>()
        .fold<DateTime?>(
          null,
          (latest, date) =>
              latest == null || date.isAfter(latest) ? date : latest,
        );

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'community_commission_gallery_hero_title'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _GalleryPalette.textPrimary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'community_commission_gallery_hero_subtitle'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _GalleryPalette.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(
                  'community_commission_gallery_stats_total_label'.tr(),
                  totalPieces.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(
                  'community_commission_gallery_stats_value_label'.tr(),
                  _compactCurrencyFormatter.format(totalValue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(
                  'community_commission_gallery_stats_avg_label'.tr(),
                  _currencyFormatter.format(averageValue),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(
                  'community_commission_gallery_stats_last_label'.tr(),
                  lastDelivery != null
                      ? _dateFormatter.format(lastDelivery)
                      : 'community_commission_gallery_stats_last_none'.tr(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          HudButton.primary(
            onPressed: _isLoading ? null : _loadCommissions,
            text: 'community_commission_gallery_refresh_button'.tr(),
            isLoading: _isLoading,
            icon: Icons.refresh,
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      borderRadius: 24,
      glassOpacity: 0.04,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: _GalleryPalette.textTertiary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'community_commission_gallery_gallery_title'.tr(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: _GalleryPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'community_commission_gallery_gallery_subtitle'.tr(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _GalleryPalette.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCommissionCard(DirectCommissionModel commission) {
    final statusColor =
        _statusColors[commission.status] ?? _GalleryPalette.accentTeal;
    final statusLabel =
        _statusLabelKeys[commission.status]?.tr() ??
        commission.status.displayName;
    final typeLabel =
        _typeLabelKeys[commission.type]?.tr() ?? commission.type.displayName;
    final priceLabel = commission.totalPrice > 0
        ? _currencyFormatter.format(commission.totalPrice)
        : 'community_commission_gallery_card_value_unknown'.tr();
    final DateTime? deliveredAt =
        commission.completedAt ?? commission.acceptedAt;
    final deliveredLabel = deliveredAt != null
        ? _dateFormatter.format(deliveredAt)
        : 'community_commission_gallery_stats_last_none'.tr();

    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 28,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => _openCommissionDetail(commission),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPreviewHeader(
                commission,
                statusLabel,
                statusColor,
                typeLabel,
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      commission.title.isNotEmpty
                          ? commission.title
                          : 'community_commission_gallery_untitled'.tr(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _GalleryPalette.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'community_commission_gallery_card_client_label'.tr(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _GalleryPalette.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      commission.clientName.isNotEmpty
                          ? commission.clientName
                          : 'community_commission_gallery_unknown_client'.tr(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _GalleryPalette.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'community_commission_gallery_card_value_label'
                                  .tr(),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _GalleryPalette.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              priceLabel,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'community_commission_gallery_card_delivered_label'
                                  .tr(),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _GalleryPalette.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  deliveredLabel,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _GalleryPalette.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewHeader(
    DirectCommissionModel commission,
    String statusLabel,
    Color statusColor,
    String typeLabel,
  ) {
    final previewUrl = _resolvePreviewUrl(commission);

    return SizedBox(
      height: 190,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (previewUrl != null)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                child: Image.network(
                  previewUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return _buildPreviewFallback();
                  },
                  errorBuilder: (_, __, ___) => _buildPreviewFallback(),
                ),
              ),
            )
          else
            _buildPreviewFallback(),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black12, Color(0xCC07060F)],
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: GradientBadge(
              text: statusLabel,
              icon: _statusIcons[commission.status],
              gradient: LinearGradient(
                colors: [
                  statusColor.withValues(alpha: 0.9),
                  statusColor.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.palette, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    typeLabel,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

  Widget _buildPreviewFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A1330), Color(0xFF071C18)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.brush, color: Colors.white54, size: 36),
      ),
    );
  }

  List<DirectCommissionModel> _sortCommissions(
    List<DirectCommissionModel> source,
  ) {
    final sorted = [...source];
    sorted.sort((a, b) {
      final aDate = a.completedAt ?? a.acceptedAt ?? a.requestedAt;
      final bDate = b.completedAt ?? b.acceptedAt ?? b.requestedAt;
      return bDate.compareTo(aDate);
    });
    return sorted;
  }

  String? _resolvePreviewUrl(DirectCommissionModel commission) {
    final files = commission.files;
    if (files.isEmpty) return null;

    final priorities = ['final', 'progress', 'reference'];
    for (final type in priorities) {
      for (final file in files) {
        if (file.type == type && file.url.isNotEmpty) {
          return file.url;
        }
      }
    }

    final fallback = files.firstWhere(
      (file) => file.url.isNotEmpty,
      orElse: () => files.first,
    );
    return fallback.url.isNotEmpty ? fallback.url : null;
  }

  void _openCommissionDetail(DirectCommissionModel commission) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CommissionDetailScreen(commission: commission),
      ),
    );
  }
}
