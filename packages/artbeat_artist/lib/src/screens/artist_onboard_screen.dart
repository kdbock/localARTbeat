import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'artist_profile_edit_screen.dart';
import '../services/artist_profile_service.dart';

/// Artist onboarding with customized experience for your medium and a seamless gallery setup
class ArtistOnboardScreen extends StatefulWidget {
  final String? preselectedPlan;

  const ArtistOnboardScreen({super.key, this.preselectedPlan});

  @override
  State<ArtistOnboardScreen> createState() =>
      _ArtistOnboardScreenState();
}

class _ArtistOnboardScreenState extends State<ArtistOnboardScreen>
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
    'beginner': 'Just starting my studio journey',
    'hobbyist': 'Creating for personal joy',
    'emerging': 'Ready to reach more people',
    'professional': 'Full-time Artist',
    'business': 'Gallery or Collective'
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
      backgroundColor: const Color(0xFF0F172A), // Deeper navy for better contrast
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, // More modern icon
              color: Colors.white.withValues(alpha: 0.92),
              size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              tr('art_walk_skip'),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          _buildBackgroundBlobs(),
          SafeArea(
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
        ],
      ),
    );
  }

  Widget _buildBackgroundBlobs() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C4DFF).withValues(alpha: 0.2),
                  blurRadius: 150,
                  spreadRadius: 50,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF22D3EE).withValues(alpha: 0.15),
                  blurRadius: 200,
                  spreadRadius: 80,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          for (int i = 0; i < 4; i++)
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: i <= _currentPage
                      ? const LinearGradient(
                          colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
                        )
                      : null,
                  color: i <= _currentPage
                      ? null
                      : Colors.white.withValues(alpha: 0.1),
                  boxShadow: i == _currentPage
                      ? [
                          BoxShadow(
                            color: const Color(0xFF22D3EE).withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
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
          offset: Offset(0, 20 * (1 - _slideAnimation.value)),
          child: Opacity(
            opacity: _slideAnimation.value.clamp(0.0, 1.0),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // High-Impact Artistic Hero
                  Container(
                    height: 280,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      image: const DecorationImage(
                        image: NetworkImage(
                            'https://images.unsplash.com/photo-1513364776144-60967b0f800f?q=80&w=800&auto=format&fit=crop'),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C4DFF).withValues(alpha: 0.2),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            const Color(0xFF0F172A).withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.bottomLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22D3EE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'FOR ARTISTS',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your Studio.\nWithout the Noise.',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Benefit-Driven Value Proposition
                  Text(
                    'Stop chasing algorithms. Start building your legacy.',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'In the next 2 minutes, we\'ll help you unlock a professional gallery experience tailored to your craft.',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.5),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // What you'll achieve (Explicit Benefits)
                  Text(
                    'HIT NEXT TO UNLOCK:',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF22D3EE),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildAchievementItem(
                    Icons.remove_red_eye_outlined,
                    'Reach Nearby Collectors',
                    'Zero-algorithm visibility to people in your city.',
                  ),
                  _buildAchievementItem(
                    Icons.auto_awesome_mosaic_outlined,
                    'Your Verified Gallery',
                    'A distraction-free space for your professional portfolio.',
                  ),
                  _buildAchievementItem(
                    Icons.insights_outlined,
                    'Real Reach Metrics',
                    'Understand your impact with honest, local data.',
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAchievementItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.5),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalizationScreen() {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _slideAnimation.value)),
          child: Opacity(
            opacity: _slideAnimation.value.clamp(0.0, 1.0),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('art_walk_what__s_your_artistic_focus'),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tr('art_walk_select_all_that_apply_to_personalize_your_experience'),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildInterestGrid(_artistInterests),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInterestGrid(List<String> interests) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: interests.map((interest) {
        final isSelected = _selectedInterests.contains(interest);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF22D3EE)
                        : Colors.white.withValues(alpha: 0.1),
                    width: isSelected ? 2 : 1,
                  ),
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            const Color(0xFF7C4DFF).withValues(alpha: 0.2),
                            const Color(0xFF22D3EE).withValues(alpha: 0.2),
                          ],
                        )
                      : null,
                  color: isSelected ? null : Colors.white.withValues(alpha: 0.03),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF22D3EE).withValues(alpha: 0.2),
                            blurRadius: 12,
                            spreadRadius: -2,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      interest,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Color(0xFF22D3EE),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGoalsScreen() {
    final Map<String, IconData> levelIcons = {
      'beginner': Icons.eco_outlined,
      'hobbyist': Icons.favorite_border,
      'emerging': Icons.trending_up,
      'professional': Icons.workspace_premium_outlined,
      'business': Icons.storefront_outlined,
    };

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _slideAnimation.value)),
          child: Opacity(
            opacity: _slideAnimation.value.clamp(0.0, 1.0),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('art_walk_what_describes_you_best'),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tr('art_walk_this_helps_us_recommend_the_right_plan_for_you'),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 40),
                  ..._experienceLevels.entries.map((entry) {
                    final isSelected = _experienceLevel == entry.key;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _experienceLevel = entry.key;
                            });
                          },
                          borderRadius: BorderRadius.circular(24),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF34D399)
                                    : Colors.white.withValues(alpha: 0.1),
                                width: isSelected ? 2 : 1,
                              ),
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: [
                                        const Color(0xFF34D399)
                                            .withValues(alpha: 0.15),
                                        const Color(0xFF0F172A),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isSelected
                                  ? null
                                  : Colors.white.withValues(alpha: 0.03),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF34D399)
                                            .withValues(alpha: 0.2)
                                        : Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    levelIcons[entry.key] ?? Icons.person,
                                    color: isSelected
                                        ? const Color(0xFF34D399)
                                        : Colors.white.withValues(alpha: 0.5),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.value,
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.white
                                                  .withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF34D399),
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
    final recommendedPlan = _getRecommendedPlan();
    _selectedPlanName ??= recommendedPlan['name'] as String;

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _slideAnimation.value)),
          child: Opacity(
            opacity: _slideAnimation.value.clamp(0.0, 1.0),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('art_walk_perfect_plan_for_you'),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Optimized for your visibility goals.',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Premium AI Recommendation Card
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C4DFF).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome,
                                  color: Color(0xFF22D3EE), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'AI RECOMMENDED',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF22D3EE),
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            recommendedPlan['name'] as String,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            recommendedPlan['price'] as String,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF34D399),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            recommendedPlan['description'] as String,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 15,
                              color: Colors.white.withValues(alpha: 0.6),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                  Text(
                    tr('art_walk_choose_a_plan'),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Minimal Plan Selector
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
                  const SizedBox(height: 24),

                  // Features List
                  Text(
                    'Included with ${(_selectedPlanName ?? "this plan")}:',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ... (SubscriptionService()
                          .getSubscriptionDetails(
                            _tierForPlanName(_selectedPlanName ?? "") ?? 
                            SubscriptionTier.free
                          )['features'] as List? ?? [])
                      .map((f) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline,
                                    size: 20, color: Color(0xFF34D399)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    f as String,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 15,
                                      color: Colors.white.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernNavigation() {
    final bool canGoNext = _getNextButtonAction() != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Row(
        children: [
          if (_currentPage > 0) ...[
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: IconButton(
                onPressed: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutQuart,
                ),
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 20),
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: canGoNext
                    ? const LinearGradient(
                        colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: canGoNext ? null : Colors.white.withValues(alpha: 0.05),
                boxShadow: canGoNext
                    ? [
                        BoxShadow(
                          color: const Color(0xFF7C4DFF).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isProcessingPlan ? null : _getNextButtonAction(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    alignment: Alignment.center,
                    child: _isProcessingPlan && _currentPage == 3
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _getNextButtonText().toUpperCase(),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: canGoNext
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.3),
                              letterSpacing: 2,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectablePlanCard(
      {required Map<String, dynamic> details, required SubscriptionTier tier}) {
    final name = details['name'] as String? ?? '';
    final priceRaw = details['price'];
    final price = priceRaw is num
        ? '\$${priceRaw.toString()}'
        : (priceRaw?.toString() ?? '');

    final isSelected = _selectedPlanName == name;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedPlanName = name),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF22D3EE)
                    : Colors.white.withValues(alpha: 0.1),
                width: isSelected ? 2 : 1,
              ),
              color: isSelected
                  ? const Color(0xFF22D3EE).withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.02),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      Text(
                        price,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF34D399)
                              : Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: Color(0xFF22D3EE))
                else
                  Icon(Icons.circle_outlined,
                      color: Colors.white.withValues(alpha: 0.2), size: 24),
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
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final artistProfileService = ArtistProfileService();
      final userService = UserService();

      final user = await userService.getUserById(currentUser.uid);
      if (user == null) throw Exception('User data not found');

      await artistProfileService.createArtistProfile(
        userId: currentUser.uid,
        displayName: currentUser.displayName ?? 'Artist',
        username: user.username,
        bio: '',
        userType: UserType.artist,
        subscriptionTier: tier,
        mediums: _selectedInterests,
        styles: [],
      );

      await userService.updateUserProfileWithMap({
        'userType': UserType.artist.name,
      });

      if (tier == SubscriptionTier.free) {
        await SubscriptionService()
            .changeTierWithValidation(tier, validateOnly: false);
      } else {
        if (!mounted) return;
        final purchaseSuccess = await Navigator.push<bool>(
          context,
          MaterialPageRoute<bool>(
            builder: (context) => SubscriptionPurchaseScreen(tier: tier),
          ),
        );
        if (purchaseSuccess != true) return;
      }

      if (mounted) {
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
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingPlan = false);
    }
  }

  Map<String, dynamic> _getRecommendedPlan() {
    if (_experienceLevel == 'beginner' || _experienceLevel == 'hobbyist') {
      return {
        'name': SubscriptionTier.free.displayName,
        'price': 'Free',
        'description': 'Perfect for getting started and exploring local discovery',
        'tier': SubscriptionTier.free,
      };
    } else if (_experienceLevel == 'emerging') {
      return {
        'name': SubscriptionTier.starter.displayName,
        'price': '\$4.99/month',
        'description': 'Ideal for artists ready to reach more people nearby',
        'tier': SubscriptionTier.starter,
      };
    } else if (_experienceLevel == 'professional') {
      return {
        'name': SubscriptionTier.creator.displayName,
        'price': '\$12.99/month',
        'description': 'For full-time artists seeking maximum visibility',
        'tier': SubscriptionTier.creator,
      };
    } else {
      return {
        'name': SubscriptionTier.business.displayName,
        'price': '\$29.99/month',
        'description': 'For galleries and professional art collectives',
        'tier': SubscriptionTier.business,
      };
    }
  }

  VoidCallback? _getNextButtonAction() {
    switch (_currentPage) {
      case 0:
        return () => _pageController.nextPage(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutQuart);
      case 1:
        return _selectedInterests.isNotEmpty
            ? () => _pageController.nextPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutQuart)
            : null;
      case 2:
        return _experienceLevel.isNotEmpty
            ? () => _pageController.nextPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutQuart)
            : null;
      case 3:
        return () => _completeOnboarding();
      default:
        return null;
    }
  }

  String _getNextButtonText() {
    switch (_currentPage) {
      case 0: return 'Get Started';
      case 1: return 'Continue';
      case 2: return 'See My Plan';
      case 3: return 'Launch Studio';
      default: return 'Next';
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
