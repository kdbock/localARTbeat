import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'audio_navigation_service.dart';

/// Tutorial step model for onboarding
class TutorialStep {
  final String id;
  final String title;
  final String description;
  final Widget? icon;
  final Offset? position;
  final double? width;
  final double? height;
  final VoidCallback? onComplete;
  final bool isVoiceEnabled;
  final String? voiceText;

  const TutorialStep({
    required this.id,
    required this.title,
    required this.description,
    this.icon,
    this.position,
    this.width,
    this.height,
    this.onComplete,
    this.isVoiceEnabled = true,
    this.voiceText,
  });
}

/// Smart onboarding service for contextual user guidance
class SmartOnboardingService {
  static const String _tutorialProgressKey = 'tutorial_progress';
  static const String _firstTimeUserKey = 'first_time_user';
  static const String _voiceGuidanceEnabledKey = 'voice_guidance_enabled';

  final SharedPreferences _prefs;
  final AudioNavigationService _audioService;

  SmartOnboardingService(this._prefs, this._audioService);

  /// Initialize onboarding for new users
  Future<void> initializeOnboarding() async {
    final isFirstTime = _prefs.getBool(_firstTimeUserKey) ?? true;
    if (isFirstTime) {
      await _prefs.setBool(_firstTimeUserKey, false);
      await _resetTutorialProgress();
    }
  }

  /// Check if user has completed a specific tutorial step
  bool isTutorialStepCompleted(String stepId) {
    final progress = _getTutorialProgress();
    return progress.contains(stepId);
  }

  /// Mark tutorial step as completed
  Future<void> completeTutorialStep(String stepId) async {
    final progress = _getTutorialProgress();
    if (!progress.contains(stepId)) {
      progress.add(stepId);
      await _saveTutorialProgress(progress);
    }
  }

  /// Get next tutorial step based on user progress and context
  TutorialStep? getNextTutorialStep(String context, {Offset? targetPosition}) {
    final progress = _getTutorialProgress();

    // Art Walk Experience Context
    if (context == 'art_walk_experience') {
      if (!progress.contains('welcome_message')) {
        return TutorialStep(
          id: 'welcome_message',
          title: 'Welcome to Your Art Walk Adventure!',
          description:
              'Tap the map markers to discover amazing art pieces around you.',
          icon: const Icon(Icons.map, color: Colors.white),
          position: targetPosition,
          isVoiceEnabled: true,
          voiceText:
              'Welcome to your art walk adventure! Tap the colorful markers on the map to discover amazing art pieces around you.',
        );
      }

      if (!progress.contains('navigation_mode')) {
        return const TutorialStep(
          id: 'navigation_mode',
          title: 'Turn-by-Turn Navigation',
          description:
              'Enable navigation mode to get voice-guided directions to each art piece.',
          icon: Icon(Icons.navigation, color: Colors.white),
          isVoiceEnabled: true,
          voiceText:
              'Enable navigation mode to receive voice-guided directions to each art piece on your walk.',
        );
      }

      if (!progress.contains('progress_tracking')) {
        return const TutorialStep(
          id: 'progress_tracking',
          title: 'Track Your Progress',
          description:
              'Watch your progress bar fill up as you discover more art pieces!',
          icon: Icon(Icons.flag, color: Colors.white),
          isVoiceEnabled: true,
          voiceText:
              'Keep an eye on your progress bar - it fills up as you discover more amazing art pieces!',
        );
      }
    }

    // My Art Walks Context
    if (context == 'my_art_walks') {
      if (!progress.contains('create_walk')) {
        return const TutorialStep(
          id: 'create_walk',
          title: 'Create Your First Art Walk',
          description:
              'Tap the + button to create a personalized art walk route.',
          icon: Icon(Icons.add, color: Colors.white),
          isVoiceEnabled: true,
          voiceText:
              'Ready to create your first art walk? Tap the plus button to design a personalized route.',
        );
      }
    }

    return null;
  }

  /// Show contextual hint based on user behavior
  Future<void> showContextualHint(String hintType, BuildContext context) async {
    final isVoiceEnabled = _prefs.getBool(_voiceGuidanceEnabledKey) ?? true;

    switch (hintType) {
      case 'location_permission':
        if (isVoiceEnabled) {
          await _audioService.speak(
            'Please allow location access to find art pieces near you.',
          );
        }
        break;

      case 'first_marker_tap':
        if (isVoiceEnabled) {
          await _audioService.speak(
            'Great! You found an art piece. Tap the marker to learn more about this amazing artwork.',
          );
        }
        break;

      case 'navigation_activated':
        if (isVoiceEnabled) {
          await _audioService.speak(
            'Navigation activated! Follow the blue line to your next art discovery.',
          );
        }
        break;

      case 'walk_completed':
        if (isVoiceEnabled) {
          await _audioService.speak(
            'Congratulations on completing your art walk! You\'ve discovered some amazing art today.',
          );
        }
        break;
    }
  }

  /// Enable/disable voice guidance
  Future<void> setVoiceGuidanceEnabled(bool enabled) async {
    await _prefs.setBool(_voiceGuidanceEnabledKey, enabled);
  }

  /// Check if voice guidance is enabled
  bool isVoiceGuidanceEnabled() {
    return _prefs.getBool(_voiceGuidanceEnabledKey) ?? true;
  }

  /// Reset tutorial progress (for testing or user preference)
  Future<void> resetTutorialProgress() async {
    await _resetTutorialProgress();
  }

  /// Get tutorial completion percentage
  double getTutorialCompletionPercentage() {
    final progress = _getTutorialProgress();
    const totalSteps = 6; // Total number of tutorial steps
    return progress.length / totalSteps;
  }

  List<String> _getTutorialProgress() {
    final progressJson = _prefs.getString(_tutorialProgressKey);
    if (progressJson != null) {
      final decoded = json.decode(progressJson);
      if (decoded is List) {
        return List<String>.from(decoded.map((item) => item.toString()));
      }
    }
    return [];
  }

  Future<void> _saveTutorialProgress(List<String> progress) async {
    await _prefs.setString(_tutorialProgressKey, json.encode(progress));
  }

  Future<void> _resetTutorialProgress() async {
    await _prefs.setString(_tutorialProgressKey, json.encode([]));
  }
}

/// Tutorial overlay widget for showing interactive guidance
class TutorialOverlay extends StatefulWidget {
  final TutorialStep step;
  final VoidCallback onDismiss;
  final VoidCallback? onComplete;

  const TutorialOverlay({
    super.key,
    required this.step,
    required this.onDismiss,
    this.onComplete,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Stack(
        children: [
          // Semi-transparent background
          Positioned.fill(
            child: GestureDetector(
              onTap: _handleDismiss,
              child: Container(color: Colors.black54),
            ),
          ),

          // Tutorial content
          Positioned(
            left:
                widget.step.position?.dx ??
                MediaQuery.of(context).size.width * 0.1,
            top:
                widget.step.position?.dy ??
                MediaQuery.of(context).size.height * 0.3,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width:
                      widget.step.width ??
                      MediaQuery.of(context).size.width * 0.8,
                  constraints: const BoxConstraints(maxWidth: 300),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon and title
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child:
                                widget.step.icon ??
                                const Icon(
                                  Icons.lightbulb,
                                  color: Colors.white,
                                ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.step.title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Description
                      Text(
                        widget.step.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),

                      const SizedBox(height: 20),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _handleDismiss,
                            child: Text('art_walk_smart_onboarding_service_button_skip'.tr()),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _handleComplete,
                            child: Text('art_walk_smart_onboarding_service_button_got_it'.tr()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleDismiss() {
    _animationController.reverse().then((_) {
      widget.onDismiss();
    });
  }

  void _handleComplete() {
    widget.step.onComplete?.call();
    _animationController.reverse().then((_) {
      widget.onComplete?.call();
      widget.onDismiss();
    });
  }
}
