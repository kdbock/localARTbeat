import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/capture_service.dart';
import 'package:artbeat_core/artbeat_core.dart' show AppLogger;

/// A reusable like button widget for captures
class LikeButtonWidget extends StatefulWidget {
  final String captureId;
  final String userId;
  final int initialLikeCount;
  final VoidCallback? onLikeChanged;

  const LikeButtonWidget({
    Key? key,
    required this.captureId,
    required this.userId,
    required this.initialLikeCount,
    this.onLikeChanged,
  }) : super(key: key);

  @override
  State<LikeButtonWidget> createState() => _LikeButtonWidgetState();
}

class _LikeButtonWidgetState extends State<LikeButtonWidget> {
  late int _likeCount;
  late bool _isLiked;
  bool _isLoading = false;
  final _captureService = CaptureService();

  @override
  void initState() {
    super.initState();
    _likeCount = widget.initialLikeCount;
    _checkIfLiked();
  }

  Future<void> _checkIfLiked() async {
    try {
      final liked = await _captureService.hasUserLikedCapture(
        widget.captureId,
        widget.userId,
      );
      if (mounted) {
        setState(() => _isLiked = liked);
      }
    } catch (e) {
      AppLogger.error('Error checking like status: $e');
    }
  }

  Future<void> _toggleLike() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      bool success;
      if (_isLiked) {
        success = await _captureService.unlikeCapture(
          widget.captureId,
          widget.userId,
        );
        if (success && mounted) {
          setState(() {
            _isLiked = false;
            _likeCount = (_likeCount - 1).clamp(0, double.infinity).toInt();
          });
        }
      } else {
        success = await _captureService.likeCapture(
          widget.captureId,
          widget.userId,
        );
        if (success && mounted) {
          setState(() {
            _isLiked = true;
            _likeCount++;
          });
        }
      }

      if (success) {
        widget.onLikeChanged?.call();
      }
    } catch (e) {
      AppLogger.error('Error toggling like: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'capture_like_error_generic'.tr().replaceAll(
                '{error}',
                e.toString(),
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isLoading ? null : _toggleLike,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Like button with animation
          AnimatedScale(
            scale: _isLoading ? 0.9 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Icon(
              _isLiked ? Icons.favorite : Icons.favorite_border,
              color: _isLiked ? Colors.red : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          // Like count
          Text(
            _likeCount > 0 ? _likeCount.toString() : '0',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _isLiked ? Colors.red : Colors.grey,
              fontWeight: _isLiked ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
