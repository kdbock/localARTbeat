import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../models/index.dart';
import '../services/index.dart';

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

  LocalAdZone _selectedZone = LocalAdZone.home;
  LocalAdSize _selectedSize = LocalAdSize.small;
  LocalAdDuration _selectedDuration = LocalAdDuration.oneWeek;
  bool _showTitle = true;
  bool _showDescription = true;
  final List<File> _selectedImages = [];
  List<String> _uploadedImageUrls = [];
  bool _isLoading = false;

  late LocalAdService _adService;
  late LocalAdIapService _iapService;

  @override
  void initState() {
    super.initState();
    _selectedSize = widget.initialSize ?? LocalAdSize.small;
    _selectedDuration = widget.initialDuration ?? LocalAdDuration.oneWeek;
    _adService = LocalAdService();
    _iapService = LocalAdIapService();
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
      final urls = <String>[];
      for (final uploadFile in _selectedImages) {
        final fileName = 'ads/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final reference = FirebaseStorage.instance.ref().child(fileName);

        try {
          await reference.putFile(uploadFile);
        } catch (e) {
          if (e.toString().contains('NSURLFileProtectionComplete') ||
              e.toString().contains('file protection')) {
            final tempDir = Directory.systemTemp;
            final tempFile = File('${tempDir.path}/temp_ad_image.jpg');
            await uploadFile.copy(tempFile.path);
            await reference.putFile(tempFile);
            await tempFile.delete();
          } else {
            rethrow;
          }
        }

        urls.add(await reference.getDownloadURL());
      }

      return urls;
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _iapService.purchaseAd(
        size: _selectedSize,
        duration: _selectedDuration,
      );

      _uploadedImageUrls = await _uploadImages();

      final now = DateTime.now();
      final expiresAt = now.add(Duration(days: _selectedDuration.days));

      final ad = LocalAd(
        id: '', // Will be set by service
        userId: user.uid,
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
        zone: _selectedZone,
        size: _selectedSize,
        createdAt: now,
        expiresAt: expiresAt,
        status: LocalAdStatus.active,
      );

      await _adService.createAd(ad);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ads_create_local_ad_success_ad_posted_successfully'.tr(),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ads_create_local_ad_error_failed_to_post'.tr()),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fromStore =
        widget.initialSize != null && widget.initialDuration != null;
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
                    _buildGlassPanel(child: _buildAdPlacementSection(context)),
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

  Widget _buildHeroSection(BuildContext context) {
    final fromStore =
        widget.initialSize != null && widget.initialDuration != null;
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
                  'ads_create_local_ad_text_promote_your_art'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'ads_create_local_ad_text_reach_art_lovers'.tr(),
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
          'Create compelling ad content that captures attention',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 20),
        _buildToggleRow(
          label: 'Show Title',
          value: _showTitle,
          onChanged: (value) {
            setState(() => _showTitle = value);
          },
        ),
        if (_showTitle) ...[
          const SizedBox(height: 12),
          _buildLabeledField(
            label: 'Ad Title',
            required: true,
            description:
                'A catchy headline that grabs attention (max 60 characters)',
            child: _buildGlassField(
              controller: _titleController,
              hint: 'e.g., "Fresh Artisan Coffee - 20% Off This Week!"',
              validatorMessage: 'Title is required',
            ),
          ),
        ],
        const SizedBox(height: 20),
        _buildToggleRow(
          label: 'Show Description',
          value: _showDescription,
          onChanged: (value) {
            setState(() => _showDescription = value);
          },
        ),
        if (_showDescription) ...[
          const SizedBox(height: 12),
          _buildLabeledField(
            label: 'Description',
            required: true,
            description: 'Explain your offer and why locals should care',
            child: _buildGlassField(
              controller: _descriptionController,
              hint: 'Describe your business, products, or special offers...',
              validatorMessage: 'Description is required',
              maxLines: 5,
            ),
          ),
        ],
        const SizedBox(height: 20),
        _buildImageSection(context),
        const SizedBox(height: 20),
        _buildLabeledField(
          label: 'Contact Information',
          description: 'How can customers reach you?',
          child: _buildGlassField(
            controller: _contactController,
            hint: 'Phone: (555) 123-4567 or @yourhandle',
          ),
        ),
        const SizedBox(height: 20),
        _buildLabeledField(
          label: 'Website URL',
          description: 'Link to your website or online presence',
          child: _buildGlassField(
            controller: _websiteController,
            hint: 'https://yourbusiness.com',
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
            activeColor: const Color(0xFF22D3EE),
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
              'Ad Images',
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
                'Optional',
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 24,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Add banner image',
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

  Widget _buildAdPlacementSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFA074).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.location_on,
                color: Color(0xFFFFA074),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'ads_create_local_ad_text_where_to_display'.tr(),
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
          'Choose where your ad will appear in the app',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Display Zone',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Select the section where your ad will be shown',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(14),
            color: const Color(0xFF1A1F2E),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DropdownButtonFormField<LocalAdZone>(
            initialValue: _selectedZone,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.transparent,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
            ),
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            iconEnabledColor: Colors.white70,
            dropdownColor: const Color(0xFF0F172A),
            items: LocalAdZone.values
                .map(
                  (zone) => DropdownMenuItem(
                    value: zone,
                    child: Text(
                      zone.displayName,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                )
                .toList(),
            onChanged: (zone) {
              if (zone != null) {
                setState(() => _selectedZone = zone);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPricingSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ads_create_local_ad_text_size_and_duration'.tr(),
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'ads_create_local_ad_text_select_size'.tr(),
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
                  onTap: () => setState(() => _selectedSize = size),
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
        const SizedBox(height: 24),
        Text(
          'ads_create_local_ad_text_select_duration'.tr(),
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: LocalAdDuration.values.map((duration) {
            final isSelected = _selectedDuration == duration;
            final price =
                AdPricingMatrix.getPrice(_selectedSize, duration) ?? 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => setState(() => _selectedDuration = duration),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        duration.displayName,
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: isSelected ? FontWeight.bold : null,
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      Text(
                        '\$${price.toStringAsFixed(2)}',
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF34D399),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    final price =
        AdPricingMatrix.getPrice(_selectedSize, _selectedDuration) ?? 0.0;
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
                'ads_create_local_ad_text_post_ad_for_price'.tr().replaceAll(
                  '{price}',
                  '\$${price.toStringAsFixed(2)}',
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
        AdPricingMatrix.getPrice(_selectedSize, _selectedDuration) ?? 0.0;
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
                'Ad Preview',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'How your ad will appear to users',
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
          'Your Ad Package',
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
                      _selectedDuration.displayName,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${price.toStringAsFixed(2)}',
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
          'Package selected from the store.',
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
    final isSpotlight = _selectedSize == LocalAdSize.small;
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
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white.withValues(alpha: 0.12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                'Sponsored',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Image preview
          if (_selectedImages.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: isSpotlight ? 320 / 50 : 300 / 250,
                child: Image.file(
                  _selectedImages[0],
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
          if (_selectedImages.isNotEmpty &&
              ((_showTitle && _titleController.text.isNotEmpty) ||
                  (_showDescription &&
                      _descriptionController.text.isNotEmpty)))
            const SizedBox(height: 12),
          // Title preview
          if (_showTitle && _titleController.text.isNotEmpty)
            Text(
              _titleController.text,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: isSpotlight ? 14 : 18,
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
                fontSize: isSpotlight ? 11 : 13,
              ),
              maxLines: isSpotlight ? 2 : 3,
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
                  '${_selectedImages.length} rotating images',
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
      // Billboard ads - large square format
      return 'Recommended: 300 x 250 px (MREC format)';
    } else {
      // Spotlight ads - banner format (industry standard)
      return 'Recommended: 320 x 50 px (mobile banner format)';
    }
  }

  String _imageRotationHint() {
    return 'Upload 2-4 images and they will automatically rotate every few seconds in your ad';
  }

  String _heroAdImageAsset() {
    if (_selectedSize == LocalAdSize.big) {
      if (_selectedDuration == LocalAdDuration.oneWeek) {
        return 'assets/images/ad_big_1w.png';
      } else if (_selectedDuration == LocalAdDuration.oneMonth) {
        return 'assets/images/ad_big_1m.png';
      } else {
        return 'assets/images/ad_big_3m.png';
      }
    } else {
      if (_selectedDuration == LocalAdDuration.oneWeek) {
        return 'assets/images/ad_small_1w.png';
      } else if (_selectedDuration == LocalAdDuration.oneMonth) {
        return 'assets/images/ad_small_1m.png';
      } else {
        return 'assets/images/ad_small_3m.png';
      }
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
