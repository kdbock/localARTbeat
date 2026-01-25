import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/artbeat_core.dart';

import '../../models/group_models.dart';
import '../../models/post_model.dart';
import '../../services/art_community_service.dart';
import '../../widgets/enhanced_post_card.dart';
import 'create_group_post_screen.dart';

class _Palette {
  static const Color textPrimary = Color(0xF2FFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color textTertiary = Color(0x8AFFFFFF);
  static const Color purple = Color(0xFF7C4DFF);
  static const Color teal = Color(0xFF22D3EE);
}

/// Group feed screen showing posts from a specific group
class GroupFeedScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupFeedScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupFeedScreen> createState() => _GroupFeedScreenState();
}

class _GroupFeedScreenState extends State<GroupFeedScreen> {
  final ArtCommunityService _communityService = ArtCommunityService();
  List<PostModel> _posts = [];
  bool _isLoading = true;
  bool _isMember = false;
  bool _checkingMembership = true;
  bool _isJoining = false;
  bool _isLeaving = false;
  GroupType? _groupType;

  @override
  void initState() {
    super.initState();
    _checkMembership();
    _loadGroupType();
    _loadGroupPosts();
  }

  @override
  void dispose() {
    _communityService.dispose();
    super.dispose();
  }

  Future<void> _checkMembership() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _isMember = false;
        _checkingMembership = false;
      });
      return;
    }

    try {
      final membershipDoc = await FirebaseFirestore.instance
          .collection('groupMembers')
          .where('groupId', isEqualTo: widget.groupId)
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (!mounted) return;
      setState(() {
        _isMember = membershipDoc.docs.isNotEmpty;
        _checkingMembership = false;
      });
    } catch (e) {
      AppLogger.error('Error checking group membership: $e');
      if (!mounted) return;
      setState(() => _checkingMembership = false);
    }
  }

  Future<void> _loadGroupType() async {
    try {
      final groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (!groupDoc.exists) return;
      final data = groupDoc.data();
      final groupTypeString = data?['groupType'] as String?;
      if (groupTypeString == null) return;

      final type = GroupType.values.firstWhere(
        (value) => value.value == groupTypeString,
        orElse: () => GroupType.artist,
      );

      if (!mounted) return;
      setState(() => _groupType = type);
    } catch (e) {
      AppLogger.error('Error loading group type: $e');
    }
  }

  Future<void> _loadGroupPosts() async {
    setState(() => _isLoading = true);

    try {
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('groupId', isEqualTo: widget.groupId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final posts = postsSnapshot.docs
          .map(PostModel.fromDocument)
          .toList(growable: false);

      if (!mounted) return;
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Error loading group posts: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _joinGroup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('community_group_feed.join_sign_in_required'.tr());
      return;
    }

    setState(() => _isJoining = true);

    try {
      await FirebaseFirestore.instance.collection('groupMembers').add({
        'groupId': widget.groupId,
        'userId': user.uid,
        'role': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
      });

      final groupRef = FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId);
      await groupRef.update({'memberCount': FieldValue.increment(1)});

      if (!mounted) return;
      setState(() {
        _isMember = true;
        _isJoining = false;
      });

      _showSnackBar(
        'community_group_feed.join_success'.tr(
          namedArgs: {'group': widget.groupName},
        ),
      );

      await _loadGroupPosts();
    } catch (e) {
      AppLogger.error('Error joining group: $e');
      if (!mounted) return;
      setState(() => _isJoining = false);
      _showSnackBar('community_group_feed.join_error'.tr());
    }
  }

  Future<void> _leaveGroup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLeaving = true);

    try {
      final membershipDocs = await FirebaseFirestore.instance
          .collection('groupMembers')
          .where('groupId', isEqualTo: widget.groupId)
          .where('userId', isEqualTo: user.uid)
          .get();

      for (final doc in membershipDocs.docs) {
        await doc.reference.delete();
      }

      final groupRef = FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId);
      await groupRef.update({'memberCount': FieldValue.increment(-1)});

      if (!mounted) return;
      setState(() {
        _isMember = false;
        _isLeaving = false;
      });

      _showSnackBar(
        'community_group_feed.leave_success'.tr(
          namedArgs: {'group': widget.groupName},
        ),
      );
    } catch (e) {
      AppLogger.error('Error leaving group: $e');
      if (!mounted) return;
      setState(() => _isLeaving = false);
      _showSnackBar('community_group_feed.leave_error'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupArgs = {'group': widget.groupName};
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: HudTopBar(
        title: 'community_group_feed.app_bar'.tr(namedArgs: groupArgs),
        actions: [
          IconButton(
            tooltip: 'community_group_feed.refresh_cta'.tr(),
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: (_isLoading || _checkingMembership)
                ? null
                : _loadGroupPosts,
          ),
        ],
        subtitle: '',
      ),
      body: WorldBackground(
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: _buildBody(groupArgs, bottomInset),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(Map<String, String> groupArgs, double bottomInset) {
    if (_checkingMembership) {
      return _buildLoadingPanel(
        'community_group_feed.membership_checking'.tr(),
      );
    }

    if (!_isMember) {
      return _buildJoinExperience(groupArgs);
    }

    return _buildMemberFeed(groupArgs, bottomInset);
  }

  Widget _buildMemberFeed(Map<String, String> groupArgs, double bottomInset) {
    final children = <Widget>[
      _buildHeroCard(groupArgs),
      const SizedBox(height: 16),
    ];

    if (_isLoading) {
      children.add(_buildLoadingCard());
    } else if (_posts.isEmpty) {
      children.add(_buildEmptyState());
    } else {
      children.addAll(
        _posts.map(
          (post) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: EnhancedPostCard(
              post: post,
              communityService: _communityService,
              onLike: () => _handleLike(post),
              onShare: () => _handleShare(post),
            ),
          ),
        ),
      );
    }

    children.add(SizedBox(height: bottomInset + 32));

    return RefreshIndicator(
      onRefresh: _loadGroupPosts,
      color: _Palette.purple,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: children,
      ),
    );
  }

  Widget _buildHeroCard(Map<String, String> groupArgs) {
    final typeTitle = _resolveGroupTypeTitle();
    final typeDescription = _resolveGroupTypeDescription();

    return GlassCard(
      padding: const EdgeInsets.all(24),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientBadge(
            child: Text(
              typeTitle,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'community_group_feed.hero_title'.tr(namedArgs: groupArgs),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _Palette.textPrimary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'community_group_feed.hero_subtitle'.tr(
              namedArgs: {'type': typeTitle},
            ),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _Palette.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            typeDescription,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _Palette.textTertiary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(
                  'community_group_feed.posts_label'.tr(),
                  _posts.length.toString(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatTile(
                  'community_group_feed.membership_label'.tr(),
                  _membershipStatusLabel(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GradientCTAButton(
                  text: 'community_group_feed.create_cta'.tr(),
                  onPressed: _isLoading
                      ? null
                      : () => _createGroupPost(context),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 148,
                child: HudButton.destructive(
                  text: 'community_group_feed.leave_cta'.tr(),
                  icon: Icons.logout,
                  onPressed: _isLeaving ? null : _leaveGroup,
                  isLoading: _isLeaving,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _Palette.textTertiary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _Palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingPanel(String label) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(_Palette.teal),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _Palette.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(_Palette.purple),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'community_group_feed.loading_label'.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _Palette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinExperience(Map<String, String> groupArgs) {
    final typeDescription = _resolveGroupTypeDescription();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: GlassCard(
            padding: const EdgeInsets.all(32),
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GradientBadge(
                  child: Text(
                    'community_group_feed.members_badge'.tr(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: const Icon(
                    Icons.groups_2,
                    size: 56,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'community_group_feed.join_prompt_title'.tr(
                    namedArgs: groupArgs,
                  ),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _Palette.textPrimary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'community_group_feed.join_prompt_subtitle'.tr(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _Palette.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  typeDescription,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _Palette.textTertiary,
                  ),
                ),
                const SizedBox(height: 32),
                GradientCTAButton(
                  text: 'community_group_feed.join_cta'.tr(),
                  onPressed: _isJoining ? null : _joinGroup,
                  isLoading: _isJoining,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: const Icon(
              Icons.article_outlined,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'community_group_feed.empty_title'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _Palette.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'community_group_feed.empty_subtitle'.tr(),
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _Palette.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _createGroupPost(BuildContext context) {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (context) => CreateGroupPostScreen(
              groupType: _groupType ?? GroupType.artist,
              postType: 'update',
              groupId: widget.groupId,
            ),
          ),
        )
        .then((_) => _loadGroupPosts());
  }

  void _handleLike(PostModel post) {
    AppLogger.info('Liked post: ${post.id}');
  }

  void _handleShare(PostModel post) {
    AppLogger.info('Shared post: ${post.id}');
  }

  String _membershipStatusLabel() {
    return _isMember
        ? 'community_group_feed.membership_active'.tr()
        : 'community_group_feed.membership_guest'.tr();
  }

  String _resolveGroupTypeTitle() {
    final typeKey = _groupType?.value ?? 'unknown';
    final key = 'community_group_feed.group_type_${typeKey}_title';
    final translated = key.tr();
    if (translated == key) {
      return 'community_group_feed.group_type_unknown_title'.tr();
    }
    return translated;
  }

  String _resolveGroupTypeDescription() {
    final typeKey = _groupType?.value ?? 'unknown';
    final key = 'community_group_feed.group_type_${typeKey}_description';
    final translated = key.tr();
    if (translated == key) {
      return 'community_group_feed.group_type_unknown_description'.tr();
    }
    return translated;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
