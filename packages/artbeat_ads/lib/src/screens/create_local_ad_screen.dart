import 'dart:ui';

import 'package:artbeat_core/artbeat_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io' show File;
import '../models/index.dart';
import '../services/index.dart';
import 'my_ads_screen.dart';

class CreateLocalAdScreen extends StatefulWidget {
  const CreateLocalAdScreen({Key? key, this.initialSize, this.initialDuration})
    : super(key: key);

  final LocalAdSize? initialSize;
  final LocalAdDuration? initialDuration;

  @override
  State<CreateLocalAdScreen> createState() => _CreateLocalAdScreenState();
}

class _CreateLocalAdScreenState extends State<CreateLocalAdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactController = TextEditingController();
  final _websiteController = TextEditingController();

  LocalAdZone _selectedPlacement = LocalAdZone.community;
  LocalAdSize _selectedSize = LocalAdSize.small;
  LocalAdDuration _selectedDuration = LocalAdDuration.oneMonth;
  bool _showTitle = true;
  bool _showDescription = true;
  final List<File> _selectedImages = [];
  List<String> _uploadedImageUrls = [];
  bool _isLoading = false;

  late LocalAdService _adService;
  late LocalAdIapService _adIapService;
  final MonetizationFunnelService _funnelService = MonetizationFunnelService();
  final DefensibilityTelemetryService _telemetry =
      DefensibilityTelemetryService();

  @override
  void initState() {
    super.initState();
    _selectedSize = widget.initialSize ?? LocalAdSize.small;
    _selectedDuration = LocalAdDuration.oneMonth;
    _selectedPlacement = _availablePlacementsForSelectedType.first;
    _adService = context.read<LocalAdService>();
    _adIapService = context.read<LocalAdIapService>();
    _trackFunnelStage(stage: 'form_viewed');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contactController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        for (final file in pickedFiles) {
          if (_selectedImages.length >= 4) break;
          _selectedImages.add(File(file.path));
        }
      });
      return;
    }

    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && _selectedImages.length < 4) {
      setState(() {
        _selectedImages.add(File(pickedFile.path));
      });
    }
  }

  Future<List<String>> _uploadImages() async {
    if (_selectedImages.isEmpty) return [];

    try {
      return _adService.uploadImagesForCurrentUser(_selectedImages);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ads_create_local_ad_error_failed_to_upload'.tr()),
          ),
        );
      }
      return [];
    }
  }

  Future<void> _submitAd() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = _adService.requireCurrentUserId();

      await _trackFunnelStage(
        stage: 'checkout_started',
        userId: userId,
        metadata: <String, Object?>{
          'size': _selectedSize.name,
          'duration_days': _selectedDuration.days,
          'placement': _selectedPlacement.name,
          'has_images': _selectedImages.isNotEmpty,
        },
      );

      _uploadedImageUrls = await _uploadImages();
      if (_selectedImages.isNotEmpty &&
          _uploadedImageUrls.length != _selectedImages.length) {
        throw Exception('One or more ad images failed to upload.');
      }

      final purchase = await _adIapService.purchaseAdSubscription(
        size: _selectedSize,
      );

      await _trackFunnelStage(
        stage: 'checkout_completed',
        userId: userId,
        status: 'purchase_succeeded',
        amount: purchase.price,
        currencyCode: purchase.currencyCode,
        metadata: <String, Object?>{
          'product_id': purchase.productId,
          'purchase_id': purchase.purchaseId,
          'transaction_id': purchase.transactionId,
        },
      );

      _telemetry.trackEvent(
        DefensibilityEvent.subscriptionStartOrRenewal,
        surface: _selectedPlacement.name,
        creatorId: userId,
        extra: {
          'product_id': purchase.productId,
          'purchase_id': purchase.purchaseId,
          'amount': purchase.price,
          'currency_code': purchase.currencyCode,
          'source': 'local_ad_checkout',
        },
      );

      final now = DateTime.now();
      final expiresAt = now.add(Duration(days: _selectedDuration.days));

      final ad = LocalAd(
        id: '', // Will be set by service
        userId: userId,
        title: _showTitle ? _titleController.text.trim() : '',
        description: _showDescription ? _descriptionController.text.trim() : '',
        imageUrl: _uploadedImageUrls.isNotEmpty
            ? _uploadedImageUrls.first
            : null,
        imageUrls: _uploadedImageUrls,
        contactInfo: _contactController.text.trim().isNotEmpty
            ? _contactController.text.trim()
            : null,
        websiteUrl: _websiteController.text.trim().isNotEmpty
            ? _websiteController.text.trim()
            : null,
        zone: _selectedPlacement,
        size: _selectedSize,
        createdAt: now,
        expiresAt: expiresAt,
        status: LocalAdStatus.pendingReview,
        subscriptionProductId: purchase.productId,
        purchaseId: purchase.purchaseId,
        transactionId: purchase.transactionId,
        monthlyPrice: purchase.price,
        currencyCode: purchase.currencyCode,
        autoRenewing: true,
        purchaseFollowUpStatus: 'verification_pending',
        purchaseFollowUpNotes:
            'Waiting for server-side purchase verification before review.',
      );

      final creationOutcome = await _adService.createPurchasedAd(
        ad: ad,
        verificationData: purchase.verificationData,
      );

      await _trackFunnelStage(
        stage: creationOutcome.adId != null
            ? 'review_queued'
            : 'recovery_required',
        userId: userId,
        status: creationOutcome.adId != null
            ? 'pending_review'
            : 'verification_pending',
        amount: purchase.price,
        currencyCode: purchase.currencyCode,
        metadata: <String, Object?>{
          'ad_id': creationOutcome.adId,
          'recovery_id': creationOutcome.recoveryId,
          'product_id': purchase.productId,
        },
      );

      if (mounted) {
        if (creationOutcome.adId != null) {
          _telemetry.trackEvent(
            DefensibilityEvent.sponsorCampaignConversion,
            surface: _selectedPlacement.name,
            creatorId: userId,
            campaignId: creationOutcome.adId,
            extra: {
              'status': 'pending_review',
              'source': 'local_ad_submission',
            },
          );
          await _showSubmissionSuccessDialog();
        } else {
          await _showPurchaseRecoveryDialog(creationOutcome.recoveryId);
        }
      }
    } catch (e) {
      await _trackFunnelStage(
        stage: 'checkout_failed',
        userId: _adService.currentUserId,
        status: 'submit_failed',
        metadata: <String, Object?>{
          'error': e.toString(),
          'size': _selectedSize.name,
          'duration_days': _selectedDuration.days,
          'placement': _selectedPlacement.name,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ads_create_local_ad_error_failed_to_post'.tr(
                namedArgs: {'error': e.toString()},
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _trackFunnelStage({
    required String stage,
    String? userId,
    String? status,
    String? currencyCode,
    double? amount,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) => _funnelService.trackStage(
    flow: 'local_ads',
    stage: stage,
    productFamily: 'local_ad',
    placement: _selectedPlacement.name,
    status: status,
    userId: userId,
    currencyCode: currencyCode,
    amount: amount,
    metadata: metadata,
  );

  @override
  Widget build(BuildContext context) {
    final fromStore = widget.initialSize != null;
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('ads_create_local_ad_text_create_ad'.tr()),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      body: Stack(
        children: [
          _buildWorldBackground(),
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 96, 16, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroSection(context),
                    const SizedBox(height: 24),
                    _buildGlassPanel(child: _buildAdDetailsSection(context)),
                    const SizedBox(height: 24),
                    _buildGlassPanel(
                      child: fromStore
                          ? _buildSelectedPackageSummary()
                          : _buildPricingSection(context),
                    ),
                    const SizedBox(height: 24),
                    _buildSubmitButton(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSubmissionSuccessDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: Text(
          'ads_create_local_ad_submission_title'.tr(),
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ads_create_local_ad_submission_body'.tr(),
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 14),
            Text(
              'ads_create_local_ad_next_steps_title'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ads_create_local_ad_submission_step_1'.tr(),
              style: const TextStyle(color: Colors.white70, height: 1.35),
            ),
            Text(
              'ads_create_local_ad_submission_step_2'.tr(),
              style: const TextStyle(color: Colors.white70, height: 1.35),
            ),
            Text(
              'ads_create_local_ad_submission_step_3'.tr(),
              style: const TextStyle(color: Colors.white70, height: 1.35),
            ),
            Text(
              'ads_create_local_ad_submission_step_4'.tr(),
              style: const TextStyle(color: Colors.white70, height: 1.35),
            ),
            Text(
              'ads_create_local_ad_submission_step_5'.tr(),
              style: const TextStyle(color: Colors.white70, height: 1.35),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
            child: Text('ads_create_local_ad_done'.tr()),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (context) => const MyAdsScreen(),
                ),
              );
            },
            child: Text('ads_create_local_ad_view_my_ads'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _showPurchaseRecoveryDialog(String? recoveryId) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: Text(
          'ads_create_local_ad_recovery_title'.tr(),
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ads_create_local_ad_recovery_body'.tr(),
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 14),
            Text(
              'ads_create_local_ad_next_steps_title'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ads_create_local_ad_recovery_step_1'.tr(),
              style: const TextStyle(color: Colors.white70, height: 1.35),
            ),
            Text(
              'ads_create_local_ad_recovery_step_2'.tr(),
              style: const TextStyle(color: Colors.white70, height: 1.35),
            ),
            Text(
              'ads_create_local_ad_recovery_step_3'.tr(),
              style: const TextStyle(color: Colors.white70, height: 1.35),
            ),
            if (recoveryId != null) ...[
              const SizedBox(height: 12),
              Text(
                'ads_create_local_ad_recovery_id'.tr(
                  namedArgs: {'id': recoveryId},
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (context) => const MyAdsScreen(),
                ),
              );
            },
            child: Text('ads_create_local_ad_open_my_ads'.tr()),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
            child: Text('common_close'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final fromStore = widget.initialSize != null;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        color: Colors.white.withValues(alpha: 0.06),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 40,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFFA074), Color(0xFF22D3EE)],
              ),
              image: fromStore
                  ? DecorationImage(
                      image: AssetImage(_heroAdImageAsset()),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: fromStore
                ? const SizedBox(width: 28, height: 28)
                : const Icon(Icons.campaign, size: 28, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ads_create_local_ad_hero_title'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'ads_create_local_ad_hero_subtitle'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdDetailsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF22D3EE).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.edit_note,
                color: Color(0xFF22D3EE),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'ads_create_local_ad_text_ad_content'.tr(),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'ads_create_local_ad_content_subtitle'.tr(),
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 20),
        _buildToggleRow(
          label: 'ads_create_local_ad_toggle_show_title'.tr(),
          value: _showTitle,
          onChanged: (value) {
            setState(() => _showTitle = value);
          },
        ),
        if (_showTitle) ...[
          const SizedBox(height: 12),
          _buildLabeledField(
            label: 'ads_create_local_ad_title_label'.tr(),
            required: true,
            description: 'ads_create_local_ad_title_description'.tr(),
            child: _buildGlassField(
              controller: _titleController,
              hint: 'ads_create_local_ad_title_hint'.tr(),
              validatorMessage: 'ads_create_local_ad_title_required'.tr(),
            ),
          ),
        ],
        const SizedBox(height: 20),
        _buildToggleRow(
          label: 'ads_create_local_ad_toggle_show_description'.tr(),
          value: _showDescription,
          onChanged: (value) {
            setState(() => _showDescription = value);
          },
        ),
        if (_showDescription) ...[
          const SizedBox(height: 12),
          _buildLabeledField(
            label: 'common_description'.tr(),
            required: true,
            description: 'ads_create_local_ad_description_description'.tr(),
            child: _buildGlassField(
              controller: _descriptionController,
              hint: 'ads_create_local_ad_description_hint'.tr(),
              validatorMessage: 'ads_create_local_ad_description_required'.tr(),
              maxLines: 5,
            ),
          ),
        ],
        const SizedBox(height: 20),
        _buildImageSection(context),
        const SizedBox(height: 20),
        _buildLabeledField(
          label: 'ads_create_local_ad_contact_label'.tr(),
          description: 'ads_create_local_ad_contact_description'.tr(),
          child: _buildGlassField(
            controller: _contactController,
            hint: 'ads_create_local_ad_contact_hint'.tr(),
          ),
        ),
        const SizedBox(height: 20),
        _buildLabeledField(
          label: 'ads_create_local_ad_website_label'.tr(),
          description: 'ads_create_local_ad_website_description'.tr(),
          child: _buildGlassField(
            controller: _websiteController,
            hint: 'ads_create_local_ad_website_hint'.tr(),
            keyboardType: TextInputType.url,
          ),
        ),
      ],
    );
  }

  Widget _buildLabeledField({
    required String label,
    required Widget child,
    String? description,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: GoogleFonts.spaceGrotesk(
                  color: const Color(0xFFFF6B6B),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildToggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        color: Colors.white.withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF22D3EE),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    final sizeHint = _imageSizeHint();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'ads_create_local_ad_images_title'.tr(),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'ads_create_local_ad_optional'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          sizeHint,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _imageRotationHint(),
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ..._selectedImages.asMap().entries.map((entry) {
              final index = entry.key;
              final file = entry.value;
              final isSpotlight = _selectedSize == LocalAdSize.small;
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      file,
                      height: isSpotlight ? 60 : 120,
                      width: isSpotlight ? 240 : 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImages.removeAt(index);
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
            if (_selectedImages.length < 4)
              InkWell(
                onTap: _pickImages,
                child: Container(
                  height: _selectedSize == LocalAdSize.small ? 60 : 120,
                  width: _selectedSize == LocalAdSize.small ? 240 : 120,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 24,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _selectedSize == LocalAdSize.small
                            ? 'ads_create_local_ad_add_banner_image'.tr()
                            : 'ads_create_local_ad_add_inline_image'.tr(),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPricingSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ads_create_local_ad_type_title'.tr(),
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'ads_create_local_ad_type_subtitle'.tr(),
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: LocalAdSize.values.map((size) {
            final isSelected = _selectedSize == size;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: InkWell(
                  onTap: () => setState(() {
                    _selectedSize = size;
                    final allowedPlacements =
                        _availablePlacementsForSelectedType;
                    if (!allowedPlacements.contains(_selectedPlacement)) {
                      _selectedPlacement = allowedPlacements.first;
                    }
                  }),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF22D3EE)
                            : Colors.white.withValues(alpha: 0.2),
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.02),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          size.displayName,
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          size.description,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Text(
          'ads_create_local_ad_placement_title'.tr(),
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _availablePlacementsForSelectedType.map((placement) {
            final isSelected = _selectedPlacement == placement;
            return InkWell(
              onTap: () => setState(() => _selectedPlacement = placement),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 170,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF22D3EE)
                        : Colors.white.withValues(alpha: 0.12),
                    width: isSelected ? 2 : 1,
                  ),
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.03),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _placementTitle(placement),
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _placementDescription(placement),
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              const Icon(Icons.repeat, color: Color(0xFF22D3EE), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'ads_create_local_ad_checkout_notice'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'ads_create_local_ad_available_now'.tr(),
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white.withValues(alpha: 0.58),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    final price =
        AdPricingMatrix.getPrice(_selectedSize, LocalAdDuration.oneMonth) ??
        0.0;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitAd,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF22D3EE),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'ads_create_local_ad_submit_cta'.tr(
                  namedArgs: {'price': price.toStringAsFixed(2)},
                ),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Widget _buildSelectedPackageSummary() {
    final price =
        AdPricingMatrix.getPrice(_selectedSize, LocalAdDuration.oneMonth) ??
        0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedImages.isNotEmpty ||
            (_showTitle && _titleController.text.isNotEmpty) ||
            (_showDescription && _descriptionController.text.isNotEmpty))
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ads_create_local_ad_preview_title'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ads_create_local_ad_preview_subtitle'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              _buildAdPreview(),
              const SizedBox(height: 24),
            ],
          ),
        Text(
          'ads_create_local_ad_subscription_title'.tr(),
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            color: Colors.white.withValues(alpha: 0.04),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.ads_click, color: Color(0xFF22D3EE)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedSize.displayName,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'ads_create_local_ad_subscription_frequency'.tr(),
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _placementTitle(_selectedPlacement),
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white.withValues(alpha: 0.62),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'ads_create_local_ad_subscription_price'.tr(
                  namedArgs: {'price': price.toStringAsFixed(2)},
                ),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'ads_create_local_ad_subscription_note'.tr(),
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassField({
    required TextEditingController controller,
    required String hint,
    String? validatorMessage,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
        color: const Color(0xFF1A1F2E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.spaceGrotesk(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
        cursorColor: const Color(0xFF22D3EE),
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFF1A1F2E),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 18,
            vertical: maxLines > 1 ? 16 : 14,
          ),
          hintStyle: GoogleFonts.spaceGrotesk(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 14,
          ),
          errorStyle: GoogleFonts.spaceGrotesk(
            color: const Color(0xFFFF6B6B),
            fontSize: 12,
          ),
        ),
        validator: validatorMessage == null
            ? null
            : (value) => value?.isEmpty ?? true ? validatorMessage : null,
      ),
    );
  }

  Widget _buildGlassPanel({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            color: Colors.white.withValues(alpha: 0.04),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildWorldBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF05030D), Color(0xFF0B1330), Color(0xFF041C16)],
          ),
        ),
        child: Stack(
          children: [
            _buildGlow(const Offset(-120, -60), Colors.orangeAccent),
            _buildGlow(const Offset(140, 120), Colors.tealAccent),
            _buildGlow(const Offset(-30, 320), Colors.purpleAccent),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.05,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdPreview() {
    final isBanner = _selectedSize == LocalAdSize.small;
    final previewAspectRatio = isBanner ? 320 / 80 : 4 / 3;
    final imagePreview = AspectRatio(
      aspectRatio: previewAspectRatio,
      child: _selectedImages.isNotEmpty
          ? Image.file(
              _selectedImages[0],
              fit: BoxFit.cover,
              width: double.infinity,
            )
          : Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.image_outlined,
                size: isBanner ? 16 : 28,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
    );
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF22D3EE).withValues(alpha: 0.3),
        ),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF22D3EE).withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image preview with discreet sponsored label
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                imagePreview,
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.black.withValues(alpha: 0.55),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      'ads_create_local_ad_preview_sponsored'.tr(),
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_selectedImages.isNotEmpty &&
              ((_showTitle && _titleController.text.isNotEmpty) ||
                  (_showDescription && _descriptionController.text.isNotEmpty)))
            const SizedBox(height: 12),
          // Title preview
          if (_showTitle && _titleController.text.isNotEmpty)
            Text(
              _titleController.text,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: isBanner ? 14 : 18,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          // Description preview
          if (_showDescription && _descriptionController.text.isNotEmpty)
            const SizedBox(height: 6),
          if (_showDescription && _descriptionController.text.isNotEmpty)
            Text(
              _descriptionController.text,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: isBanner ? 11 : 13,
              ),
              maxLines: isBanner ? 2 : 3,
              overflow: TextOverflow.ellipsis,
            ),
          // Show rotation indicator if multiple images
          if (_selectedImages.length > 1) const SizedBox(height: 8),
          if (_selectedImages.length > 1)
            Row(
              children: [
                Icon(
                  Icons.replay_circle_filled,
                  size: 14,
                  color: const Color(0xFF22D3EE).withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  'ads_create_local_ad_preview_rotating_images'.tr(
                    namedArgs: {'count': '${_selectedImages.length}'},
                  ),
                  style: GoogleFonts.spaceGrotesk(
                    color: const Color(0xFF22D3EE).withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _imageSizeHint() {
    final size = widget.initialSize ?? _selectedSize;
    if (size == LocalAdSize.big) {
      return 'ads_create_local_ad_image_hint_inline'.tr();
    } else {
      return 'ads_create_local_ad_image_hint_banner'.tr();
    }
  }

  String _imageRotationHint() {
    return 'ads_create_local_ad_image_rotation_hint'.tr();
  }

  List<LocalAdZone> get _availablePlacementsForSelectedType =>
      _selectedSize == LocalAdSize.big
      ? const [LocalAdZone.community, LocalAdZone.artists]
      : LocalAdZoneExtension.launchPlacements;

  String _placementTitle(LocalAdZone placement) => placement.displayName;

  String _placementDescription(LocalAdZone placement) => placement.description;

  String _heroAdImageAsset() {
    if (_selectedSize == LocalAdSize.big) {
      return 'assets/images/ad_big_1m.png';
    } else {
      return 'assets/images/ad_small_1m.png';
    }
  }

  Widget _buildGlow(Offset offset, Color color) {
    return Positioned(
      left: offset.dx < 0 ? null : offset.dx,
      right: offset.dx < 0 ? -offset.dx : null,
      top: offset.dy,
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 100,
              spreadRadius: 16,
            ),
          ],
        ),
      ),
    );
  }
}
