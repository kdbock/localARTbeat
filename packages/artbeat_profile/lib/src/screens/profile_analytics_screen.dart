// START of the redesigned ProfileAnalyticsScreen UI shell
// Applies Local ARTbeat design standards: world background, glass panels, HUD bar, Space Grotesk, color palette

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/profile_analytics_model.dart';
import '../services/profile_analytics_service.dart';
import '../services/user_service.dart';

class ProfileAnalyticsScreen extends StatefulWidget {
  const ProfileAnalyticsScreen({super.key});

  @override
  State<ProfileAnalyticsScreen> createState() => _ProfileAnalyticsScreenState();
}

class _ProfileAnalyticsScreenState extends State<ProfileAnalyticsScreen> {
  final ProfileAnalyticsService _analyticsService = ProfileAnalyticsService();

  bool _isLoading = true;
  ProfileAnalyticsModel? _analytics;
  Map<String, dynamic> _engagementMetrics = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final user = Provider.of<UserService>(context, listen: false).currentUser;
      if (user != null) {
        final [analytics, metrics] = await Future.wait([
          _analyticsService.getProfileAnalytics(user.uid),
          _analyticsService.getEngagementMetrics(user.uid),
        ]);

        setState(() {
          _analytics = analytics as ProfileAnalyticsModel?;
          _engagementMetrics = metrics as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error loading analytics: \$e')));
      }
    }
  }

  Widget _buildEngagementSummary() {
    if (_engagementMetrics.isEmpty) {
      return _buildGlassPanel(
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'No engagement metrics yet',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    final entries = _engagementMetrics.entries.take(6).toList();
    return _buildGlassPanel(
      Column(
        children: entries
            .map(
              (entry) => _buildMetricRow(
                _formatMetricLabel(entry.key),
                entry.value,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildMetricRow(String label, dynamic value) {
    final displayValue = value == null ? '—' : value.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            displayValue,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassPanel(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: child,
    );
  }

  String _formatMetricLabel(String raw) {
    final cleaned = raw.replaceAll('_', ' ');
    if (cleaned.isEmpty) return raw;
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07060F),
      body: Stack(
        children: [
          _buildWorldBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHudBar(),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF22D3EE),
                          ),
                        )
                      : _analytics == null
                      ? _buildNoDataWidget()
                      : RefreshIndicator(
                          onRefresh: _loadAnalytics,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Overview'),
                                const SizedBox(height: 16),
                                Container(height: 200, color: Colors.white10),
                                const SizedBox(height: 24),
                                _buildSectionTitle('Engagement'),
                                const SizedBox(height: 16),
                                _buildEngagementSummary(),
                                const SizedBox(height: 24),
                                _buildSectionTitle('Daily Views'),
                                const SizedBox(height: 16),
                                Container(height: 120, color: Colors.white10),
                                const SizedBox(height: 24),
                                _buildSectionTitle('Top Profile Viewers'),
                                const SizedBox(height: 16),
                                Container(height: 200, color: Colors.white10),
                                const SizedBox(height: 24),
                                _buildSectionTitle('Recent Trends'),
                                const SizedBox(height: 16),
                                Container(height: 150, color: Colors.white10),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorldBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF07060F), Color(0xFF0A1330), Color(0xFF071C18)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildHudBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const BackButton(color: Colors.white),
                Expanded(
                  child: Text(
                    'profile_analytics_title'.tr(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadAnalytics,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.spaceGrotesk(
        fontWeight: FontWeight.w900,
        fontSize: 18,
        color: Colors.white.withValues(alpha: 0.92),
      ),
    );
  }

  Widget _buildNoDataWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Analytics Data',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your profile analytics will appear here once you start gaining activity.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadAnalytics,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22D3EE),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                'profile_analytics_refresh'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
