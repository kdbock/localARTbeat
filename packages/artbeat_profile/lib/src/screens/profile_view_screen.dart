import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_profile/widgets/widgets.dart';
import 'package:artbeat_core/src/services/achievement_service.dart';
import '../services/profile_connection_service.dart';

class ProfileViewScreen extends StatefulWidget {
  final String userId;
  final bool isCurrentUser;

  const ProfileViewScreen({
    super.key,
    required this.userId,
    this.isCurrentUser = false,
  });

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen>
    with SingleTickerProviderStateMixin {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final UserService _userService = UserService();
  final CaptureService _captureService = CaptureService();
  final AchievementService _achievementService = AchievementService();
  final ProfileConnectionService _connectionService =
      ProfileConnectionService();
  late TabController _tabController;

  bool _isLoading = true;
  UserModel? _userModel;
  List<CaptureModel> _userCaptures = [];
  bool _isLoadingCaptures = true;
  List<Map<String, dynamic>> _userAchievements = [];
  bool _isUserBlocked = false;
  final int _artwalksCompleted = 0;

  // Streak data from stats field
  int _loginStreak = 0;
  int _challengeStreak = 0;
  int _categoryStreak = 0;
  String? _categoryName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserProfile();
    _loadUserCaptures();
    _loadUserAchievements();
    _loadStreakData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Profile data getters
  String get username => _userModel?.username ?? "artbeat_user";
  String get name => _userModel?.fullName ?? "ARTbeat User";
  String get bio => _userModel?.bio ?? "Art enthusiast and creative explorer";
  String get location => _userModel?.location ?? "United States";
  String get profileImageUrl => _userModel?.profileImageUrl ?? "";
  int get postsCount => _userModel?.posts.length ?? 0;

  int get capturesCount => _userCaptures.length;
  String get cityState => _userModel?.location ?? "City, State";
  int get artwalksCompleted => _artwalksCompleted;

  Future<void> _loadUserProfile() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Loading profile for user ID

      // Check if userId is valid
      if (widget.userId.isEmpty) {
        // debugPrint('❌ ProfileViewScreen: Empty userId provided');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('profile_invalid_user'.tr())));
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // First, try to get user from Firestore
      UserModel? userModel = await _userService.getUserById(widget.userId);

      // If no user model found, and this is the current user, create a placeholder
      if (userModel == null && widget.isCurrentUser) {
        // Creating placeholder for current user
        userModel = UserModel.placeholder(widget.userId);

        // Try to reload user data from authentication
        try {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            userModel = userModel.copyWith(
              email: currentUser.email,
              fullName: currentUser.displayName ?? 'ARTbeat User',
              profileImageUrl: currentUser.photoURL,
            );
          }
        } catch (e) {
          // debugPrint('⚠️ ProfileViewScreen: Error loading auth data: $e');
        }
      }

      if (mounted) {
        setState(() {
          _userModel = userModel;
          _isLoading = false;
        });
      }

      if (userModel == null) {
        // debugPrint('❌ ProfileViewScreen: Could not load user profile');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('profile_not_found'.tr())));
        }
        return;
      }

      // Successfully loaded profile
    } catch (e) {
      // debugPrint('❌ ProfileViewScreen: Error loading profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'profile_error_loading'.tr(namedArgs: {'error': e.toString()}),
            ),
          ),
        );

        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUserCaptures() async {
    try {
      // Loading captures for user

      if (widget.userId.isEmpty) {
        // debugPrint('❌ ProfileViewScreen: Empty userId for captures');
        return;
      }

      final captures = await _captureService.getCapturesForUser(widget.userId);

      if (mounted) {
        setState(() {
          _userCaptures = captures;
          _isLoadingCaptures = false;
        });
      }

      // Successfully loaded captures
    } catch (e) {
      // debugPrint('❌ ProfileViewScreen: Error loading captures: $e');
      if (mounted) {
        setState(() {
          _isLoadingCaptures = false;
        });
      }
    }
  }

  Future<void> _loadUserAchievements() async {
    try {
      final achievements = await _achievementService.getUserAchievements();
      if (mounted) {
        setState(() {
          _userAchievements = achievements;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading user achievements: $e');
    }
  }

  Future<void> _loadStreakData() async {
    try {
      // Fetch streak data from Firestore stats field
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final stats = userData?['stats'] as Map<String, dynamic>?;
        final categoryStreaks =
            userData?['categoryStreaks'] as Map<String, dynamic>?;

        if (mounted) {
          setState(() {
            _loginStreak = stats?['loginStreak'] as int? ?? 0;
            // Try to get challenge streak from stats or categoryStreaks
            _challengeStreak = stats?['challengeStreak'] as int? ?? 0;

            // Get category streak data
            if (categoryStreaks != null && categoryStreaks.isNotEmpty) {
              // Get the first category with highest streak
              int maxStreak = 0;
              String? topCategory;

              categoryStreaks.forEach((category, data) {
                if (data is Map) {
                  final currentStreak = data['currentStreak'] as int? ?? 0;
                  if (currentStreak > maxStreak) {
                    maxStreak = currentStreak;
                    topCategory = category;
                  }
                }
              });

              _categoryStreak = maxStreak;
              _categoryName = topCategory;
            }
          });
        }
      }
    } catch (e) {
      AppLogger.error('Error loading streak data: $e');
    }
  }

  TextStyle get _heroNameStyle => GoogleFonts.spaceGrotesk(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: Colors.white,
  );

  TextStyle get _heroMetaStyle => GoogleFonts.spaceGrotesk(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Colors.white.withValues(alpha: 0.7),
  );

  TextStyle get _bodyStyle => GoogleFonts.spaceGrotesk(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white.withValues(alpha: 0.9),
  );

  TextStyle get _sectionLabelStyle => GoogleFonts.spaceGrotesk(
    fontSize: 14,
    letterSpacing: 0.6,
    fontWeight: FontWeight.w800,
    color: Colors.white.withValues(alpha: 0.9),
  );

  TextStyle get _tabLabelStyle => GoogleFonts.spaceGrotesk(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
  );

  void _handleEditProfile() {
    if (!widget.isCurrentUser) return;
    Navigator.pushNamed(context, '/profile/edit');
  }

  Future<void> _blockUser() async {
    if (currentUser == null) return;

    try {
      await _connectionService.blockConnection(currentUser!.uid, widget.userId);
      if (mounted) {
        setState(() {
          _isUserBlocked = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile_blocked_success'.tr()),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'profile_block_failed'.tr(namedArgs: {'error': e.toString()}),
            ),
          ),
        );
      }
      AppLogger.error('Error blocking user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final view = _isLoading
        ? const Center(
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22D3EE)),
            ),
          )
        : Column(
            children: [
              HudTopBar(
                title: widget.isCurrentUser ? 'My Profile' : name,
                actions: widget.isCurrentUser
                    ? [
                        IconButton(
                          onPressed: _handleEditProfile,
                          icon: const Icon(Icons.edit, color: Colors.white),
                        ),
                      ]
                    : [],
              ),
              const SizedBox(height: 20),
              Expanded(child: _buildProfileContent()),
            ],
          );

    return MainLayout(
      currentIndex: -1,
      child: WorldBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: view,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        _buildHeroCard(),
        const SizedBox(height: 20),
        _buildActionRow(),
        const SizedBox(height: 20),
        _buildTabSection(),
      ],
    );
  }

  Widget _buildHeroCard() {
    final level = _userModel?.level ?? 1;
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: OptimizedAvatar(
                  imageUrl: profileImageUrl,
                  displayName: name,
                  radius: 46,
                  isVerified: false,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: _heroNameStyle),
                    const SizedBox(height: 4),
                    Text('@$username', style: _heroMetaStyle),
                    const SizedBox(height: 4),
                    Text(cityState, style: _heroMetaStyle),
                  ],
                ),
              ),
              GradientBadge(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'LEVEL $level',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(bio, style: _bodyStyle),
          const SizedBox(height: 20),
          ContentEngagementBar(
            contentId: widget.userId,
            contentType: 'profile',
            initialStats:
                _userModel?.engagementStats ??
                EngagementStats(lastUpdated: DateTime.now()),
            showSecondaryActions: !widget.isCurrentUser,
          ),
          const SizedBox(height: 20),
          LevelProgressBar(
            currentXP: _userModel?.experiencePoints ?? 0,
            level: _userModel?.level ?? 1,
            showDetails: true,
          ),
          const SizedBox(height: 12),
          StreakDisplay(
            loginStreak: _loginStreak,
            challengeStreak: _challengeStreak,
            categoryStreak: _categoryStreak,
            categoryName: _categoryName ?? 'Street Art',
          ),
          const SizedBox(height: 12),
          RecentBadgesCarousel(
            recentBadges: _getRecentBadges(),
            onViewAll: () => _tabController.animateTo(1),
          ),
          const SizedBox(height: 16),
          EnhancedStatsGrid(
            posts: postsCount,
            captures: capturesCount,
            artWalks: _artwalksCompleted,
            likes: _userModel?.engagementStats.likeCount ?? 0,
            shares: _userModel?.engagementStats.shareCount ?? 0,
            comments: _userModel?.engagementStats.commentCount ?? 0,
            followers: _userModel?.engagementStats.followCount ?? 0,
            following: _userModel?.followingCount ?? 0,
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow() {
    final buttons = widget.isCurrentUser
        ? [
            HudButton(
              text: 'Edit Profile',
              icon: Icons.edit_outlined,
              onPressed: _handleEditProfile,
              width: 160,
            ),
            HudButton(
              text: 'My Captures',
              icon: Icons.camera_alt_outlined,
              onPressed: () => Navigator.pushNamed(context, '/captures'),
              width: 160,
            ),
          ]
        : [
            if (!_isUserBlocked)
              HudButton(
                text: 'View Captures',
                icon: Icons.camera_alt_outlined,
                onPressed: () => Navigator.pushNamed(context, '/captures'),
                width: 160,
              ),
            HudButton(
              text: _isUserBlocked ? 'User Blocked' : 'Block User',
              icon: _isUserBlocked ? Icons.block : Icons.block_outlined,
              isPrimary: false,
              onPressed: _isUserBlocked ? null : _blockUser,
              width: 160,
            ),
          ];

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: buttons,
      ),
    );
  }

  Widget _buildTabSection() {
    final tabHeight = MediaQuery.of(context).size.height * 0.55;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profile Journey', style: _sectionLabelStyle),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withValues(alpha: 0.04),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
                ),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
              labelStyle: _tabLabelStyle,
              tabs: const [
                Tab(text: 'CAPTURES'),
                Tab(text: 'ACHIEVEMENTS'),
                Tab(text: 'PROGRESS'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: tabHeight,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCapturesTab(),
                DynamicAchievementsTab(userId: widget.userId),
                ProgressTab(userId: widget.userId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapturesTab() {
    if (_isLoadingCaptures) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22D3EE)),
        ),
      );
    }

    if (_userCaptures.isEmpty) {
      return _buildEmptyCapturesState();
    }

    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 12),
      physics: const BouncingScrollPhysics(),
      itemCount: _userCaptures.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, index) => _buildCaptureTile(_userCaptures[index]),
    );
  }

  Widget _buildCaptureTile(CaptureModel capture) {
    final imageProvider = ImageUrlValidator.isValidImageUrl(capture.imageUrl)
        ? ImageUrlValidator.safeNetworkImage(capture.imageUrl)
        : null;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/capture/detail',
          arguments: {'captureId': capture.id},
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            color: Colors.white.withValues(alpha: 0.04),
          ),
          child: Stack(
            children: [
              if (imageProvider != null)
                Positioned.fill(
                  child: Image(image: imageProvider, fit: BoxFit.cover),
                ),
              if (imageProvider == null)
                Positioned.fill(
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 36,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xAA05030C)],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      capture.title ?? 'Untitled Capture',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      capture.locationName ?? capture.artType ?? 'Artbeat',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCapturesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 46,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text('No captures yet', style: _bodyStyle),
          const SizedBox(height: 6),
          Text(
            'Start capturing to showcase your art trail.',
            style: _heroMetaStyle,
            textAlign: TextAlign.center,
          ),
          if (widget.isCurrentUser) ...[
            const SizedBox(height: 16),
            HudButton(
              text: 'Launch Capture',
              icon: Icons.bolt_outlined,
              onPressed: () => Navigator.pushNamed(context, '/captures'),
              width: 190,
            ),
          ],
        ],
      ),
    );
  }

  List<BadgeData> _getRecentBadges() {
    if (_userAchievements.isEmpty) {
      return [];
    }

    return _userAchievements.take(3).map((achievement) {
      return BadgeData(
        id: achievement['id'] as String? ?? '',
        name: achievement['title'] as String? ?? 'Achievement',
        description: achievement['description'] as String? ?? '',
        icon: _getAchievementIcon(achievement['type'] as String? ?? ''),
        earnedAt:
            (achievement['earnedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        category: _getAchievementCategory(achievement['type'] as String? ?? ''),
      );
    }).toList();
  }

  String _getAchievementIcon(String type) {
    switch (type.toLowerCase()) {
      case 'first_walk':
        return '🚶';
      case 'first_capture':
        return '📸';
      case 'first_post':
        return '📝';
      case 'first_follow':
        return '👥';
      case 'level_up':
        return '⭐';
      default:
        return '🏆';
    }
  }

  String _getAchievementCategory(String type) {
    switch (type.toLowerCase()) {
      case 'first_walk':
      case 'ten_walks':
        return 'Quest';
      case 'first_capture':
      case 'first_post':
        return 'Creator';
      case 'first_follow':
      case 'ten_followers':
        return 'Social';
      default:
        return 'Quest';
    }
  }
}
