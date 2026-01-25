import 'package:artbeat_core/artbeat_core.dart';
import 'package:flutter/material.dart';

/// Demo screen to test in-app purchase functionality
class InAppPurchaseDemoScreen extends StatefulWidget {
  const InAppPurchaseDemoScreen({super.key});

  @override
  State<InAppPurchaseDemoScreen> createState() =>
      _InAppPurchaseDemoScreenState();
}

class _InAppPurchaseDemoScreenState extends State<InAppPurchaseDemoScreen> {
  final InAppPurchaseManager _purchaseManager = InAppPurchaseManager();
  bool _isInitialized = false;
  String _status = 'Checking initialization...';

  @override
  void initState() {
    super.initState();
    _checkInitialization();
  }

  void _checkInitialization() {
    setState(() {
      _isInitialized = InAppPurchaseSetup().isInitialized;
      _status = _isInitialized
          ? 'In-app purchases ready!'
          : 'In-app purchases not initialized';
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('In-App Purchase Demo'),
      backgroundColor: ArtbeatColors.primary,
      foregroundColor: Colors.white,
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isInitialized ? Icons.check_circle : Icons.error,
                        color: _isInitialized ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Status',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_status),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _checkInitialization,
                    child: const Text('Refresh Status'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Subscription section
          const Text(
            'Subscriptions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Subscription Plans',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isInitialized
                          ? _showFullSubscriptionWidget
                          : null,
                      child: const Text('View All Subscription Options'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Artist Boosts section
          const Text(
            'Artist Boosts',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Power Up Artists with Boosts',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Send power-ups to artists to boost their visibility and earn XP.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isInitialized ? _showBoostPurchase : null,
                      child: const Text('Send a Boost'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Ads section
          const Text(
            'Advertisement Packages',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Promote Your Artwork',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Purchase ad packages to increase visibility for your artwork.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isInitialized ? _showFullAdWidget : null,
                      child: const Text('Promote Artwork'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (_isInitialized) ...[
            const Text(
              'Debug Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Purchase Manager Available: ${_purchaseManager.isAvailable}',
                    ),
                    const SizedBox(height: 8),
                    const Text('All IAP services initialized and ready.'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );

  void _showBoostPurchase() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send an Artist Boost'),
        content: const Text('Choose a boost tier to power up this artist.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening boost purchase screen...'),
                  backgroundColor: ArtbeatColors.primary,
                ),
              );
            },
            child: const Text('Send Boost'),
          ),
        ],
      ),
    );
  }

  void _showFullSubscriptionWidget() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Subscription Plans'),
            backgroundColor: ArtbeatColors.primary,
            foregroundColor: Colors.white,
          ),
          body: const SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: SubscriptionPurchaseWidget(),
          ),
        ),
      ),
    );
  }

  void _showFullAdWidget() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            const AdPurchaseWidget(artworkTitle: 'Demo Artwork'),
      ),
    );
  }
}
