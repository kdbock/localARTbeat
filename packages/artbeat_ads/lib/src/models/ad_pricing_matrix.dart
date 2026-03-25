import 'local_ad_size.dart';
import 'local_ad_duration.dart';

class AdPricingConfig {
  final LocalAdSize size;
  final LocalAdDuration duration;
  final String sku;
  final double price;

  const AdPricingConfig({
    required this.size,
    required this.duration,
    required this.sku,
    required this.price,
  });

  String get displayLabel {
    return '${size.displayName} - ${duration.displayName}';
  }
}

class AdPricingMatrix {
  static const List<AdPricingConfig> allConfigs = [
    // Banner ad: between sections / dashboard breaks
    AdPricingConfig(
      size: LocalAdSize.small,
      duration: LocalAdDuration.oneMonth,
      sku: 'artbeat_ad_banner_monthly',
      price: 9.99,
    ),
    // Inline ad: native-feeling placement inside feeds / browse surfaces
    AdPricingConfig(
      size: LocalAdSize.big,
      duration: LocalAdDuration.oneMonth,
      sku: 'artbeat_ad_inline_monthly',
      price: 19.99,
    ),
  ];

  static AdPricingConfig? getConfig(
    LocalAdSize size,
    LocalAdDuration duration,
  ) {
    try {
      return allConfigs.firstWhere(
        (config) => config.size == size && config.duration == duration,
      );
    } catch (e) {
      try {
        // Keep older code paths working while the merchant flow is monthly-only.
        return allConfigs.firstWhere(
          (config) =>
              config.size == size && config.duration == LocalAdDuration.oneMonth,
        );
      } catch (_) {
        return null;
      }
    }
  }

  static String? getSku(LocalAdSize size, LocalAdDuration duration) {
    return getConfig(size, duration)?.sku;
  }

  static double? getPrice(LocalAdSize size, LocalAdDuration duration) {
    return getConfig(size, duration)?.price;
  }

  static List<AdPricingConfig> getConfigsForSize(LocalAdSize size) {
    return allConfigs.where((config) => config.size == size).toList();
  }

  static List<String> getAllSkus() {
    return allConfigs.map((config) => config.sku).toList();
  }
}
