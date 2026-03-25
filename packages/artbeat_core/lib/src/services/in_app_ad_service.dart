import '../utils/logger.dart';

/// Legacy compatibility layer for the simplified monthly ad catalog.
///
/// ARTbeat no longer uses impression-based ad packages, ad credits, or
/// campaign analytics. Paid ad checkout is handled by the dedicated
/// `artbeat_ads` flow, and this service only exposes lightweight product
/// metadata for older shared purchase surfaces that still need to render
/// current ad options.
class InAppAdService {
  static final InAppAdService _instance = InAppAdService._internal();
  factory InAppAdService() => _instance;
  InAppAdService._internal();

  static const Map<String, Map<String, dynamic>> _adProducts = {
    'artbeat_ad_banner_monthly': {
      'amount': 9.99,
      'title': 'Banner Ad - Monthly',
      'description': 'Monthly banner placement between supported sections',
      'billingPeriod': 'monthly',
      'placementStyle': 'banner',
      'features': [
        'Events placement support',
        'Community section-break inventory',
        'Admin review before publishing',
      ],
    },
    'artbeat_ad_inline_monthly': {
      'amount': 19.99,
      'title': 'Inline Ad - Monthly',
      'description': 'Monthly inline placement inside supported feeds',
      'billingPeriod': 'monthly',
      'placementStyle': 'inline',
      'features': [
        'Community feed placement',
        'Artists and artwork placement',
        'Admin review before publishing',
      ],
    },
  };

  List<Map<String, dynamic>> getAvailableAdPackages() {
    return _adProducts.entries
        .map((entry) => {'productId': entry.key, ...entry.value})
        .toList(growable: false);
  }

  Map<String, dynamic>? getAdProductDetails(String productId) {
    return _adProducts[productId];
  }

  void logLegacyAdPurchaseAttempt(String productId) {
    AppLogger.warning(
      'Legacy ad purchase handler was invoked for $productId. '
      'ARTbeat ads now use the dedicated reviewed monthly subscription flow.',
    );
  }
}
