import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/direct_commission_model.dart';
import '../../services/direct_commission_service.dart';

/// Mode for the wizard: firstTime setup or editing existing settings
enum SetupMode { firstTime, editing }

/// Enhanced wizard for artists to set up commissions with portfolio & advanced pricing
class CommissionSetupWizardScreen extends StatefulWidget {
  final SetupMode mode;
  final ArtistCommissionSettings? initialSettings;

  const CommissionSetupWizardScreen({
    super.key,
    this.mode = SetupMode.firstTime,
    this.initialSettings,
  });

  @override
  State<CommissionSetupWizardScreen> createState() =>
      _CommissionSetupWizardScreenState();
}

class _CommissionSetupWizardScreenState
    extends State<CommissionSetupWizardScreen> {
  final DirectCommissionService _commissionService = DirectCommissionService();
  final core.EnhancedStorageService _storageService =
      core.EnhancedStorageService();
  final ImagePicker _imagePicker = ImagePicker();
  final PageController _pageController = PageController();

  int _currentStep = 0;
  bool _acceptingCommissions = true;
  List<CommissionType> _selectedTypes = [];
  double _basePrice = 100.0;
  int _turnaroundDays = 14;
  String _description = '';
  List<String> _portfolioImages = [];
  Map<CommissionType, double> _typePricing = {};
  Map<String, double> _sizePricing = {};
  int _maxActiveCommissions = 10;
  double _depositPercentage = 50.0;

  bool _isLoading = false;
  bool _isUploadingImage = false;

  // Size labels
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
    _initializePricingMaps();
    _loadInitialSettings();
  }

  void _initializePricingMaps() {
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
  }

  void _loadInitialSettings() {
    if (widget.initialSettings != null) {
      final settings = widget.initialSettings!;
      _acceptingCommissions = settings.acceptingCommissions;
      _selectedTypes = List.from(settings.availableTypes);
      _basePrice = settings.basePrice;
      _turnaroundDays = settings.averageTurnaroundDays;
      _description = settings.terms;
      _portfolioImages = List.from(settings.portfolioImages);
      // Merge with defaults to ensure all keys exist
      _typePricing.addAll(Map.from(settings.typePricing));
      _sizePricing.addAll(Map.from(settings.sizePricing));
      _maxActiveCommissions = settings.maxActiveCommissions;
      _depositPercentage = settings.depositPercentage;
    } else {
      _selectedTypes = [CommissionType.digital];
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not authenticated')));
        return;
      }

      final settings = ArtistCommissionSettings(
        artistId: user.uid,
        acceptingCommissions: _acceptingCommissions,
        availableTypes: _selectedTypes,
        basePrice: _basePrice,
        typePricing: _typePricing,
        sizePricing: _sizePricing,
        maxActiveCommissions: _maxActiveCommissions,
        averageTurnaroundDays: _turnaroundDays,
        depositPercentage: _depositPercentage,
        terms: _description,
        portfolioImages: _portfolioImages,
        lastUpdated: DateTime.now(),
      );

      // Use the unified method
      await _commissionService.updateArtistCommissionSettings(settings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Commission settings saved successfully!'),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pop(context, true);
          }
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving settings: $e')));
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentStep > 0) {
          setState(() => _currentStep--);
          _pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      child: Scaffold(
        appBar: core.EnhancedUniversalHeader(
          title: 'Set Up Commissions (Step ${_currentStep + 1}/6)',
          showLogo: false,
          showBackButton: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1Welcome(),
                  _buildStep2Types(),
                  _buildStep3Pricing(),
                  _buildStep4Portfolio(),
                  _buildStep5AdvancedPricing(),
                  _buildStep6Review(),
                ],
              ),
      ),
    );
  }

  Widget _buildStep1Welcome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.art_track,
                        size: 64,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Start Accepting Commissions',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Let your followers hire you for custom artwork. This quick setup will get you started.',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'What you\'ll set up:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _buildBenefitItem(
                  '✓',
                  'Commission Types',
                  'Digital, Physical, Portraits, or Commercial',
                ),
                _buildBenefitItem(
                  '✓',
                  'Base Pricing',
                  'Starting price for your work',
                ),
                _buildBenefitItem(
                  '✓',
                  'Turnaround Time',
                  'How long projects typically take',
                ),
                _buildBenefitItem(
                  '✓',
                  'Description',
                  'Tell clients about your process',
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                title: const Text('Accept Commissions'),
                subtitle: const Text('Clients will be able to request work'),
                value: _acceptingCommissions,
                onChanged: (value) {
                  setState(() => _acceptingCommissions = value);
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => _currentStep = 1);
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2Types() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What types of commissions do you want to accept?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                ...CommissionType.values.map((type) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CheckboxListTile(
                      value: _selectedTypes.contains(type),
                      onChanged: (selected) {
                        setState(() {
                          if (selected == true) {
                            _selectedTypes.add(type);
                          } else {
                            _selectedTypes.remove(type);
                          }
                        });
                      },
                      title: Text(type.displayName),
                      tileColor: Colors.grey.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _currentStep = 0);
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedTypes.isNotEmpty
                      ? () {
                          setState(() => _currentStep = 2);
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                  child: const Text('Next'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3Pricing() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set your pricing',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 32),
                Text(
                  'Base Price',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${_basePrice.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Slider(
                  value: _basePrice,
                  onChanged: (value) {
                    setState(() => _basePrice = value);
                  },
                  min: 25,
                  max: 1000,
                  divisions: 39,
                  label: '\$${_basePrice.toStringAsFixed(0)}',
                ),
                const SizedBox(height: 32),
                Text(
                  'Turnaround Time',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '$_turnaroundDays days',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Slider(
                  value: _turnaroundDays.toDouble(),
                  onChanged: (value) {
                    setState(() => _turnaroundDays = value.toInt());
                  },
                  min: 1,
                  max: 90,
                  divisions: 89,
                  label: '$_turnaroundDays days',
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _currentStep = 1);
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _currentStep = 3);
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Text('Next'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep4Portfolio() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Build Your Portfolio',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Showcase your best work to attract clients (optional but recommended)',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 24),
                // Portfolio images grid
                if (_portfolioImages.isEmpty)
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
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
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isUploadingImage ? null : _addPortfolioImage,
                    icon: _isUploadingImage
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_photo_alternate),
                    label: Text(
                      _isUploadingImage
                          ? 'Uploading...'
                          : 'Add Portfolio Image',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _currentStep = 2);
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _currentStep = 4);
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Text('Next'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep5AdvancedPricing() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Advanced Pricing',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Set modifiers for different commission types and sizes',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 24),
                // Type-specific pricing
                Text(
                  'Commission Type Modifiers',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ..._selectedTypes.map((type) {
                  final modifier = _typePricing[type] ?? 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              type.displayName,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              '+\$${modifier.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        Slider(
                          value: modifier,
                          onChanged: (value) {
                            setState(() {
                              _typePricing[type] = value;
                            });
                          },
                          min: 0,
                          max: 500,
                          divisions: 50,
                          label: '\$${modifier.toStringAsFixed(0)}',
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),
                // Size pricing
                Text(
                  'Size Modifiers',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ..._commonSizes.map((size) {
                  final modifier = _sizePricing[size] ?? 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              size,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              '+\$${modifier.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        Slider(
                          value: modifier,
                          onChanged: (value) {
                            setState(() {
                              _sizePricing[size] = value;
                            });
                          },
                          min: 0,
                          max: 500,
                          divisions: 50,
                          label: '\$${modifier.toStringAsFixed(0)}',
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),
                // Max active commissions
                Text(
                  'Max Active Commissions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$_maxActiveCommissions commissions',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'max',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _maxActiveCommissions.toDouble(),
                  onChanged: (value) {
                    setState(() => _maxActiveCommissions = value.toInt());
                  },
                  min: 1,
                  max: 20,
                  divisions: 19,
                  label: '$_maxActiveCommissions',
                ),
                const SizedBox(height: 24),
                // Deposit percentage
                Text(
                  'Deposit Required',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_depositPercentage.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'of total price',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _depositPercentage,
                  onChanged: (value) {
                    setState(() => _depositPercentage = value);
                  },
                  min: 25,
                  max: 100,
                  divisions: 15,
                  label: '${_depositPercentage.toStringAsFixed(0)}%',
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _currentStep = 3);
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _currentStep = 5);
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Text('Next'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep6Review() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Review Your Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                _buildReviewCard(
                  'Accepting Commissions',
                  _acceptingCommissions ? '✅ Yes' : '⏸ No',
                  Colors.blue,
                ),
                _buildReviewCard(
                  'Commission Types',
                  _selectedTypes.map((t) => t.displayName).join(', '),
                  Colors.purple,
                ),
                _buildReviewCard(
                  'Base Price',
                  '\$${_basePrice.toStringAsFixed(2)}',
                  Colors.green,
                ),
                _buildReviewCard(
                  'Turnaround Time',
                  '$_turnaroundDays days',
                  Colors.orange,
                ),
                const SizedBox(height: 16),
                Text(
                  'Portfolio',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                _buildReviewCard(
                  'Portfolio Images',
                  '${_portfolioImages.length} image${_portfolioImages.length != 1 ? 's' : ''}',
                  Colors.indigo,
                ),
                const SizedBox(height: 16),
                Text(
                  'Pricing Details',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                _buildReviewCard(
                  'Max Active Commissions',
                  '$_maxActiveCommissions',
                  Colors.teal,
                ),
                _buildReviewCard(
                  'Deposit Required',
                  '${_depositPercentage.toStringAsFixed(0)}%',
                  Colors.pink,
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade700,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'You\'re all set! 🎉',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade900,
                              ),
                            ),
                            Text(
                              'Clients can now request commissions from you',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _currentStep = 4);
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.check),
                  label: const Text('Save & Finish'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitItem(String emoji, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          border: Border.all(color: color.withAlpha(100)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
