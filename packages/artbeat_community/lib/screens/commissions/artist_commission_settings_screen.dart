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

class _CommissionPalette {
  static const Color textPrimary = Color(0xF2FFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color accentTeal = Color(0xFF22D3EE);
  static const Color accentPurple = Color(0xFF7C4DFF);
  static const Color accentGreen = Color(0xFF34D399);
  static const Color accentPink = Color(0xFFFF3D8D);

  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentPurple, accentTeal, accentGreen],
  );
}

class _SizeOption {
  const _SizeOption({required this.storageKey, required this.labelKey});

  final String storageKey;
  final String labelKey;
}

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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _basePriceController = TextEditingController();
  final TextEditingController _termsController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  bool _acceptingCommissions = false;

  List<CommissionType> _availableTypes = [];
  Map<CommissionType, double> _typePricing = {};
  Map<String, double> _sizePricing = {};
  int _maxActiveCommissions = 5;
  int _averageTurnaroundDays = 14;
  double _depositPercentage = 50.0;
  List<String> _portfolioImages = [];

  final Map<CommissionType, String> _typeLabelKeys = {
    CommissionType.digital: 'commission_settings_type_digital',
    CommissionType.physical: 'commission_settings_type_physical',
    CommissionType.portrait: 'commission_settings_type_portrait',
    CommissionType.commercial: 'commission_settings_type_commercial',
  };

  final Map<CommissionType, String> _typeDescriptionKeys = {
    CommissionType.digital: 'commission_settings_type_digital_desc',
    CommissionType.physical: 'commission_settings_type_physical_desc',
    CommissionType.portrait: 'commission_settings_type_portrait_desc',
    CommissionType.commercial: 'commission_settings_type_commercial_desc',
  };

  final List<_SizeOption> _sizeOptions = const [
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
        _initializeDefaults();
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
          _initializeDefaults();
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(
        'commission_settings_load_error'.tr(namedArgs: {'error': '$e'}),
        backgroundColor: _CommissionPalette.accentPink,
      );
    }
  }

  void _initializeDefaults() {
    _acceptingCommissions = false;
    _availableTypes = [CommissionType.digital];
    _typePricing = {
      CommissionType.digital: 0,
      CommissionType.physical: 50,
      CommissionType.portrait: 25,
      CommissionType.commercial: 100,
    };
    _sizePricing = {
      for (final option in _sizeOptions) option.storageKey: _defaultSizePrice(option)
    };
    _basePriceController.text = '50';
    _termsController.text = 'commission_settings_default_terms'.tr();
  }

  double _defaultSizePrice(_SizeOption option) {
    switch (option.storageKey) {
      case 'Medium (11x14" to 16x20")':
        return 25;
      case 'Large (18x24" to 24x36")':
        return 75;
      case 'Extra Large (30x40"+)':
        return 150;
      default:
        return 0;
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('commission_settings_not_authenticated'.tr());
      }

      final settings = ArtistCommissionSettings(
        artistId: user.uid,
        acceptingCommissions: _acceptingCommissions,
        availableTypes: _availableTypes,
        basePrice: double.tryParse(_basePriceController.text.trim()) ?? 0,
        typePricing: _typePricing,
        sizePricing: _sizePricing,
        maxActiveCommissions: _maxActiveCommissions,
        averageTurnaroundDays: _averageTurnaroundDays,
        depositPercentage: _depositPercentage,
        terms: _termsController.text.trim(),
        portfolioImages: _portfolioImages,
        lastUpdated: DateTime.now(),
      );

      await _commissionService.updateArtistCommissionSettings(settings);

      _showSnackBar(
        'commission_settings_save_success'.tr(),
        backgroundColor: _CommissionPalette.accentGreen,
      );
    } catch (e) {
      _showSnackBar(
        'commission_settings_save_error'.tr(namedArgs: {'error': '$e'}),
        backgroundColor: _CommissionPalette.accentPink,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WorldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: HudTopBar(
          title: 'commission_settings_title'.tr(),
          glassBackground: true,
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          children: [
                            _buildHeroCard(),
                            const SizedBox(height: 16),
                            _buildStatusCard(),
                            const SizedBox(height: 16),
                            _buildBasicSettingsCard(),
                            const SizedBox(height: 16),
                            _buildCommissionTypesCard(),
                            const SizedBox(height: 16),
                            _buildPricingCard(),
                            const SizedBox(height: 16),
                            _buildBusinessSettingsCard(),
                            const SizedBox(height: 16),
                            _buildTermsCard(),
                            const SizedBox(height: 16),
                            _buildPortfolioCard(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: HudButton.primary(
                          onPressed: _isSaving ? null : _saveSettings,
                          text: 'commission_settings_save_cta'.tr(),
                          isLoading: _isSaving,
                          icon: Icons.save,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      showAccentGlow: true,
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: _CommissionPalette.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _CommissionPalette.accentPurple.withValues(alpha: 0.25),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: const Icon(Icons.palette, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'commission_settings_hero_title'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _CommissionPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'commission_settings_hero_subtitle'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _CommissionPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (_acceptingCommissions
                          ? _CommissionPalette.accentGreen
                          : _CommissionPalette.accentPink)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _acceptingCommissions ? Icons.check_circle : Icons.pause_circle,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _acceptingCommissions
                          ? 'commission_settings_status_active'.tr()
                          : 'commission_settings_status_inactive'.tr(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _CommissionPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _acceptingCommissions
                          ? 'commission_settings_status_active_desc'.tr()
                          : 'commission_settings_status_inactive_desc'.tr(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _CommissionPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _acceptingCommissions,
                onChanged: (value) => setState(() => _acceptingCommissions = value),
                thumbColor: WidgetStateProperty.resolveWith(
                  (states) => Colors.white,
                ),
                trackColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? _CommissionPalette.accentGreen
                      : Colors.white.withValues(alpha: 0.2),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicSettingsCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'commission_settings_section_basic'.tr(),
            'commission_settings_section_basic_desc'.tr(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _basePriceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            decoration: GlassInputDecoration.glass(
              labelText: 'commission_settings_base_price_label'.tr(),
              hintText: 'commission_settings_base_price_hint'.tr(),
              prefixIcon: const Icon(Icons.attach_money, color: Colors.white),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'commission_settings_base_price_error'.tr();
              }
              if (double.tryParse(value.trim()) == null) {
                return 'commission_settings_base_price_invalid'.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildSliderRow(
            label: 'commission_settings_max_active_label'
                .tr(namedArgs: {'count': '$_maxActiveCommissions'}),
            value: _maxActiveCommissions.toDouble(),
            min: 1,
            max: 20,
            divisions: 19,
            onChanged: (value) => setState(() => _maxActiveCommissions = value.round()),
          ),
          const SizedBox(height: 12),
          _buildSliderRow(
            label: 'commission_settings_turnaround_label'
                .tr(namedArgs: {'days': '$_averageTurnaroundDays'}),
            value: _averageTurnaroundDays.toDouble(),
            min: 1,
            max: 90,
            divisions: 89,
            onChanged: (value) => setState(() => _averageTurnaroundDays = value.round()),
          ),
          const SizedBox(height: 12),
          _buildSliderRow(
            label: 'commission_settings_deposit_label'
                .tr(namedArgs: {'percent': '${_depositPercentage.round()}' }),
            value: _depositPercentage,
            min: 25,
            max: 100,
            divisions: 15,
            onChanged: (value) => setState(() => _depositPercentage = value),
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionTypesCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'commission_settings_section_types'.tr(),
            'commission_settings_section_types_desc'.tr(),
          ),
          const SizedBox(height: 16),
          ...CommissionType.values.map(_buildTypeOption),
        ],
      ),
    );
  }

  Widget _buildPricingCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'commission_settings_section_pricing'.tr(),
            'commission_settings_section_pricing_desc'.tr(),
          ),
          const SizedBox(height: 20),
          Text(
            'commission_settings_type_pricing_label'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _CommissionPalette.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ...CommissionType.values.map(
            (type) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _typeLabelKeys[type]?.tr() ?? '',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _CommissionPalette.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 130,
                    child: TextFormField(
                      initialValue: _typePricing[type]?.toStringAsFixed(0) ?? '0',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      decoration: GlassInputDecoration.glass(
                        hintText: '0',
                        prefixIcon:
                            const Icon(Icons.add, color: Colors.white, size: 16),
                      ),
                      onChanged: (value) =>
                          _typePricing[type] = double.tryParse(value) ?? 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'commission_settings_size_pricing_label'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _CommissionPalette.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ..._sizeOptions.map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option.labelKey.tr(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _CommissionPalette.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: TextFormField(
                      initialValue:
                          _sizePricing[option.storageKey]?.toStringAsFixed(0) ??
                              '0',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      decoration: GlassInputDecoration.glass(
                        hintText: '0',
                        prefixIcon:
                            const Icon(Icons.add, color: Colors.white, size: 16),
                      ),
                      onChanged: (value) =>
                          _sizePricing[option.storageKey] =
                              double.tryParse(value) ?? 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessSettingsCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'commission_settings_section_business'.tr(),
            'commission_settings_section_business_desc'.tr(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildBusinessStat(
                  icon: Icons.schedule,
                  title: 'commission_settings_business_turnaround'
                      .tr(namedArgs: {'days': '$_averageTurnaroundDays'}),
                  subtitle: 'commission_settings_business_turnaround_desc'.tr(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBusinessStat(
                  icon: Icons.account_balance_wallet,
                  title: 'commission_settings_business_deposit'
                      .tr(namedArgs: {'percent': '${_depositPercentage.round()}'}),
                  subtitle: 'commission_settings_business_deposit_desc'.tr(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBusinessStat(
            icon: Icons.work,
            title: 'commission_settings_business_max_active'
                .tr(namedArgs: {'count': '$_maxActiveCommissions'}),
            subtitle: 'commission_settings_business_max_active_desc'.tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'commission_settings_section_terms'.tr(),
            'commission_settings_section_terms_desc'.tr(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _termsController,
            maxLines: 8,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            decoration: GlassInputDecoration.glass(
              hintText: 'commission_settings_terms_hint'.tr(),
              labelText: 'commission_settings_terms_label'.tr(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'commission_settings_terms_error'.tr();
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSectionHeader(
                  'commission_settings_section_portfolio'.tr(),
                  'commission_settings_section_portfolio_desc'.tr(),
                ),
              ),
              HudButton.secondary(
                onPressed: _isUploadingImage ? null : _addPortfolioImage,
                text: _isUploadingImage
                    ? 'commission_settings_portfolio_uploading'.tr()
                    : 'commission_settings_portfolio_add'.tr(),
                icon: Icons.add_photo_alternate,
                height: 44,
                width: 190,
                isLoading: _isUploadingImage,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_portfolioImages.isEmpty)
            _buildPortfolioPlaceholder()
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: _portfolioImages.length,
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (core.ImageUrlValidator.isValidImageUrl(
                        _portfolioImages[index],
                      ))
                        Image(
                          image: core.ImageUrlValidator.safeNetworkImage(
                            _portfolioImages[index],
                          )!,
                          fit: BoxFit.cover,
                        )
                      else
                        Container(color: Colors.white.withValues(alpha: 0.08)),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => _removePortfolioImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPortfolioPlaceholder() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        color: Colors.white.withValues(alpha: 0.04),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.photo_library, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          Text(
            'commission_settings_portfolio_empty_title'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _CommissionPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'commission_settings_portfolio_empty_subtitle'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _CommissionPalette.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeOption(CommissionType type) {
    final isSelected = _availableTypes.contains(type);
    final label = _typeLabelKeys[type]?.tr() ?? '';
    final description = _typeDescriptionKeys[type]?.tr() ?? '';

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _availableTypes.remove(type);
          } else {
            _availableTypes.add(type);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected ? _CommissionPalette.primaryGradient : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.14),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _CommissionPalette.accentPurple.withValues(alpha: 0.2),
                    blurRadius: 24,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(_iconForType(type), color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(CommissionType type) {
    switch (type) {
      case CommissionType.digital:
        return Icons.tablet_mac;
      case CommissionType.physical:
        return Icons.brush;
      case CommissionType.portrait:
        return Icons.face_retouching_natural;
      case CommissionType.commercial:
        return Icons.business_center;
    }
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _CommissionPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _CommissionPalette.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _CommissionPalette.textSecondary,
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: _CommissionPalette.accentTeal,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
            thumbColor: _CommissionPalette.accentPurple,
            overlayColor: _CommissionPalette.accentPurple.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessStat({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _CommissionPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _CommissionPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addPortfolioImage() async {
    try {
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF121022),
          title: Text(
            'commission_settings_image_source_title'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: Text(
                  'commission_settings_image_source_gallery'.tr(),
                  style: GoogleFonts.spaceGrotesk(color: Colors.white),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: Text(
                  'commission_settings_image_source_camera'.tr(),
                  style: GoogleFonts.spaceGrotesk(color: Colors.white),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
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
        setState(() => _portfolioImages.add(uploadResult['imageUrl']!));
        _showSnackBar(
          'commission_settings_upload_success'.tr(),
          backgroundColor: _CommissionPalette.accentGreen,
        );
      }
    } catch (e) {
      _showSnackBar(
        'commission_settings_upload_error'.tr(namedArgs: {'error': '$e'}),
        backgroundColor: _CommissionPalette.accentPink,
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  void _removePortfolioImage(int index) {
    setState(() => _portfolioImages.removeAt(index));
  }

  void _showSnackBar(String message, {Color backgroundColor = Colors.black87}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        content: Text(
          message,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
