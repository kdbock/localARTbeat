import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:flutter/material.dart';

import '../services/onboarding_funnel_report_service.dart';

class OnboardingFunnelReportScreen extends StatefulWidget {
  const OnboardingFunnelReportScreen({super.key});

  @override
  State<OnboardingFunnelReportScreen> createState() =>
      _OnboardingFunnelReportScreenState();
}

class _OnboardingFunnelReportScreenState
    extends State<OnboardingFunnelReportScreen> {
  final OnboardingFunnelReportService _reportService =
      OnboardingFunnelReportService();

  bool _isLoading = true;
  OnboardingFunnelReport? _report;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);

    final report = await _reportService.getReport();
    if (!mounted) return;

    setState(() {
      _report = report;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const core.EnhancedUniversalHeader(
      title: 'Onboarding Funnel',
      showLogo: false,
    ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadReport,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildTopRow(),
                const SizedBox(height: 12),
                _buildMapCard(
                  title: 'Role Selected',
                  icon: Icons.people_outline,
                  values: _report?.roleSelections ?? const {},
                ),
                const SizedBox(height: 12),
                _buildMapCard(
                  title: 'Permission Results',
                  icon: Icons.shield_outlined,
                  values: _report?.permissionResults ?? const {},
                ),
                const SizedBox(height: 12),
                _buildMapCard(
                  title: 'Completion Actions',
                  icon: Icons.flag_outlined,
                  values: _report?.completions ?? const {},
                ),
              ],
            ),
          ),
  );

  Widget _buildTopRow() {
    final report = _report;
    if (report == null) return const SizedBox();

    return Row(
      children: [
        Expanded(
          child: _metricCard(
            label: 'Total Events',
            value: '${report.totalEvents}',
            icon: Icons.analytics_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _metricCard(
            label: 'Screen Views',
            value: '${report.screenViews}',
            icon: Icons.remove_red_eye_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _metricCard(
            label: 'Completion Rate',
            value: '${(report.completionRate * 100).toStringAsFixed(1)}%',
            icon: Icons.trending_up,
          ),
        ),
      ],
    );
  }

  Widget _metricCard({
    required String label,
    required String value,
    required IconData icon,
  }) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: core.ArtbeatColors.primaryPurple),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
      ],
    ),
  );

  Widget _buildMapCard({
    required String title,
    required IconData icon,
    required Map<String, int> values,
  }) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: core.ArtbeatColors.primaryPurple),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (values.isEmpty)
          Text('No data yet', style: TextStyle(color: Colors.grey[600]))
        else
          ...values.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(child: Text(entry.key)),
                  Text(
                    '${entry.value}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
