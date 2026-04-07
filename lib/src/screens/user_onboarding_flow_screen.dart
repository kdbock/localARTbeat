import 'dart:io';

import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/onboarding_analytics_service.dart';

/// Streamlined first-run onboarding for all users.
///
/// Compressed 2-screen flow: role selection → action/completion.
/// Fixes text visibility with scrollable containers and reduced copy.
class UserOnboardingFlowScreen extends StatefulWidget {
  const UserOnboardingFlowScreen({super.key});

  @override
  State<UserOnboardingFlowScreen> createState() =>
      _UserOnboardingFlowScreenState();
}

class _UserOnboardingFlowScreenState extends State<UserOnboardingFlowScreen> {
  final PageController _controller = PageController();
  final ImagePicker _picker = ImagePicker();
  final OnboardingAnalyticsService _onboardingAnalytics =
      OnboardingAnalyticsService();

  bool _isArtistPath = false;
  bool _isCompleting = false;
  bool _roleSelected = false;
  File? _artistPhoto;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackScreenView(stepIndex: 0, stepName: 'role_selection');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _goToStep(int index) async {
    await _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );

    if (index == 1) {
      await _trackScreenView(
        stepIndex: 1,
        stepName: _isArtistPath ? 'artist_action' : 'fan_action',
      );
    }
  }

  Future<void> _completeAndEnterApp({required String action}) async {
    if (_isCompleting) return;
    setState(() => _isCompleting = true);

    await _trackCompletion(action: action);

    await core.OnboardingService().markOnboardingCompleted();
    if (!mounted) return;

    await Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(core.AppRoutes.dashboard, (route) => false);
  }

  Future<void> _selectRole(bool isArtist) async {
    setState(() {
      _isArtistPath = isArtist;
      _roleSelected = true;
    });
    await _trackRoleSelected(isArtist ? 'artist' : 'fan');
    await _goToStep(1);
  }

  Future<void> _requestLocationThenContinue() async {
    final allowed =
        await core.PermissionUtils.requestLocationPermissionWithSafety(context);
    await _trackPermissionResult(
      permission: 'location',
      result: allowed ? 'granted' : 'denied_or_deferred',
    );

    if (!mounted) return;
    await _completeAndEnterApp(action: 'location_permission_completed');
  }

  Future<void> _pickArtistPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      imageQuality: 90,
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _artistPhoto = File(picked.path);
    });

    await _trackPermissionResult(
      permission: 'photo_library',
      result: 'selected',
    );

    await _completeAndEnterApp(action: 'photo_upload_completed');
  }

  Future<void> _trackScreenView({
    required int stepIndex,
    required String stepName,
  }) async {
    await _onboardingAnalytics.trackScreenView(
      stepIndex: stepIndex,
      stepName: stepName,
      rolePath: _isArtistPath ? 'artist' : 'fan',
    );
  }

  Future<void> _trackRoleSelected(String role) async {
    await _onboardingAnalytics.trackRoleSelected(role: role);
  }

  Future<void> _trackPermissionResult({
    required String permission,
    required String result,
  }) async {
    await _onboardingAnalytics.trackPermissionResult(
      permission: permission,
      result: result,
      rolePath: _isArtistPath ? 'artist' : 'fan',
    );
  }

  Future<void> _trackCompletion({required String action}) async {
    await _onboardingAnalytics.trackCompletion(
      action: action,
      rolePath: _isArtistPath ? 'artist' : 'fan',
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF0A0E27),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _completeAndEnterApp(action: 'skip'),
                      child: const Text('Skip'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildRoleSelectionScreen(),
                    _buildActionScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildRoleSelectionScreen() => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1B3158),
                      Color(0xFF0F4E4E),
                      Color(0xFF4B1C42),
                    ],
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(40),
                  child: Icon(
                    Icons.palette_outlined,
                    size: 84,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Discover, photograph, and share public art.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => _selectRole(false),
                child: const Text('Explore as a Fan'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _selectRole(true),
                child: const Text("I'm an Artist"),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );

  Widget _buildActionScreen() {
    if (!_roleSelected) {
      return const SizedBox.shrink();
    }

    if (_isArtistPath) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Icon(
                Icons.collections,
                size: 56,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              const Text(
                'Upload one photo of your work.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Complete your profile later.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 280,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: _artistPhoto == null
                      ? const Center(
                          child: Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 56,
                            color: Colors.white70,
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(_artistPhoto!, fit: BoxFit.cover),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _pickArtistPhoto,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(
                  _artistPhoto == null ? 'Choose Photo' : 'Change Photo',
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Icon(
              Icons.location_on_outlined,
              size: 56,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            const Text(
              'Allow location to discover art nearby.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'We show public art within a few miles of you.',
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _requestLocationThenContinue,
              icon: const Icon(Icons.my_location),
              label: const Text('Allow Location'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () =>
                  _completeAndEnterApp(action: 'location_skipped'),
              child: const Text('Skip for Now'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
