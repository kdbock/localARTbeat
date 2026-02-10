import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart' show WalkStatus;
import 'package:artbeat_artwork/artbeat_artwork.dart';
import 'package:artbeat_artist/artbeat_artist.dart' as artist;
import 'package:artbeat_core/artbeat_core.dart' hide ArtworkModel;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:easy_localization/easy_localization.dart';

/// Screen for reading written content (books, stories, etc.)
class WrittenContentDetailScreen extends StatefulWidget {
  final String artworkId;

  const WrittenContentDetailScreen({super.key, required this.artworkId});

  @override
  State<WrittenContentDetailScreen> createState() =>
      _WrittenContentDetailScreenState();
}

class _WrittenContentDetailScreenState
    extends State<WrittenContentDetailScreen> {
  static const int _freeChapterLimit = 3;
  static const double _perChapterPrice = 1.0;
  static const double _fullBookPrice = 20.0;

  final ArtworkService _artworkService = ArtworkService();
  final ChapterService _chapterService = ChapterService();
  final artist.SubscriptionService _subscriptionService =
      artist.SubscriptionService();
  final artist.VisibilityService _visibilityService =
      artist.VisibilityService();
  final UnifiedPaymentService _paymentService = UnifiedPaymentService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  ArtworkModel? _artwork;
  ArtistProfileModel? _artist;
  List<ChapterModel> _chapters = [];
  ChapterModel? _currentChapter;
  int _currentChapterIndex = 0;
  String? _fallbackArtistName;
  bool _isOwner = false;
  bool _hasAccess = false;
  bool _isAdmin = false;
  bool _hasEngagementUnlock = false;
  bool _hasFullBookPurchase = false;
  int _captureCount = 0;
  int _discoveryCount = 0;
  int _walksCompleted = 0;
  final Set<String> _purchasedChapterIds = {};

  // Reading progress
  final ScrollController _scrollController = ScrollController();
  bool _isDescriptionExpanded = false;
  bool _isChapterExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _meetsEngagementUnlockCriteria({
    required int captures,
    required int discoveries,
    required int walksCompleted,
  }) {
    return captures >= 3 || discoveries >= 3 || walksCompleted >= 1;
  }

  bool _isArtworkFree(ArtworkModel artwork) {
    return !artwork.isForSale || (artwork.price ?? 0) <= 0;
  }

  bool _isChapterUnlocked(ChapterModel chapter) {
    if (_isOwner || _isAdmin) return true;
    if (_hasAccess) return true;
    final chapterNumber = chapter.episodeNumber ?? chapter.chapterNumber;
    if (_hasEngagementUnlock && chapterNumber <= _freeChapterLimit) {
      return true;
    }

    return _purchasedChapterIds.contains(chapter.id);
  }

  Future<void> _loadPurchaseStatus() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      _hasFullBookPurchase = false;
      _purchasedChapterIds.clear();
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('artwork_sales')
          .where('buyerId', isEqualTo: uid)
          .where('artworkId', isEqualTo: widget.artworkId)
          .get();

      bool hasFullBookPurchase = false;
      final purchasedChapterIds = <String>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status']?.toString().toLowerCase();
        if (status != null && status != 'completed' && status != 'success') {
          continue;
        }

        final purchaseType = data['purchaseType']?.toString().toLowerCase();
        final isFullBook =
            data['isFullBook'] == true || data['fullBook'] == true;
        final chapterId = data['chapterId']?.toString();
        final chapterNumber = data['chapterNumber'] as int?;

        if (purchaseType == 'full_book' || isFullBook) {
          hasFullBookPurchase = true;
          continue;
        }

        if (chapterId != null && chapterId.isNotEmpty) {
          purchasedChapterIds.add(chapterId);
          continue;
        }

        if (chapterNumber != null) {
          for (final chapter in _chapters) {
            final number = chapter.episodeNumber ?? chapter.chapterNumber;
            if (number == chapterNumber) {
              purchasedChapterIds.add(chapter.id);
              break;
            }
          }
        }
      }

      _hasFullBookPurchase = hasFullBookPurchase;
      _purchasedChapterIds
        ..clear()
        ..addAll(purchasedChapterIds);
    } catch (e) {
      AppLogger.error('❌ Error loading purchase status: $e');
      _hasFullBookPurchase = false;
      _purchasedChapterIds.clear();
    }
  }

  Future<void> _loadEngagementUnlockStatus() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      _captureCount = 0;
      _discoveryCount = 0;
      _walksCompleted = 0;
      _hasEngagementUnlock = false;
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final captureCountFuture = firestore
          .collection('captures')
          .where('userId', isEqualTo: uid)
          .count()
          .get();
      final discoveryCountFuture = firestore
          .collection('users')
          .doc(uid)
          .collection('discoveries')
          .count()
          .get();
      final walksCompletedFuture = firestore
          .collection('artWalkProgress')
          .where('userId', isEqualTo: uid)
          .where('status', isEqualTo: WalkStatus.completed.name)
          .count()
          .get();

      final results = await Future.wait([
        captureCountFuture,
        discoveryCountFuture,
        walksCompletedFuture,
      ]);

      final captures = results[0].count ?? 0;
      final discoveries = results[1].count ?? 0;
      final walksCompleted = results[2].count ?? 0;

      _captureCount = captures;
      _discoveryCount = discoveries;
      _walksCompleted = walksCompleted;
      _hasEngagementUnlock = _meetsEngagementUnlockCriteria(
        captures: captures,
        discoveries: discoveries,
        walksCompleted: walksCompleted,
      );
      AppLogger.info(
        '🎯 Engagement status: captures=$_captureCount, discoveries=$_discoveryCount, walks=$_walksCompleted, hasUnlock=$_hasEngagementUnlock',
      );
    } catch (e) {
      AppLogger.error('❌ Error checking engagement unlock status: $e');
      _captureCount = 0;
      _discoveryCount = 0;
      _walksCompleted = 0;
      _hasEngagementUnlock = false;
      AppLogger.info(
        '🎯 Engagement status reset: captures=$_captureCount, discoveries=$_discoveryCount, walks=$_walksCompleted, hasUnlock=$_hasEngagementUnlock',
      );
    }
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load artwork details
      final artwork = await _artworkService.getArtworkById(widget.artworkId);
      if (artwork == null) {
        throw Exception('Artwork not found');
      }

      // Check if this is written content
      if (artwork.contentType != ArtworkContentType.written) {
        throw Exception('This artwork is not written content');
      }

      _artwork = artwork;

      // Check ownership and access
      final currentUser = _auth.currentUser;
      _isOwner = currentUser?.uid == artwork.userId ||
          currentUser?.uid == artwork.artistProfileId;

      // Check if user is admin - more robust check
      try {
        final uid = currentUser?.uid ?? '';
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        final userData = userDoc.data();

        // Check multiple possible admin field names and values
        final userType = userData?['userType']?.toString().toLowerCase() ?? '';
        final role = userData?['role']?.toString().toLowerCase() ?? '';
        final isAdmin = userData?['isAdmin'] as bool? ?? false;

        _isAdmin = userType == 'admin' || role == 'admin' || isAdmin;
        AppLogger.info(
          '🔑 Admin check for UID $uid: userType=$userType, role=$role, isAdmin=$isAdmin, result=$_isAdmin',
        );
        AppLogger.info('📋 Full user data: $userData');
      } catch (e) {
        AppLogger.error('❌ Error checking admin status: $e');
        _isAdmin = false;
      }

      // Load artist info
      try {
        final artistProfile = await _subscriptionService.getArtistProfileById(
          artwork.artistProfileId,
        );
        _artist = artistProfile;

        // If artist profile not found, try to get user information as fallback
        if (artistProfile == null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(artwork.artistProfileId)
              .get();
          final userData = userDoc.data();
          _fallbackArtistName =
              (userData?['fullName'] as String?) ??
              (userData?['displayName'] as String?) ??
              'Unknown Artist';
        }
      } catch (e) {
        _fallbackArtistName = 'Unknown Artist';
      }

      // Load chapters if serialized or has multiple chapters
      // Fallback: always try for written content to ensure visibility
      if (artwork.isSerializing ||
          (artwork.totalChapters ?? 0) > 0 ||
          artwork.contentType == ArtworkContentType.written) {
        // getChaptersForArtwork now handles all filtering logic for public/author/moderator
        _chapters = await _chapterService.getChaptersForArtwork(
          widget.artworkId,
          currentUserId: _auth.currentUser?.uid,
          isModerator: _isAdmin,
        );
        _chapters.sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));

        if (_chapters.isNotEmpty) {
          _currentChapter = _chapters[0];
        }
      }

      // Load engagement unlock status
      if (!_isOwner) {
        await _loadEngagementUnlockStatus();
      }

      // Load purchase status (full book + chapter purchases)
      if (!_isOwner) {
        await _loadPurchaseStatus();
      }

      // Full-book access only (chapters 1-3 still gated by engagement unless purchased)
      if (_isOwner || _isAdmin) {
        _hasAccess = true;
        AppLogger.info('✅ Access granted: owner/admin');
      } else if (_isArtworkFree(artwork)) {
        _hasAccess = true;
        AppLogger.info('📖 Full book is free: access granted');
      } else if (_hasFullBookPurchase) {
        _hasAccess = true;
        AppLogger.info('💳 Full book purchase detected: access granted');
      } else {
        _hasAccess = false;
        AppLogger.info('🔒 Full book locked: access denied');
      }

      AppLogger.info(
        'Final access: _isOwner=$_isOwner, isForSale=${artwork.isForSale}, price=${artwork.price}, _hasAccess=$_hasAccess, hasEngagement=$_hasEngagementUnlock, purchasedChapters=${_purchasedChapterIds.length}',
      );

      // Track view analytics
      await _visibilityService.trackArtworkView(
        artworkId: widget.artworkId,
        artistId: artwork.artistProfileId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'art_walk_error_loading_content'.tr().replaceAll(
                '{error}',
                e.toString(),
              ),
            ),
          ),
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

  void _navigateToChapter(int index) {
    if (index >= 0 && index < _chapters.length) {
      setState(() {
        _currentChapterIndex = index;
        _currentChapter = _chapters[index];
        _isChapterExpanded = true;
      });
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      backgroundColor: Colors.black,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: _shareContent,
        ),
        if (_isOwner)
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => Navigator.pushNamed(
              context,
              '/artwork/edit',
              arguments: _artwork,
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Blurred Background
            if (_artwork?.imageUrl != null)
              Image.network(
                _artwork!.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(color: Colors.black.withValues(alpha: 0.6)),
            ),

            // Immersive Vertical Cover
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 40),
                height: 220,
                width: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child:
                      _artwork?.imageUrl != null
                          ? Image.network(_artwork!.imageUrl, fit: BoxFit.cover)
                          : Container(
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.book,
                                size: 64,
                                color: Colors.white54,
                              ),
                            ),
                ),
              ),
            ),

            // Title and Author in Header
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  Text(
                    _artwork?.title ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      if (_artist != null) {
                        Navigator.pushNamed(
                          context,
                          '/artist/profile',
                          arguments: _artist!.id,
                        );
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundImage: ImageUrlValidator.safeNetworkImage(
                            _artist?.profileImageUrl,
                          ),
                          child:
                              !ImageUrlValidator.isValidImageUrl(
                                _artist?.profileImageUrl,
                              )
                              ? Text(
                                  (_artist?.displayName ??
                                          _fallbackArtistName ??
                                          'A')[0]
                                      .toUpperCase(),
                                  style: const TextStyle(fontSize: 10),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _artist?.displayName ??
                              _fallbackArtistName ??
                              'Unknown Artist',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
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
      ),
    );
  }

  Widget _buildContentHeader() {
    final metadata = _artwork?.writingMetadata;
    final hook = metadata?.shortHook;
    final status = metadata?.storyStatus ?? 'Ongoing';

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hook section
          if (hook != null && hook.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Text(
                hook,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),

          // Metadata row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetaItem(
                  Icons.layers_outlined,
                  '${_chapters.length}',
                  'Chapters',
                ),
                _buildMetaItem(
                  Icons.schedule_outlined,
                  '${metadata?.estimatedReadMinutes ?? 0}',
                  'Min Read',
                ),
                _buildMetaItem(Icons.info_outline, status, 'Status'),
              ],
            ),
          ),

          const Divider(indent: 20, endIndent: 20),

          // Collapsible Description
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About this Story',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Stack(
                  children: [
                    Text(
                      _artwork!.description,
                      maxLines: _isDescriptionExpanded ? null : 4,
                      overflow:
                          _isDescriptionExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                    if (!_isDescriptionExpanded)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.only(left: 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Theme.of(
                                  context,
                                ).colorScheme.surface.withValues(alpha: 0),
                                Theme.of(context).colorScheme.surface,
                              ],
                            ),
                          ),
                          child: TextButton(
                            onPressed:
                                () => setState(
                                  () => _isDescriptionExpanded = true,
                                ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Read More'),
                          ),
                        ),
                      ),
                  ],
                ),
                if (_isDescriptionExpanded)
                  TextButton(
                    onPressed: () => setState(() => _isDescriptionExpanded = false),
                    child: const Text('Show Less'),
                  ),
              ],
            ),
          ),

          const Divider(thickness: 8, color: Color(0xFFF5F5F5)),

          // Chapters Widget Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chapters',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_chapters.length} Total',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }


  Widget _buildChaptersList() {
    if (_chapters.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: Text('No chapters released yet.')),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final chapter = _chapters[index];
        final chapterNumber = chapter.episodeNumber ?? chapter.chapterNumber;
        final isUnlocked = _isChapterUnlocked(chapter);
        final isSelected = index == _currentChapterIndex;
        final isEngagementLocked =
            !_hasAccess &&
            !_isOwner &&
            !_isAdmin &&
            !_hasEngagementUnlock &&
            chapterNumber <= _freeChapterLimit &&
            !isUnlocked;
        final isPaidChapter = chapterNumber > _freeChapterLimit;

        return InkWell(
          onTap: () {
            if (isUnlocked) {
              _navigateToChapter(index);
            } else {
              _showUnlockBottomSheet(chapter);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.withValues(alpha: 0.05) : null,
              border: Border(
                bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
              ),
            ),
            child: Row(
              children: [
                // Chapter Number
                Container(
                  width: 40,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${chapter.episodeNumber ?? chapter.chapterNumber}',
                    style: TextStyle(
                      color: isSelected ? Colors.blue : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),

                // Chapter Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter.title,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 16,
                          color: isSelected ? Colors.blue : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${chapter.estimatedReadingTime} min',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (isPaidChapter && !isUnlocked)
                            Row(
                              children: [
                                Icon(
                                  Icons.monetization_on,
                                  size: 14,
                                  color: Colors.orange[300],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '\$${_perChapterPrice.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: Colors.orange[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          if (isEngagementLocked)
                            Row(
                              children: [
                                Icon(
                                  Icons.verified,
                                  size: 14,
                                  color: Colors.blue[300],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Engagement Unlock',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          if (_isOwner && !chapter.isReleased)
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit_note,
                                    size: 14,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Draft',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          // Moderation Status (only for owner/admin)
                          if ((_isOwner || _isAdmin) && chapter.moderationStatus != ChapterModerationStatus.approved)
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: chapter.moderationStatus == ChapterModerationStatus.rejected 
                                      ? Colors.red.withValues(alpha: 0.1) 
                                      : Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  chapter.moderationStatus.displayName,
                                  style: TextStyle(
                                    color: chapter.moderationStatus == ChapterModerationStatus.rejected 
                                        ? Colors.red 
                                        : Colors.orange,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action Icon
                if (!isUnlocked)
                  Icon(Icons.lock_outline, color: Colors.grey[400], size: 20)
                else if (isSelected)
                  const Icon(Icons.play_circle_fill, color: Colors.blue, size: 24)
                else
                  Icon(Icons.play_circle_outline, color: Colors.grey[400], size: 24),
              ],
            ),
          ),
        );
      },
        childCount: _chapters.length,
      ),
    );
  }

  void _showUnlockBottomSheet(ChapterModel chapter) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final chapterNumber = chapter.episodeNumber ?? chapter.chapterNumber;
        final isEngagementEligible =
            _hasEngagementUnlock && chapterNumber <= _freeChapterLimit;

        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Icon(Icons.lock_open, size: 48, color: Colors.blue),
              const SizedBox(height: 16),
              Text(
                'Unlock Chapter ${chapter.episodeNumber ?? chapter.chapterNumber}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isEngagementEligible
                    ? 'You already qualify to unlock this chapter.'
                    : 'This chapter requires payment to read. Unlock it now to continue the story.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed:
                      isEngagementEligible
                          ? () {
                            Navigator.pop(context);
                            _navigateToChapter(
                              _chapters.indexWhere(
                                (c) => c.id == chapter.id,
                              ),
                            );
                          }
                          : () {
                            Navigator.pop(context);
                            _purchaseChapter(chapter);
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isEngagementEligible
                        ? 'Read Chapter ${chapterNumber}'
                        : 'Unlock for \$${_perChapterPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _purchaseFullBook();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Unlock Full Book for \$${_fullBookPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Maybe Later'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReadingView() {
    if (_currentChapter == null) return const SliverToBoxAdapter(child: SizedBox.shrink());

    if (!_isChapterUnlocked(_currentChapter!)) {
      final chapterNumber =
          _currentChapter!.episodeNumber ?? _currentChapter!.chapterNumber;
      final bool isEngagementLocked =
          !_hasEngagementUnlock && chapterNumber <= _freeChapterLimit;

      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                const Icon(Icons.lock, size: 48, color: Colors.blue),
                const SizedBox(height: 16),
                Text(
                  'Chapter $chapterNumber is locked',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isEngagementLocked
                      ? 'Complete 3 captures, 3 discoveries, or 1 art walk to unlock Chapters 1–3 for free. You can also unlock this chapter for \$${_perChapterPrice.toStringAsFixed(0)} or get the full book for \$${_fullBookPrice.toStringAsFixed(0)}.'
                      : 'Unlock this chapter for \$${_perChapterPrice.toStringAsFixed(0)} or get the full book for \$${_fullBookPrice.toStringAsFixed(0)}.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _showUnlockBottomSheet(_currentChapter!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Unlock Options'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chapter ${_currentChapter!.episodeNumber ?? _currentChapter!.chapterNumber}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentChapter!.title,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: _isChapterExpanded ? 'Minimize' : 'Expand',
                  icon: Icon(
                    _isChapterExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[700],
                  ),
                  onPressed: () {
                    setState(() {
                      _isChapterExpanded = !_isChapterExpanded;
                    });
                  },
                ),
              ],
            ),
            if (_isChapterExpanded) ...[
              const SizedBox(height: 32),
              MarkdownBody(
                data: _currentChapter!.content,
                styleSheet: MarkdownStyleSheet(
                  p: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.8,
                    fontSize: 18,
                    color: Colors.grey[800],
                  ),
                  h1: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                  blockquote: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                  blockquoteDecoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Colors.blue[100]!, width: 4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 60),
              _buildNextChapterCard(),
              const SizedBox(height: 100), // Padding for floating button
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNextChapterCard() {
    if (_currentChapterIndex >= _chapters.length - 1) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 48),
            SizedBox(height: 16),
            Text(
              'You\'ve caught up!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Stay tuned for more chapters coming soon.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final nextChapter = _chapters[_currentChapterIndex + 1];
    final isUnlocked = _isChapterUnlocked(nextChapter);

    return InkWell(
      onTap: () {
        if (isUnlocked) {
          _navigateToChapter(_currentChapterIndex + 1);
        } else {
          _showUnlockBottomSheet(nextChapter);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[600]!, Colors.blue[800]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NEXT CHAPTER',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chapter ${nextChapter.episodeNumber ?? nextChapter.chapterNumber}: ${nextChapter.title}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    if (_currentChapter == null) return const SizedBox.shrink();

    final isUnlocked = _isChapterUnlocked(_currentChapter!);
    final String label = isUnlocked
      ? (_currentChapterIndex == 0
        ? 'START READING'
        : 'CONTINUE CH. ${_currentChapterIndex + 1}')
      : 'UNLOCK CH. ${_currentChapterIndex + 1}';

    return Positioned(
      bottom: 24,
      left: 32,
      right: 32,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            if (!isUnlocked) {
              _showUnlockBottomSheet(_currentChapter!);
              return;
            }

            if (!_isChapterExpanded) {
              setState(() {
                _isChapterExpanded = true;
              });
            }

            _scrollController.animateTo(
              600,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 0,
          ),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Future<void> _shareContent() async {
    final title = _artwork?.title ?? 'Written Content';
    final url = 'https://artbeat.app/artwork/${widget.artworkId}';

    // ignore: deprecated_member_use
    await Share.share('$title\n\n$url');
  }

  Future<void> _purchaseChapter(ChapterModel chapter) async {
    if (_artwork == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      const double totalAmount = _perChapterPrice;
      final chapterNumber = chapter.episodeNumber ?? chapter.chapterNumber;

      // 1. Create payment intent on the backend
      final intentData = await _paymentService.createPaymentIntent(
        amount: totalAmount,
        currency: 'USD',
        description:
            'Unlock chapter $chapterNumber of ${_artwork!.title}',
        metadata: {
          'artworkId': widget.artworkId,
          'artistId': _artwork!.artistProfileId,
          'contentType': 'written',
          'purchaseType': 'chapter',
          'chapterId': chapter.id,
          'chapterNumber': chapterNumber,
        },
      );

      final String? clientSecret = intentData['clientSecret'] as String?;
      final String? paymentIntentId = intentData['paymentIntentId'] as String?;

      if (clientSecret == null || paymentIntentId == null) {
        throw Exception('Failed to initialize payment intent');
      }

      // 2. Initialize the payment sheet
      await _paymentService.initPaymentSheetForPayment(
        paymentIntentClientSecret: clientSecret,
      );

      // 3. Present the payment sheet
      await _paymentService.presentPaymentSheet();

      // 4. Complete purchase on backend
      final result = await _paymentService.processArtworkSalePayment(
        artworkId: widget.artworkId,
        artistId: _artwork!.artistProfileId,
        amount: totalAmount,
        paymentIntentId: paymentIntentId,
      );

      if (result.success) {
        if (!mounted) return;
        _purchasedChapterIds.add(chapter.id);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Payment successful!')));

        setState(() {});
      } else {
        throw Exception(result.error ?? 'Payment verification failed');
      }
    } catch (e) {
      late final String errorMessage;
      if (e.runtimeType.toString().contains('StripeException')) {
        errorMessage = e.toString().contains('cancelled')
            ? 'Payment was cancelled'
            : 'Payment failed';
      } else {
        errorMessage = e.toString();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Purchase failed: $errorMessage')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _purchaseFullBook() async {
    if (_artwork == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      const double totalAmount = _fullBookPrice;

      // 1. Create payment intent on the backend
      final intentData = await _paymentService.createPaymentIntent(
        amount: totalAmount,
        currency: 'USD',
        description: 'Unlock full book: ${_artwork!.title}',
        metadata: {
          'artworkId': widget.artworkId,
          'artistId': _artwork!.artistProfileId,
          'contentType': 'written',
          'purchaseType': 'full_book',
        },
      );

      final String? clientSecret = intentData['clientSecret'] as String?;
      final String? paymentIntentId = intentData['paymentIntentId'] as String?;

      if (clientSecret == null || paymentIntentId == null) {
        throw Exception('Failed to initialize payment intent');
      }

      // 2. Initialize the payment sheet
      await _paymentService.initPaymentSheetForPayment(
        paymentIntentClientSecret: clientSecret,
      );

      // 3. Present the payment sheet
      await _paymentService.presentPaymentSheet();

      // 4. Complete purchase on backend
      final result = await _paymentService.processArtworkSalePayment(
        artworkId: widget.artworkId,
        artistId: _artwork!.artistProfileId,
        amount: totalAmount,
        paymentIntentId: paymentIntentId,
      );

      if (result.success) {
        if (!mounted) return;
        _hasFullBookPurchase = true;
        _hasAccess = true;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Payment successful!')));

        setState(() {});
      } else {
        throw Exception(result.error ?? 'Payment verification failed');
      }
    } catch (e) {
      late final String errorMessage;
      if (e.runtimeType.toString().contains('StripeException')) {
        errorMessage = e.toString().contains('cancelled')
            ? 'Payment was cancelled'
            : 'Payment failed';
      } else {
        errorMessage = e.toString();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Purchase failed: $errorMessage')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.info(
      '🎬 WrittenContentDetailScreen BUILD called: _isLoading=$_isLoading, _hasAccess=$_hasAccess, _isAdmin=$_isAdmin',
    );

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_artwork == null) {
      return Scaffold(
        appBar: AppBar(title: Text('art_walk_content_not_found'.tr())),
        body: Center(child: Text('art_walk_content_not_found'.tr())),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildAppBar(),
              _buildContentHeader(),
              _buildReadingView(),
              _buildChaptersList(),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
          _buildFloatingActionButton(),
        ],
      ),
    );
  }
}

