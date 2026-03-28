import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

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
      appBar: AppBar(title: Text('ad_purchase_title'.tr())),
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
                    Text(
                      'ad_purchase_retired_title'.tr(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('ad_purchase_retired_body'.tr()),
                    if (artworkTitle != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'ad_purchase_legacy_context'.tr(
                          namedArgs: {'artworkTitle': artworkTitle!},
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text('ad_purchase_manage_prompt'.tr()),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('common_close'.tr()),
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
