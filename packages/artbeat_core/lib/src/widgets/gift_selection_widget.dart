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
  bool _isInitializing = true;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    setState(() {
      _isInitializing = true;
      _initError = null;
    });

    // Small delay to let IAP complete initialization if just started
    // ignore: inference_failure_on_instance_creation
    await Future.delayed(const Duration(milliseconds: 300));

    if (!_giftService.isAvailable) {
      setState(() {
        _initError =
            'In-app purchases are not available. Please ensure you are connected to the internet and your device supports in-app purchases.';
        _isInitializing = false;
      });
      return;
    }

    setState(() {
      _isInitializing = false;
    });
  }

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
        _showError(
          'In-app purchases are not available. Please check your internet connection and app store settings.',
        );
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
        AppLogger.error(
          'Gift purchase returned false - check logs for details',
        );
        _showError(
          'Unable to start purchase. This may be due to:\n'
          '• Products not loaded from store\n'
          '• Device payment method not configured\n'
          '• Network connectivity issue\n\n'
          'Please check your internet connection and device payment settings.',
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
    if (_isInitializing) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Checking gift availability...'),
          ],
        ),
      );
    }

    if (_initError != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _initError!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _checkAvailability();
              },
              child: const Text('Retry'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    }

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your gift provides greater exposure for their artwork and events within the app.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      // Log diagnostic info
                      AppLogger.info('=== GIFT DIAGNOSTICS ===');
                      AppLogger.info(
                        'IAP Available: ${_giftService.isAvailable}',
                      );
                      final products = _giftService.getGiftProductDetails(
                        'artbeat_gift_small',
                      );
                      AppLogger.info(
                        'Gift products config: ${products != null}',
                      );
                      AppLogger.info('======================');

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Diagnostic info logged - check console',
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bug_report, size: 16),
                    label: const Text(
                      'Debug Info',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
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
