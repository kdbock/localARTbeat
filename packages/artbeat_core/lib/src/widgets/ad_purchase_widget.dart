import 'package:flutter/material.dart';

/// Legacy compatibility widget for older routes that previously opened the
/// retired ad-package flow.
///
/// ARTbeat local ads now use the dedicated `artbeat_ads` submission flow,
/// where businesses create an ad, choose a placement, complete store checkout,
/// and then wait for admin review before the ad is published.
class AdPurchaseWidget extends StatelessWidget {
  final String? artworkId;
  final String? artworkTitle;
  final void Function(String)? onAdPurchased;
  final void Function(String)? onError;

  const AdPurchaseWidget({
    super.key,
    this.artworkId,
    this.artworkTitle,
    this.onAdPurchased,
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Local Ads')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.campaign, size: 36),
                    const SizedBox(height: 16),
                    const Text(
                      'The old ad-package purchase flow has been retired.',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Local ads now use the dedicated ARTbeat ad submission flow. '
                      'Businesses choose Banner or Inline, select a placement, '
                      'complete monthly store checkout, and then wait for review before publishing.',
                    ),
                    if (artworkTitle != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Legacy context: ${artworkTitle!}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Text(
                      'Use the Local Ads screens in the app to create or manage ad subscriptions.',
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
