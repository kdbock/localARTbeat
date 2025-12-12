import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../services/artist_profile_service.dart';

class ArtistOnboardingScreen extends StatefulWidget {
  final core.UserModel user;
  final VoidCallback? onComplete;

  const ArtistOnboardingScreen({
    super.key,
    required this.user,
    this.onComplete,
  });

  @override
  State<ArtistOnboardingScreen> createState() => _ArtistOnboardingScreenState();
}

class _ArtistOnboardingScreenState extends State<ArtistOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bioController;
  late TextEditingController _websiteController;
  final List<String> _selectedMediums = [];
  final List<String> _selectedStyles = [];
  bool _isSubmitting = false;

  // Available options for art mediums and styles
  final List<String> _availableMediums = [
    'Oil',
    'Acrylic',
    'Watercolor',
    'Digital',
    'Photography',
    'Sculpture',
    'Mixed Media',
    'Other'
  ];

  final List<String> _availableStyles = [
    'Abstract',
    'Realism',
    'Impressionism',
    'Pop Art',
    'Minimalism',
    'Contemporary',
    'Traditional',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController();
    _websiteController = TextEditingController();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Create artist profile
      final artistProfileService = ArtistProfileService();
      final userService = core.UserService();

      await artistProfileService.createArtistProfile(
        userId: widget.user.id,
        displayName: widget.user.fullName,
        bio: _bioController.text,
        website: _websiteController.text,
        mediums: _selectedMediums,
        styles: _selectedStyles,
        userType: core.UserType.artist,
        subscriptionTier: core.SubscriptionTier.free,
      );

      // Update user type in core user model
      await userService.updateUserProfileWithMap({
        'userType': core.UserType.artist.name,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(tr(
                  'artist_artist_onboarding_success_artist_profile_created'))),
        );
        // Navigate to subscription comparison after onboarding
        Navigator.pushNamed(context, '/subscription/comparison');
        widget.onComplete?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  tr('artist_artist_onboarding_error_error_creating_artist'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return core.MainLayout(
      currentIndex: -1,
      child: Container(
        decoration: const BoxDecoration(
          gradient: core.ArtbeatColors.primaryGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              color: core.ArtbeatColors.cardBackground.withValues(alpha: 0.98),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            // Hero image (add your own asset or use a placeholder)
                            SizedBox(
                              height: 100,
                              child: Image.asset(
                                'assets/artist_onboarding_hero.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.brush,
                                        size: 80,
                                        color:
                                            core.ArtbeatColors.primaryPurple),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              tr('art_walk_welcome_to_artbeat_for_artists'),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: core.ArtbeatColors.primaryPurple,
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              tr('art_walk_showcase_your_talent_and_join_a_vibrant_community_of_creators'),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: core.ArtbeatColors.textSecondary,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(
                          color: core.ArtbeatColors.divider, thickness: 1.2),
                      const SizedBox(height: 18),
                      Text(
                        tr('art_walk_about_you'),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: core.ArtbeatColors.primaryPurple,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _bioController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Artist Bio',
                          hintText: 'Tell us about your artistic journey...',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter your bio';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _websiteController,
                        decoration: const InputDecoration(
                          labelText: 'Website (Optional)',
                          hintText: 'https://your-portfolio.com',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(
                          color: core.ArtbeatColors.divider, thickness: 1.2),
                      const SizedBox(height: 18),
                      Text(
                        tr('art_walk_art_mediums'),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: core.ArtbeatColors.primaryGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tr('art_walk_select_all_that_apply__what_materials_or_techniques_do_you_use_most'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: core.ArtbeatColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: _availableMediums.map((medium) {
                          return FilterChip(
                            label: Text(medium),
                            selected: _selectedMediums.contains(medium),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedMediums.add(medium);
                                } else {
                                  _selectedMediums.remove(medium);
                                }
                              });
                            },
                            backgroundColor:
                                core.ArtbeatColors.backgroundSecondary,
                            selectedColor: core.ArtbeatColors.primaryPurple
                                .withValues(alpha: 0.15),
                            checkmarkColor: core.ArtbeatColors.primaryPurple,
                            labelStyle: TextStyle(
                              color: _selectedMediums.contains(medium)
                                  ? core.ArtbeatColors.primaryPurple
                                  : core.ArtbeatColors.textPrimary,
                              fontWeight: _selectedMediums.contains(medium)
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: _selectedMediums.contains(medium)
                                    ? core.ArtbeatColors.primaryPurple
                                    : core.ArtbeatColors.border,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (_selectedMediums.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            tr('art_walk_please_select_at_least_one_medium'),
                            style: const TextStyle(color: core.ArtbeatColors.error),
                          ),
                        ),
                      const SizedBox(height: 24),
                      const Divider(
                          color: core.ArtbeatColors.divider, thickness: 1.2),
                      const SizedBox(height: 18),
                      Text(
                        tr('art_walk_art_styles'),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: core.ArtbeatColors.accent1,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tr('art_walk_what_styles_best_describe_your_work__select_as_many_as_you_like'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: core.ArtbeatColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: _availableStyles.map((style) {
                          return FilterChip(
                            label: Text(style),
                            selected: _selectedStyles.contains(style),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedStyles.add(style);
                                } else {
                                  _selectedStyles.remove(style);
                                }
                              });
                            },
                            backgroundColor:
                                core.ArtbeatColors.backgroundSecondary,
                            selectedColor: core.ArtbeatColors.accent1
                                .withValues(alpha: 0.15),
                            checkmarkColor: core.ArtbeatColors.accent1,
                            labelStyle: TextStyle(
                              color: _selectedStyles.contains(style)
                                  ? core.ArtbeatColors.accent1
                                  : core.ArtbeatColors.textPrimary,
                              fontWeight: _selectedStyles.contains(style)
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: _selectedStyles.contains(style)
                                    ? core.ArtbeatColors.accent1
                                    : core.ArtbeatColors.border,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (_selectedStyles.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            tr('art_walk_please_select_at_least_one_style'),
                            style: const TextStyle(color: core.ArtbeatColors.error),
                          ),
                        ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: core.ArtbeatColors.primaryPurple,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 6,
                          ),
                          onPressed: _isSubmitting ||
                                  _selectedMediums.isEmpty ||
                                  _selectedStyles.isEmpty
                              ? null
                              : _submitForm,
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        core.ArtbeatColors.white),
                                  ),
                                )
                              : Text(
                                  tr('art_walk_create_artist_profile'),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: core.ArtbeatColors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          tr('art_walk_you_can_edit_your_profile_and_add_more_details_later'),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: core.ArtbeatColors.textDisabled,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
