import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_core/shared_widgets.dart';

import '../../models/direct_commission_model.dart';
import '../../services/direct_commission_service.dart';

enum SetupMode { firstTime, editing }

class CommissionSetupWizardScreen extends StatefulWidget {
  const CommissionSetupWizardScreen({
    super.key,
    this.mode = SetupMode.firstTime,
    this.initialSettings,
  });

  final SetupMode mode;
  final ArtistCommissionSettings? initialSettings;

  @override
  State<CommissionSetupWizardScreen> createState() =>
      _CommissionSetupWizardScreenState();
}

class _CommissionSetupWizardScreenState
    extends State<CommissionSetupWizardScreen> {
  static const int _totalSteps = 6;
  static const List<String> _stepLabelKeys = [
    'commission_setup_step_intro',
    'commission_setup_step_types',
    'commission_setup_step_pricing',
    'commission_setup_step_portfolio',
    'commission_setup_step_advanced',
    'commission_setup_step_review',
  ];
  static const List<String> _stepSubtitleKeys = [
    'commission_setup_step_intro_subtitle',
    'commission_setup_step_types_subtitle',
    'commission_setup_step_pricing_subtitle',
    'commission_setup_step_portfolio_subtitle',
    'commission_setup_step_advanced_subtitle',
    'commission_setup_step_review_subtitle',
  ];
  static const List<_BenefitItem> _benefitItems = [
    _BenefitItem(
      icon: Icons.palette,
      titleKey: 'commission_setup_intro_checklist_types_title',
      subtitleKey: 'commission_setup_intro_checklist_types_desc',
    ),
    _BenefitItem(
      icon: Icons.attach_money,
      titleKey: 'commission_setup_intro_checklist_pricing_title',
      subtitleKey: 'commission_setup_intro_checklist_pricing_desc',
    ),
    _BenefitItem(
      icon: Icons.schedule,
      titleKey: 'commission_setup_intro_checklist_turnaround_title',
      subtitleKey: 'commission_setup_intro_checklist_turnaround_desc',
    ),
    _BenefitItem(
      icon: Icons.photo_library,
      titleKey: 'commission_setup_intro_checklist_portfolio_title',
      subtitleKey: 'commission_setup_intro_checklist_portfolio_desc',
    ),
  ];
  static const Map<CommissionType, IconData> _typeIcons = {
    CommissionType.digital: Icons.tablet_mac,
    CommissionType.physical: Icons.brush,
    CommissionType.portrait: Icons.face_retouching_natural,
    CommissionType.commercial: Icons.business_center,
  };
  static const Map<CommissionType, String> _typeLabelKeys = {
    CommissionType.digital: 'commission_settings_type_digital',
    CommissionType.physical: 'commission_settings_type_physical',
    CommissionType.portrait: 'commission_settings_type_portrait',
    CommissionType.commercial: 'commission_settings_type_commercial',
  };
  static const Map<CommissionType, String> _typeDescriptionKeys = {
    CommissionType.digital: 'commission_settings_type_digital_desc',
    CommissionType.physical: 'commission_settings_type_physical_desc',
    CommissionType.portrait: 'commission_settings_type_portrait_desc',
    CommissionType.commercial: 'commission_settings_type_commercial_desc',
  };
  static const List<_SizeOption> _sizeOptions = [
    _SizeOption(
      storageKey: 'Small (up to 8x10")',
      labelKey: 'commission_settings_size_small',
    ),
    _SizeOption(
      storageKey: 'Medium (11x14" to 16x20")',
      labelKey: 'commission_settings_size_medium',
    ),
    _SizeOption(
      storageKey: 'Large (18x24" to 24x36")',
      labelKey: 'commission_settings_size_large',
    ),
    _SizeOption(
      storageKey: 'Extra Large (30x40"+)',
      labelKey: 'commission_settings_size_extra_large',
    ),
    _SizeOption(
      storageKey: 'Custom Size',
      labelKey: 'commission_settings_size_custom',
    ),
  ];

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

  @override
  void initState() {
    super.initState();
    _initializePricingMaps();
    _loadInitialSettings();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _initializePricingMaps() {
    _typePricing = {
      CommissionType.digital: 0.0,
      CommissionType.physical: 50.0,
      CommissionType.portrait: 25.0,
      CommissionType.commercial: 100.0,
    };
    _sizePricing = {
      for (final option in _sizeOptions)
        option.storageKey: _defaultSizeModifier(option.storageKey),
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
      _typePricing.addAll(Map.from(settings.typePricing));
      _sizePricing.addAll(Map.from(settings.sizePricing));
      _maxActiveCommissions = settings.maxActiveCommissions;
      _depositPercentage = settings.depositPercentage;
    } else {
      _selectedTypes = [CommissionType.digital];
      _description = 'commission_settings_default_terms'.tr();
    }
  }

  double _defaultSizeModifier(String key) {
    switch (key) {
      case 'Medium (11x14" to 16x20")':
        return 25.0;
      case 'Large (18x24" to 24x36")':
        return 75.0;
      case 'Extra Large (30x40"+)':
        return 150.0;
      default:
        return 0.0;
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar(
          'commission_setup_error_not_authenticated'.tr(),
          backgroundColor: _WizardPalette.accentPink,
        );
        setState(() => _isLoading = false);
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

      await _commissionService.updateArtistCommissionSettings(settings);

      if (!mounted) return;
      _showSnackBar(
        'commission_setup_toast_saved'.tr(),
        backgroundColor: _WizardPalette.accentGreen,
      );
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          'commission_setup_toast_error'.tr(namedArgs: {'error': '$e'}),
          backgroundColor: _WizardPalette.accentPink,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addPortfolioImage() async {
    try {
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          child: GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'commission_setup_image_source_title'.tr(),
                  style: _sectionTitleStyle,
                ),
                const SizedBox(height: 16),
                HudButton(isPrimary: true,
                  onPressed: () => Navigator.pop(context, ImageSource.gallery),
                  text: 'commission_setup_image_source_gallery'.tr(),
                  icon: Icons.photo_library,
                ),
                const SizedBox(height: 12),
                HudButton(isPrimary: false,
                  onPressed: () => Navigator.pop(context, ImageSource.camera),
                  text: 'commission_setup_image_source_camera'.tr(),
                  icon: Icons.camera_alt,
                ),
              ],
            ),
          ),
        ),
      );

      if (source == null) return;

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _isUploadingImage = true);

      final uploadResult = await _storageService.uploadImageWithOptimization(
        imageFile: File(pickedFile.path),
        category: 'commission_portfolio',
        generateThumbnail: true,
      );

      if (uploadResult['imageUrl'] != null) {
        setState(() {
          _portfolioImages.add(uploadResult['imageUrl']!);
          _isUploadingImage = false;
        });
        if (mounted) {
          _showSnackBar(
            'commission_setup_image_success'.tr(),
            backgroundColor: _WizardPalette.accentGreen,
          );
        }
      } else {
        setState(() => _isUploadingImage = false);
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        _showSnackBar(
          'commission_setup_image_error'.tr(namedArgs: {'error': '$e'}),
          backgroundColor: _WizardPalette.accentPink,
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
          _handleBack();
        }
      },
      child: WorldBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: HudTopBar(
            title: widget.mode == SetupMode.firstTime
                ? 'commission_setup_title'.tr()
                : 'commission_setup_edit_title'.tr(),
            glassBackground: true, subtitle: '',
          ),
          body: SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      _buildProgressHeader(),
                      const SizedBox(height: 12),
                      Expanded(
                        child: PageView(
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
                      const SizedBox(height: 12),
                      _buildNavigationBar(),
                      const SizedBox(height: 16),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    final stepLabel = _stepLabelKeys[_currentStep].tr();
    final stepSubtitle = _stepSubtitleKeys[_currentStep].tr();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'commission_setup_progress_label'.tr(
                namedArgs: {
                  'current': '${_currentStep + 1}',
                  'total': '$_totalSteps',
                },
              ),
              style: _bodyStyle(opacity: 0.8, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(
                _totalSteps,
                (index) => Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.symmetric(horizontal: index == 0 ? 0 : 4),
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: index <= _currentStep
                          ? _WizardPalette.primaryGradient
                          : null,
                      color: index <= _currentStep
                          ? null
                          : Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(stepLabel, style: _sectionTitleStyle),
            const SizedBox(height: 4),
            Text(stepSubtitle, style: _bodyStyle(opacity: 0.7)),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationBar() {
    final isLastStep = _currentStep == _totalSteps - 1;
    final primaryText = isLastStep
        ? 'commission_setup_action_save'.tr()
        : 'commission_setup_action_next'.tr();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: HudButton(isPrimary: false,
              onPressed: _currentStep == 0 ? null : _handleBack,
              text: 'commission_setup_action_back'.tr(),
              icon: Icons.arrow_back,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GradientCTAButton(
              onPressed: _canProceed ? _handleNext : null,
              text: primaryText,
              icon: isLastStep ? Icons.check : Icons.arrow_forward,
              isLoading: isLastStep && _isLoading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1Welcome() {
    return _buildStepWrapper(
      [
        GlassCard(
          padding: const EdgeInsets.all(20),
          showAccentGlow: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBadge('commission_setup_intro_badge'.tr()),
              const SizedBox(height: 16),
              Text('commission_setup_intro_title'.tr(), style: _heroTitleStyle),
              const SizedBox(height: 8),
              Text(
                'commission_setup_intro_subtitle'.tr(),
                style: _bodyStyle(opacity: 0.75),
              ),
            ],
          ),
        ),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: _benefitItems
                .map(
                  (benefit) => Padding(
                    padding: EdgeInsets.only(
                      bottom: benefit == _benefitItems.last ? 0 : 16,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Icon(benefit.icon, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                benefit.titleKey.tr(),
                                style: _sectionTitleStyle,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                benefit.subtitleKey.tr(),
                                style: _bodyStyle(opacity: 0.72),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'commission_setup_accept_label'.tr(),
                      style: _sectionTitleStyle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'commission_setup_accept_subtitle'.tr(),
                      style: _bodyStyle(opacity: 0.7, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _acceptingCommissions,
                onChanged: (value) =>
                    setState(() => _acceptingCommissions = value),
                thumbColor: WidgetStateProperty.all(Colors.white),
                trackColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? _WizardPalette.accentTeal.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2Types() {
    return _buildStepWrapper(
      [
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'commission_setup_types_title'.tr(),
                'commission_setup_types_subtitle'.tr(),
              ),
              const SizedBox(height: 16),
              ...CommissionType.values.map(
                (type) => Padding(
                  padding: EdgeInsets.only(
                    bottom: type == CommissionType.values.last ? 0 : 16,
                  ),
                  child: _buildTypeOption(type),
                ),
              ),
              if (_selectedTypes.isEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'commission_setup_types_hint'.tr(),
                  style: _bodyStyle(opacity: 0.65, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3Pricing() {
    return _buildStepWrapper(
      [
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'commission_setup_pricing_title'.tr(),
                'commission_setup_pricing_subtitle'.tr(),
              ),
              const SizedBox(height: 16),
              _buildStatRow(
                'commission_settings_base_price_label'.tr(),
                _formatCurrency(_basePrice),
                icon: Icons.attach_money,
              ),
              const SizedBox(height: 8),
              Text(
                'commission_setup_pricing_base_helper'.tr(),
                style: _bodyStyle(opacity: 0.65, fontSize: 12),
              ),
              _buildSlider(
                value: _basePrice,
                min: 25,
                max: 1000,
                divisions: 39,
                label: _formatCurrency(_basePrice),
                onChanged: (value) => setState(() => _basePrice = value),
              ),
              const SizedBox(height: 24),
              _buildStatRow(
                'commission_setup_pricing_turnaround_label'.tr(),
                '${_turnaroundDays} ${'commission_setup_label_days'.tr()}',
                icon: Icons.schedule,
              ),
              const SizedBox(height: 8),
              Text(
                'commission_setup_pricing_turnaround_helper'.tr(),
                style: _bodyStyle(opacity: 0.65, fontSize: 12),
              ),
              _buildSlider(
                value: _turnaroundDays.toDouble(),
                min: 1,
                max: 90,
                divisions: 89,
                label:
                    '${_turnaroundDays} ${'commission_setup_label_days'.tr()}',
                onChanged: (value) =>
                    setState(() => _turnaroundDays = value.toInt()),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep4Portfolio() {
    return _buildStepWrapper(
      [
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'commission_setup_portfolio_title'.tr(),
                'commission_setup_portfolio_subtitle'.tr(),
              ),
              const SizedBox(height: 16),
              if (_portfolioImages.isEmpty)
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.photo_library,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'commission_setup_portfolio_empty_title'.tr(),
                          style: _sectionTitleStyle,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'commission_setup_portfolio_empty_subtitle'.tr(),
                          textAlign: TextAlign.center,
                          style: _bodyStyle(opacity: 0.7, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _portfolioImages.length,
                  itemBuilder: (context, index) => _buildPortfolioTile(index),
                ),
              const SizedBox(height: 16),
              HudButton.secondary(
                onPressed: _isUploadingImage ? null : _addPortfolioImage,
                text: _isUploadingImage
                    ? 'commission_setup_portfolio_uploading'.tr()
                    : 'commission_setup_portfolio_add_button'.tr(),
                icon: Icons.add_photo_alternate,
                isLoading: _isUploadingImage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep5AdvancedPricing() {
    return _buildStepWrapper(
      [
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'commission_setup_advanced_title'.tr(),
                'commission_setup_advanced_subtitle'.tr(),
              ),
              const SizedBox(height: 16),
              Text(
                'commission_setup_advanced_types_label'.tr(),
                style: _sectionTitleStyle,
              ),
              const SizedBox(height: 12),
              ..._selectedTypes.map(
                (type) => Padding(
                  padding: EdgeInsets.only(
                    bottom: type == _selectedTypes.last ? 0 : 16,
                  ),
                  child: _buildModifierSlider(
                    label: _typeLabelKeys[type]!.tr(),
                    value: _typePricing[type] ?? 0,
                    onChanged: (value) => setState(() {
                      _typePricing[type] = value;
                    }),
                  ),
                ),
              ),
              if (_selectedTypes.isEmpty)
                Text(
                  'commission_setup_types_hint'.tr(),
                  style: _bodyStyle(opacity: 0.65, fontSize: 12),
                ),
              if (_selectedTypes.isNotEmpty) const SizedBox(height: 24),
              Text(
                'commission_setup_advanced_sizes_label'.tr(),
                style: _sectionTitleStyle,
              ),
              const SizedBox(height: 12),
              ..._sizeOptions.map(
                (option) => Padding(
                  padding: EdgeInsets.only(
                    bottom: option == _sizeOptions.last ? 0 : 16,
                  ),
                  child: _buildModifierSlider(
                    label: option.labelKey.tr(),
                    value: _sizePricing[option.storageKey] ?? 0,
                    onChanged: (value) => setState(() {
                      _sizePricing[option.storageKey] = value;
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'commission_setup_advanced_max_label'.tr(),
                style: _sectionTitleStyle,
              ),
              const SizedBox(height: 8),
              Text(
                'commission_setup_advanced_max_helper'.tr(),
                style: _bodyStyle(opacity: 0.65, fontSize: 12),
              ),
              _buildSlider(
                value: _maxActiveCommissions.toDouble(),
                min: 1,
                max: 20,
                divisions: 19,
                label: '$_maxActiveCommissions',
                onChanged: (value) =>
                    setState(() => _maxActiveCommissions = value.toInt()),
              ),
              const SizedBox(height: 24),
              Text(
                'commission_setup_advanced_deposit_label'.tr(),
                style: _sectionTitleStyle,
              ),
              const SizedBox(height: 8),
              Text(
                'commission_setup_advanced_deposit_helper'.tr(),
                style: _bodyStyle(opacity: 0.65, fontSize: 12),
              ),
              _buildSlider(
                value: _depositPercentage,
                min: 25,
                max: 100,
                divisions: 15,
                label: '${_depositPercentage.toStringAsFixed(0)}%',
                onChanged: (value) => setState(() => _depositPercentage = value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep6Review() {
    final acceptingValue = _acceptingCommissions
        ? 'commission_setup_review_accepting_on'.tr()
        : 'commission_setup_review_accepting_off'.tr();
    final typeSummary = _selectedTypes.isEmpty
        ? 'commission_setup_types_hint'.tr()
        : _selectedTypes.map((type) => _typeLabelKeys[type]!.tr()).join(', ');
    final portfolioCount = 'commission_setup_review_portfolio_count'.plural(
      _portfolioImages.length,
      namedArgs: {'count': _portfolioImages.length.toString()},
    );

    return _buildStepWrapper(
      [
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'commission_setup_review_title'.tr(),
                'commission_setup_review_subtitle'.tr(),
              ),
              const SizedBox(height: 16),
              _buildReviewRow(
                'commission_setup_review_accepting_label'.tr(),
                acceptingValue,
              ),
              _buildReviewRow(
                'commission_setup_review_types_label'.tr(),
                typeSummary,
              ),
              _buildReviewRow(
                'commission_setup_review_base_label'.tr(),
                _formatCurrency(_basePrice),
              ),
              _buildReviewRow(
                'commission_setup_review_turnaround_label'.tr(),
                '${_turnaroundDays} ${'commission_setup_label_days'.tr()}',
              ),
              _buildReviewRow(
                'commission_setup_review_portfolio_label'.tr(),
                portfolioCount,
              ),
              _buildReviewRow(
                'commission_setup_review_pricing_label'.tr(),
                '$_maxActiveCommissions',
              ),
              _buildReviewRow(
                'commission_setup_review_deposit_label'.tr(),
                '${_depositPercentage.toStringAsFixed(0)}%',
              ),
            ],
          ),
        ),
        GlassCard(
          padding: const EdgeInsets.all(20),
          showAccentGlow: true,
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: _WizardPalette.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.rocket_launch, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'commission_setup_review_ready_title'.tr(),
                      style: _heroTitleStyle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'commission_setup_review_ready_subtitle'.tr(),
                      style: _bodyStyle(opacity: 0.8),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepWrapper(List<Widget> children) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _sectionTitleStyle),
        const SizedBox(height: 4),
        Text(subtitle, style: _bodyStyle(opacity: 0.7)),
      ],
    );
  }

  Widget _buildTypeOption(CommissionType type) {
    final isSelected = _selectedTypes.contains(type);
    final icon = _typeIcons[type] ?? Icons.palette;

    return GestureDetector(
      onTap: () => setState(() {
        if (isSelected) {
          _selectedTypes.remove(type);
        } else {
          _selectedTypes.add(type);
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected ? _WizardPalette.primaryGradient : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.18),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _WizardPalette.accentPurple.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: isSelected ? 0.18 : 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _typeLabelKeys[type]!.tr(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _typeDescriptionKeys[type]!.tr(),
                    style: _bodyStyle(opacity: 0.75, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: isSelected ? 0.3 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSelected ? Icons.check : Icons.add,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: _bodyStyle(opacity: 0.7, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSlider({
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
  }) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: _WizardPalette.accentTeal,
        inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
        thumbColor: Colors.white,
        overlayColor: _WizardPalette.accentTeal.withValues(alpha: 0.2),
        valueIndicatorColor: _WizardPalette.accentPurple,
      ),
      child: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        label: label,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildModifierSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: _bodyStyle(opacity: 0.9, fontSize: 14),
              ),
            ),
            Text(
              '+${_formatCurrency(value)}',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _WizardPalette.accentGreen,
              ),
            ),
          ],
        ),
        _buildSlider(
          value: value,
          min: 0,
          max: 500,
          divisions: 50,
          label: _formatCurrency(value),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildPortfolioTile(int index) {
    final imageUrl = _portfolioImages[index];
    final imageProvider = core.ImageUrlValidator.isValidImageUrl(imageUrl)
        ? core.ImageUrlValidator.safeNetworkImage(imageUrl)
        : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageProvider != null)
            DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(color: Colors.white.withValues(alpha: 0.05)),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _removePortfolioImage(index),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(Icons.close, size: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: _bodyStyle(opacity: 0.7, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: _bodyStyle(opacity: 0.95, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _handleBack() {
    if (_currentStep == 0) return;
    _goToStep(_currentStep - 1);
  }

  void _handleNext() {
    if (_currentStep >= _totalSteps - 1) {
      _saveSettings();
      return;
    }
    _goToStep(_currentStep + 1);
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
  }

  bool get _canProceed {
    if (_currentStep == 1) {
      return _selectedTypes.isNotEmpty;
    }
    return true;
  }

  void _showSnackBar(String message, {Color backgroundColor = Colors.black}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: backgroundColor.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatCurrency(double value) {
    final formatted =
        value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
    return '\$$formatted';
  }

  Widget _buildBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  TextStyle get _heroTitleStyle => GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: _WizardPalette.textPrimary,
      );

  TextStyle get _sectionTitleStyle => GoogleFonts.spaceGrotesk(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: _WizardPalette.textPrimary,
      );

  TextStyle _bodyStyle({double opacity = 0.8, double fontSize = 13}) {
    return GoogleFonts.spaceGrotesk(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: Colors.white.withValues(alpha: opacity),
      height: 1.4,
    );
  }
}

class _WizardPalette {
  static const Color textPrimary = Color(0xF2FFFFFF);
  static const Color accentTeal = Color(0xFF22D3EE);
  static const Color accentPurple = Color(0xFF7C4DFF);
  static const Color accentGreen = Color(0xFF34D399);
  static const Color accentPink = Color(0xFFFF3D8D);
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentPurple, accentTeal, accentGreen],
  );
}

class _BenefitItem {
  const _BenefitItem({
    required this.icon,
    required this.titleKey,
    required this.subtitleKey,
  });

  final IconData icon;
  final String titleKey;
  final String subtitleKey;
}

class _SizeOption {
  const _SizeOption({
    required this.storageKey,
    required this.labelKey,
  });

  final String storageKey;
  final String labelKey;
}
