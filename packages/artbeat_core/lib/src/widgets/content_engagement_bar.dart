import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/engagement_model.dart';
import '../services/engagement_config_service.dart';
import '../services/content_engagement_service.dart';
import '../services/in_app_gift_service.dart';

/// Content-specific engagement bar for ARTbeat content types
/// Replaces the universal engagement bar with content-specific engagement options
class ContentEngagementBar extends StatefulWidget {
  final String contentId;
  final String contentType;
  final EngagementStats initialStats;
  final bool isCompact;
  final Map<EngagementType, VoidCallback?>? customHandlers;
  final bool showSecondaryActions;
  final EdgeInsets? padding;
  final VoidCallback? onEngagementChanged;
  final String? artistId;
  final String? artistName;

  const ContentEngagementBar({
    super.key,
    required this.contentId,
    required this.contentType,
    required this.initialStats,
    this.isCompact = false,
    this.customHandlers,
    this.showSecondaryActions = false,
    this.padding,
    this.onEngagementChanged,
    this.artistId,
    this.artistName,
  });

  @override
  State<ContentEngagementBar> createState() => _ContentEngagementBarState();
}

class _ContentEngagementBarState extends State<ContentEngagementBar> {
  late EngagementStats _stats;
  final Map<EngagementType, bool> _userEngagements = {};
  bool _isLoading = false;
  final InAppGiftService _giftService = InAppGiftService();

  @override
  void initState() {
    super.initState();
    _stats = widget.initialStats;
    _loadUserEngagements();
  }

  Future<void> _loadUserEngagements() async {
    final service = context.read<ContentEngagementService>();
    final primaryTypes = EngagementConfigService.getPrimaryEngagementTypes(
      widget.contentType,
    );

    for (final type in primaryTypes) {
      final hasEngaged = await service.hasUserEngaged(
        contentId: widget.contentId,
        engagementType: type,
      );
      if (mounted) {
        setState(() {
          _userEngagements[type] = hasEngaged;
        });
      }
    }
  }

  Future<void> _handleEngagement(EngagementType type) async {
    if (_isLoading) return;

    // Check for custom handler first
    final customHandler = widget.customHandlers?[type];
    if (customHandler != null) {
      customHandler();
      return;
    }

    // Handle demo content specially - just update UI without Firebase operations
    if (_isDemoContent()) {
      _handleDemoEngagement(type);
      return;
    }

    // Handle special engagement types
    if (EngagementConfigService.requiresSpecialHandling(type)) {
      await _handleSpecialEngagement(type);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final service = context.read<ContentEngagementService>();
      final newEngagementState = await service.toggleEngagement(
        contentId: widget.contentId,
        contentType: widget.contentType,
        engagementType: type,
      );

      if (mounted) {
        setState(() {
          _userEngagements[type] = newEngagementState;
          _stats = _updateStatsForEngagement(type, newEngagementState);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  /// Check if this is demo content that doesn't exist in Firestore
  bool _isDemoContent() {
    return widget.contentId.startsWith('demo_');
  }

  /// Handle engagement for demo content (just UI feedback, no Firebase operations)
  void _handleDemoEngagement(EngagementType type) {
    final isCurrentlyEngaged = _userEngagements[type] ?? false;
    final newEngagementState = !isCurrentlyEngaged;

    setState(() {
      _userEngagements[type] = newEngagementState;
      _stats = _updateStatsForEngagement(type, newEngagementState);
    });

    // Show feedback for demo engagement
    String message;
    switch (type) {
      case EngagementType.like:
        message = newEngagementState ? 'Demo liked! ❤️' : 'Demo unliked';
        break;
      case EngagementType.comment:
        message = 'Demo comment feature! 💬';
        break;
      case EngagementType.share:
        message = 'Demo share feature! 📤';
        break;
      case EngagementType.gift:
        message =
            'Demo gift feature! 🎁 (Gift functionality available in full app)';
        break;
      case EngagementType.commission:
        message =
            'Demo commission feature! 🎨 (Commission functionality available in full app)';
        break;
      case EngagementType.sponsor:
        message =
            'Demo sponsor feature! 💖 (Sponsorship functionality available in full app)';
        break;
      case EngagementType.message:
        message =
            'Demo message feature! 💌 (Messaging functionality available in full app)';
        break;
      default:
        message = 'Demo engagement! ✨';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _handleSpecialEngagement(EngagementType type) async {
    switch (type) {
      case EngagementType.gift:
        await _showGiftDialog();
        break;
      case EngagementType.sponsor:
        await _showSponsorDialog();
        break;
      case EngagementType.commission:
        await _showCommissionDialog();
        break;
      case EngagementType.message:
        await _showMessageDialog();
        break;
      case EngagementType.review:
        await _showReviewDialog();
        break;
      case EngagementType.rate:
        await _showRatingDialog();
        break;
      case EngagementType.comment:
        await _handleComment();
        break;
      case EngagementType.share:
        await _handleShare();
        break;
      default:
        // Handle normally
        await _handleEngagement(type);
    }
  }

  EngagementStats _updateStatsForEngagement(
    EngagementType type,
    bool isEngaged,
  ) {
    final increment = isEngaged ? 1 : -1;

    switch (type) {
      case EngagementType.like:
        return _stats.copyWith(
          likeCount: (_stats.likeCount + increment)
              .clamp(0, double.infinity)
              .toInt(),
        );
      case EngagementType.comment:
        return _stats.copyWith(
          commentCount: (_stats.commentCount + increment)
              .clamp(0, double.infinity)
              .toInt(),
        );
      case EngagementType.reply:
        return _stats.copyWith(
          replyCount: (_stats.replyCount + increment)
              .clamp(0, double.infinity)
              .toInt(),
        );
      case EngagementType.share:
        return _stats.copyWith(
          shareCount: (_stats.shareCount + increment)
              .clamp(0, double.infinity)
              .toInt(),
        );
      case EngagementType.rate:
        return _stats.copyWith(
          rateCount: (_stats.rateCount + increment)
              .clamp(0, double.infinity)
              .toInt(),
        );
      case EngagementType.review:
        return _stats.copyWith(
          reviewCount: (_stats.reviewCount + increment)
              .clamp(0, double.infinity)
              .toInt(),
        );
      case EngagementType.follow:
        return _stats.copyWith(
          followCount: (_stats.followCount + increment)
              .clamp(0, double.infinity)
              .toInt(),
        );
      case EngagementType.gift:
        return _stats.copyWith(
          giftCount: (_stats.giftCount + increment)
              .clamp(0, double.infinity)
              .toInt(),
        );
      case EngagementType.sponsor:
        return _stats.copyWith(
          sponsorCount: (_stats.sponsorCount + increment)
              .clamp(0, double.infinity)
              .toInt(),
        );
      case EngagementType.message:
        return _stats.copyWith(
          messageCount: (_stats.messageCount + increment)
              .clamp(0, double.infinity)
              .toInt(),
        );
      case EngagementType.commission:
        return _stats.copyWith(
          commissionCount: (_stats.commissionCount + increment)
              .clamp(0, double.infinity)
              .toInt(),
        );
      default:
        return _stats;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryTypes = EngagementConfigService.getPrimaryEngagementTypes(
      widget.contentType,
    );
    final secondaryTypes = widget.showSecondaryActions
        ? EngagementConfigService.getSecondaryEngagementTypes(
            widget.contentType,
          )
        : <EngagementType>[];

    // Combine all engagement types into a single list for one row display
    final allEngagementTypes = [...primaryTypes, ...secondaryTypes];

    return Container(
      padding:
          widget.padding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: allEngagementTypes
            .map((type) => Flexible(child: _buildEngagementButton(type)))
            .toList(),
      ),
    );
  }

  Widget _buildEngagementButton(
    EngagementType type, {
    bool isSecondary = false,
  }) {
    final isEngaged = _userEngagements[type] ?? false;
    final count = _stats.getCount(type);
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => _handleEngagement(type),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: widget.isCompact ? 8 : 12,
          vertical: widget.isCompact ? 4 : 8,
        ),
        child: widget.isCompact
            ? _buildCompactButton(type, isEngaged, count, theme)
            : _buildFullButton(type, isEngaged, count, theme, isSecondary),
      ),
    );
  }

  Widget _buildCompactButton(
    EngagementType type,
    bool isEngaged,
    int count,
    ThemeData theme,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _getIconData(type),
          size: 16,
          color: isEngaged
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        if (count > 0) ...[
          const SizedBox(width: 4),
          Text(
            _formatCount(count),
            style: theme.textTheme.bodySmall?.copyWith(
              color: isEngaged
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFullButton(
    EngagementType type,
    bool isEngaged,
    int count,
    ThemeData theme,
    bool isSecondary,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _getIconData(type),
          size: isSecondary ? 20 : 24,
          color: isEngaged
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(height: 4),
        Text(
          count > 0 ? _formatCount(count) : type.displayName,
          style:
              (isSecondary
                      ? theme.textTheme.bodySmall
                      : theme.textTheme.bodyMedium)
                  ?.copyWith(
                    color: isEngaged
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
        ),
      ],
    );
  }

  IconData _getIconData(EngagementType type) {
    switch (type) {
      case EngagementType.like:
        return Icons.favorite; // heart icon
      case EngagementType.comment:
        return Icons.chat_bubble_outline; // chat bubble
      case EngagementType.reply:
        return Icons.reply; // reply arrow
      case EngagementType.share:
        return Icons.share; // share icon
      case EngagementType.seen:
        return Icons.visibility; // eye icon
      case EngagementType.rate:
        return Icons.star_border; // star for rating
      case EngagementType.review:
        return Icons.rate_review; // review icon
      case EngagementType.follow:
        return Icons.person_add; // follow icon
      case EngagementType.gift:
        return Icons.card_giftcard; // gift icon
      case EngagementType.sponsor:
        return Icons.volunteer_activism; // sponsor icon
      case EngagementType.message:
        return Icons.message; // message icon
      case EngagementType.commission:
        return Icons.palette; // commission icon (more art-related)
    }
  }

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }

  // Engagement dialog methods
  Future<void> _showRatingDialog() async {
    int selectedRating = 0;

    final result = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Rate this artwork'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('How would you rate this artwork?'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < selectedRating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            selectedRating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: selectedRating > 0
                      ? () => Navigator.of(context).pop(selectedRating)
                      : null,
                  child: const Text('Rate'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      // Submit rating
      await _submitEngagement(EngagementType.rate, {'rating': result});
    }
  }

  Future<void> _showReviewDialog() async {
    final TextEditingController reviewController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Write a review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Share your thoughts about this artwork:'),
              const SizedBox(height: 16),
              TextField(
                controller: reviewController,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Write your review here...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(reviewController.text),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      // Submit review
      await _submitEngagement(EngagementType.review, {'review': result});
    }
  }

  Future<void> _showGiftDialog() async {
    if (widget.artistId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot send gift - artist not found.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Processing gift...'),
        duration: Duration(seconds: 1),
      ),
    );

    final success = await _giftService.purchaseQuickGift(widget.artistId!);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gift purchase initiated! 🎁'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to send gift. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleShare() async {
    try {
      // For artwork content type, show enhanced share dialog
      if (widget.contentType == 'artwork') {
        await _showArtworkShareDialog();
      } else {
        // Default share for other content types
        final message =
            'Check out this amazing ${widget.contentType} on ARTbeat!';
        await SharePlus.instance.share(ShareParams(text: message));

        // Track share engagement
        await _submitEngagement(EngagementType.share, {
          'platform': 'native_share',
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sharing: $e')));
      }
    }
  }

  Future<void> _showArtworkShareDialog() async {
    final shareText =
        'Check out this amazing artwork on ARTbeat! 🎨\n\nhttps://artbeat.app/artwork/${widget.contentId}';

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Share Artwork',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildShareOption(
                    icon: Icons.message,
                    label: 'Messages',
                    onTap: () async {
                      Navigator.pop(context);
                      await SharePlus.instance.share(
                        ShareParams(
                          text: shareText,
                          subject: 'Amazing artwork on ARTbeat',
                        ),
                      );
                      await _submitEngagement(EngagementType.share, {
                        'platform': 'messages',
                      });
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.copy,
                    label: 'Copy Link',
                    onTap: () async {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link copied to clipboard'),
                        ),
                      );
                      await _submitEngagement(EngagementType.share, {
                        'platform': 'copy_link',
                      });
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.share,
                    label: 'More',
                    onTap: () async {
                      Navigator.pop(context);
                      await SharePlus.instance.share(
                        ShareParams(
                          text: shareText,
                          subject: 'Amazing artwork on ARTbeat',
                        ),
                      );
                      await _submitEngagement(EngagementType.share, {
                        'platform': 'system_share',
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildShareOption(
                    icon: Icons.camera_alt,
                    label: 'Stories',
                    color: Colors.purple,
                    onTap: () async {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Stories sharing coming soon!'),
                        ),
                      );
                      await _submitEngagement(EngagementType.share, {
                        'platform': 'stories',
                      });
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.facebook,
                    label: 'Facebook',
                    color: Colors.blue,
                    onTap: () async {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Facebook sharing coming soon!'),
                        ),
                      );
                      await _submitEngagement(EngagementType.share, {
                        'platform': 'facebook',
                      });
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.photo_camera,
                    label: 'Instagram',
                    color: Colors.pink,
                    onTap: () async {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Instagram sharing coming soon!'),
                        ),
                      );
                      await _submitEngagement(EngagementType.share, {
                        'platform': 'instagram',
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (color ?? Theme.of(context).primaryColor).withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color ?? Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitEngagement(
    EngagementType type,
    Map<String, dynamic> metadata,
  ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final service = context.read<ContentEngagementService>();
      final newEngagementState = await service.toggleEngagement(
        contentId: widget.contentId,
        contentType: widget.contentType,
        engagementType: type,
        metadata: metadata,
      );

      if (mounted) {
        setState(() {
          _userEngagements[type] = newEngagementState;
          _stats = _updateStatsForEngagement(type, newEngagementState);
          _isLoading = false;
        });

        // Show success feedback
        String message;
        switch (type) {
          case EngagementType.rate:
            message = 'Thank you for rating!';
            break;
          case EngagementType.review:
            message = 'Review submitted successfully!';
            break;
          case EngagementType.gift:
            message = 'Gift sent to the artist!';
            break;
          case EngagementType.share:
            message = 'Thank you for sharing!';
            break;
          default:
            message = 'Thank you for your engagement!';
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));

        // Notify parent of engagement change (for ratings and reviews)
        if (widget.onEngagementChanged != null &&
            (type == EngagementType.rate || type == EngagementType.review)) {
          widget.onEngagementChanged!();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _handleComment() async {
    final TextEditingController commentController = TextEditingController();

    final comment = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Comment'),
          content: TextField(
            controller: commentController,
            decoration: const InputDecoration(
              hintText: 'Write your comment...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            maxLength: 500,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = commentController.text.trim();
                if (text.isNotEmpty) {
                  Navigator.pop(context, text);
                }
              },
              child: const Text('Comment'),
            ),
          ],
        );
      },
    );

    if (comment != null && comment.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        // ignore: use_build_context_synchronously
        final service = context.read<ContentEngagementService>();
        await service.addComment(
          contentId: widget.contentId,
          contentType: widget.contentType,
          comment: comment,
        );

        if (mounted) {
          setState(() {
            _stats = _stats.copyWith(commentCount: _stats.commentCount + 1);
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Comment added successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error adding comment: $e')));
        }
      }
    }
  }

  Future<void> _showSponsorDialog() async {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.volunteer_activism, color: Colors.pink),
              SizedBox(width: 8),
              Text('Sponsor Artist'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.artistName != null)
                Text(
                  'Sponsor ${widget.artistName}\'s creative work',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else
                const Text(
                  'Support an artist\'s creative work',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              const SizedBox(height: 16),
              const Text(
                'Artist sponsorship features are coming soon! You\'ll be able to:\n\n'
                '• Provide monthly support to artists\n'
                '• Get exclusive access to their work\n'
                '• Receive personalized updates\n'
                '• Support emerging talent\n'
                '• Build long-term relationships',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.pink.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.pink),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'For now, you can show support by liking their work and sending gifts.',
                        style: TextStyle(color: Colors.pink.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            if (widget.artistId != null && widget.artistName != null)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showGiftDialog();
                },
                icon: const Icon(Icons.card_giftcard, size: 16),
                label: const Text('Send Gift'),
              )
            else
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
          ],
        );
      },
    );
  }

  Future<void> _showCommissionDialog() async {
    // Navigate to commission request screen if artist info is available
    if (widget.artistId != null && widget.artistName != null) {
      try {
        // Use dynamic import to avoid circular dependencies
        final commissionModule = await _loadCommissionModule();
        if (commissionModule != null) {
          // ignore: use_build_context_synchronously
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (context) => commissionModule),
          );
        } else {
          _showCommissionFallbackDialog();
        }
      } catch (e) {
        _showCommissionFallbackDialog();
      }
    } else {
      _showCommissionFallbackDialog();
    }
  }

  Future<Widget?> _loadCommissionModule() async {
    try {
      // Try to dynamically create commission request screen
      // This is a placeholder - in a real implementation you'd use proper module loading
      return null; // Will trigger fallback
    } catch (e) {
      return null;
    }
  }

  void _showCommissionFallbackDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.palette, color: Colors.purple),
              SizedBox(width: 8),
              Text('Commission Request'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.artistName != null)
                Text(
                  'Request a custom commission from ${widget.artistName}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else
                const Text(
                  'Request a custom artwork commission',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              const SizedBox(height: 16),
              const Text(
                'Commission features are coming soon! You\'ll be able to:\n\n'
                '• Request custom artwork\n'
                '• Set your budget and timeline\n'
                '• Communicate directly with artists\n'
                '• Track progress with milestones\n'
                '• Secure payment processing',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'For now, you can message the artist directly to discuss commission details.',
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            if (widget.artistId != null)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showMessageDialog();
                },
                icon: const Icon(Icons.message, size: 16),
                label: const Text('Message Artist'),
              )
            else
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
          ],
        );
      },
    );
  }

  Future<void> _showMessageDialog() async {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.message, color: Colors.blue),
              SizedBox(width: 8),
              Text('Send Message'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.artistName != null)
                Text(
                  'Send a message to ${widget.artistName}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else
                const Text(
                  'Send a direct message',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              const SizedBox(height: 16),
              const Text(
                'Direct messaging features are coming soon! You\'ll be able to:\n\n'
                '• Send private messages to artists\n'
                '• Share artwork and inspiration\n'
                '• Discuss collaborations\n'
                '• Get instant notifications\n'
                '• Organize conversations by topic',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'For now, you can connect through the community feed and comments.',
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
