import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';
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
  File? _selectedImage;
  String? _uploadedImageUrl;
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    try {
      final fileName = 'ads/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final reference = FirebaseStorage.instance.ref().child(fileName);

      final uploadFile = _selectedImage!;
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

      return await reference.getDownloadURL();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ads_create_local_ad_error_failed_to_upload'.tr()),
          ),
        );
      }
      return null;
    }
  }

  Future<void> _submitAd() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      _uploadedImageUrl = await _uploadImage();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final expiresAt = now.add(Duration(days: _selectedDuration.days));

      final ad = LocalAd(
        id: '', // Will be set by service
        userId: user.uid,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: _uploadedImageUrl,
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

      await _iapService.purchaseAd(
        size: _selectedSize,
        duration: _selectedDuration,
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
    return Scaffold(
      appBar: AppBar(
        title: Text('ads_create_local_ad_text_create_ad'.tr()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHeroSection(context),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAdDetailsSection(context),
                    const SizedBox(height: 32),
                    _buildAdPlacementSection(context),
                    const SizedBox(height: 32),
                    _buildPricingSection(context),
                    const SizedBox(height: 32),
                    _buildSubmitButton(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ArtbeatColors.primaryPurple.withValues(alpha: 0.12),
            ArtbeatColors.primaryGreen.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ArtbeatColors.primaryPurple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.campaign_outlined,
                size: 48,
                color: ArtbeatColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ads_create_local_ad_text_promote_your_art'.tr(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: ArtbeatColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ads_create_local_ad_text_reach_art_lovers'.tr(),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdDetailsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ads_create_local_ad_text_ad_content'.tr(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: ArtbeatColors.primaryPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Ad Title',
              hintText: 'What are you promoting?',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
              labelStyle: TextStyle(color: ArtbeatColors.primaryPurple),
            ),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Title is required' : null,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Tell people more about your offering',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
              labelStyle: TextStyle(color: ArtbeatColors.primaryPurple),
            ),
            maxLines: 4,
            validator: (value) =>
                value?.isEmpty ?? true ? 'Description is required' : null,
          ),
        ),
        const SizedBox(height: 16),
        _buildImageSection(context),
      ],
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ads_create_local_ad_text_image_optional'.tr(),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (_selectedImage == null)
          InkWell(
            onTap: _pickImage,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: ArtbeatColors.primaryPurple.withValues(alpha: 0.3),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 32,
                      color: ArtbeatColors.primaryPurple.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ads_create_local_ad_text_tap_to_select_image'.tr(),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  backgroundColor: Colors.red[400],
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => setState(() => _selectedImage = null),
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
        Text(
          'ads_create_local_ad_text_where_to_display'.tr(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: ArtbeatColors.primaryPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'ads_create_local_ad_text_select_zone'.tr(),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<LocalAdZone>(
            initialValue: _selectedZone,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            dropdownColor: Colors.white,
            items: LocalAdZone.values
                .map(
                  (zone) => DropdownMenuItem(
                    value: zone,
                    child: Text(
                      zone.displayName,
                      style: const TextStyle(color: Colors.black87),
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: ArtbeatColors.primaryPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'ads_create_local_ad_text_select_size'.tr(),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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
                            ? ArtbeatColors.primaryPurple
                            : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected
                          ? ArtbeatColors.primaryPurple.withValues(alpha: 0.08)
                          : null,
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          size.displayName,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? ArtbeatColors.primaryPurple
                                    : Colors.black,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          size.description,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600], fontSize: 10),
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
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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
                          ? ArtbeatColors.primaryPurple
                          : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected
                        ? ArtbeatColors.primaryPurple.withValues(alpha: 0.08)
                        : null,
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : null,
                          color: isSelected
                              ? ArtbeatColors.primaryPurple
                              : Colors.black,
                        ),
                      ),
                      Text(
                        '\$${price.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ArtbeatColors.primaryGreen,
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
          backgroundColor: ArtbeatColors.primaryPurple,
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
