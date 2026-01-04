import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import 'package:artbeat_core/artbeat_core.dart' as core hide NumberFormat;
import 'package:artbeat_core/shared_widgets.dart';

import '../../models/commission_analytics_model.dart'
    show ArtistCommissionAnalytics;
import '../../services/commission_analytics_service.dart';

class CommissionAnalyticsDashboard extends StatefulWidget {
  final String artistId;

  const CommissionAnalyticsDashboard({super.key, required this.artistId});

  @override
  State<CommissionAnalyticsDashboard> createState() =>
      _CommissionAnalyticsDashboardState();
}

class _CommissionAnalyticsDashboardState
    extends State<CommissionAnalyticsDashboard> {
  final CommissionAnalyticsService _analyticsService =
      CommissionAnalyticsService();

  ArtistCommissionAnalytics? _analytics;
  bool _isLoading = true;

  final intl.NumberFormat _currencyFormatter = intl.NumberFormat.currency(
    symbol: '\$',
  );

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final analytics = await _analyticsService.getArtistAnalytics(
        widget.artistId,
      );
      if (!mounted) return;
      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      core.AppLogger.error('Failed to load analytics: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WorldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: HudTopBar(
          title: 'commission_analytics_title'.tr(),
          glassBackground: true, subtitle: '',
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _analytics == null
              ? _buildEmptyState()
              : _buildAnalyticsContent(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        showAccentGlow: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.analytics_outlined,
              color: _AnalyticsPalette.accentTeal,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'commission_analytics_empty_title'.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _AnalyticsPalette.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'commission_analytics_empty_subtitle'.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _AnalyticsPalette.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            HudButton.secondary(
              onPressed: _loadAnalytics,
              text: 'commission_analytics_empty_refresh'.tr(),
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    final analytics = _analytics!;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        _buildHeroCard(analytics.totalCommissions),
        const SizedBox(height: 16),
        _buildStatGrid(analytics),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'commission_analytics_section_key_metrics_title'.tr(),
          subtitle: 'commission_analytics_section_key_metrics_subtitle'.tr(),
          children: [
            _AnalyticsMetricRow(
              label: 'commission_analytics_metric_avg_rating'.tr(),
              value: '${analytics.averageRating.toStringAsFixed(1)} ⭐',
            ),
            _AnalyticsMetricRow(
              label: 'commission_analytics_metric_completion_rate'.tr(),
              value: '${(analytics.completionRate * 100).toStringAsFixed(1)}%',
            ),
            _AnalyticsMetricRow(
              label: 'commission_analytics_metric_acceptance_rate'.tr(),
              value: '${(analytics.acceptanceRate * 100).toStringAsFixed(1)}%',
            ),
            _AnalyticsMetricRow(
              label: 'commission_analytics_metric_turnaround'.tr(),
              value:
                  '${analytics.averageTurnaroundDays.toStringAsFixed(1)} ${'commission_analytics_metric_days'.tr()}',
            ),
            _AnalyticsMetricRow(
              label: 'commission_analytics_metric_repeat_clients'.tr(),
              value: '${analytics.returningClients}',
            ),
          ],
        ),
        if (analytics.commissionsByType.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'commission_analytics_section_types_title'.tr(),
            subtitle: 'commission_analytics_section_types_subtitle'.tr(),
            children: analytics.commissionsByType.entries.map((entry) {
              final earnings = analytics.earningsByType[entry.key] ?? 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _AnalyticsPalette.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      'commission_analytics_type_value'.tr(
                        namedArgs: {
                          'count': '${entry.value}',
                          'earnings': _currencyFormatter.format(earnings),
                        },
                      ),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _AnalyticsPalette.accentTeal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'commission_analytics_section_financial_title'.tr(),
          subtitle: 'commission_analytics_section_financial_subtitle'.tr(),
          children: [
            _AnalyticsMetricRow(
              label: 'commission_analytics_metric_avg_value'.tr(),
              value: _currencyFormatter.format(
                analytics.averageCommissionValue,
              ),
            ),
            _AnalyticsMetricRow(
              label: 'commission_analytics_metric_estimated_earnings'.tr(),
              value: _currencyFormatter.format(analytics.estimatedEarnings),
            ),
            _AnalyticsMetricRow(
              label: 'commission_analytics_metric_total_refunded'.tr(),
              value: _currencyFormatter.format(analytics.totalRefunded),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'commission_analytics_section_clients_title'.tr(),
          subtitle: 'commission_analytics_section_clients_subtitle'.tr(),
          children: [
            _AnalyticsMetricRow(
              label: 'commission_analytics_metric_unique_clients'.tr(),
              value: '${analytics.uniqueClients}',
            ),
            _AnalyticsMetricRow(
              label: 'commission_analytics_metric_returning_clients'.tr(),
              value: '${analytics.returningClients}',
            ),
            if (analytics.returningClients > 0 && analytics.uniqueClients > 0)
              _AnalyticsMetricRow(
                label: 'commission_analytics_metric_repeat_rate'.tr(),
                value:
                    '${((analytics.returningClients / analytics.uniqueClients) * 100).toStringAsFixed(1)}%',
              ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'commission_analytics_section_quality_title'.tr(),
          subtitle: 'commission_analytics_section_quality_subtitle'.tr(),
          children: [
            _AnalyticsMetricRow(
              label: 'commission_analytics_metric_on_time'.tr(),
              value: '${analytics.onTimeDeliveryCount}',
            ),
            _AnalyticsMetricRow(
              label: 'commission_analytics_metric_late'.tr(),
              value: '${analytics.lateDeliveryCount}',
            ),
            _AnalyticsMetricRow(
              label: 'commission_analytics_metric_ratings'.tr(),
              value: '${analytics.ratingsCount}',
            ),
            _AnalyticsMetricRow(
              label: 'commission_analytics_metric_disputes'.tr(),
              value: '${analytics.disputesCount}',
            ),
          ],
        ),
        const SizedBox(height: 24),
        HudButton.primary(
          onPressed: _loadAnalytics,
          text: 'commission_analytics_refresh'.tr(),
          icon: Icons.refresh,
        ),
      ],
    );
  }

  Widget _buildHeroCard(int totalCommissions) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      showAccentGlow: true,
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: _AnalyticsPalette.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _AnalyticsPalette.accentPurple.withValues(alpha: 0.25),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: const Icon(Icons.auto_graph, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'commission_analytics_hero_title'.tr(
                    namedArgs: {'count': '$totalCommissions'},
                  ),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _AnalyticsPalette.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'commission_analytics_hero_subtitle'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _AnalyticsPalette.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid(ArtistCommissionAnalytics analytics) {
    final stats = [
      _AnalyticsStatConfig(
        title: 'commission_analytics_stat_total'.tr(),
        value: '${analytics.totalCommissions}',
        icon: Icons.workspaces_outlined,
        gradient: _AnalyticsPalette.primaryGradient,
      ),
      _AnalyticsStatConfig(
        title: 'commission_analytics_stat_completed'.tr(),
        value: '${analytics.completedCommissions}',
        icon: Icons.verified_outlined,
        gradient: _AnalyticsPalette.successGradient,
      ),
      _AnalyticsStatConfig(
        title: 'commission_analytics_stat_active'.tr(),
        value: '${analytics.activeCommissions}',
        icon: Icons.timelapse,
        gradient: _AnalyticsPalette.warningGradient,
      ),
      _AnalyticsStatConfig(
        title: 'commission_analytics_stat_total_earnings'.tr(),
        value: _currencyFormatter.format(analytics.totalEarnings),
        icon: Icons.attach_money,
        gradient: _AnalyticsPalette.accentGradient,
      ),
    ];

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 12,
      runSpacing: 12,
      children: stats
          .map(
            (stat) => _AnalyticsStatCard(
              title: stat.title,
              value: stat.value,
              icon: stat.icon,
              gradient: stat.gradient,
            ),
          )
          .toList(),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _AnalyticsPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _AnalyticsPalette.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _AnalyticsPalette {
  static const Color textPrimary = Color(0xF2FFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color accentTeal = Color(0xFF22D3EE);
  static const Color accentPurple = Color(0xFF7C4DFF);

  static const Gradient primaryGradient = LinearGradient(
    colors: [accentPurple, accentTeal, Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient accentGradient = LinearGradient(
    colors: [Color(0xFFFF3D8D), accentPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient successGradient = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF22D3EE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient warningGradient = LinearGradient(
    colors: [Color(0xFFFFC857), Color(0xFFFF3D8D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class _AnalyticsStatConfig {
  const _AnalyticsStatConfig({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  final String title;
  final String value;
  final IconData icon;
  final Gradient gradient;
}

class _AnalyticsStatCard extends StatelessWidget {
  const _AnalyticsStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  final String title;
  final String value;
  final IconData icon;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final availableWidth = MediaQuery.of(context).size.width;
    return SizedBox(
      width: (availableWidth - 52) / 2,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _AnalyticsPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _AnalyticsPalette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsMetricRow extends StatelessWidget {
  const _AnalyticsMetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _AnalyticsPalette.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _AnalyticsPalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
