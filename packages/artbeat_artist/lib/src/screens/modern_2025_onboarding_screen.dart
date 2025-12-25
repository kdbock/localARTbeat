import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'artist_profile_edit_screen.dart';
import '../services/artist_profile_service.dart';

/// Modern 2025 onboarding with AI-driven personalization and micro-interactions
class Modern2025OnboardingScreen extends StatefulWidget {
  final String? preselectedPlan;

  const Modern2025OnboardingScreen({super.key, this.preselectedPlan});

  @override
  State<Modern2025OnboardingScreen> createState() =>
      _Modern2025OnboardingScreenState();
}

class _Modern2025OnboardingScreenState extends State<Modern2025OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  int _currentPage = 0;
  final List<String> _selectedInterests = [];
  String _experienceLevel = '';
  String? _selectedPlanName;
  bool _isProcessingPlan = false;

  // 2025 Standard: Personalization questions
  final List<String> _artistInterests = [
    'Digital Art',
    'Traditional Painting',
    'Photography',
    'Sculpture',
    'NFT Creation',
    'AI Art',
    'Mixed Media',
    'Street Art',
    'Illustration',
    'Animation',
    '3D Modeling',
    'Ceramics'
  ];

  final Map<String, String> _experienceLevels = {
    'beginner': 'Just starting my artistic journey',
    'hobbyist': 'Creating art as a hobby',
    'emerging': 'Looking to sell my first pieces',
    'professional': 'Established artist seeking growth',
    'business': 'Gallery or institution'
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();

    // If a plan is preselected from a previous screen, set selection and
    // jump to the pricing page to show it.
    if (widget.preselectedPlan != null) {
      _selectedPlanName = widget.preselectedPlan;
      // schedule to run after first frame to avoid page controller issues
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pageController.jumpToPage(3);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              tr('art_walk_skip'),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildModernProgressBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                  _animationController.reset();
                  _animationController.forward();
                },
                children: [
                  _buildWelcomeScreen(),
                  _buildPersonalizationScreen(),
                  _buildGoalsScreen(),
                  _buildPricingScreen(),
                ],
              ),
            ),
            _buildModernNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildModernProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          for (int i = 0; i < 4; i++)
            Expanded(
              child: Container(
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: i <= _currentPage
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _slideAnimation.value)),
          child: Opacity(
            opacity: _slideAnimation.value.clamp(0.0, 1.0),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Modern hero animation
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1200),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context).primaryColor,
                                Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.7),
                                Colors.purple.shade400,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.3),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.palette,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),

                  // Modern typography
                  Text(
                    tr('art_walk_welcome_to_nartbeat'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    tr('art_walk_the_modern_platform_where_artists_thrive__npersonalized_for_your_creative_journey'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Modern stats preview
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem('50K+', 'Artists'),
                        _buildStatItem('2M+', 'Artworks'),
                        _buildStatItem('5M+', 'Sales'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String number, String label) {
    return Column(
      children: [
        Text(
          number,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalizationScreen() {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _slideAnimation.value)),
          child: Opacity(
            opacity: _slideAnimation.value.clamp(0.0, 1.0),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('art_walk_what__s_your_artistic_focus'),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr('art_walk_select_all_that_apply_to_personalize_your_experience'),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 32),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _artistInterests.length,
                    itemBuilder: (context, index) {
                      final interest = _artistInterests[index];
                      final isSelected = _selectedInterests.contains(interest);

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedInterests.remove(interest);
                                } else {
                                  _selectedInterests.add(interest);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                                color: isSelected
                                    ? Theme.of(context)
                                        .primaryColor
                                        .withValues(alpha: 0.1)
                                    : Colors.white,
                              ),
                              child: Center(
                                child: Text(
                                  interest,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGoalsScreen() {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _slideAnimation.value)),
          child: Opacity(
            opacity: _slideAnimation.value.clamp(0.0, 1.0),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('art_walk_what_describes_you_best'),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr('art_walk_this_helps_us_recommend_the_right_plan_for_you'),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ..._experienceLevels.entries.map((entry) {
                    final isSelected = _experienceLevel == entry.key;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _experienceLevel = entry.key;
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                              color: isSelected
                                  ? Theme.of(context)
                                      .primaryColor
                                      .withValues(alpha: 0.1)
                                  : Colors.white,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey.shade400,
                                      width: 2,
                                    ),
                                    color: isSelected
                                        ? Theme.of(context).primaryColor
                                        : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    entry.value,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPricingScreen() {
    // AI-recommended plan based on user input
    final recommendedPlan = _getRecommendedPlan();
    // Ensure there's a selected plan name (use recommended if none)
    _selectedPlanName ??= recommendedPlan['name'] as String;

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _slideAnimation.value)),
          child: Opacity(
            opacity: _slideAnimation.value.clamp(0.0, 1.0),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('art_walk_perfect_plan_for_you'),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Based on your interests: ${_selectedInterests.take(2).join(", ")}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // AI recommendation card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          Colors.purple.shade50,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              tr('art_walk_ai_recommended'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          recommendedPlan['name'] as String,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          recommendedPlan['price'] as String,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          recommendedPlan['description'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  // Feature preview
                  Text(
                    tr('art_walk_what_you__ll_get'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Plan selection
                  Text(
                    tr('art_walk_choose_a_plan'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  // Plan cards
                  Column(
                    children: [
                      for (final tier in [
                        SubscriptionTier.free,
                        SubscriptionTier.starter,
                        SubscriptionTier.creator,
                        SubscriptionTier.business,
                      ])
                        _buildSelectablePlanCard(
                          details: SubscriptionService()
                              .getSubscriptionDetails(tier),
                          tier: tier,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Selected plan features (non-scrollable list inside scroll view)
                  Column(
                    children: (recommendedPlan['features'] as List).map((f) {
                      final feature = f as String;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                feature,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectablePlanCard(
      {required Map<String, dynamic> details, required SubscriptionTier tier}) {
    final name = details['name'] as String? ?? '';
    final priceRaw = details['price'];
    final price = priceRaw is num
        ? '\$${priceRaw.toString()}'
        : (priceRaw?.toString() ?? '');
    final features = (details['features'] as List?) ?? [];

    final isSelected = _selectedPlanName == name;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected
            ? Theme.of(context).primaryColor.withValues(alpha: 0.04)
            : Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedPlanName = name),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                  width: isSelected ? 2 : 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(name,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 8),
                          Text(price,
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...features
                          .take(2)
                          .map((f) => Text(f as String,
                              style: TextStyle(color: Colors.grey.shade600)))
                          .toList(),
                    ],
                  ),
                ),
                Icon(isSelected ? Icons.check_circle : Icons.chevron_right,
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SubscriptionTier? _tierForPlanName(String name) {
    switch (name.toLowerCase()) {
      case 'free':
      case 'free plan':
        return SubscriptionTier.free;
      case 'starter':
      case 'starter plan':
        return SubscriptionTier.starter;
      case 'creator':
      case 'creator plan':
        return SubscriptionTier.creator;
      case 'business':
      case 'business plan':
        return SubscriptionTier.business;
      default:
        return null;
    }
  }

  Future<void> _completeOnboarding() async {
    final tier =
        _selectedPlanName != null ? _tierForPlanName(_selectedPlanName!) : null;

    if (tier == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  tr('artist_modern_2025_onboarding_text_please_select_a'))),
        );
      }
      return;
    }

    setState(() => _isProcessingPlan = true);

    try {
      // First, create artist profile and update user type
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final artistProfileService = ArtistProfileService();
      final userService = UserService();

      // Get the user data to access username
      final user = await userService.getUserById(currentUser.uid);
      if (user == null) {
        throw Exception('User data not found');
      }

      // Create artist profile with basic info
      await artistProfileService.createArtistProfile(
        userId: currentUser.uid,
        displayName: currentUser.displayName ?? 'Artist',
        username: user.username,
        bio: '',
        userType: UserType.artist,
        subscriptionTier: tier,
        mediums: _selectedInterests
            .where((interest) => [
                  'Oil Paint',
                  'Acrylic',
                  'Watercolor',
                  'Digital',
                  'Photography',
                  'Sculpture',
                  'Mixed Media'
                ].contains(interest))
            .toList(),
        styles: [],
      );

      // Update user type in core user model
      await userService.updateUserProfileWithMap({
        'userType': UserType.artist.name,
      });

      // Then handle subscription
      if (tier == SubscriptionTier.free) {
        final result = await SubscriptionService()
            .changeTierWithValidation(tier, validateOnly: false);

        if ((result['isValid'] as bool? ?? false) == false) {
          final msg = result['message'] ?? 'Failed to set free plan';
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(msg.toString())));
          }
          return;
        }
      } else {
        // For paid tiers, navigate to payment screen
        final purchaseSuccess = await Navigator.push<bool>(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute<bool>(
            builder: (context) => SubscriptionPurchaseScreen(tier: tier),
          ),
        );

        if (purchaseSuccess != true) {
          // Payment failed or cancelled
          return;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'artist_modern_2025_onboarding_title_welcome_setting_up'
                      .tr())),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (context) => const ArtistProfileEditScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing artist onboarding: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingPlan = false);
      }
    }
  }

  Map<String, dynamic> _getRecommendedPlan() {
    // AI logic based on user input - using 2025 industry-standard pricing
    if (_experienceLevel == 'beginner' || _experienceLevel == 'hobbyist') {
      return {
        'name': 'Free Plan',
        'price': 'Free',
        'description': 'Perfect for getting started with your artistic journey',
        'tier': SubscriptionTier.free,
        'features': [
          'Up to 3 artworks',
          '0.5GB storage',
          '5 AI credits/month',
          'Basic community access',
          'Mobile app access',
        ],
      };
    } else if (_experienceLevel == 'emerging') {
      return {
        'name': 'Starter Plan',
        'price': '\$4.99/month',
        'description': 'Ideal for artists ready to sell their first pieces',
        'tier': SubscriptionTier.starter,
        'features': [
          'Up to 25 artworks',
          '5GB storage',
          '50 AI credits/month',
          'Basic analytics',
          'Email support',
        ],
      };
    } else if (_experienceLevel == 'professional') {
      return {
        'name': 'Creator Plan',
        'price': '\$12.99/month',
        'description': 'For established artists growing their business',
        'tier': SubscriptionTier.creator,
        'features': [
          'Up to 100 artworks',
          '25GB storage',
          '200 AI credits/month',
          'Advanced analytics',
          'Featured placement',
          'Event creation',
          'Priority support',
        ],
      };
    } else {
      // gallery or advanced users
      return {
        'name': 'Business Plan',
        'price': '\$29.99/month',
        'description': 'For galleries and professional art businesses',
        'tier': SubscriptionTier.business,
        'features': [
          'Unlimited artworks',
          '100GB storage',
          '500 AI credits/month',
          'Team collaboration (5 users)',
          'Custom branding',
          'API access',
          'Advanced reporting',
          'Dedicated support',
        ],
      };
    }
  }

  Widget _buildModernNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentPage > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(tr('artist_artist_journey_text_back')),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: _currentPage == 0 ? 1 : 2,
            child: ElevatedButton(
              onPressed: _isProcessingPlan ? null : _getNextButtonAction(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isProcessingPlan && _currentPage == 3
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(_getNextButtonText()),
            ),
          ),
        ],
      ),
    );
  }

  VoidCallback? _getNextButtonAction() {
    switch (_currentPage) {
      case 0:
        return () => _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
      case 1:
        return _selectedInterests.isNotEmpty
            ? () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                )
            : null;
      case 2:
        return _experienceLevel.isNotEmpty
            ? () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                )
            : null;
      case 3:
        return () => _completeOnboarding();
      default:
        return null;
    }
  }

  String _getNextButtonText() {
    switch (_currentPage) {
      case 0:
        return 'Get Started';
      case 1:
        return 'Continue';
      case 2:
        return 'See My Plan';
      case 3:
        return 'Start Creating';
      default:
        return 'Next';
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
