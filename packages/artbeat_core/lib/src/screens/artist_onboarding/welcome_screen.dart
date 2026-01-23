import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/artist_onboarding/artist_onboarding_view_model.dart';
import 'artist_onboarding_navigator.dart';
import 'onboarding_widgets.dart';

/// Screen 1: Welcome & Artist Identification
///
/// Features:
/// - Hero image/video placeholder
/// - Testimonial from Izzy Piel
/// - Three CTA options for entry
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleArtistSelection(BuildContext context) {
    final viewModel = context.read<ArtistOnboardingViewModel>();
    viewModel.setCurrentStep(1);
    ArtistOnboardingNavigator.navigateNext(context, 0);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),

                    // Logo or app name
                    _buildHeader(),

                    const SizedBox(height: 32),

                    // Hero image/video placeholder
                    _buildHeroSection(size),

                    const SizedBox(height: 40),

                    // Welcome message
                    _buildWelcomeMessage(),

                    const SizedBox(height: 32),

                    // Testimonial
                    _buildTestimonial(),

                    const SizedBox(height: 40),

                    // CTA Buttons
                    _buildCTAButtons(context),

                    const SizedBox(height: 24),

                    // Secondary option
                    _buildSecondaryOption(context),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Text(
      'ArtBeat',
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF00F5FF),
        letterSpacing: 2,
        shadows: [
          Shadow(
            color: const Color(0xFF00F5FF).withValues(alpha: 0.5),
            blurRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(Size size) {
    // Video placeholder - 16:9 aspect ratio
    final height = size.width * 0.5625; // 16:9 ratio

    return Container(
      height: height.clamp(200.0, 400.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF00F5FF).withValues(alpha: 0.2),
            const Color(0xFFFF00F5).withValues(alpha: 0.2),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Placeholder for video
          Icon(
            Icons.play_circle_outline,
            size: 80,
            color: Colors.white.withValues(alpha: 0.6),
          ),

          // Video placeholder text
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '15-second welcome video\n(Coming soon)',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Column(
      children: [
        Text(
          'Welcome to ArtBeat',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Where Your Art Finds Its Audience',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 18,
            color: Colors.white70,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTestimonial() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00F5FF).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF00F5FF), Color(0xFFFF00F5)],
              ),
            ),
            child: const Icon(Icons.person, size: 32, color: Colors.white),
          ),

          const SizedBox(height: 16),

          // Quote
          Text(
            '"Local ARTbeat has put me on the map! I love the exposure it provides and seeing others engage with my art."',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 12),

          // Attribution
          Text(
            'Izzy Piel',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF00F5FF),
            ),
          ),
          Text(
            'Visual Artist',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildCTAButtons(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OnboardingButton(
        text: "I'm Ready to Share My Art",
        onPressed: () => _handleArtistSelection(context),
        isPrimary: true,
        icon: Icons.palette,
      ),
    );
  }

  Widget _buildSecondaryOption(BuildContext context) {
    return TextButton(
      onPressed: () {
        // Navigate to art discovery/browsing
        Navigator.of(context).pushReplacementNamed('/dashboard');
      },
      child: Text(
        "I'm Here to Discover Art",
        style: GoogleFonts.poppins(fontSize: 16, color: Colors.white60),
      ),
    );
  }
}
