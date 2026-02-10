import 'package:artbeat_artwork/artbeat_artwork.dart'
    show ArtworkCleanupService;
import 'package:artbeat_core/artbeat_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.useScaffold = true});

  final bool useScaffold;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final UserService _userService = UserService();

  UserModel? _currentUserModel;
  _NotificationFilter _activeFilter = _NotificationFilter.all;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userModel = await _userService.getUserModel(user.uid);
      if (mounted) {
        setState(() => _currentUserModel = userModel);
      }
    } on Exception catch (e) {
      AppLogger.error('Error loading user model: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return _buildWorldShell(
        Column(
          children: [
            _buildHudTopBar(showActions: false),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GlassCard(
                  margin: const EdgeInsets.only(top: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 48,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'notifications_login_required'.tr(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _buildWorldShell(
      Column(
        children: [
          _buildHudTopBar(showActions: true),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildFilterBar(),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildNotificationsStream(user),
            ),
          ),
          if (_isAdminUser() && kDebugMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: _buildDebugTools(),
            ),
        ],
      ),
    );
  }

  Widget _buildWorldShell(Widget child) {
    final content = WorldBackground(child: SafeArea(top: false, child: child));

    if (widget.useScaffold) {
      return Scaffold(backgroundColor: const Color(0xFF07060F), body: content);
    }

    return content;
  }

  Widget _buildHudTopBar({required bool showActions}) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    child: HudTopBar(
      title: 'notifications_title'.tr(),
      onBackPressed: () => Navigator.of(context).maybePop(),
      actions: showActions ? _buildHudActions() : const [],
      subtitle: '',
    ),
  );

  List<Widget> _buildHudActions() {
    final actions = <Widget>[
      IconButton(
        icon: const Icon(Icons.done_all, color: Colors.white, size: 20),
        tooltip: _trWithFallback(
          'notifications_mark_all_read',
          'Mark all as read',
        ),
        onPressed: _markAllAsRead,
      ),
    ];

    if (kDebugMode) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.add, color: Colors.white, size: 20),
          tooltip: _trWithFallback(
            'notifications_add_test',
            'Add test notification',
          ),
          onPressed: _createTestNotification,
        ),
      );
    }

    actions.add(const SizedBox(width: 4));
    return actions;
  }

  Widget _buildFilterBar() => GlassCard(
    margin: EdgeInsets.zero,
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    child: Wrap(
      spacing: 10,
      runSpacing: 8,
      children: _NotificationFilter.values.map((filter) {
        final selected = _activeFilter == filter;
        final label = _trWithFallback(filter.labelKey, filter.fallbackLabel);

        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(filter.icon, size: 16),
              const SizedBox(width: 6),
              Text(label),
            ],
          ),
          selected: selected,
          onSelected: (value) {
            if (value && _activeFilter != filter) {
              setState(() => _activeFilter = filter);
            }
          },
          labelStyle: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          backgroundColor: Colors.white.withValues(alpha: 0.06),
          selectedColor: ArtbeatColors.primaryPurple.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          elevation: 0,
        );
      }).toList(),
    ),
  );

  Widget _buildNotificationsStream(User user) =>
      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notification_summary')
            .doc('summary')
            .snapshots(),
        builder: (context, summarySnapshot) =>
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('notifications')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) =>
                  _buildNotificationsList(snapshot, summarySnapshot),
            ),
      );

  Widget _buildNotificationsList(
    AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
    AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> summarySnapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return _buildErrorState(snapshot.error?.toString() ?? 'Error');
    }

    final docs = snapshot.data?.docs ?? [];
    if (docs.isEmpty) {
      return _buildEmptyNotificationsState();
    }

    final summaryData = summarySnapshot.data?.data();
    final cachedTotal = summaryData?['totalCount'] as int?;
    final cachedUnread = summaryData?['unreadCount'] as int?;
    final cachedUpdated = (summaryData?['lastUpdated'] as Timestamp?)?.toDate();

    final unreadCount =
        cachedUnread ?? docs.where((doc) => doc.data()['read'] != true).length;
    final totalCount = cachedTotal ?? docs.length;
    final lastUpdated = cachedUpdated ?? _extractLatestDate(docs);

    final filteredDocs = docs
        .where((doc) => _activeFilter.appliesTo(doc.data()))
        .toList();

    final summaryCard = _buildSummaryCard(
      total: totalCount,
      unread: unreadCount,
      lastUpdated: lastUpdated,
    );

    if (filteredDocs.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        physics: const BouncingScrollPhysics(),
        children: [
          summaryCard,
          const SizedBox(height: 12),
          _buildFilterEmptyState(),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      physics: const BouncingScrollPhysics(),
      itemCount: filteredDocs.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(children: [summaryCard, const SizedBox(height: 12)]);
        }

        final doc = filteredDocs[index - 1];
        final data = doc.data();
        final title = _parseTitle(data);
        final message = _parseMessage(data);
        final type = (data['type'] as String?) ?? '';
        final timestamp = data['createdAt'] as Timestamp?;
        final createdAt = timestamp?.toDate();
        final isRead = data['read'] == true;

        return _buildNotificationCard(
          notificationId: doc.id,
          data: data,
          title: title,
          message: message,
          type: type,
          isRead: isRead,
          createdAt: createdAt,
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required int total,
    required int unread,
    required DateTime? lastUpdated,
  }) => GlassCard(
    margin: EdgeInsets.zero,
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _trWithFallback('notifications_summary_title', 'Notification Center'),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildSummaryMetric(
              value: total.toString(),
              label: _trWithFallback('notifications_stat_total', 'Total'),
            ),
            const SizedBox(width: 12),
            _buildSummaryMetric(
              value: unread.toString(),
              label: _trWithFallback('notifications_stat_unread', 'Unread'),
            ),
            const SizedBox(width: 12),
            _buildSummaryMetric(
              value: lastUpdated != null
                  ? _formatNotificationDate(lastUpdated)
                  : '—',
              label: _trWithFallback(
                'notifications_stat_recent',
                'Last update',
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildSummaryMetric({required String value, required String label}) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildNotificationCard({
    required String notificationId,
    required Map<String, dynamic> data,
    required String title,
    required String message,
    required String type,
    required bool isRead,
    required DateTime? createdAt,
  }) {
    final accent = _notificationAccent(type);

    return GlassCard(
      margin: const EdgeInsets.symmetric(vertical: 6),
      glassColor: isRead
          ? Colors.white.withValues(alpha: 0.04)
          : ArtbeatColors.primaryPurple.withValues(alpha: 0.18),
      borderColor: Colors.white.withValues(alpha: 0.12),
      onTap: () => _handleNotificationTap(notificationId, data),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accent, accent.withValues(alpha: 0.65)],
              ),
            ),
            child: Icon(_getNotificationIcon(type), color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          fontWeight: isRead
                              ? FontWeight.w600
                              : FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (createdAt != null)
                      Text(
                        _formatNotificationDate(createdAt),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildTypeChip(type, accent),
                    if (!isRead) _buildUnreadChip(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String type, Color accent) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      color: accent.withValues(alpha: 0.25),
      border: Border.all(color: accent.withValues(alpha: 0.6)),
    ),
    child: Text(
      _formatTypeLabel(type),
      style: GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
  );

  Widget _buildUnreadChip() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      color: ArtbeatColors.secondaryTeal.withValues(alpha: 0.2),
      border: Border.all(
        color: ArtbeatColors.secondaryTeal.withValues(alpha: 0.65),
      ),
    ),
    child: Text(
      _trWithFallback('notifications_badge_new', 'New'),
      style: GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
  );

  Widget _buildFilterEmptyState() => GlassCard(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        Icon(
          Icons.filter_list_off,
          size: 40,
          color: Colors.white.withValues(alpha: 0.7),
        ),
        const SizedBox(height: 12),
        Text(
          _trWithFallback(
            'notifications_filter_empty',
            'No notifications match this filter.',
          ),
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white.withValues(alpha: 0.85),
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () =>
              setState(() => _activeFilter = _NotificationFilter.all),
          icon: const Icon(Icons.refresh, size: 18),
          label: Text(
            _trWithFallback('notifications_reset_filter', 'Show all'),
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
          ),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildEmptyNotificationsState() => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GlassCard(
        margin: const EdgeInsets.only(top: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: Colors.white.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              'notifications_empty_title'.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'notifications_empty_subtitle'.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildErrorState(String message) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GlassCard(
        margin: const EdgeInsets.only(top: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.redAccent.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 12),
            Text(
              _trWithFallback(
                'notifications_error_title',
                'Something went wrong',
              ),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildDebugTools() => GlassCard(
    margin: EdgeInsets.zero,
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Debug Tools',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _runImageCleanup,
          icon: const Icon(Icons.build_rounded),
          label: Text('notifications_fix_images'.tr()),
          style: ElevatedButton.styleFrom(
            backgroundColor: ArtbeatColors.primaryPurple,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    ),
  );

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllNotificationsAsRead();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('notifications_all_marked_read'.tr()),
          duration: const Duration(seconds: 2),
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _createTestNotification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _notificationService.sendNotification(
        userId: user.uid,
        title: _trWithFallback('notifications_test_title', 'Test notification'),
        message: _trWithFallback(
          'notifications_test_message',
          'This is a test notification',
        ),
        type: NotificationType.achievement,
        data: {'testData': 'This is test data'},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _trWithFallback(
              'notifications_test_created',
              'Test notification created',
            ),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleNotificationTap(
    String notificationId,
    Map<String, dynamic> data,
  ) async {
    if (data['read'] != true) {
      await _notificationService.markNotificationAsRead(notificationId);
    }

    final type = data['type'] as String?;
    final notificationData = data['data'] as Map<String, dynamic>?;

    if (type != null && notificationData != null && mounted) {
      _navigateBasedOnNotificationType(type, notificationData);
    }
  }

  void _navigateBasedOnNotificationType(
    String type,
    Map<String, dynamic> data,
  ) {
    switch (type) {
      case 'achievement':
        Navigator.pushNamed(context, '/profile/achievements');
        break;
      case 'galleryInvitation':
        Navigator.pushNamed(context, '/artist/invitations');
        break;
      case 'follow':
        final userId = data['fromUserId'] as String?;
        if (userId != null) {
          Navigator.pushNamed(context, '/profile/$userId');
        }
        break;
      case 'like':
      case 'comment':
        final postId = data['postId'] as String?;
        final artworkId = data['artworkId'] as String?;
        if (postId != null) {
          Navigator.pushNamed(context, '/post/$postId');
        } else if (artworkId != null) {
          Navigator.pushNamed(context, '/artwork/$artworkId');
        }
        break;
      case 'message':
        final chatId = data['chatId'] as String?;
        if (chatId != null) {
          Navigator.pushNamed(context, '/chat/$chatId');
        }
        break;
      default:
        break;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite_rounded;
      case 'comment':
        return Icons.comment_rounded;
      case 'follow':
        return Icons.person_add_rounded;
      case 'message':
        return Icons.message_rounded;
      case 'mention':
        return Icons.alternate_email_rounded;
      case 'artworkPurchase':
        return Icons.shopping_cart_rounded;
      case 'subscription':
        return Icons.star_rounded;
      case 'subscriptionExpiration':
        return Icons.warning_amber_rounded;
      case 'galleryInvitation':
        return Icons.business_center_rounded;
      case 'invitationResponse':
        return Icons.check_circle_rounded;
      case 'invitationCancelled':
        return Icons.cancel_rounded;
      case 'achievement':
        return Icons.emoji_events_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _notificationAccent(String type) {
    switch (type) {
      case 'like':
      case 'follow':
        return const Color(0xFFFF3D8D);
      case 'comment':
        return const Color(0xFFFFB74D);
      case 'message':
        return ArtbeatColors.primaryPurple;
      case 'achievement':
        return ArtbeatColors.primaryGreen;
      case 'artworkPurchase':
        return const Color(0xFF4DD0E1);
      default:
        return const Color(0xFF7C4DFF);
    }
  }

  String _parseTitle(Map<String, dynamic> data) {
    final title = data['title'];
    if (title is String && title.trim().isNotEmpty) return title;
    return _trWithFallback('notifications_default_title', 'ARTbeat update');
  }

  String _parseMessage(Map<String, dynamic> data) {
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) return message;
    final body = data['body'];
    if (body is String && body.trim().isNotEmpty) return body;
    return '';
  }

  String _formatTypeLabel(String type) {
    switch (type) {
      case 'follow':
        return _trWithFallback('notifications_type_follow', 'Social');
      case 'like':
      case 'comment':
        return _trWithFallback('notifications_type_engagement', 'Engagement');
      case 'message':
        return _trWithFallback('notifications_type_message', 'Message');
      case 'achievement':
        return _trWithFallback('notifications_type_achievement', 'Achievement');
      case 'artworkPurchase':
        return _trWithFallback('notifications_type_purchase', 'Purchase');
      default:
        return _trWithFallback('notifications_type_alert', 'Alert');
    }
  }

  String _formatNotificationDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'notifications_just_now'.tr();
    } else if (difference.inMinutes < 60) {
      return 'notifications_minutes_ago'.tr(
        namedArgs: {'count': difference.inMinutes.toString()},
      );
    } else if (difference.inHours < 24) {
      return 'notifications_hours_ago'.tr(
        namedArgs: {'count': difference.inHours.toString()},
      );
    } else if (difference.inDays < 7) {
      return 'notifications_days_ago'.tr(
        namedArgs: {'count': difference.inDays.toString()},
      );
    } else {
      return intl.DateFormat('MMM d, y').format(date);
    }
  }

  DateTime? _extractLatestDate(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (docs.isEmpty) return null;
    final timestamp = docs.first.data()['createdAt'] as Timestamp?;
    return timestamp?.toDate();
  }

  bool _isAdminUser() => _currentUserModel?.isAdmin ?? false;

  Future<void> _runImageCleanup() async {
    final cleanupService = ArtworkCleanupService();
    await cleanupService.checkSpecificImage();
    await cleanupService.cleanupBrokenArtworkImages();
    await cleanupService.cleanupBrokenArtworkImages(dryRun: false);
  }

  String _trWithFallback(String key, String fallback) {
    final value = key.tr();
    return value == key ? fallback : value;
  }
}

enum _NotificationFilter { all, unread, social, system }

const Set<String> _socialTypes = {
  'follow',
  'like',
  'comment',
  'message',
  'mention',
};
const Set<String> _systemTypes = {
  'achievement',
  'galleryinvitation',
  'artworkpurchase',
  'subscription',
  'subscriptionexpiration',
  'system',
  'alert',
  'reminder',
};

extension _NotificationFilterExtension on _NotificationFilter {
  IconData get icon {
    switch (this) {
      case _NotificationFilter.all:
        return Icons.dashboard_customize_rounded;
      case _NotificationFilter.unread:
        return Icons.mark_email_unread_rounded;
      case _NotificationFilter.social:
        return Icons.groups_rounded;
      case _NotificationFilter.system:
        return Icons.shield_moon_rounded;
    }
  }

  String get labelKey {
    switch (this) {
      case _NotificationFilter.all:
        return 'notifications_filter_all';
      case _NotificationFilter.unread:
        return 'notifications_filter_unread';
      case _NotificationFilter.social:
        return 'notifications_filter_social';
      case _NotificationFilter.system:
        return 'notifications_filter_system';
    }
  }

  String get fallbackLabel {
    switch (this) {
      case _NotificationFilter.all:
        return 'All';
      case _NotificationFilter.unread:
        return 'Unread';
      case _NotificationFilter.social:
        return 'Social';
      case _NotificationFilter.system:
        return 'System';
    }
  }

  bool appliesTo(Map<String, dynamic> data) {
    switch (this) {
      case _NotificationFilter.all:
        return true;
      case _NotificationFilter.unread:
        return data['read'] != true;
      case _NotificationFilter.social:
        final type = (data['type'] as String?)?.toLowerCase() ?? '';
        return _socialTypes.contains(type);
      case _NotificationFilter.system:
        final type = (data['type'] as String?)?.toLowerCase() ?? '';
        if (type.isEmpty) return true;
        return _systemTypes.contains(type) || !_socialTypes.contains(type);
    }
  }
}
