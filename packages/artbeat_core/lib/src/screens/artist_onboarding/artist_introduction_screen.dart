import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/design_system.dart';
import '../../viewmodels/artist_onboarding/artist_onboarding_view_model.dart';
import 'onboarding_widgets.dart';

/// Screen 2: Artist Introduction
///
/// Features:
/// - Freeform text for artist introduction (no limiting categories)
/// - Auto-save on text changes
/// - Large, accessible text fields
/// - Examples for inspiration
class ArtistIntroductionScreen extends StatefulWidget {
  const ArtistIntroductionScreen({super.key});

  @override
  State<ArtistIntroductionScreen> createState() =>
      _ArtistIntroductionScreenState();
}

class _ArtistIntroductionScreenState extends State<ArtistIntroductionScreen> {
  late TextEditingController _introController;
  bool _showExamples = false;

  @override
  void initState() {
    super.initState();

    final viewModel = context.read<ArtistOnboardingViewModel>();
    _introController = TextEditingController(
      text: viewModel.data.artistIntroduction ?? '',
    );

    _introController.addListener(_onIntroChanged);
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  void _onIntroChanged() {
    context.read<ArtistOnboardingViewModel>().updateArtistIntroduction(
      _introController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ArtistOnboardingViewModel>(
      builder: (context, viewModel, child) {
        final canProceed = _introController.text.trim().isNotEmpty;

        return OnboardingScaffold(
          currentStep: 1,
          canProceed: canProceed,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OnboardingHeader(
                title: 'Tell us about yourself',
                subtitle:
                    'Share your story and creative vision in your own words.',
              ),

              // Main introduction field - no limiting categories
              OnboardingTextField(
                label: 'Introduce yourself as an artist',
                hint: 'I create art that...',
                controller: _introController,
                maxLines: 5,
                maxLength: 250,
                keyboardType: TextInputType.multiline,
              ),

              const SizedBox(height: 16),

              // Examples toggle
              _buildExamplesSection(),

              const SizedBox(height: 24),

              // Auto-save indicator
              if (viewModel.isSaving)
                _buildSavingIndicator()
              else if (!viewModel.hasUnsavedChanges)
                _buildSavedIndicator(),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExamplesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HudButton.secondary(
          text: _showExamples ? 'Hide examples' : 'See examples',
          icon: _showExamples ? Icons.expand_less : Icons.expand_more,
          onPressed: () {
            setState(() {
              _showExamples = !_showExamples;
            });
          },
        ),

        if (_showExamples) ...[
          const SizedBox(height: 12),
          _buildExampleCard(
            'Emerging Artist',
            '"I\'m a contemporary painter exploring themes of identity and urban life through bold colors and abstract forms."',
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            'Experienced Artist',
            '"As a documentary photographer with 15 years of experience, I capture authentic moments that tell powerful human stories."',
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            'Multi-Medium Artist',
            '"I work across sculpture, installation, and digital art to create immersive experiences that challenge perception."',
          ),
        ],
      ],
    );
  }

  Widget _buildExampleCard(String title, String example) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF00F5FF),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            example,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingIndicator() {
    return Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Saving...',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSavedIndicator() {
    return const Row(
      children: [
        Icon(Icons.check_circle, size: 16, color: Color(0xFF00F5FF)),
        SizedBox(width: 8),
        Text('Saved', style: TextStyle(color: Color(0xFF00F5FF), fontSize: 14)),
      ],
    );
  }
}
