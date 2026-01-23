import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../theme/design_system.dart';
import '../../viewmodels/artist_onboarding/artist_onboarding_view_model.dart';
import 'onboarding_widgets.dart';

/// Screen 3: Artist Story
///
/// Features:
/// - Adaptive mode toggle (Guided vs Free Write)
/// - Three guided prompts with examples
/// - Free write mode for experienced users
/// - Profile photo upload (camera or gallery)
/// - Live preview panel
class ArtistStoryScreen extends StatefulWidget {
  const ArtistStoryScreen({super.key});

  @override
  State<ArtistStoryScreen> createState() => _ArtistStoryScreenState();
}

class _ArtistStoryScreenState extends State<ArtistStoryScreen> {
  bool _isGuidedMode = true;
  int _expandedPromptIndex = 0;

  late TextEditingController _originController;
  late TextEditingController _inspirationController;
  late TextEditingController _messageController;
  late TextEditingController _freeWriteController;

  final ImagePicker _imagePicker = ImagePicker();
  String? _localPhotoPath;

  @override
  void initState() {
    super.initState();

    final viewModel = context.read<ArtistOnboardingViewModel>();
    _originController = TextEditingController(
      text: viewModel.data.storyOrigin ?? '',
    );
    _inspirationController = TextEditingController(
      text: viewModel.data.storyInspiration ?? '',
    );
    _messageController = TextEditingController(
      text: viewModel.data.storyMessage ?? '',
    );

    // Combine prompts for free write mode
    final combined = [
      viewModel.data.storyOrigin,
      viewModel.data.storyInspiration,
      viewModel.data.storyMessage,
    ].where((s) => s != null && s.isNotEmpty).join('\n\n');

    _freeWriteController = TextEditingController(text: combined);

    _localPhotoPath = viewModel.data.profilePhotoLocalPath;

    _originController.addListener(_onOriginChanged);
    _inspirationController.addListener(_onInspirationChanged);
    _messageController.addListener(_onMessageChanged);
    _freeWriteController.addListener(_onFreeWriteChanged);
  }

  @override
  void dispose() {
    _originController.dispose();
    _inspirationController.dispose();
    _messageController.dispose();
    _freeWriteController.dispose();
    super.dispose();
  }

  void _onOriginChanged() {
    context.read<ArtistOnboardingViewModel>().updateStoryOrigin(
      _originController.text,
    );
  }

  void _onInspirationChanged() {
    context.read<ArtistOnboardingViewModel>().updateStoryInspiration(
      _inspirationController.text,
    );
  }

  void _onMessageChanged() {
    context.read<ArtistOnboardingViewModel>().updateStoryMessage(
      _messageController.text,
    );
  }

  void _onFreeWriteChanged() {
    // In free write mode, store everything in storyOrigin field
    context.read<ArtistOnboardingViewModel>().updateStoryOrigin(
      _freeWriteController.text,
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _localPhotoPath = image.path;
        });

        context.read<ArtistOnboardingViewModel>().updateProfilePhoto(
          localPath: image.path,
        );
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ArtistOnboardingViewModel>(
      builder: (context, viewModel, child) {
        return OnboardingScaffold(
          currentStep: 2,
          showSkip: true,
          onSkip: () {
            viewModel.nextStep();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with mode toggle
              _buildHeader(),

              const SizedBox(height: 24),

              // Photo upload section
              _buildPhotoUpload(),

              const SizedBox(height: 32),

              // Story input (guided or free write)
              if (_isGuidedMode) _buildGuidedMode() else _buildFreeWriteMode(),

              const SizedBox(height: 24),

              // Save indicator
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Artist Story',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Help people connect with your artistic journey',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Mode toggle
            _buildModeToggle(),
          ],
        ),
      ],
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeButton('Guided', _isGuidedMode, () {
            setState(() => _isGuidedMode = true);
          }),
          const SizedBox(width: 4),
          _buildModeButton('Free Write', !_isGuidedMode, () {
            setState(() => _isGuidedMode = false);
          }),
        ],
      ),
    );
  }

  Widget _buildModeButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00F5FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.black : Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add your artist headshot',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Photos get 2x more profile views',
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white54),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            // Photo preview
            GestureDetector(
              onTap: () => _showPhotoOptions(),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                    color: const Color(0xFF00F5FF).withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: _localPhotoPath != null
                    ? ClipOval(
                        child: Image.file(
                          File(_localPhotoPath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.broken_image,
                              size: 48,
                              color: Colors.white.withValues(alpha: 0.3),
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 48,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
              ),
            ),

            const SizedBox(width: 16),

            // Upload buttons
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HudButton.secondary(
                    text: 'Take Photo',
                    icon: Icons.camera_alt,
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                  const SizedBox(height: 8),
                  HudButton.secondary(
                    text: 'Choose from Gallery',
                    icon: Icons.photo_library,
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0A0E27),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF00F5FF)),
              title: const Text(
                'Take Photo',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Color(0xFF00F5FF),
              ),
              title: const Text(
                'Choose from Gallery',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_localPhotoPath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Remove Photo',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _localPhotoPath = null);
                  context.read<ArtistOnboardingViewModel>().updateProfilePhoto(
                    localPath: null,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidedMode() {
    final prompts = [
      {
        'title': 'Where did your artistic journey begin?',
        'placeholder': 'I discovered my love for art when...',
        'controller': _originController,
      },
      {
        'title': 'What inspires your work?',
        'placeholder': 'My inspiration comes from...',
        'controller': _inspirationController,
      },
      {
        'title': 'What do you want people to know about your art?',
        'placeholder': 'When you view my work, I hope you...',
        'controller': _messageController,
      },
    ];

    return Column(
      children: List.generate(prompts.length, (index) {
        final prompt = prompts[index];
        final isExpanded = _expandedPromptIndex == index;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildPromptCard(
            title: prompt['title'] as String,
            placeholder: prompt['placeholder'] as String,
            controller: prompt['controller'] as TextEditingController,
            isExpanded: isExpanded,
            onExpand: () => setState(() => _expandedPromptIndex = index),
            promptNumber: index + 1,
          ),
        );
      }),
    );
  }

  Widget _buildPromptCard({
    required String title,
    required String placeholder,
    required TextEditingController controller,
    required bool isExpanded,
    required VoidCallback onExpand,
    required int promptNumber,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded
              ? const Color(0xFF00F5FF)
              : Colors.white.withValues(alpha: 0.1),
          width: isExpanded ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: onExpand,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF00F5FF).withValues(alpha: 0.2),
                    ),
                    child: Center(
                      child: Text(
                        '$promptNumber',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF00F5FF),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),

          // Content
          if (isExpanded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextField(
                controller: controller,
                maxLines: 6,
                maxLength: 900, // ~150 words
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                decoration: InputDecoration(
                  hintText: placeholder,
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white38,
                  ),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  counterStyle: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFreeWriteMode() {
    return OnboardingTextField(
      label: 'Tell your story as an artist',
      hint:
          'Write about your artistic journey, what inspires you, and what you want people to know about your art...',
      controller: _freeWriteController,
      maxLines: 12,
      maxLength: 2700, // ~450 words
      keyboardType: TextInputType.multiline,
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
