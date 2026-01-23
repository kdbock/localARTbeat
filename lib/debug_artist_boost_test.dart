// ignore_for_file: implementation_imports, cascade_invocations

import 'package:artbeat_core/artbeat_core.dart';
import 'package:flutter/material.dart';

/// Simple debug screen to test artist boost functionality
class DebugArtistBoostTestScreen extends StatefulWidget {
  const DebugArtistBoostTestScreen({super.key});

  @override
  State<DebugArtistBoostTestScreen> createState() => _DebugArtistBoostTestScreenState();
}

class _DebugArtistBoostTestScreenState extends State<DebugArtistBoostTestScreen> {
  final ArtistBoostService _boostService = ArtistBoostService();
  final InAppPurchaseService _purchaseService = InAppPurchaseService();
  String _status = 'Checking...';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking boost system status...';
    });

    final buffer = StringBuffer();

    // Check in-app purchase availability
    buffer
      ..writeln('🛒 In-App Purchase Service:')
      ..writeln('   Available: ${_purchaseService.isAvailable}')
      // Check boost service availability
      ..writeln('\n⚡ Artist Boost Service:')
      ..writeln('   Available: ${_boostService.isAvailable}')
      // Check available boost products
      ..writeln('\n📦 Available Boost Products:');
    final boostProducts = [
      'artbeat_boost_quick_spark',
      'artbeat_boost_neon_surge',
      'artbeat_boost_titan_overdrive',
      'artbeat_boost_mythic_expansion',
    ];
    for (final productId in boostProducts) {
      final details = _boostService.getBoostProductDetails(productId);
      if (details != null) {
        buffer.writeln(
          '   ✅ $productId: \$${details['amount']} - ${details['title']}',
        );
      } else {
        buffer.writeln('   ❌ $productId: Not found');
      }
    }

    // Check store products
    buffer.writeln('\n🏪 Store Products:');
    final storeProducts = _purchaseService.getBoostProducts();
    if (storeProducts.isEmpty) {
      buffer.writeln('   ❌ No products loaded from store');
    } else {
      for (final product in storeProducts) {
        buffer.writeln(
          '   ✅ ${product.id}: ${product.price} - ${product.title}',
        );
      }
    }

    setState(() {
      _status = buffer.toString();
      _isLoading = false;
    });
  }

  Future<void> _testBoostPurchase() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing boost purchase...';
    });

    try {
      // Test with a dummy recipient ID (use your own user ID for testing)
      const testRecipientId = 'test_recipient_id';
      const testBoostId = 'artbeat_boost_quick_spark';

      AppLogger.info('🧪 Testing boost purchase...');

      final success = await _boostService.purchaseBoost(
        recipientId: testRecipientId,
        boostProductId: testBoostId,
        message: 'Test boost purchase',
      );

      setState(() {
        _status = success
            ? '✅ Boost purchase test successful!'
            : '❌ Boost purchase test failed - check logs for details';
        _isLoading = false;
      });
    } on Exception catch (e) {
      setState(() {
        _status = '❌ Boost purchase test error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Artist Boost Debug Test'),
      backgroundColor: ArtbeatColors.primary,
      foregroundColor: Colors.white,
    ),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Artist Boost System Debug',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  _status,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _checkStatus,
                  child: const Text('Refresh Status'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _testBoostPurchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ArtbeatColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Test Boost Purchase'),
                ),
              ),
            ],
          ),
          if (_isLoading) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    ),
  );
}
