import 'package:artbeat_core/artbeat_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../models/sponsorship.dart';
import '../../models/sponsorship_status.dart';
import '../../models/sponsorship_tier.dart';
import '../../services/sponsorship_repository.dart';
import '../../widgets/sponsorship_review_row.dart';
import '../../widgets/sponsorship_section.dart';

class SponsorshipDetailScreen extends StatelessWidget {
  const SponsorshipDetailScreen({super.key, required this.sponsorshipId});

  final String sponsorshipId;

  @override
  Widget build(BuildContext context) => WorldBackground(
    child: Column(
      children: [
        HudTopBar(
          title: 'sponsorship_dashboard_title'.tr(),
          onBackPressed: () => Navigator.pop(context),
        ),
        Expanded(
          child: FutureBuilder<Sponsorship?>(
            future: SponsorshipRepository().getById(sponsorshipId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final sponsorship = snapshot.data;
              if (sponsorship == null) {
                return Center(
                  child: Text(
                    'sponsorship_dashboard_empty_title'.tr(),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  SponsorshipSection(
                    title: 'sponsorship_review_summary_title'.tr(),
                    child: Column(
                      children: [
                        SponsorshipReviewRow(
                          label: 'sponsorship_review_label_type'.tr(),
                          value: _tierLabel(sponsorship.tier).tr(),
                        ),
                        SponsorshipReviewRow(
                          label: 'sponsorship_review_label_price'.tr(),
                          value: _tierPriceLabel(sponsorship.tier).tr(),
                        ),
                        SponsorshipReviewRow(
                          label: 'sponsorship_review_label_duration'.tr(),
                          value: _dateRangeLabel(sponsorship),
                        ),
                        SponsorshipReviewRow(
                          label: 'sponsorship_detail_label_status'.tr(),
                          value: sponsorship.status.displayName,
                        ),
                        SponsorshipReviewRow(
                          label: 'sponsorship_detail_label_payment'.tr(),
                          value: (sponsorship.paymentStatus ?? '--')
                              .toUpperCase(),
                        ),
                        SponsorshipReviewRow(
                          label: 'Payment follow-up',
                          value: sponsorship.paymentFollowUpStatus ?? '--',
                        ),
                      ],
                    ),
                  ),
                  SponsorshipSection(
                    title: 'sponsorship_review_info_title'.tr(),
                    child: Column(
                      children: [
                        SponsorshipReviewRow(
                          label: 'sponsorship_review_business_name_label'.tr(),
                          value: sponsorship.businessName,
                        ),
                        SponsorshipReviewRow(
                          label: 'sponsorship_review_branding_notes_label'.tr(),
                          value:
                              sponsorship.businessDescription
                                      ?.trim()
                                      .isNotEmpty ??
                                  false
                              ? sponsorship.businessDescription!
                              : '--',
                        ),
                        SponsorshipReviewRow(
                          label: 'Business address',
                          value: sponsorship.businessAddress ?? '--',
                        ),
                        SponsorshipReviewRow(
                          label: 'sponsorship_review_contact_email_label'.tr(),
                          value: sponsorship.contactEmail ?? '--',
                        ),
                        SponsorshipReviewRow(
                          label: 'sponsorship_review_phone_label'.tr(),
                          value: sponsorship.phone ?? '--',
                        ),
                      ],
                    ),
                  ),
                  SponsorshipSection(
                    title: 'sponsorship_review_event_details_title'.tr(),
                    child: Column(
                      children: [
                        SponsorshipReviewRow(
                          label: 'sponsorship_review_label_event'.tr(),
                          value:
                              sponsorship.relatedEntityName ??
                              sponsorship.relatedEntityId ??
                              '--',
                        ),
                        SponsorshipReviewRow(
                          label: 'sponsorship_review_label_date'.tr(),
                          value:
                              '${sponsorship.startDate.month}/${sponsorship.startDate.day}/${sponsorship.startDate.year}',
                        ),
                        SponsorshipReviewRow(
                          label: 'sponsorship_review_label_type'.tr(),
                          value: sponsorship.placementKeys.join(', '),
                        ),
                        SponsorshipReviewRow(
                          label: 'Moderation notes',
                          value: sponsorship.moderationNotes ?? '--',
                        ),
                        SponsorshipReviewRow(
                          label: 'Payment follow-up notes',
                          value: sponsorship.paymentFollowUpNotes ?? '--',
                        ),
                        SponsorshipReviewRow(
                          label: 'Reviewed by',
                          value: sponsorship.reviewedBy ?? '--',
                        ),
                        SponsorshipReviewRow(
                          label: 'sponsorship_detail_label_radius'.tr(),
                          value: sponsorship.radiusMiles == null
                              ? '--'
                              : '${sponsorship.radiusMiles} mi',
                        ),
                        SponsorshipReviewRow(
                          label: 'sponsorship_detail_label_stripe_subscription'
                              .tr(),
                          value: sponsorship.stripeSubscriptionId ?? '--',
                        ),
                        SponsorshipReviewRow(
                          label: 'sponsorship_detail_label_stripe_price'.tr(),
                          value: sponsorship.stripePriceId ?? '--',
                        ),
                        SponsorshipReviewRow(
                          label: 'Stripe payment intent',
                          value: sponsorship.stripePaymentIntentStatus ?? '--',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );

  String _tierLabel(SponsorshipTier tier) {
    switch (tier) {
      case SponsorshipTier.artWalk:
        return 'sponsorship_hub_option_art_walk_title';
      case SponsorshipTier.capture:
        return 'sponsorship_hub_option_capture_title';
      case SponsorshipTier.discover:
        return 'sponsorship_hub_option_discovery_title';
    }
  }

  String _tierPriceLabel(SponsorshipTier tier) {
    switch (tier) {
      case SponsorshipTier.artWalk:
        return 'sponsorship_common_price_art_walk';
      case SponsorshipTier.capture:
        return 'sponsorship_common_price_capture';
      case SponsorshipTier.discover:
        return 'sponsorship_common_price_discovery';
    }
  }

  String _dateRangeLabel(Sponsorship sponsorship) {
    final start = sponsorship.startDate;
    final end = sponsorship.endDate;
    return '${start.month}/${start.day}/${start.year} - ${end.month}/${end.day}/${end.year}';
  }
}
