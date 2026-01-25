import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/artist_onboarding/artist_onboarding_data.dart';
import '../../routing/app_routes.dart';
import '../../theme/design_system.dart';
import '../../viewmodels/artist_onboarding/artist_onboarding_view_model.dart';
import 'onboarding_widgets.dart';

/// Completion Screen
///
/// Features:
/// - Success animation
/// - Welcome message
/// - Quick stats card
/// - Primary CTAs
/// - Share profile option
class OnboardingCompletionScreen extends StatefulWidget {
  const OnboardingCompletionScreen({super.key});

  @override
  State<OnboardingCompletionScreen> createState() =>
      _OnboardingCompletionScreenState();
}

class _OnboardingCompletionScreenState
    extends State<OnboardingCompletionScreen> {
  bool _showContent = false;

  @override
  void initState() {
    super.initState();

    // Show content after animation
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _showContent = true);
      }
    });
  }

  Future<void> _shareProfile() async {
    // TODO: Get actual profile URL
    await SharePlus.instance.share(
      ShareParams(
        text:
            'Check out my artist profile on ArtBeat! artbeat.com/artist/username',
      ),
    );
  }

  void _navigateToDashboard() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.artistDashboard);
  }

  void _navigateToProfile() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.artistPublicProfile,
        arguments: {'artistId': userId},
      );
    }
  }

  void _addMoreArtwork() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.artworkUpload);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ArtistOnboardingViewModel>(
      builder: (context, viewModel, child) {
        final data = viewModel.data;

        return Scaffold(
          backgroundColor: const Color(0xFF0A0E27),
          body: SafeArea(
            child: Stack(
              children: [
                // Success animation
                if (!_showContent) const OnboardingSuccessAnimation(),

                // Main content
                if (_showContent)
                  AnimatedOpacity(
                    opacity: _showContent ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 40),

                          // Celebration icon
                          Center(
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(
                                  0xFF00F5FF,
                                ).withValues(alpha: 0.2),
                              ),
                              child: const Icon(
                                Icons.celebration,
                                size: 60,
                                color: Color(0xFF00F5FF),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Welcome message
                          Text(
                            'Your Artist Profile is Live! 🎉',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),

                          const SizedBox(height: 16),

                          Text(
                            'Welcome to the ArtBeat community',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Stats card
                          _buildStatsCard(data),

                          const SizedBox(height: 32),

                          // Primary CTAs
                          OnboardingButton(
                            text: 'Artist Dashboard',
                            icon: Icons.dashboard,
                            onPressed: _navigateToDashboard,
                          ),

                          const SizedBox(height: 12),

                          OnboardingButton(
                            text: 'View My Profile',
                            icon: Icons.person,
                            onPressed: _navigateToProfile,
                            isPrimary: false,
                          ),

                          const SizedBox(height: 12),

                          OnboardingButton(
                            text: 'Explore ArtBeat',
                            icon: Icons.explore,
                            onPressed: () {
                              Navigator.of(context).pushReplacementNamed('/');
                            },
                            isPrimary: false,
                          ),

                          const SizedBox(height: 12),

                          HudButton.secondary(
                            text: 'Add More Artwork',
                            icon: Icons.add_photo_alternate,
                            onPressed: _addMoreArtwork,
                          ),

                          const SizedBox(height: 24),

                          // Share button
                          Center(
                            child: TextButton.icon(
                              onPressed: _shareProfile,
                              icon: const Icon(
                                Icons.share,
                                color: Color(0xFF00F5FF),
                              ),
                              label: Text(
                                'Share My Profile',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: const Color(0xFF00F5FF),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Email confirmation
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.mail_outline,
                                  color: Color(0xFF00F5FF),
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'We sent you a welcome guide with tips for getting started',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsCard(ArtistOnboardingData data) {
    final artworkCount = data.artworks.length;
    final featuredCount = data.featuredArtworkIds.length;
    final tier = data.selectedTier ?? 'FREE';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF00F5FF).withValues(alpha: 0.2),
            const Color(0xFFFF00F5).withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00F5FF).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Your Profile Summary',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.palette,
                value: '$artworkCount',
                label: 'Artworks',
              ),
              _buildStatItem(
                icon: Icons.star,
                value: '$featuredCount',
                label: 'Featured',
              ),
              _buildStatItem(
                icon: Icons.workspace_premium,
                value: tier,
                label: 'Plan',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF00F5FF), size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
        ),
      ],
    );
  }
}
