import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/design_system.dart';
import 'artist_onboarding_navigator.dart';

/// Base scaffold for all onboarding screens
/// Provides consistent layout, progress tracking, and navigation
class OnboardingScaffold extends StatelessWidget {
  final int currentStep;
  final Widget child;
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final String? nextButtonText;
  final bool canProceed;
  final bool showProgress;
  final bool showSkip;
  final VoidCallback? onSkip;

  const OnboardingScaffold({
    super.key,
    required this.currentStep,
    required this.child,
    this.onNext,
    this.onBack,
    this.nextButtonText,
    this.canProceed = true,
    this.showProgress = true,
    this.showSkip = false,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final isFirstStep = ArtistOnboardingNavigator.isFirstStep(currentStep);
    final isLastStep = ArtistOnboardingNavigator.isLastStep(currentStep);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar and navigation
            if (showProgress) _buildProgressHeader(context, isFirstStep),

            // Main content (scrollable)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: child,
              ),
            ),

            // Bottom navigation buttons
            _buildBottomNavigation(context, isFirstStep, isLastStep),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader(BuildContext context, bool isFirstStep) {
    final progressText = ArtistOnboardingNavigator.getProgressText(currentStep);
    final progress = ArtistOnboardingNavigator.getProgressPercentage(
      currentStep,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Row(
            children: [
              // Back button
              if (!isFirstStep)
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white70),
                  onPressed:
                      onBack ??
                      () => ArtistOnboardingNavigator.navigateBack(
                        context,
                        currentStep,
                      ),
                )
              else
                const SizedBox(width: 48), // Spacer for alignment
              // Progress text
              Expanded(
                child: Text(
                  progressText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Skip button or spacer
              if (showSkip)
                TextButton(
                  onPressed: onSkip,
                  child: Text(
                    'Skip',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF00F5FF),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                const SizedBox(width: 48), // Spacer for alignment
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF00F5FF), // Neon cyan
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(
    BuildContext context,
    bool isFirstStep,
    bool isLastStep,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E27).withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Back button
            if (!isFirstStep)
              Expanded(
                child: HudButton.secondary(
                  text: 'Back',
                  onPressed:
                      onBack ??
                      () => ArtistOnboardingNavigator.navigateBack(
                        context,
                        currentStep,
                      ),
                ),
              ),

            if (!isFirstStep) const SizedBox(width: 12),

            // Next/Continue button
            Expanded(
              flex: 2,
              child: HudButton.primary(
                text: nextButtonText ?? (isLastStep ? 'Complete' : 'Continue'),
                onPressed: canProceed
                    ? (onNext ??
                          () => ArtistOnboardingNavigator.navigateNext(
                            context,
                            currentStep,
                          ))
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Styled button for onboarding screens - wraps HudButton for consistency
class OnboardingButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isLoading;
  final IconData? icon;

  const OnboardingButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isPrimary = true,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return isPrimary
        ? HudButton.primary(
            text: text,
            onPressed: onPressed,
            icon: icon,
            isLoading: isLoading,
          )
        : HudButton.secondary(
            text: text,
            onPressed: onPressed,
            icon: icon,
            isLoading: isLoading,
          );
  }
}

/// Section header for onboarding screens
class OnboardingHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const OnboardingHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 12),
          Text(
            subtitle!,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}

/// Input field styled for onboarding
class OnboardingTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final int? maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final bool showCounter;

  const OnboardingTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.onChanged,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.showCounter = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          maxLines: maxLines,
          maxLength: showCounter ? maxLength : null,
          keyboardType: keyboardType,
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(fontSize: 16, color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00F5FF), width: 2),
            ),
            counterStyle: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white54,
            ),
          ),
        ),
      ],
    );
  }
}

/// Success animation widget
class OnboardingSuccessAnimation extends StatefulWidget {
  final VoidCallback? onComplete;

  const OnboardingSuccessAnimation({super.key, this.onComplete});

  @override
  State<OnboardingSuccessAnimation> createState() =>
      _OnboardingSuccessAnimationState();
}

class _OnboardingSuccessAnimationState extends State<OnboardingSuccessAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF00F5FF),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00F5FF).withValues(alpha: 0.5),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child: const Icon(Icons.check, size: 60, color: Colors.black),
        ),
      ),
    );
  }
}
