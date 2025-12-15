import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/direct_commission_model.dart';
import '../../services/direct_commission_service.dart';
import '../../theme/community_colors.dart';

class ArtistCommissionSettingsScreen extends StatefulWidget {
  const ArtistCommissionSettingsScreen({super.key});

  @override
  State<ArtistCommissionSettingsScreen> createState() =>
      _ArtistCommissionSettingsScreenState();
}

class _ArtistCommissionSettingsScreenState
    extends State<ArtistCommissionSettingsScreen> {
  final DirectCommissionService _commissionService = DirectCommissionService();
  final core.EnhancedStorageService _storageService =
      core.EnhancedStorageService();
  final ImagePicker _imagePicker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final _basePriceController = TextEditingController();
  final _termsController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  // Form fields
  bool _acceptingCommissions = false;
  List<CommissionType> _availableTypes = [];
  Map<CommissionType, double> _typePricing = {};
  Map<String, double> _sizePricing = {};
  int _maxActiveCommissions = 5;
  int _averageTurnaroundDays = 14;
  double _depositPercentage = 50.0;
  List<String> _portfolioImages = [];

  final Map<CommissionType, String> _typeDescriptions = {
    CommissionType.digital: 'Digital artwork delivered as files',
    CommissionType.physical: 'Physical artwork shipped to client',
    CommissionType.portrait: 'Custom portraits of people or pets',
    CommissionType.commercial: 'Artwork for commercial use',
  };

  final List<String> _commonSizes = [
    'Small (up to 8x10")',
    'Medium (11x14" to 16x20")',
    'Large (18x24" to 24x36")',
    'Extra Large (30x40"+)',
    'Custom Size',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _basePriceController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final settings = await _commissionService.getArtistSettings(user.uid);

      setState(() {
        if (settings != null) {
          _acceptingCommissions = settings.acceptingCommissions;
          _availableTypes = List.from(settings.availableTypes);
          _typePricing = Map.from(settings.typePricing);
          _sizePricing = Map.from(settings.sizePricing);
          _maxActiveCommissions = settings.maxActiveCommissions;
          _averageTurnaroundDays = settings.averageTurnaroundDays;
          _depositPercentage = settings.depositPercentage;
          _portfolioImages = List.from(settings.portfolioImages);
          _basePriceController.text = settings.basePrice.toString();
          _termsController.text = settings.terms;
        } else {
          // Initialize with defaults
          _initializeDefaults();
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading settings: $e')));
      }
    }
  }

  void _initializeDefaults() {
    _acceptingCommissions = false;
    _availableTypes = [CommissionType.digital];
    _typePricing = {
      CommissionType.digital: 0.0,
      CommissionType.physical: 50.0,
      CommissionType.portrait: 25.0,
      CommissionType.commercial: 100.0,
    };
    _sizePricing = {
      'Small (up to 8x10")': 0.0,
      'Medium (11x14" to 16x20")': 25.0,
      'Large (18x24" to 24x36")': 75.0,
      'Extra Large (30x40"+)': 150.0,
      'Custom Size': 0.0,
    };
    _basePriceController.text = '50.0';
    _termsController.text =
        '''
Commission Terms & Conditions:

1. Payment: 50% deposit required to start work, remaining balance due upon completion.
2. Revisions: Up to 2 minor revisions included in base price.
3. Timeline: Estimated completion time provided with quote.
4. Copyright: Client receives usage rights, artist retains copyright unless otherwise agreed.
5. Cancellation: Deposit is non-refundable after work begins.

Please contact me with any questions before placing your commission request.
    '''
            .trim();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final settings = ArtistCommissionSettings(
        artistId: user.uid,
        acceptingCommissions: _acceptingCommissions,
        availableTypes: _availableTypes,
        basePrice: double.tryParse(_basePriceController.text) ?? 0.0,
        typePricing: _typePricing,
        sizePricing: _sizePricing,
        maxActiveCommissions: _maxActiveCommissions,
        averageTurnaroundDays: _averageTurnaroundDays,
        depositPercentage: _depositPercentage,
        terms: _termsController.text,
        portfolioImages: _portfolioImages,
        lastUpdated: DateTime.now(),
      );

      await _commissionService.updateArtistCommissionSettings(settings);

      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commission settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving settings: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 48 + 4),
        child: Container(
          decoration: const BoxDecoration(
            gradient: core.ArtbeatColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.palette,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Commission Settings',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Configure your commission preferences',
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
      backgroundColor: CommunityColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Status Card
                  _buildStatusCard(),
                  const SizedBox(height: 16),

                  // Basic Settings
                  _buildBasicSettingsCard(),
                  const SizedBox(height: 16),

                  // Commission Types
                  _buildCommissionTypesCard(),
                  const SizedBox(height: 16),

                  // Pricing
                  _buildPricingCard(),
                  const SizedBox(height: 16),

                  // Business Settings
                  _buildBusinessSettingsCard(),
                  const SizedBox(height: 16),

                  // Terms & Conditions
                  _buildTermsCard(),
                  const SizedBox(height: 16),

                  // Portfolio Images
                  _buildPortfolioCard(),
                  const SizedBox(height: 24),

                  // Save Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      gradient: core.ArtbeatColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: CommunityColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.save, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Save Settings',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _acceptingCommissions
              ? [Colors.green.shade50, Colors.green.shade100]
              : [Colors.orange.shade50, Colors.orange.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _acceptingCommissions
              ? Colors.green.shade200
              : Colors.orange.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _acceptingCommissions
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _acceptingCommissions
                        ? Icons.check_circle
                        : Icons.pause_circle,
                    color: _acceptingCommissions
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _acceptingCommissions
                            ? 'Accepting Commissions'
                            : 'Not Accepting Commissions',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: CommunityColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _acceptingCommissions
                            ? 'Your commission request form is visible to clients'
                            : 'Clients cannot request new commissions from you',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: CommunityColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _acceptingCommissions,
                  onChanged: (value) {
                    setState(() => _acceptingCommissions = value);
                  },
                  thumbColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.white;
                    }
                    return Colors.grey.shade300;
                  }),
                  trackColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.green.shade600;
                    }
                    return Colors.grey.shade400;
                  }),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Settings',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _basePriceController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Base Price (\$)',
                hintText: 'Starting price for commissions',
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a base price';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Max Active Commissions: $_maxActiveCommissions'),
                      Slider(
                        value: _maxActiveCommissions.toDouble(),
                        min: 1,
                        max: 20,
                        divisions: 19,
                        label: _maxActiveCommissions.toString(),
                        onChanged: (value) {
                          setState(() => _maxActiveCommissions = value.round());
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Average Turnaround: $_averageTurnaroundDays days'),
                      Slider(
                        value: _averageTurnaroundDays.toDouble(),
                        min: 1,
                        max: 90,
                        divisions: 89,
                        label: '$_averageTurnaroundDays days',
                        onChanged: (value) {
                          setState(
                            () => _averageTurnaroundDays = value.round(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deposit Percentage: ${_depositPercentage.round()}%',
                      ),
                      Slider(
                        value: _depositPercentage,
                        min: 25,
                        max: 100,
                        divisions: 15,
                        label: '${_depositPercentage.round()}%',
                        onChanged: (value) {
                          setState(() => _depositPercentage = value);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionTypesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Commission Types',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Select the types of commissions you offer',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ...CommissionType.values.map((type) {
              final isSelected = _availableTypes.contains(type);
              return CheckboxListTile(
                title: Text(type.displayName),
                subtitle: Text(_typeDescriptions[type] ?? ''),
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _availableTypes.add(type);
                    } else {
                      _availableTypes.remove(type);
                    }
                  });
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pricing Modifiers',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Additional charges for different types and sizes',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),

            // Type Pricing
            Text(
              'Type Pricing (added to base price)',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ...CommissionType.values.map((type) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(width: 120, child: Text(type.displayName)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: _typePricing[type]?.toString() ?? '0',
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixText: '+\$',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _typePricing[type] = double.tryParse(value) ?? 0.0;
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),

            // Size Pricing
            Text(
              'Size Pricing (added to base price)',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ..._commonSizes.map((size) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 160,
                      child: Text(size, style: const TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: _sizePricing[size]?.toString() ?? '0',
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixText: '+\$',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _sizePricing[size] = double.tryParse(value) ?? 0.0;
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Business Settings',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: Text('Average Turnaround: $_averageTurnaroundDays days'),
              subtitle: const Text('How long commissions typically take'),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: Text('Deposit: ${_depositPercentage.round()}%'),
              subtitle: const Text('Percentage required upfront'),
            ),
            ListTile(
              leading: const Icon(Icons.work),
              title: Text('Max Active: $_maxActiveCommissions'),
              subtitle: const Text('Maximum concurrent commissions'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms & Conditions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'These terms will be shown to clients before they request a commission',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _termsController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Terms & Conditions',
                hintText: 'Enter your commission terms...',
              ),
              maxLines: 8,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your terms and conditions';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Portfolio Images',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _isUploadingImage ? null : _addPortfolioImage,
                  icon: _isUploadingImage
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_photo_alternate),
                  label: Text(_isUploadingImage ? 'Uploading...' : 'Add Image'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Showcase your work to potential clients',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            if (_portfolioImages.isEmpty)
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_library,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No portfolio images added',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _portfolioImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image:
                              core.ImageUrlValidator.isValidImageUrl(
                                _portfolioImages[index],
                              )
                              ? DecorationImage(
                                  image: core.ImageUrlValidator.safeNetworkImage(
                                    _portfolioImages[index],
                                  )!,
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removePortfolioImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
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
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addPortfolioImage() async {
    try {
      // Show image source selection dialog
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      // Pick image
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // Show loading indicator
      setState(() => _isUploadingImage = true);

      // Upload image to Firebase Storage
      final imageFile = File(pickedFile.path);
      final uploadResult = await _storageService.uploadImageWithOptimization(
        imageFile: imageFile,
        category: 'commission_portfolio',
        generateThumbnail: true,
      );

      // Add image URL to portfolio
      if (uploadResult['imageUrl'] != null) {
        setState(() {
          _portfolioImages.add(uploadResult['imageUrl']!);
          _isUploadingImage = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Portfolio image uploaded successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error uploading image: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _removePortfolioImage(int index) {
    setState(() {
      _portfolioImages.removeAt(index);
    });
  }
}
