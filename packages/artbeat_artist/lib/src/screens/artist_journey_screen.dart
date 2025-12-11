import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:firebase_auth/firebase_auth.dart';
import 'modern_2025_onboarding_screen.dart';
import 'artist_onboarding_screen.dart';

/// Comprehensive artist journey screen that guides users through becoming an artist
/// This replaces the direct jump to subscription and provides better UX
class ArtistJourneyScreen extends StatefulWidget {
  const ArtistJourneyScreen({super.key});

  @override
  State<ArtistJourneyScreen> createState() => _ArtistJourneyScreenState();
}

class _ArtistJourneyScreenState extends State<ArtistJourneyScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;
  String? _selectedPlan;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return core.MainLayout(
      currentIndex: -1,
      child: Scaffold(
        appBar: const core.EnhancedUniversalHeader(
          title: 'Become an Artist',
          showLogo: false,
          showBackButton: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Progress indicator
                  _buildProgressIndicator(),
                  // Page content
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      children: [
                        _buildWelcomePage(),
                        _buildBenefitsPage(),
                        _buildAccountChangesPage(),
                        _buildSubscriptionInfoPage(),
                      ],
                    ),
                  ),
                  // Navigation buttons
                  _buildNavigationButtons(),
                ],
              ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(4, (index) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 4,
              decoration: BoxDecoration(
                color: index <= _currentPage
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hero image
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor.withValues(alpha: 0.8),
                  Theme.of(context).primaryColor,
                ],
              ),
            ),
            child: const Icon(
              Icons.palette,
              size: 80,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          const Text('art_walk_welcome_to_the_artist_community'.tr(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text('art_walk_transform_your_artbeat_experience_and_unlock_powerful_tools_designed_specifically_for_artists_and_creators'.tr(),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('art_walk_this_will_upgrade_your_account_to_unlock_artist_features_and_opportunities'.tr(),
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
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

  Widget _buildBenefitsPage() {
    final benefits = [
      {
        'icon': Icons.storefront,
        'title': 'Your Own Gallery',
        'description':
            'Create a professional profile to showcase and sell your artwork'
      },
      {
        'icon': Icons.trending_up,
        'title': 'Increased Visibility',
        'description':
            'Get discovered by art collectors and enthusiasts worldwide'
      },
      {
        'icon': Icons.people,
        'title': 'Artist Community',
        'description':
            'Connect with fellow artists and participate in exclusive events'
      },
      {
        'icon': Icons.analytics,
        'title': 'Performance Analytics',
        'description':
            'Track your artwork views, engagement, and sales performance'
      },
      {
        'icon': Icons.event,
        'title': 'Event Management',
        'description': 'Create and promote your exhibitions and art shows'
      },
      {
        'icon': Icons.verified_user,
        'title': 'Verified Badge',
        'description': 'Get a verified artist badge to build trust with buyers'
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Text('art_walk_what_you__ll_get_as_an_artist'.tr(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text('art_walk_unlock_powerful_tools_and_opportunities_designed_for_creators'.tr(),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: benefits.length,
              itemBuilder: (context, index) {
                final benefit = benefits[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          benefit['icon'] as IconData,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              benefit['title'] as String,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              benefit['description'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountChangesPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('art_walk_what_changes_in_your_account'.tr(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text('art_walk_here__s_what_happens_when_you_become_an_artist'.tr(),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildChangeItem(
              icon: Icons.account_circle,
              title: 'Account Type',
              before: 'Art Enthusiast',
              after: 'Artist',
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            _buildChangeItem(
              icon: Icons.dashboard,
              title: 'Dashboard',
              before: 'Discover & Browse',
              after: 'Artist Management Hub',
              color: Colors.green,
            ),
            const SizedBox(height: 20),
            _buildChangeItem(
              icon: Icons.menu,
              title: 'Navigation',
              before: 'Basic Features',
              after: 'Artist Tools & Analytics',
              color: Colors.orange,
            ),
            const SizedBox(height: 20),
            _buildChangeItem(
              icon: Icons.star,
              title: 'Profile',
              before: 'Basic Profile',
              after: 'Professional Artist Gallery',
              color: Colors.purple,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('art_walk_don__t_worry__you_can_always_switch_back_to_a_regular_user_account_if_needed'.tr(),
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangeItem({
    required IconData icon,
    required String title,
    required String before,
    required String after,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('art_walk_before'.tr(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            before,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('art_walk_after'.tr(),
                            style: TextStyle(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            after,
                            style: TextStyle(
                              fontSize: 14,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionInfoPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Text('art_walk_choose_your_artist_plan'.tr(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text('art_walk_start_free_and_upgrade_anytime___plans_built_for_creators_in_2025'.tr(),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              children: [
                _buildPlanPreview(
                  title: 'Free Plan',
                  price: 'Free',
                  description:
                      'Perfect for getting started with your artistic journey',
                  features: [
                    'Up to 3 artworks',
                    '0.5GB storage',
                    '5 AI credits/month',
                    'Basic community access',
                    'Mobile app access',
                  ],
                  isRecommended: true,
                  isSelected: _selectedPlan == 'Free Plan',
                  onTap: () => _onPlanTap('Free Plan'),
                ),
                const SizedBox(height: 12),
                _buildPlanPreview(
                  title: 'Starter Plan',
                  price: '\$4.99/month',
                  description:
                      'Ideal for artists ready to sell their first pieces',
                  features: [
                    'Up to 25 artworks',
                    '5GB storage',
                    '50 AI credits/month',
                    'Basic analytics',
                    'Email support',
                  ],
                  isRecommended: false,
                  isSelected: _selectedPlan == 'Starter Plan',
                  onTap: () => _onPlanTap('Starter Plan'),
                ),
                const SizedBox(height: 12),
                _buildPlanPreview(
                  title: 'Creator Plan',
                  price: '\$12.99/month',
                  description: 'For established artists growing their business',
                  features: [
                    'Up to 100 artworks',
                    '25GB storage',
                    '200 AI credits/month',
                    'Advanced analytics',
                    'Featured placement',
                    'Event creation',
                    'Priority support',
                  ],
                  isRecommended: false,
                  isSelected: _selectedPlan == 'Creator Plan',
                  onTap: () => _onPlanTap('Creator Plan'),
                ),
                const SizedBox(height: 12),
                _buildPlanPreview(
                  title: 'Business Plan',
                  price: '\$29.99/month',
                  description: 'For galleries and professional art businesses',
                  features: [
                    'Unlimited artworks',
                    '100GB storage',
                    '500 AI credits/month',
                    'Team collaboration (5 users)',
                    'Custom branding',
                    'API access',
                    'Advanced reporting',
                    'Dedicated support',
                  ],
                  isRecommended: false,
                  isSelected: _selectedPlan == 'Business Plan',
                  onTap: () => _onPlanTap('Business Plan'),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('art_walk_if_you__re_unsure_which_plan_fits__complete_the_modern_onboarding_for_a_personalized_recommendation'.tr(),
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanPreview({
    required String title,
    required String price,
    required String description,
    required List<String> features,
    required bool isRecommended,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return Material(
      color: isSelected
          ? Theme.of(context).primaryColor.withValues(alpha: 0.04)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : (isRecommended
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300),
              width: isSelected ? 2.5 : (isRecommended ? 2 : 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isRecommended) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text('art_walk_recommended'.tr(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...features
                  .map((feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                feature,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentPage > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Text('artist_artist_journey_text_back'.tr()),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: _currentPage == 3 ? _startArtistJourney : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                _currentPage == 3 ? 'Start My Artist Journey' : 'Continue',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _startArtistJourney() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Get user data
      final userService = core.UserService();
      final userData = await userService.getUserById(user.uid);

      if (userData == null) {
        throw Exception('User data not found');
      }

      if (mounted) {
        // Step 1: Modern onboarding
        await Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (context) => Modern2025OnboardingScreen(
              // After completion, go to artist profile setup
              key: UniqueKey(),
            ),
          ),
        );

        // Step 2: Artist profile setup
        await Navigator.push<void>(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute<void>(
            builder: (context) => ArtistOnboardingScreen(
              user: userData,
              onComplete: () {
                // After profile setup, go to dashboard or next step
                Navigator.pushReplacementNamed(context, '/dashboard');
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('admin_unified_admin_dashboard_error_error_e'.tr())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onPlanTap(String planName) {
    setState(() {
      _selectedPlan = planName;
    });

    // Immediately proceed to modern onboarding with preselected plan
    _startArtistJourneyWithPlan(planName);
  }

  Future<void> _startArtistJourneyWithPlan(String planName) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final userService = core.UserService();
      final userData = await userService.getUserById(user.uid);
      if (userData == null) throw Exception('User data not found');

      if (mounted) {
        await Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (context) => Modern2025OnboardingScreen(
              key: UniqueKey(),
              preselectedPlan: planName,
            ),
          ),
        );

        await Navigator.push<void>(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute<void>(
            builder: (context) => ArtistOnboardingScreen(
              user: userData,
              onComplete: () {
                Navigator.pushReplacementNamed(context, '/dashboard');
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('admin_unified_admin_dashboard_error_error_e'.tr())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
