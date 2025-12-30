import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import 'package:artbeat_artist/artbeat_artist.dart';

import '../../models/direct_commission_model.dart';
import '../../services/direct_commission_service.dart';
import '../../widgets/widgets.dart';
import 'artist_commission_settings_screen.dart';
import 'commission_analytics_dashboard.dart';
import 'commission_detail_screen.dart';
import 'commission_dispute_screen.dart';
import 'commission_gallery_screen.dart';
import 'commission_progress_tracker.dart';
import 'commission_rating_screen.dart';
import 'commission_setup_wizard_screen.dart';
import 'commission_templates_browser.dart';
import 'direct_commissions_screen.dart';

class CommissionHubScreen extends StatefulWidget {
  const CommissionHubScreen({super.key});

  @override
  State<CommissionHubScreen> createState() => _CommissionHubScreenState();
}

class _CommissionHubScreenState extends State<CommissionHubScreen> {
  final DirectCommissionService _commissionService = DirectCommissionService();

  final intl.DateFormat _dateFormat = intl.DateFormat('MMM d, yyyy');
  final intl.NumberFormat _compactCurrencyFormatter =
      intl.NumberFormat.compactCurrency(symbol: '\$');
  final intl.NumberFormat _currencyFormatter =
      intl.NumberFormat.currency(symbol: '\$');

  bool _isLoading = true;
  bool _isArtist = false;
  ArtistCommissionSettings? _artistSettings;
  List<DirectCommissionModel> _recentCommissions = [];
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _isArtist = false;
          _artistSettings = null;
          _recentCommissions = [];
          _stats = {};
          _isLoading = false;
        });
        return;
      }

      ArtistCommissionSettings? artistSettings;
      var isArtist = false;
      try {
        artistSettings = await _commissionService.getArtistSettings(user.uid);
        isArtist = artistSettings != null;
      } catch (_) {
        isArtist = false;
        artistSettings = null;
      }

      final commissions = await _commissionService.getCommissionsByUser(user.uid);
      final recentCommissions = commissions.take(5).toList();

      final activeCount = commissions
          .where(
            (c) => [
              CommissionStatus.pending,
              CommissionStatus.quoted,
              CommissionStatus.accepted,
              CommissionStatus.inProgress,
            ].contains(c.status),
          )
          .length;

      final completedCount = commissions
          .where(
            (c) => [
              CommissionStatus.completed,
              CommissionStatus.delivered,
            ].contains(c.status),
          )
          .length;

      final totalEarnings = commissions
          .where(
            (c) =>
                c.artistId == user.uid &&
                [CommissionStatus.completed, CommissionStatus.delivered]
                    .contains(c.status),
          )
          .fold<double>(0, (sum, c) => sum + c.totalPrice);

      if (!mounted) return;
      setState(() {
        _isArtist = isArtist;
        _artistSettings = artistSettings;
        _recentCommissions = recentCommissions;
        _stats = {
          'active': activeCount,
          'completed': completedCount,
          'total': commissions.length,
          'earnings': totalEarnings.round(),
        };
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'commission_hub_load_error_with_reason'.tr(
              namedArgs: {'error': e.toString()},
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: HudTopBar(
        title: 'commission_hub_app_bar'.tr(),
        glassBackground: true,
        leading: const SizedBox.shrink(),
        actions: [
          IconButton(
            tooltip: 'commission_hub_refresh_tooltip'.tr(),
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoading ? null : _loadData,
          ),
        ],
      ),
      body: WorldBackground(
        child: SafeArea(
          bottom: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF7C4DFF),
                    ),
                  )
                : RefreshIndicator(
                    color: const Color(0xFF7C4DFF),
                    onRefresh: _loadData,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding + 32),
                      children: [
                        _buildHeroCard(),
                        const SizedBox(height: 16),
                        _buildStatsSection(),
                        const SizedBox(height: 16),
                        _buildQuickActionsSection(),
                        if (_isArtist) ...[
                          const SizedBox(height: 16),
                          _buildArtistSection(),
                        ],
                        const SizedBox(height: 16),
                        _buildRecentCommissionsSection(),
                        if ((_stats['total'] ?? 0) == 0) ...[
                          const SizedBox(height: 16),
                          _buildGettingStartedCard(),
                        ],
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    final badge = _isArtist
        ? 'commission_hub_hero_badge_artist'.tr()
        : 'commission_hub_hero_badge_patron'.tr();
    final subtitle = _isArtist
        ? 'commission_hub_hero_artist_subtitle'.tr()
        : 'commission_hub_hero_patron_subtitle'.tr();

    return GlassCard(
      padding: const EdgeInsets.all(24),
      showAccentGlow: true,
      accentColor: _isArtist
          ? _CommissionPalette.tealAccent
          : _CommissionPalette.purpleAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: Text(
              badge,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: _CommissionPalette.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'commission_hub_hero_title'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _CommissionPalette.textPrimary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _CommissionPalette.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GradientCTAButton(
                  text: (_isArtist
                          ? 'commission_hub_hero_cta_artist_primary'
                          : 'commission_hub_hero_cta_patron_primary')
                      .tr(),
                  icon: _isArtist ? Icons.view_timeline : Icons.explore,
                  onPressed: _isArtist ? _openCommissions : _browseArtists,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: HudButton.secondary(
                  onPressed: _isArtist
                      ? () => _openSetupWizard(SetupMode.editing)
                      : _setupArtistProfile,
                  text: (_isArtist
                          ? 'commission_hub_hero_cta_artist_secondary'
                          : 'commission_hub_hero_cta_patron_secondary')
                      .tr(),
                  icon: _isArtist ? Icons.auto_fix_high : Icons.brush,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final stats = <_StatEntry>[
      _StatEntry(
        label: 'commission_hub_stats_active'.tr(),
        value: (_stats['active'] ?? 0).toString(),
        icon: Icons.pending_actions,
        color: _CommissionPalette.yellowAccent,
      ),
      _StatEntry(
        label: 'commission_hub_stats_completed'.tr(),
        value: (_stats['completed'] ?? 0).toString(),
        icon: Icons.check_circle,
        color: _CommissionPalette.greenAccent,
      ),
      _StatEntry(
        label: 'commission_hub_stats_total'.tr(),
        value: (_stats['total'] ?? 0).toString(),
        icon: Icons.layers,
        color: _CommissionPalette.purpleAccent,
      ),
    ];

    if (_isArtist) {
      stats.add(
        _StatEntry(
          label: 'commission_hub_stats_earnings'.tr(),
          value: _compactCurrencyFormatter.format(_stats['earnings'] ?? 0),
          icon: Icons.attach_money,
          color: _CommissionPalette.tealAccent,
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'commission_hub_stats_title'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _CommissionPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumnWidth = (constraints.maxWidth - 12) / 2;
              final singleColumn = constraints.maxWidth < 360;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: stats.map((entry) {
                  final width = singleColumn ? constraints.maxWidth : twoColumnWidth;
                  return SizedBox(
                    width: width,
                    child: _StatTile(entry: entry),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    final actions = <_QuickActionData>[
      _QuickActionData(
        label: 'commission_hub_actions_view_all'.tr(),
        icon: Icons.list_alt,
        onTap: _openCommissions,
      ),
      _QuickActionData(
        label: 'commission_hub_actions_browse_artists'.tr(),
        icon: Icons.biotech,
        onTap: _browseArtists,
      ),
    ];

    if (_isArtist) {
      actions.addAll([
        _QuickActionData(
          label: 'commission_hub_actions_settings'.tr(),
          icon: Icons.settings,
          onTap: _openArtistSettings,
        ),
        _QuickActionData(
          label: 'commission_hub_actions_analytics'.tr(),
          icon: Icons.analytics,
          onTap: _viewAnalytics,
        ),
        _QuickActionData(
          label: 'commission_hub_actions_templates'.tr(),
          icon: Icons.auto_awesome,
          onTap: _viewTemplates,
        ),
        _QuickActionData(
          label: 'commission_hub_actions_gallery'.tr(),
          icon: Icons.image,
          onTap: _viewGallery,
        ),
      ]);
    }

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'commission_hub_actions_title'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _CommissionPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumnWidth = (constraints.maxWidth - 12) / 2;
              final singleColumn = constraints.maxWidth < 420;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: actions.map((action) {
                  final width = singleColumn ? constraints.maxWidth : twoColumnWidth;
                  return _QuickActionButton(
                    width: width,
                    label: action.label,
                    icon: action.icon,
                    onTap: action.onTap,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildArtistSection() {
    final accepting = _artistSettings?.acceptingCommissions ?? false;
    final basePrice = _artistSettings?.basePrice ?? 0;
    final availableTypes = _artistSettings?.availableTypes
            .map((type) => type.displayName)
            .join(', ') ??
        '';

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'commission_hub_artist_section_title'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _CommissionPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'commission_hub_artist_section_subtitle'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _CommissionPalette.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (accepting
                            ? _CommissionPalette.greenAccent
                            : _CommissionPalette.yellowAccent)
                        .withValues(alpha: 0.18),
                  ),
                  child: Icon(
                    accepting ? Icons.check_circle : Icons.pause_circle,
                    color: accepting
                        ? _CommissionPalette.greenAccent
                        : _CommissionPalette.yellowAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        accepting
                            ? 'commission_hub_artist_status_accepting'.tr()
                            : 'commission_hub_artist_status_paused'.tr(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _CommissionPalette.textPrimary,
                        ),
                      ),
                      if (_artistSettings != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'commission_hub_artist_base_price'.tr(
                            namedArgs: {
                              'price': _currencyFormatter.format(basePrice),
                            },
                          ),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _CommissionPalette.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_artistSettings != null) ...[
            Text(
              'commission_hub_artist_types'.tr(
                namedArgs: {'types': availableTypes},
              ),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _CommissionPalette.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                HudButton.secondary(
                  onPressed: () => _openSetupWizard(SetupMode.editing),
                  text: 'commission_hub_artist_cta_edit_wizard'.tr(),
                  icon: Icons.auto_fix_high,
                  width: 200,
                ),
                HudButton.secondary(
                  onPressed: _openArtistSettings,
                  text: 'commission_hub_artist_cta_open_settings'.tr(),
                  icon: Icons.settings,
                  width: 200,
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'commission_hub_artist_no_settings_title'.tr(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _CommissionPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'commission_hub_artist_no_settings_body'.tr(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _CommissionPalette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                GradientCTAButton(
                  text: 'commission_hub_artist_cta_quick_setup'.tr(),
                  icon: Icons.auto_awesome,
                  onPressed: () => _openSetupWizard(SetupMode.firstTime),
                ),
                HudButton.secondary(
                  onPressed: _openArtistSettings,
                  text: 'commission_hub_artist_cta_detailed_settings'.tr(),
                  icon: Icons.settings,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentCommissionsSection() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'commission_hub_recent_title'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _CommissionPalette.textPrimary,
                ),
              ),
              const Spacer(),
              if (_recentCommissions.isNotEmpty)
                TextButton(
                  onPressed: _openCommissions,
                  child: Text(
                    'commission_hub_recent_cta_view_all'.tr(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _CommissionPalette.tealAccent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentCommissions.isEmpty)
            _buildEmptyState()
          else
            Column(
              children: _recentCommissions
                  .map((commission) => _buildCommissionTile(commission))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCommissionTile(DirectCommissionModel commission) {
    final statusColor = _getStatusColor(commission.status);
    final statusLabel = _getStatusLabel(commission.status);
    final isArtistView =
        commission.artistId == FirebaseAuth.instance.currentUser?.uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => _openCommissionDetail(commission),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor.withValues(alpha: 0.12),
                      ),
                      child: Icon(
                        _getStatusIcon(commission.status),
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            commission.title,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _CommissionPalette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isArtistView
                                ? 'commission_hub_recent_meta_client'
                                    .tr(namedArgs: {'name': commission.clientName})
                                : 'commission_hub_recent_meta_artist'
                                    .tr(namedArgs: {'name': commission.artistName}),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _CommissionPalette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (commission.totalPrice > 0)
                      Text(
                        _currencyFormatter.format(commission.totalPrice),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _CommissionPalette.greenAccent,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        statusLabel,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'commission_hub_recent_meta_requested'.tr(
                        namedArgs: {
                          'date': _dateFormat.format(commission.requestedAt),
                        },
                      ),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _CommissionPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildCommissionActions(commission),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommissionActions(DirectCommissionModel commission) {
    final actions = <Widget>[];

    if ([
      CommissionStatus.accepted,
      CommissionStatus.inProgress,
      CommissionStatus.revision,
    ].contains(commission.status)) {
      actions.add(
        HudButton.secondary(
          onPressed: () => _viewProgress(commission),
          text: 'commission_hub_commission_actions_progress'.tr(),
          icon: Icons.timeline,
          width: 180,
        ),
      );
    }

    if ([
          CommissionStatus.completed,
          CommissionStatus.delivered,
        ].contains(commission.status) &&
        FirebaseAuth.instance.currentUser != null) {
      actions.add(
        HudButton.secondary(
          onPressed: () => _rateCommission(commission),
          text: 'commission_hub_commission_actions_rate'.tr(),
          icon: Icons.star_rate,
          width: 180,
        ),
      );
    }

    if ([
          CommissionStatus.inProgress,
          CommissionStatus.revision,
        ].contains(commission.status) &&
        FirebaseAuth.instance.currentUser != null) {
      actions.add(
        HudButton.secondary(
          onPressed: () => _reportDispute(commission),
          text: 'commission_hub_commission_actions_report'.tr(),
          icon: Icons.flag,
          width: 180,
        ),
      );
    }

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: actions,
    );
  }

  Widget _buildGettingStartedCard() {
    final description = _isArtist
        ? 'commission_hub_getting_started_artist'.tr()
        : 'commission_hub_getting_started_patron'.tr();
    final ctaLabel = _isArtist
        ? 'commission_hub_getting_started_cta_artist'.tr()
        : 'commission_hub_getting_started_cta_patron'.tr();
    final ctaAction = _isArtist ? _openArtistSettings : _browseArtists;
    final ctaIcon = _isArtist ? Icons.settings : Icons.search;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.auto_awesome, size: 48, color: _CommissionPalette.purpleAccent),
          const SizedBox(height: 16),
          Text(
            'commission_hub_getting_started_title'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _CommissionPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _CommissionPalette.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          GradientCTAButton(
            text: ctaLabel,
            icon: ctaIcon,
            onPressed: ctaAction,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          const Icon(Icons.auto_fix_off, size: 40, color: _CommissionPalette.textTertiary),
          const SizedBox(height: 12),
          Text(
            'commission_hub_recent_empty_title'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _CommissionPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'commission_hub_recent_empty_subtitle'.tr(),
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _CommissionPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _openCommissions() {
    Navigator.push(
      context,
      MaterialPageRoute<DirectCommissionsScreen>(
        builder: (context) => const DirectCommissionsScreen(),
      ),
    );
  }

  void _setupArtistProfile() {
    _openSetupWizard(SetupMode.firstTime);
  }

  Future<void> _openSetupWizard(SetupMode mode) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => CommissionSetupWizardScreen(
          mode: mode,
          initialSettings: mode == SetupMode.editing ? _artistSettings : null,
        ),
      ),
    );
    if (mounted) {
      await _loadData();
    }
  }

  Future<void> _openArtistSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const ArtistCommissionSettingsScreen(),
      ),
    );
    if (mounted) {
      await _loadData();
    }
  }

  void _browseArtists() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const ArtistBrowseScreen(mode: 'commissions'),
      ),
    );
  }

  void _viewAnalytics() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => CommissionAnalyticsDashboard(artistId: user.uid),
      ),
    );
  }

  void _viewTemplates() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const CommissionTemplatesBrowser(),
      ),
    );
  }

  void _viewGallery() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => CommissionGalleryScreen(artistId: user.uid),
      ),
    );
  }

  void _openCommissionDetail(DirectCommissionModel commission) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => CommissionDetailScreen(commission: commission),
      ),
    );
  }

  void _viewProgress(DirectCommissionModel commission) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => CommissionProgressTracker(commission: commission),
      ),
    );
  }

  void _rateCommission(DirectCommissionModel commission) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => CommissionRatingScreen(commission: commission),
      ),
    );
  }

  void _reportDispute(DirectCommissionModel commission) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final otherPartyId = commission.artistId == currentUser.uid
        ? commission.clientId
        : commission.artistId;
    final otherPartyName = commission.artistId == currentUser.uid
        ? commission.clientName
        : commission.artistName;

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => CommissionDisputeScreen(
          commissionId: commission.id,
          otherPartyId: otherPartyId,
          otherPartyName: otherPartyName,
        ),
      ),
    );
  }

  String _getStatusLabel(CommissionStatus status) {
    switch (status) {
      case CommissionStatus.pending:
        return 'commission_hub_status_pending'.tr();
      case CommissionStatus.quoted:
        return 'commission_hub_status_quoted'.tr();
      case CommissionStatus.accepted:
        return 'commission_hub_status_accepted'.tr();
      case CommissionStatus.inProgress:
        return 'commission_hub_status_in_progress'.tr();
      case CommissionStatus.revision:
        return 'commission_hub_status_revision'.tr();
      case CommissionStatus.completed:
        return 'commission_hub_status_completed'.tr();
      case CommissionStatus.delivered:
        return 'commission_hub_status_delivered'.tr();
      case CommissionStatus.cancelled:
        return 'commission_hub_status_cancelled'.tr();
      case CommissionStatus.disputed:
        return 'commission_hub_status_disputed'.tr();
    }
  }

  Color _getStatusColor(CommissionStatus status) {
    switch (status) {
      case CommissionStatus.pending:
        return _CommissionPalette.yellowAccent;
      case CommissionStatus.quoted:
        return _CommissionPalette.tealAccent;
      case CommissionStatus.accepted:
        return _CommissionPalette.greenAccent;
      case CommissionStatus.inProgress:
        return _CommissionPalette.purpleAccent;
      case CommissionStatus.revision:
        return _CommissionPalette.yellowAccent;
      case CommissionStatus.completed:
        return _CommissionPalette.greenAccent;
      case CommissionStatus.delivered:
        return _CommissionPalette.greenAccent;
      case CommissionStatus.cancelled:
        return _CommissionPalette.pinkAccent;
      case CommissionStatus.disputed:
        return _CommissionPalette.pinkAccent;
    }
  }

  IconData _getStatusIcon(CommissionStatus status) {
    switch (status) {
      case CommissionStatus.pending:
        return Icons.schedule;
      case CommissionStatus.quoted:
        return Icons.request_quote;
      case CommissionStatus.accepted:
        return Icons.handshake;
      case CommissionStatus.inProgress:
        return Icons.brush;
      case CommissionStatus.revision:
        return Icons.edit;
      case CommissionStatus.completed:
        return Icons.check_circle;
      case CommissionStatus.delivered:
        return Icons.local_shipping;
      case CommissionStatus.cancelled:
        return Icons.cancel;
      case CommissionStatus.disputed:
        return Icons.warning;
    }
  }
}

class _StatEntry {
  const _StatEntry({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.entry});

  final _StatEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        color: Colors.white.withValues(alpha: 0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: entry.color.withValues(alpha: 0.18),
            ),
            child: Icon(entry.icon, color: entry.color),
          ),
          const SizedBox(height: 12),
          Text(
            entry.value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: _CommissionPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entry.label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _CommissionPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionData {
  const _QuickActionData({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.width,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final double width;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF7C4DFF),
                        Color(0xFF22D3EE),
                        Color(0xFF34D399),
                      ],
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _CommissionPalette.textPrimary,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward, color: Colors.white54, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CommissionPalette {
  static const Color textPrimary = Color(0xF2FFFFFF);
  static const Color textSecondary = Color(0xCCFFFFFF);
  static const Color textTertiary = Color(0x80FFFFFF);
  static const Color purpleAccent = Color(0xFF7C4DFF);
  static const Color tealAccent = Color(0xFF22D3EE);
  static const Color greenAccent = Color(0xFF34D399);
  static const Color pinkAccent = Color(0xFFFF3D8D);
  static const Color yellowAccent = Color(0xFFFFC857);
}
