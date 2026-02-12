import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_utils.dart';

enum ChapterPartnerType {
  city('city'),
  university('university'),
  festival('festival'),
  corporate('corporate'),
  district('district');

  final String value;
  const ChapterPartnerType(this.value);

  static ChapterPartnerType fromString(String value) {
    return ChapterPartnerType.values.firstWhere(
      (type) => type.value == value.toLowerCase(),
      orElse: () => ChapterPartnerType.district,
    );
  }
}

class BrandingConfig {
  final String primaryColor;
  final String secondaryColor;
  final String bannerImageUrl;
  final String heroHeadline;
  final String shortDescription;
  final String partnerLogoUrl;
  final bool sponsorBadgeEnabled;

  BrandingConfig({
    required this.primaryColor,
    required this.secondaryColor,
    required this.bannerImageUrl,
    required this.heroHeadline,
    required this.shortDescription,
    required this.partnerLogoUrl,
    this.sponsorBadgeEnabled = false,
  });

  factory BrandingConfig.fromMap(Map<String, dynamic> data) {
    return BrandingConfig(
      primaryColor: FirestoreUtils.safeStringDefault(data['primary_color'], '#000000'),
      secondaryColor: FirestoreUtils.safeStringDefault(data['secondary_color'], '#FFFFFF'),
      bannerImageUrl: FirestoreUtils.safeStringDefault(data['banner_image_url']),
      heroHeadline: FirestoreUtils.safeStringDefault(data['hero_headline']),
      shortDescription: FirestoreUtils.safeStringDefault(data['short_description']),
      partnerLogoUrl: FirestoreUtils.safeStringDefault(data['partner_logo_url']),
      sponsorBadgeEnabled: FirestoreUtils.safeBool(data['sponsor_badge_enabled'], false),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'primary_color': primaryColor,
      'secondary_color': secondaryColor,
      'banner_image_url': bannerImageUrl,
      'hero_headline': heroHeadline,
      'short_description': shortDescription,
      'partner_logo_url': partnerLogoUrl,
      'sponsor_badge_enabled': sponsorBadgeEnabled,
    };
  }
}

class ChapterPartner {
  final String id;
  final String name;
  final String slug;
  final ChapterPartnerType partnerType;
  final BrandingConfig brandingConfig;
  final bool isActive;
  final String subscriptionTier;
  final DateTime startDate;
  final DateTime? renewalDate;
  final bool analyticsEnabled;

  ChapterPartner({
    required this.id,
    required this.name,
    required this.slug,
    required this.partnerType,
    required this.brandingConfig,
    this.isActive = true,
    required this.subscriptionTier,
    required this.startDate,
    this.renewalDate,
    this.analyticsEnabled = false,
  });

  factory ChapterPartner.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChapterPartner(
      id: doc.id,
      name: FirestoreUtils.safeStringDefault(data['name']),
      slug: FirestoreUtils.safeStringDefault(data['slug']),
      partnerType: ChapterPartnerType.fromString(
        FirestoreUtils.safeStringDefault(data['partner_type'], 'district'),
      ),
      brandingConfig: BrandingConfig.fromMap(
        data['branding_config'] as Map<String, dynamic>? ?? {},
      ),
      isActive: FirestoreUtils.safeBool(data['active_status'], true),
      subscriptionTier: FirestoreUtils.safeStringDefault(data['subscription_tier'], 'basic'),
      startDate: FirestoreUtils.safeDateTime(data['start_date']),
      renewalDate: FirestoreUtils.getOptionalDateTime(data, 'renewal_date'),
      analyticsEnabled: FirestoreUtils.safeBool(data['analytics_enabled'], false),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'slug': slug,
      'partner_type': partnerType.value,
      'branding_config': brandingConfig.toMap(),
      'active_status': isActive,
      'subscription_tier': subscriptionTier,
      'start_date': Timestamp.fromDate(startDate),
      if (renewalDate != null) 'renewal_date': Timestamp.fromDate(renewalDate!),
      'analytics_enabled': analyticsEnabled,
    };
  }
}
