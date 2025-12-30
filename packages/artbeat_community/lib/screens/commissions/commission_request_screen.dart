import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/direct_commission_model.dart';
import '../../services/direct_commission_service.dart';
import '../../widgets/widgets.dart';
import 'commission_gallery_screen.dart';
import 'commission_templates_browser.dart';

class CommissionRequestScreen extends StatefulWidget {
  final String artistId;
  final String artistName;
  final ArtistCommissionSettings? artistSettings;

  const CommissionRequestScreen({
    super.key,
    required this.artistId,
    required this.artistName,
    this.artistSettings,
  });

  @override
  State<CommissionRequestScreen> createState() => _CommissionRequestScreenState();
}

class _CommissionRequestScreenState extends State<CommissionRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sizeController = TextEditingController();
  final _mediumController = TextEditingController();
  final _styleController = TextEditingController();
  final _customRequirementsController = TextEditingController();

  final DirectCommissionService _commissionService = DirectCommissionService();
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  final NumberFormat _currencyFormatter = NumberFormat.currency(symbol: '\$');

  CommissionType _selectedType = CommissionType.digital;
  String _selectedColorScheme = 'Full Color';
  int _revisions = 1;
  bool _commercialUse = false;
  String _deliveryFormat = 'High-res PNG';
  DateTime? _deadline;

  bool _isLoading = false;
  double? _estimatedPrice;

  static const Map<CommissionType, String> _commissionTypeLabelKeys = {
    CommissionType.digital: 'commission_request_type_digital',
    CommissionType.physical: 'commission_request_type_physical',
    CommissionType.portrait: 'commission_request_type_portrait',
    CommissionType.commercial: 'commission_request_type_commercial',
  };

  static const Map<String, String> _colorSchemeLabelKeys = {
    'Full Color': 'commission_request_color_full',
    'Black & White': 'commission_request_color_bw',
    'Sepia': 'commission_request_color_sepia',
    'Monochrome': 'commission_request_color_monochrome',
    'Custom Palette': 'commission_request_color_custom',
  };

  static const Map<String, String> _deliveryFormatLabelKeys = {
    'High-res PNG': 'commission_request_delivery_png',
    'High-res JPEG': 'commission_request_delivery_jpeg',
    'Vector (SVG)': 'commission_request_delivery_svg',
    'PSD File': 'commission_request_delivery_psd',
    'Print-ready PDF': 'commission_request_delivery_pdf',
    'Physical Shipping': 'commission_request_delivery_shipping',
    'Local Pickup': 'commission_request_delivery_pickup',
    'Digital Photo + Physical': 'commission_request_delivery_photo_physical',
    'Physical Print': 'commission_request_delivery_print',
    'Canvas Print': 'commission_request_delivery_canvas',
    'Full Rights Package': 'commission_request_delivery_full_rights',
  };

  final List<String> _colorSchemes = [
    'Full Color',
    'Black & White',
    'Sepia',
    'Monochrome',
    'Custom Palette',
  ];

  final Map<CommissionType, List<String>> _deliveryFormats = {
    CommissionType.digital: [
      'High-res PNG',
      'High-res JPEG',
      'Vector (SVG)',
      'PSD File',
      'Print-ready PDF',
    ],
    CommissionType.physical: [
      'Physical Shipping',
      'Local Pickup',
      'Digital Photo + Physical',
    ],
    CommissionType.portrait: [
      'High-res PNG',
      'High-res JPEG',
      'Physical Print',
      'Canvas Print',
    ],
    CommissionType.commercial: [
      'High-res PNG',
      'Vector (SVG)',
      'Print-ready PDF',
      'Full Rights Package',
    ],
  };

  @override
  void initState() {
    super.initState();
    _updateDeliveryFormat();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _sizeController.dispose();
    _mediumController.dispose();
    _styleController.dispose();
    _customRequirementsController.dispose();
    super.dispose();
  }

  void _updateDeliveryFormat() {
    final formats = _deliveryFormats[_selectedType] ?? [];
    if (formats.isNotEmpty && !formats.contains(_deliveryFormat)) {
      _deliveryFormat = formats.first;
    }
  }

  Future<void> _calculatePrice() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final specs = _buildSpecs();
      final price = await _commissionService.calculateCommissionPrice(
        artistId: widget.artistId,
        type: _selectedType,
        specs: specs,
      );

      if (!mounted) return;
      setState(() {
        _estimatedPrice = price;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'commission_request_calculate_error'.tr(namedArgs: {'error': '$e'}),
          ),
        ),
      );
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final specs = _buildSpecs();
      final commissionId = await _commissionService.createCommissionRequest(
        artistId: widget.artistId,
        artistName: widget.artistName,
        type: _selectedType,
        title: _titleController.text,
        description: _descriptionController.text,
        specs: specs,
        deadline: _deadline,
        metadata: {
          'estimatedPrice': _estimatedPrice,
          'requestedAt': DateTime.now().toIso8601String(),
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('commission_request_submit_success'.tr())),
      );
      Navigator.pop(context, commissionId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'commission_request_submit_error'.tr(namedArgs: {'error': '$e'}),
          ),
        ),
      );
    }
  }

  CommissionSpecs _buildSpecs() {
    return CommissionSpecs(
      size: _sizeController.text,
      medium: _mediumController.text,
      style: _styleController.text,
      colorScheme: _selectedColorScheme,
      revisions: _revisions,
      commercialUse: _commercialUse,
      deliveryFormat: _deliveryFormat,
      customRequirements: {'description': _customRequirementsController.text},
    );
  }

  Future<void> _pickDeadline() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      setState(() => _deadline = selectedDate);
    }
  }

  void _openGallery() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => CommissionGalleryScreen(artistId: widget.artistId),
      ),
    );
  }

  void _openTemplates() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const CommissionTemplatesBrowser(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: HudTopBar(
        title: 'commission_request_app_bar'.tr(),
        glassBackground: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'commission_request_action_templates'.tr(),
            icon: const Icon(Icons.auto_awesome, color: Colors.white),
            onPressed: _openTemplates,
          ),
          IconButton(
            tooltip: 'commission_request_action_gallery'.tr(),
            icon: const Icon(Icons.image_search, color: Colors.white),
            onPressed: _openGallery,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: WorldBackground(
        child: SafeArea(
          bottom: false,
          child: Form(
            key: _formKey,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding + 32),
              children: [
                _buildHeroCard(),
                const SizedBox(height: 16),
                _buildTypeCard(),
                const SizedBox(height: 16),
                _buildBasicInfoCard(),
                const SizedBox(height: 16),
                _buildSpecificationsCard(),
                const SizedBox(height: 16),
                _buildOptionsCard(),
                const SizedBox(height: 16),
                _buildTimelineCard(),
                const SizedBox(height: 16),
                _buildRequirementsCard(),
                if (_estimatedPrice != null) ...[
                  const SizedBox(height: 16),
                  _buildPriceCard(),
                ],
                const SizedBox(height: 24),
                _buildActionRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      showAccentGlow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'commission_request_from_artist'.tr(namedArgs: {'artist': widget.artistName}),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'commission_request_intro'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.78),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 200,
                child: HudButton.primary(
                  onPressed: _openTemplates,
                  text: 'commission_request_action_templates'.tr(),
                  icon: Icons.auto_awesome,
                  isLoading: false,
                ),
              ),
              SizedBox(
                width: 200,
                child: HudButton.secondary(
                  onPressed: _openGallery,
                  text: 'commission_request_action_gallery'.tr(),
                  icon: Icons.image_search,
                  isLoading: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('commission_request_section_type'),
          const SizedBox(height: 16),
          DropdownButtonFormField<CommissionType>(
            initialValue: _selectedType,
            decoration: GlassInputDecoration(
              labelText: 'commission_request_field_type_label'.tr(),
            ),
            dropdownColor: const Color(0xFF0E1122),
            iconEnabledColor: Colors.white,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            items: CommissionType.values.map((type) {
              final isAvailable =
                  widget.artistSettings?.availableTypes.contains(type) ?? true;
              return DropdownMenuItem(
                enabled: isAvailable,
                value: type,
                child: Text(
                  _commissionTypeLabelKeys[type]!.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isAvailable
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedType = value;
                  _updateDeliveryFormat();
                });
              }
            },
            validator: (value) {
              if (value == null) {
                return 'commission_request_field_type_validation'.tr();
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('commission_request_section_basic'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            cursorColor: const Color(0xFF22D3EE),
            decoration: GlassInputDecoration(
              labelText: 'commission_request_field_title_label'.tr(),
              hintText: 'commission_request_field_title_hint'.tr(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'commission_request_field_title_validation'.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            cursorColor: const Color(0xFF22D3EE),
            decoration: GlassInputDecoration(
              labelText: 'commission_request_field_description_label'.tr(),
              hintText: 'commission_request_field_description_hint'.tr(),
            ),
            maxLines: 4,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'commission_request_field_description_validation'.tr();
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificationsCard() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('commission_request_section_specs'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTextField(_sizeController,
                  label: 'commission_request_field_size_label'.tr(),
                  hint: 'commission_request_field_size_hint'.tr(),
                  validatorMessage: 'commission_request_field_size_validation'.tr())),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField(_mediumController,
                  label: 'commission_request_field_medium_label'.tr(),
                  hint: 'commission_request_field_medium_hint'.tr(),
                  validatorMessage: 'commission_request_field_medium_validation'.tr())),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTextField(_styleController,
                  label: 'commission_request_field_style_label'.tr(),
                  hint: 'commission_request_field_style_hint'.tr(),
                  validatorMessage: 'commission_request_field_style_validation'.tr())),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedColorScheme,
                  decoration: GlassInputDecoration(
                    labelText: 'commission_request_field_color_label'.tr(),
                  ),
                  dropdownColor: const Color(0xFF0E1122),
                  iconEnabledColor: Colors.white,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  items: _colorSchemes.map((scheme) {
                    return DropdownMenuItem(
                      value: scheme,
                      child: Text(
                        _colorSchemeLabelKeys[scheme]!.tr(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedColorScheme = value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _deliveryFormat,
            decoration: GlassInputDecoration(
              labelText: 'commission_request_field_delivery_label'.tr(),
            ),
            dropdownColor: const Color(0xFF0E1122),
            iconEnabledColor: Colors.white,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            items: (_deliveryFormats[_selectedType] ?? []).map((format) {
              return DropdownMenuItem(
                value: format,
                child: Text(
                  _deliveryFormatLabelKeys[format]!.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _deliveryFormat = value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsCard() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('commission_request_section_options'),
          const SizedBox(height: 16),
          Text(
            'commission_request_revisions_label'
                .tr(namedArgs: {'count': '$_revisions'}),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF22D3EE),
              inactiveTrackColor: Colors.white.withOpacity(0.2),
              thumbColor: const Color(0xFF7C4DFF),
            ),
            child: Slider(
              value: _revisions.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: '$_revisions',
              onChanged: (value) {
                setState(() => _revisions = value.round());
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'commission_request_revisions_helper'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'commission_request_option_commercial_use'.tr(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'commission_request_option_commercial_use_hint'.tr(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _commercialUse,
                  onChanged: (value) => setState(() => _commercialUse = value),
                  activeThumbColor: const Color(0xFF22D3EE),
                  activeTrackColor: const Color(0xFF22D3EE).withOpacity(0.3),
                  inactiveTrackColor: Colors.white.withOpacity(0.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('commission_request_section_timeline'),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: _pickDeadline,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.white, size: 18),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _deadline == null
                              ? 'commission_request_deadline_none'.tr()
                              : 'commission_request_deadline_value'.tr(
                                  namedArgs: {
                                    'date': _dateFormat.format(_deadline!),
                                  },
                                ),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'commission_request_deadline_hint'.tr(),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white70),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementsCard() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('commission_request_section_requirements'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _customRequirementsController,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            cursorColor: const Color(0xFF22D3EE),
            maxLines: 4,
            decoration: GlassInputDecoration(
              labelText: 'commission_request_requirements_label'.tr(),
              hintText: 'commission_request_requirements_hint'.tr(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      showAccentGlow: true,
      accentColor: const Color(0xFF22D3EE),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('commission_request_section_price'),
          const SizedBox(height: 16),
          Text(
            _currencyFormatter.format(_estimatedPrice ?? 0),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'commission_request_price_caption'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow() {
    return Row(
      children: [
        Expanded(
          child: HudButton.secondary(
            onPressed: _isLoading ? null : _calculatePrice,
            text: 'commission_request_action_calculate'.tr(),
            icon: Icons.toll,
            isLoading: _isLoading,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GradientCTAButton(
            text: 'commission_request_action_submit'.tr(),
            onPressed: _isLoading ? null : _submitRequest,
            isLoading: _isLoading,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller, {
    required String label,
    required String hint,
    required String validatorMessage,
  }) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      cursorColor: const Color(0xFF22D3EE),
      decoration: GlassInputDecoration(
        labelText: label,
        hintText: hint,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return validatorMessage;
        }
        return null;
      },
    );
  }

  Text _sectionTitle(String key) {
    return Text(
      key.tr(),
      style: GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: 0.4,
      ),
    );
  }
}
