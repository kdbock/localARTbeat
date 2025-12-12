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
    // SMALL ADS (BANNER FORMAT)
    AdPricingConfig(
      size: LocalAdSize.small,
      duration: LocalAdDuration.oneWeek,
      sku: 'ad_small_1w',
      price: 0.99,
    ),
    AdPricingConfig(
      size: LocalAdSize.small,
      duration: LocalAdDuration.oneMonth,
      sku: 'ad_small_1m',
      price: 1.99,
    ),
    AdPricingConfig(
      size: LocalAdSize.small,
      duration: LocalAdDuration.threeMonths,
      sku: 'ad_small_3m',
      price: 4.99,
    ),
    // BIG ADS (SQUARE FORMAT)
    AdPricingConfig(
      size: LocalAdSize.big,
      duration: LocalAdDuration.oneWeek,
      sku: 'ad_big_1w',
      price: 1.99,
    ),
    AdPricingConfig(
      size: LocalAdSize.big,
      duration: LocalAdDuration.oneMonth,
      sku: 'ad_big_1m',
      price: 3.99,
    ),
    AdPricingConfig(
      size: LocalAdSize.big,
      duration: LocalAdDuration.threeMonths,
      sku: 'ad_big_3m',
      price: 9.99,
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
      return null;
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
