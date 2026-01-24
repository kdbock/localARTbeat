import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/shared_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum AuctionSetupMode { firstTime, editing }

/// Wizard screen for setting up auction preferences for artists
class AuctionSetupWizardScreen extends StatefulWidget {
  const AuctionSetupWizardScreen({
    super.key,
    this.mode = AuctionSetupMode.firstTime,
  });

  final AuctionSetupMode mode;

  @override
  State<AuctionSetupWizardScreen> createState() =>
      _AuctionSetupWizardScreenState();
}

class _AuctionSetupWizardScreenState extends State<AuctionSetupWizardScreen> {
  static const int _totalSteps = 5;
  static const List<String> _stepLabels = [
    'Welcome to Auctions',
    'Default Settings',
    'Duration & Timing',
    'Reserve Prices',
    'Review & Save',
  ];
  static const List<String> _stepSubtitles = [
    'Learn about artwork auctions',
    'Set your auction defaults',
    'Configure auction duration',
    'Protect your minimum price',
    'Review your settings',
  ];

  final PageController _pageController = PageController();

  int _currentStep = 0;
  bool _isLoading = false;

  // Auction settings
  final bool _enableAuctionsByDefault = false;
  double _defaultStartingPrice = 50.0;
  int _defaultDurationDays = 7;
  bool _useReservePriceByDefault = false;
  double _defaultReservePricePercent = 150.0; // % of starting price
  double _minimumBidIncrement = 5.0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return true; // Intro step
      case 1:
        return _defaultStartingPrice >= 1.0;
      case 2:
        return _defaultDurationDays >= 1 && _defaultDurationDays <= 30;
      case 3:
        return !_useReservePriceByDefault || _defaultReservePricePercent >= 100;
      case 4:
        return true; // Review step
      default:
        return false;
    }
  }

  void _handleNext() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _saveSettings();
    }
  }

  void _handleBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar(
          'You must be logged in to save auction settings',
          backgroundColor: Colors.red,
        );
        setState(() => _isLoading = false);
        return;
      }

      // Save auction preferences to user document
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'auctionPreferences': {
          'enableAuctionsByDefault': _enableAuctionsByDefault,
          'defaultStartingPrice': _defaultStartingPrice,
          'defaultDurationDays': _defaultDurationDays,
          'useReservePriceByDefault': _useReservePriceByDefault,
          'defaultReservePricePercent': _defaultReservePricePercent,
          'minimumBidIncrement': _minimumBidIncrement,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      if (!mounted) return;
      _showSnackBar(
        'Auction preferences saved successfully!',
        backgroundColor: Colors.green,
      );
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error saving settings: $e', backgroundColor: Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
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
            title: widget.mode == AuctionSetupMode.firstTime
                ? 'Auction Setup'
                : 'Edit Auction Settings',
            glassBackground: true,
            subtitle: '',
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
                            _buildStep2DefaultSettings(),
                            _buildStep3Duration(),
                            _buildStep4ReservePrice(),
                            _buildStep5Review(),
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
    final stepLabel = _stepLabels[_currentStep];
    final stepSubtitle = _stepSubtitles[_currentStep];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step ${_currentStep + 1} of $_totalSteps',
              style: _bodyStyle(opacity: 0.8, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(
                _totalSteps,
                (index) => Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.symmetric(
                      horizontal: index == 0 ? 0 : 4,
                    ),
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: index <= _currentStep
                          ? const LinearGradient(
                              colors: [Color(0xFFFF6B35), Color(0xFFF7B801)],
                            )
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
    final primaryText = isLastStep ? 'Save Settings' : 'Next';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: HudButton(
              isPrimary: false,
              onPressed: _currentStep == 0 ? null : _handleBack,
              text: 'Back',
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

  Widget _buildStepWrapper(List<Widget> children) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children:
            children.expand((w) => [w, const SizedBox(height: 16)]).toList()
              ..removeLast(),
      ),
    );
  }

  Widget _buildStep1Welcome() {
    return _buildStepWrapper([
      GlassCard(
        padding: const EdgeInsets.all(20),
        showAccentGlow: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBadge('NEW FEATURE'),
            const SizedBox(height: 16),
            Text('Welcome to Auctions', style: _heroTitleStyle),
            const SizedBox(height: 8),
            Text(
              'Set up your auction preferences to start selling your artworks through exciting time-limited bidding.',
              style: _bodyStyle(opacity: 0.75),
            ),
          ],
        ),
      ),
      GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildBenefitRow(
              Icons.gavel,
              'Competitive Bidding',
              'Let collectors compete for your artwork, potentially driving prices higher',
            ),
            const SizedBox(height: 16),
            _buildBenefitRow(
              Icons.schedule,
              'Time-Limited Sales',
              'Create urgency with auction deadlines that encourage quick decisions',
            ),
            const SizedBox(height: 16),
            _buildBenefitRow(
              Icons.trending_up,
              'Market Value Discovery',
              'Find out what your artwork is really worth through open market bidding',
            ),
            const SizedBox(height: 16),
            _buildBenefitRow(
              Icons.shield,
              'Reserve Price Protection',
              'Set a minimum price to ensure you don\'t sell below your desired value',
            ),
          ],
        ),
      ),
      GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF22D3EE), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'You can enable auctions on individual artworks at any time. These settings are just your defaults.',
                style: _bodyStyle(opacity: 0.8, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildStep2DefaultSettings() {
    return _buildStepWrapper([
      GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'Default Auction Settings',
              'These will be applied when you create new auctions',
            ),
            const SizedBox(height: 24),
            _buildStatRow(
              'Default Starting Price',
              _formatCurrency(_defaultStartingPrice),
              icon: Icons.attach_money,
            ),
            const SizedBox(height: 8),
            Text(
              'The initial price where bidding starts. Should be set strategically to attract bidders.',
              style: _bodyStyle(opacity: 0.65, fontSize: 12),
            ),
            _buildSlider(
              value: _defaultStartingPrice,
              min: 1,
              max: 500,
              divisions: 99,
              label: _formatCurrency(_defaultStartingPrice),
              onChanged: (value) =>
                  setState(() => _defaultStartingPrice = value),
            ),
            const SizedBox(height: 24),
            _buildStatRow(
              'Minimum Bid Increment',
              _formatCurrency(_minimumBidIncrement),
              icon: Icons.add_circle_outline,
            ),
            const SizedBox(height: 8),
            Text(
              'The minimum amount each new bid must exceed the current highest bid.',
              style: _bodyStyle(opacity: 0.65, fontSize: 12),
            ),
            _buildSlider(
              value: _minimumBidIncrement,
              min: 1,
              max: 50,
              divisions: 49,
              label: _formatCurrency(_minimumBidIncrement),
              onChanged: (value) =>
                  setState(() => _minimumBidIncrement = value),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildStep3Duration() {
    return _buildStepWrapper([
      GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'Auction Duration',
              'How long should your auctions run by default?',
            ),
            const SizedBox(height: 24),
            _buildStatRow(
              'Default Duration',
              '$_defaultDurationDays days',
              icon: Icons.calendar_today,
            ),
            const SizedBox(height: 8),
            Text(
              'Shorter durations create urgency, while longer durations give more people time to discover and bid.',
              style: _bodyStyle(opacity: 0.65, fontSize: 12),
            ),
            _buildSlider(
              value: _defaultDurationDays.toDouble(),
              min: 1,
              max: 30,
              divisions: 29,
              label: '$_defaultDurationDays days',
              onChanged: (value) =>
                  setState(() => _defaultDurationDays = value.toInt()),
            ),
            const SizedBox(height: 24),
            _buildDurationPresetButtons(),
          ],
        ),
      ),
      GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Duration Guidelines', style: _sectionTitleStyle),
            const SizedBox(height: 12),
            _buildGuidelineRow(
              '1-3 days',
              'Best for high-demand or trending works',
            ),
            const SizedBox(height: 8),
            _buildGuidelineRow(
              '7 days',
              'Standard duration, balanced approach',
            ),
            const SizedBox(height: 8),
            _buildGuidelineRow(
              '14-30 days',
              'For higher-priced or niche artworks',
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildStep4ReservePrice() {
    return _buildStepWrapper([
      GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'Reserve Price',
              'Protect yourself with a minimum acceptable sale price',
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(
                'Use Reserve Price by Default',
                style: _sectionTitleStyle,
              ),
              subtitle: Text(
                'If bids don\'t reach this price, you won\'t be obligated to sell',
                style: _bodyStyle(opacity: 0.7, fontSize: 12),
              ),
              value: _useReservePriceByDefault,
              onChanged: (value) =>
                  setState(() => _useReservePriceByDefault = value),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      if (_useReservePriceByDefault)
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatRow(
                'Reserve Price',
                '${_defaultReservePricePercent.toInt()}% of starting price',
                icon: Icons.shield,
              ),
              const SizedBox(height: 8),
              Text(
                'Example: If starting price is ${_formatCurrency(_defaultStartingPrice)}, reserve would be ${_formatCurrency(_defaultStartingPrice * _defaultReservePricePercent / 100)}',
                style: _bodyStyle(opacity: 0.65, fontSize: 12),
              ),
              _buildSlider(
                value: _defaultReservePricePercent,
                min: 100,
                max: 300,
                divisions: 20,
                label: '${_defaultReservePricePercent.toInt()}%',
                onChanged: (value) =>
                    setState(() => _defaultReservePricePercent = value),
              ),
            ],
          ),
        ),
      GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(
              Icons.lightbulb_outline,
              color: Color(0xFFF7B801),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pro Tip',
                    style: _sectionTitleStyle.copyWith(
                      color: const Color(0xFFF7B801),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reserve prices are hidden from bidders. They only see if the reserve has been met.',
                    style: _bodyStyle(opacity: 0.8, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildStep5Review() {
    return _buildStepWrapper([
      GlassCard(
        padding: const EdgeInsets.all(20),
        showAccentGlow: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Review Your Settings', style: _heroTitleStyle),
            const SizedBox(height: 8),
            Text(
              'These are your default auction settings. You can adjust them for individual artworks later.',
              style: _bodyStyle(opacity: 0.75),
            ),
          ],
        ),
      ),
      GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pricing', style: _sectionTitleStyle),
            const SizedBox(height: 12),
            _buildReviewRow(
              'Starting Price',
              _formatCurrency(_defaultStartingPrice),
            ),
            const SizedBox(height: 8),
            _buildReviewRow(
              'Minimum Bid Increment',
              _formatCurrency(_minimumBidIncrement),
            ),
            const SizedBox(height: 8),
            _buildReviewRow(
              'Reserve Price',
              _useReservePriceByDefault
                  ? '${_defaultReservePricePercent.toInt()}% of starting (${_formatCurrency(_defaultStartingPrice * _defaultReservePricePercent / 100)})'
                  : 'Not using reserve price',
            ),
          ],
        ),
      ),
      GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Duration', style: _sectionTitleStyle),
            const SizedBox(height: 12),
            _buildReviewRow(
              'Default Auction Length',
              '$_defaultDurationDays days',
            ),
          ],
        ),
      ),
      GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Color(0xFF34D399),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Ready to save! You can change these settings anytime from your artist dashboard.',
                style: _bodyStyle(opacity: 0.8),
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  // Helper widgets
  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFF7B801)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: _sectionTitleStyle),
              const SizedBox(height: 4),
              Text(subtitle, style: _bodyStyle(opacity: 0.72)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _sectionTitleStyle),
        const SizedBox(height: 4),
        Text(subtitle, style: _bodyStyle(opacity: 0.7, fontSize: 12)),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, {IconData? icon}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 20),
              const SizedBox(width: 8),
            ],
            Text(label, style: _bodyStyle(opacity: 0.85)),
          ],
        ),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
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
      data: SliderThemeData(
        activeTrackColor: const Color(0xFFFF6B35),
        inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
        thumbColor: Colors.white,
        overlayColor: const Color(0xFFFF6B35).withValues(alpha: 0.3),
        valueIndicatorColor: const Color(0xFFFF6B35),
        valueIndicatorTextStyle: const TextStyle(color: Colors.white),
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

  Widget _buildDurationPresetButtons() {
    final presets = [
      (1, '1 day'),
      (3, '3 days'),
      (7, '7 days'),
      (14, '14 days'),
      (30, '30 days'),
    ];

    return Row(
      children: presets.map((preset) {
        final isSelected = _defaultDurationDays == preset.$1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => setState(() => _defaultDurationDays = preset.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFF6B35).withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFF6B35)
                        : Colors.white.withValues(alpha: 0.12),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  preset.$2,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGuidelineRow(String duration, String description) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFFFF6B35),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$duration: ',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: description,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: _bodyStyle(opacity: 0.8))),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}';
  }

  // Text styles
  TextStyle get _heroTitleStyle => GoogleFonts.spaceGrotesk(
    fontSize: 26,
    fontWeight: FontWeight.w900,
    color: Colors.white,
    height: 1.2,
  );

  TextStyle get _sectionTitleStyle => GoogleFonts.spaceGrotesk(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  TextStyle _bodyStyle({double opacity = 1.0, double fontSize = 14}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: Colors.white.withValues(alpha: opacity),
      );
}
