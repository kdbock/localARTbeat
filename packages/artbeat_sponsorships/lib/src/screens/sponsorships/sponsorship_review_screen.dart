import 'package:artbeat_core/artbeat_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

import '../../models/sponsorship.dart';
import '../../models/sponsorship_status.dart';
import '../../models/sponsorship_tier.dart';
import '../../services/sponsorship_checkout_service.dart';
import '../../services/sponsorship_repository.dart';
import '../../utils/sponsorship_placements.dart';
import '../../utils/sponsorship_pricing.dart';
import '../../utils/tour_events.dart';
import '../../widgets/gradient_cta_button.dart';
import '../../widgets/sponsorship_review_row.dart';
import '../../widgets/sponsorship_section.dart';

class SponsorshipReviewScreen extends StatefulWidget {
  const SponsorshipReviewScreen({
    super.key,
    required this.type,
    required this.duration,
    required this.price,
    this.selectedEvent,
    this.notes,
    this.radiusMiles,
  });

  final String type;
  final String duration;
  final String price;
  final TourEvent? selectedEvent;
  final String? notes;
  final double? radiusMiles;

  @override
  State<SponsorshipReviewScreen> createState() =>
      _SponsorshipReviewScreenState();
}

class _SponsorshipReviewScreenState extends State<SponsorshipReviewScreen> {
  final SponsorshipCheckoutService _checkoutService =
      SponsorshipCheckoutService();
  final SponsorshipRepository _sponsorshipRepository = SponsorshipRepository();
  final MonetizationFunnelService _funnelService = MonetizationFunnelService();
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _brandingNotesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _businessNameController.text = user?.displayName?.trim() ?? '';
    _contactEmailController.text = user?.email?.trim() ?? '';
    _trackFunnelStage(stage: 'form_viewed', userId: user?.uid);
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _contactEmailController.dispose();
    _businessAddressController.dispose();
    _phoneController.dispose();
    _brandingNotesController.dispose();
    super.dispose();
  }

  InputDecoration _buildFieldDecoration({
    required String labelText,
    required String hintText,
  }) => InputDecoration(
    labelText: labelText,
    hintText: hintText,
    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.06),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF22D3EE), width: 1.2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
    ),
  );

  @override
  Widget build(BuildContext context) => WorldBackground(
    child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            HudTopBar(
              title: 'sponsorship_review_title'.tr(),
              onBackPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
                  children: [
                    SponsorshipSection(
                      title: 'sponsorship_review_summary_title'.tr(),
                      child: Column(
                        children: [
                          SponsorshipReviewRow(
                            label: 'sponsorship_review_label_type'.tr(),
                            value: widget.type,
                          ),
                          SponsorshipReviewRow(
                            label: 'sponsorship_review_label_duration'.tr(),
                            value: widget.duration,
                          ),
                          SponsorshipReviewRow(
                            label: 'sponsorship_review_label_price'.tr(),
                            value: widget.price,
                          ),
                        ],
                      ),
                    ),
                    if (widget.selectedEvent != null)
                      SponsorshipSection(
                        title: 'sponsorship_review_event_details_title'.tr(),
                        child: Column(
                          children: [
                            SponsorshipReviewRow(
                              label: 'sponsorship_review_label_event'.tr(),
                              value: widget.selectedEvent!.name,
                            ),
                            SponsorshipReviewRow(
                              label: 'sponsorship_review_label_venue'.tr(),
                              value: widget.selectedEvent!.venue,
                            ),
                            SponsorshipReviewRow(
                              label: 'sponsorship_review_label_date'.tr(),
                              value: widget.selectedEvent!.startDate,
                            ),
                          ],
                        ),
                      ),
                    SponsorshipSection(
                      title: 'sponsorship_review_info_title'.tr(),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _businessNameController,
                            style: const TextStyle(color: Colors.white),
                            cursorColor: const Color(0xFF22D3EE),
                            decoration: _buildFieldDecoration(
                              labelText:
                                  'sponsorship_review_business_name_label'.tr(),
                              hintText: 'sponsorship_review_business_name_hint'
                                  .tr(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'sponsorship_review_business_name_error'
                                    .tr();
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _contactEmailController,
                            style: const TextStyle(color: Colors.white),
                            cursorColor: const Color(0xFF22D3EE),
                            decoration: _buildFieldDecoration(
                              labelText:
                                  'sponsorship_review_contact_email_label'.tr(),
                              hintText: 'sponsorship_review_contact_email_hint'
                                  .tr(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'sponsorship_review_contact_email_error'
                                    .tr();
                              }
                              if (!RegExp(
                                r'^[^@]+@[^@]+\.[^@]+',
                              ).hasMatch(value)) {
                                return 'sponsorship_review_contact_email_invalid'
                                    .tr();
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _businessAddressController,
                            style: const TextStyle(color: Colors.white),
                            cursorColor: const Color(0xFF22D3EE),
                            decoration: _buildFieldDecoration(
                              labelText: 'Business address',
                              hintText: '123 Main St, City, State ZIP',
                            ),
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              final requiresAddress = _resolveTier(
                                widget.type,
                              ).isRadiusBased;
                              if (!requiresAddress) return null;
                              if (value == null || value.trim().isEmpty) {
                                return 'Business address is required.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneController,
                            style: const TextStyle(color: Colors.white),
                            cursorColor: const Color(0xFF22D3EE),
                            decoration: _buildFieldDecoration(
                              labelText: 'sponsorship_review_phone_label'.tr(),
                              hintText: 'sponsorship_review_phone_hint'.tr(),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _brandingNotesController,
                            style: const TextStyle(color: Colors.white),
                            cursorColor: const Color(0xFF22D3EE),
                            decoration: _buildFieldDecoration(
                              labelText:
                                  'sponsorship_review_branding_notes_label'
                                      .tr(),
                              hintText: 'sponsorship_review_branding_notes_hint'
                                  .tr(),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                    SponsorshipSection(
                      title: 'sponsorship_review_thank_you_title'.tr(),
                      child: Text(
                        'sponsorship_review_thank_you_body'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: GradientCtaButton(
            label: _isSubmitting
                ? 'sponsorship_review_processing_button'.tr()
                : 'sponsorship_review_submit_button'.tr(),
            onPressed: _isSubmitting ? () {} : _submitSponsorship,
          ),
        ),
      ),
    ),
  );

  Future<void> _submitSponsorship() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final tier = _resolveTier(widget.type);
      final radiusMiles = widget.radiusMiles ?? _radiusFromNotes(widget.notes);
      if (tier.isRadiusBased && radiusMiles == null) {
        throw Exception(
          'A valid radius is required for this sponsorship type.',
        );
      }
      await _trackFunnelStage(
        stage: 'checkout_started',
        userId: userId,
        metadata: <String, Object?>{
          'tier': tier.value,
          'duration': widget.duration,
          'selected_event': widget.selectedEvent?.displayName,
          'radius_miles': radiusMiles,
        },
      );
      final businessAddress = _businessAddressController.text.trim();
      final targetLocation = await _resolveTargetLocation(
        tier: tier,
        businessAddress: businessAddress,
      );
      final checkout = await _checkoutService.startRecurringCheckout(
        tier: tier,
        businessName: _businessNameController.text.trim(),
        contactEmail: _contactEmailController.text.trim(),
      );
      final paymentStatus = _normalizePaymentStatus(checkout);
      final paymentFollowUpStatus = _paymentFollowUpStatusFor(checkout);
      final paymentFollowUpNotes = _paymentFollowUpNotesFor(
        tier: tier,
        checkout: checkout,
      );

      await _trackFunnelStage(
        stage: 'checkout_completed',
        userId: userId,
        status: paymentStatus,
        metadata: <String, Object?>{
          'tier': tier.value,
          'subscription_id': checkout.subscriptionId,
          'product_id': checkout.productId,
          'price_id': checkout.priceId,
          'payment_intent_status': checkout.paymentIntentStatus,
        },
      );

      final now = DateTime.now();
      final sponsorshipId = FirebaseFirestore.instance
          .collection('sponsorships')
          .doc()
          .id;
      final sponsorship = Sponsorship(
        id: sponsorshipId,
        businessId:
            FirebaseAuth.instance.currentUser?.uid ?? 'unknown_business',
        businessName: _businessNameController.text.trim(),
        businessDescription: _brandingNotesController.text.trim().isEmpty
            ? null
            : _brandingNotesController.text.trim(),
        tier: tier,
        status: SponsorshipStatus.pending,
        startDate: now,
        endDate: now.add(
          Duration(days: SponsorshipPricing.durationDaysFor(tier)),
        ),
        placementKeys: _placementsForTier(tier),
        radiusMiles: radiusMiles,
        latitude: targetLocation?.latitude,
        longitude: targetLocation?.longitude,
        logoUrl: '',
        linkUrl: '',
        createdAt: now,
        relatedEntityName: widget.selectedEvent?.displayName,
        businessAddress: businessAddress.isEmpty ? null : businessAddress,
        contactEmail: _contactEmailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        brandingNotes: _brandingNotesController.text.trim().isEmpty
            ? null
            : _brandingNotesController.text.trim(),
        additionalNotes: widget.notes,
        paymentStatus: paymentStatus,
        paymentFollowUpStatus: paymentFollowUpStatus,
        paymentFollowUpNotes: paymentFollowUpNotes,
        stripeCustomerId: checkout.customerId,
        stripeSubscriptionId: checkout.subscriptionId,
        stripePriceId: checkout.priceId,
        stripeProductId: checkout.productId,
        stripePaymentIntentStatus: checkout.paymentIntentStatus,
      );

      await _sponsorshipRepository.createSponsorship(sponsorship);
      await _trackFunnelStage(
        stage: 'review_queued',
        userId: userId,
        status: paymentFollowUpStatus,
        metadata: <String, Object?>{
          'tier': tier.value,
          'sponsorship_id': sponsorshipId,
          'subscription_id': checkout.subscriptionId,
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sponsorship submitted. Payment is on file and the request is now queued for review.',
          ),
        ),
      );
      Navigator.pop(context);
    } on Exception catch (e) {
      await _trackFunnelStage(
        stage: 'checkout_failed',
        userId: FirebaseAuth.instance.currentUser?.uid,
        status: 'submit_failed',
        metadata: <String, Object?>{
          'type': widget.type,
          'duration': widget.duration,
          'error': '$e',
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'sponsorship_review_submit_error'.tr(namedArgs: {'error': '$e'}),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _trackFunnelStage({
    required String stage,
    String? userId,
    String? status,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) => _funnelService.trackStage(
    flow: 'sponsorships',
    stage: stage,
    productFamily: 'sponsorship',
    placement: widget.type,
    status: status,
    userId: userId,
    metadata: metadata,
  );

  Future<Location?> _resolveTargetLocation({
    required SponsorshipTier tier,
    required String businessAddress,
  }) async {
    if (!tier.isRadiusBased) return null;
    if (businessAddress.isEmpty) {
      throw Exception('Business address is required for radius targeting.');
    }

    final matches = await locationFromAddress(businessAddress);
    if (matches.isEmpty) {
      throw Exception(
        'Could not locate that business address. Please enter a full address.',
      );
    }
    return matches.first;
  }

  SponsorshipTier _resolveTier(String type) {
    switch (type.toLowerCase()) {
      case 'art_walk':
      case 'artwalk':
      case 'art_walk_sponsorship':
        return SponsorshipTier.artWalk;
      case 'discover':
      case 'discovery':
        return SponsorshipTier.discover;
      case 'capture':
      default:
        return SponsorshipTier.capture;
    }
  }

  List<String> _placementsForTier(SponsorshipTier tier) {
    switch (tier) {
      case SponsorshipTier.artWalk:
        return [SponsorshipPlacements.artWalkHeader];
      case SponsorshipTier.capture:
        return [SponsorshipPlacements.captureDetailBanner];
      case SponsorshipTier.discover:
        return [SponsorshipPlacements.discoverRadarBanner];
    }
  }

  double? _radiusFromNotes(String? notes) {
    if (notes == null || notes.isEmpty) return null;
    final match = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(notes);
    if (match == null) return null;
    return double.tryParse(match.group(1)!);
  }

  String _normalizePaymentStatus(SponsorshipCheckoutResult checkout) {
    final status = checkout.status?.trim();
    if (status != null && status.isNotEmpty) {
      return status;
    }

    final intentStatus = checkout.paymentIntentStatus?.trim();
    if (intentStatus != null && intentStatus.isNotEmpty) {
      return intentStatus;
    }

    return 'payment_method_attached';
  }

  String _paymentFollowUpStatusFor(SponsorshipCheckoutResult checkout) {
    final status = _normalizePaymentStatus(checkout).toLowerCase();
    if (status == 'active' || status == 'trialing' || status == 'paid') {
      return 'paid_pending_review';
    }
    if (status == 'processing' ||
        status == 'requires_action' ||
        status == 'requires_confirmation') {
      return 'payment_processing_pending_review';
    }
    if (status == 'incomplete' || status == 'past_due') {
      return 'payment_attention_required';
    }
    return 'paid_pending_review';
  }

  String _paymentFollowUpNotesFor({
    required SponsorshipTier tier,
    required SponsorshipCheckoutResult checkout,
  }) {
    final pieces = <String>[
      'Recurring sponsorship checkout completed for ${tier.value}.',
      'Subscription ${checkout.subscriptionId} was created for admin review.',
    ];

    final status = checkout.status?.trim();
    if (status != null && status.isNotEmpty) {
      pieces.add('Stripe subscription status: $status.');
    }

    final paymentIntentStatus = checkout.paymentIntentStatus?.trim();
    if (paymentIntentStatus != null && paymentIntentStatus.isNotEmpty) {
      pieces.add('Initial payment intent status: $paymentIntentStatus.');
    }

    pieces.add(
      'Creative assets and destination link still need moderation follow-through before activation.',
    );
    return pieces.join(' ');
  }
}
