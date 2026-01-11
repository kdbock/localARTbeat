// Core definition of subscription tier that should be used across all modules

/// Represents the different subscription tiers available in the application
/// Updated to 2025 industry standards with competitive pricing
enum SubscriptionTier {
  free('free', 'Free'),
  starter('starter', 'Starter'),
  creator('creator', 'Creator'),
  business('business', 'Gallery / Collective'),
  enterprise('enterprise', 'Enterprise');

  final String apiName;
  final String displayName;

  const SubscriptionTier(this.apiName, this.displayName);

  /// Returns the monthly price in dollars (2025 industry-standard pricing)
  double get monthlyPrice {
    switch (this) {
      case SubscriptionTier.free:
        return 0.0;
      case SubscriptionTier.starter:
        return 4.99; // Entry-level creators
      case SubscriptionTier.creator:
        return 12.99; // Matches Canva Pro pricing
      case SubscriptionTier.business:
        return 29.99; // Small businesses (matches Shopify)
      case SubscriptionTier.enterprise:
        return 79.99; // Galleries/institutions
    }
  }

  /// Returns the yearly price in dollars
  double get yearlyPrice {
    switch (this) {
      case SubscriptionTier.free:
        return 0.0;
      case SubscriptionTier.starter:
        return 47.99; // 20% savings
      case SubscriptionTier.creator:
        return 124.99; // 20% savings
      case SubscriptionTier.business:
        return 289.99; // Yearly price for Apple App Store
      case SubscriptionTier.enterprise:
        return 769.99; // Yearly price for Apple App Store
    }
  }

  /// Returns a list of features included in this subscription tier
  /// Updated with 2025 usage-based limits and modern features
  List<String> get features {
    switch (this) {
      case SubscriptionTier.free:
        return [
          'Up to 10 artworks',
          'Appear on Local Discovery Map',
          'Standard Local Reach',
          'Community Support',
          '0.5GB Secure Storage',
        ];
      case SubscriptionTier.starter:
        return [
          'Up to 25 artworks',
          'Enhanced Local Discovery',
          'Direct Interest Messaging',
          'Email support',
          '5GB Secure Storage',
        ];
      case SubscriptionTier.creator:
        return [
          'Up to 100 artworks',
          'Featured Placement (3-5x more views)',
          'Launch Unlimited Sale Events',
          'Prioritized Discovery',
          'Priority Artist Support',
          '25GB Secure Storage',
        ];
      case SubscriptionTier.business:
        return [
          'Unlimited artworks',
          'Gallery/Collective management',
          'Team collaboration (up to 5 users)',
          'Custom Branding for your Studio',
          'Advanced Discovery Insights',
          '100GB Secure Storage',
          'Dedicated Success Manager',
        ];
      case SubscriptionTier.enterprise:
        return [
          'Unlimited everything',
          'White-label Gallery Experience',
          'Custom Integrations',
          'Enterprise Security',
          'Dedicated Account Manager',
        ];
    }
  }

  /// Convert from legacy name and new names
  static SubscriptionTier fromLegacyName(String name) {
    switch (name.toLowerCase()) {
      // Free tier
      case 'free':
      case 'none':
        return SubscriptionTier.free;

      // Starter tier (new) / Basic tier (legacy)
      case 'starter':
      case 'artist_basic':
      case 'artistbasic':
      case 'basic':
        return SubscriptionTier.starter;

      // Creator tier (new) / Pro tier (legacy)
      case 'creator':
      case 'artist_pro':
      case 'artistpro':
      case 'pro':
      case 'standard':
        return SubscriptionTier.creator;

      // Business tier (new) / Gallery tier (legacy)
      case 'business':
      case 'gallery_business':
      case 'premium':
        return SubscriptionTier.business;

      // Enterprise tier (new)
      case 'enterprise':
      case 'enterprise_plus':
        return SubscriptionTier.enterprise;

      default:
        return SubscriptionTier.free;
    }
  }

  /// Get price display string
  String get priceString {
    final price = monthlyPrice;
    return price > 0 ? '\$${price.toStringAsFixed(2)}/month' : 'Free';
  }
}
