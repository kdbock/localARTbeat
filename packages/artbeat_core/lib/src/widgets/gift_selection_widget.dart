import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/in_app_gift_service.dart';
import '../utils/logger.dart';

class GiftSelectionWidget extends StatefulWidget {
  final String recipientId;
  final String recipientName;

  const GiftSelectionWidget({
    super.key,
    required this.recipientId,
    required this.recipientName,
  });

  @override
  State<GiftSelectionWidget> createState() => _GiftSelectionWidgetState();
}

class _GiftSelectionWidgetState extends State<GiftSelectionWidget> {
  final InAppGiftService _giftService = InAppGiftService();
  bool _isLoading = false;

  final List<Map<String, dynamic>> _gifts = [
    {
      'id': 'artbeat_gift_small',
      'name': '🎨 Supporter Gift',
      'price': 4.99,
      'description':
          'Artist featured for 30 days - Give your favorite artist more visibility!',
    },
    {
      'id': 'artbeat_gift_medium',
      'name': '🖼️ Fan Gift',
      'price': 9.99,
      'description':
          'Artist featured for 90 days + 1 artwork featured for 90 days - Boost their exposure!',
    },
    {
      'id': 'artbeat_gift_large',
      'name': '✨ Patron Gift',
      'price': 24.99,
      'description':
          'Artist featured for 180 days + 5 artworks featured for 180 days + Artist ad in rotation for 180 days - Maximum support!',
    },
    {
      'id': 'artbeat_gift_premium',
      'name': '👑 Benefactor Gift',
      'price': 49.99,
      'description':
          'Artist featured for 1 year + 5 artworks featured for 1 year + Artist ad in rotation for 1 year - Ultimate artist support!',
    },
  ];

  Future<void> _purchaseGift(String giftId, double price) async {
    AppLogger.info(
      '🎁 Gift purchase started: $giftId for \$${price.toStringAsFixed(2)}',
    );
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppLogger.error('User not authenticated');
        _showError('Please log in to send gifts');
        setState(() => _isLoading = false);
        return;
      }

      // Check if user is trying to gift themselves
      if (user.uid == widget.recipientId) {
        AppLogger.error('User trying to gift themselves');
        _showError('You cannot send gifts to yourself');
        setState(() => _isLoading = false);
        return;
      }

      // Check if in-app purchases are available
      if (!_giftService.isAvailable) {
        AppLogger.error('In-app purchases not available');
        _showError('In-app purchases are not available on this device');
        setState(() => _isLoading = false);
        return;
      }

      AppLogger.info(
        '🎁 Calling purchaseGift with recipient: ${widget.recipientId}',
      );
      final success = await _giftService.purchaseGift(
        recipientId: widget.recipientId,
        giftProductId: giftId,
        message: 'Supporting ${widget.recipientName}\'s art and events',
      );

      AppLogger.info('🎁 Purchase result: $success');

      if (!mounted) return;

      if (success) {
        _showSuccess('Gift purchase initiated! 🎁');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        _showError(
          'Gift purchase failed. Please check your payment method and try again.',
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      AppLogger.error('Error purchasing gift: $e');
      String errorMessage = 'An error occurred while processing your gift';

      // Provide more specific error messages
      if (e.toString().contains('not authenticated')) {
        errorMessage = 'Please log in to send gifts';
      } else if (e.toString().contains('not available')) {
        errorMessage = 'In-app purchases are not available on this device';
      } else if (e.toString().contains('Product not found')) {
        errorMessage = 'Gift product not available. Please try again later.';
      } else if (e.toString().contains('cancelled')) {
        errorMessage = 'Gift purchase was cancelled';
      }

      _showError(errorMessage);
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Send a Gift to ${widget.recipientName}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Your gift provides greater exposure for their artwork and events within the app.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            ..._gifts.map((gift) {
              final id = gift['id'] as String;
              final name = gift['name'] as String;
              final description = gift['description'] as String;
              final price = gift['price'] as double;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Card(
                  child: ListTile(
                    title: Text(name),
                    subtitle: Text(description),
                    trailing: Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onTap: _isLoading ? null : () => _purchaseGift(id, price),
                    enabled: !_isLoading,
                  ),
                ),
              );
            }).toList(),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Processing gift...'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
