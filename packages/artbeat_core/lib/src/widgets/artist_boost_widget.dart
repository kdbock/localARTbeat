import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/artist_boost_service.dart';
import '../services/in_app_purchase_setup.dart';
import '../utils/logger.dart';
import '../theme/glass_card.dart';

class ArtistBoostWidget extends StatefulWidget {
  final String recipientId;
  final String recipientName;
  final VoidCallback? onBoostCompleted;

  const ArtistBoostWidget({
    super.key,
    required this.recipientId,
    required this.recipientName,
    this.onBoostCompleted,
  });

  @override
  State<ArtistBoostWidget> createState() => _ArtistBoostWidgetState();
}

class _ArtistBoostWidgetState extends State<ArtistBoostWidget> {
  final ArtistBoostService _boostService = ArtistBoostService();
  final InAppPurchaseSetup _purchaseSetup = InAppPurchaseSetup();
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _initError;
  final bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    setState(() {
      _isInitializing = true;
      _initError = null;
    });

    try {
      AppLogger.info('🛒 Checking in-app purchase availability...');

      // Attempt to initialize the purchase service if not already available
      if (!_boostService.isAvailable) {
        AppLogger.info(
          '🔄 Purchase service not available, attempting initialization...',
        );
        final initialized = await _purchaseSetup.initialize();

        if (!initialized) {
          AppLogger.error('❌ Failed to initialize in-app purchases');
          AppLogger.warning('⚠️ This may be due to:');
          AppLogger.warning(
            '  - Running on simulator without StoreKit configuration',
          );
          AppLogger.warning('  - No internet connection to App Store');
          AppLogger.warning('  - In-app purchase capability not enabled');
          if (mounted) {
            setState(() {
              _initError = 'boost_store_unavailable'.tr();
              _isInitializing = false;
            });
          }
          return;
        }

        AppLogger.info('✅ In-app purchases initialized successfully');
      }

      // Double-check availability after initialization attempt
      if (!_boostService.isAvailable) {
        AppLogger.warning(
          '⚠️ Purchase service still not available after initialization',
        );
        if (mounted) {
          setState(() {
            _initError = 'boost_store_unavailable'.tr();
            _isInitializing = false;
          });
        }
        return;
      }

      AppLogger.info('✅ Purchase service is available');
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      AppLogger.error('❌ Error checking purchase availability: $e');
      if (mounted) {
        setState(() {
          _initError = 'boost_store_unavailable'.tr();
          _isInitializing = false;
        });
      }
    }
  }

  final List<Map<String, dynamic>> _boostOptions = [
    {
      'id': 'artbeat_boost_spark',
      'name': 'boost_tier_spark_name'.tr(),
      'image': 'assets/images/spark_boost.png',
      'price': 4.99,
      'momentum': '+50 Momentum',
      'momentumValue': 50,
      'powerLevel': 'SPARK',
      'description': 'boost_tier_spark_desc'.tr(),
      'gradient': const LinearGradient(
        colors: [Color(0xFFFB7185), Color(0xFF22D3EE)],
      ),
    },
    {
      'id': 'artbeat_boost_surge',
      'name': 'boost_tier_surge_name'.tr(),
      'image': 'assets/images/surge_boost.png',
      'price': 9.99,
      'momentum': '+120 Momentum',
      'momentumValue': 120,
      'powerLevel': 'SURGE',
      'description': 'boost_tier_surge_desc'.tr(),
      'gradient': const LinearGradient(
        colors: [Color(0xFFF97316), Color(0xFFFACC15)],
      ),
    },
    {
      'id': 'artbeat_boost_overdrive',
      'name': 'boost_tier_overdrive_name'.tr(),
      'image': 'assets/images/overdrive_boost.png',
      'price': 24.99,
      'momentum': '+350 Momentum',
      'momentumValue': 350,
      'powerLevel': 'OVERDRIVE',
      'description': 'boost_tier_overdrive_desc'.tr(),
      'gradient': const LinearGradient(
        colors: [Color(0xFF34D399), Color(0xFF0EA5E9)],
      ),
    },
  ];

  Future<void> _activateBoost(String boostId, double price) async {
    AppLogger.info('===============================================');
    AppLogger.info('🚨 BOOST ACTIVATION STARTED: $boostId');
    AppLogger.info('===============================================');
    AppLogger.info(
      '🚀 Activating boost: $boostId (\$${price.toStringAsFixed(2)})',
    );
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      AppLogger.info('🚨 User check: ${user?.uid ?? "NO USER"}');
      if (user == null) {
        _showError('boost_error_signin'.tr());
        setState(() => _isLoading = false);
        return;
      }

      AppLogger.info('🚨 Recipient check: ${widget.recipientId}');
      if (user.uid == widget.recipientId) {
        _showError('boost_error_self'.tr());
        setState(() => _isLoading = false);
        return;
      }

      AppLogger.info('🚨 About to call purchaseBoost...');
      AppLogger.info('🛒 Attempting purchase for boost: $boostId');

      final success = await _boostService.purchaseBoost(
        recipientId: widget.recipientId,
        boostProductId: boostId,
        message: 'boost_fueled_by'.tr(args: [user.displayName ?? 'common_supporter'.tr().toUpperCase()]),
      );

      AppLogger.info('🚨 Purchase result: $success');
      AppLogger.info('🛒 Purchase result: $success');

      if (!mounted) return;

      if (success) {
        setState(() => _isLoading = false);
        // Show celebratory success screen
        await _showSuccessScreen(boostId, price);
        if (mounted) {
          // Call the callback to refresh parent screen
          widget.onBoostCompleted?.call();
          Navigator.pop(context);
        }
      } else {
        _showError('boost_error_connection'.tr());
        setState(() => _isLoading = false);
      }
    } catch (e) {
      AppLogger.error('🚨 EXCEPTION CAUGHT: $e');
      AppLogger.error('Error activating boost: $e');
      if (mounted) {
        _showError('Error: ${e.toString().replaceAll('Exception: ', '')}');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showSuccessScreen(String boostId, double price) async {
    final boostData = _boostOptions.firstWhere((b) => b['id'] == boostId);
    final momentum = boostData['momentumValue'] as int;
    final powerLevel = boostData['powerLevel'] as String;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: boostData['gradient'] as LinearGradient,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: (boostData['gradient'] as LinearGradient).colors.first
                    .withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Celebration icon
                const Icon(
                  Icons.celebration_rounded,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),

                // Success title
                Text(
                  'boost_activated'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Power level
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    powerLevel,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Impact details
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Momentum added
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.bolt_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              'boost_momentum_added'.tr(args: [momentum.toString()]),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Impact description
                      Text(
                        'boost_impact_title'.tr(args: [widget.recipientName]),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.95),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      Text(
                        'boost_impact_details'.tr(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.85),
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Supporter badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.stars_rounded,
                        color: Color(0xFFFFC857),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'boost_active_label'.tr(args: [powerLevel]),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Close button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.3),
                            Colors.white.withValues(alpha: 0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'boost_view_profile'.tr(),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF03050F).withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              if (_isInitializing)
                const Center(
                  child: CircularProgressIndicator(color: Colors.cyanAccent),
                )
              else if (_initError != null)
                _buildErrorState()
              else
                _buildBoostList(),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: CircularProgressIndicator(color: Colors.pinkAccent),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        if (_showCelebration)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _showCelebration ? 1 : 0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    gradient: RadialGradient(
                      radius: 0.8,
                      colors: [
                        Colors.pinkAccent.withValues(alpha: 0.35),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.8, end: 1.15),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, value, child) {
                        return Transform.scale(scale: value, child: child);
                      },
                      child: Icon(
                        Icons.auto_awesome,
                        size: 90,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'boost_fuel_artist'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.cyanAccent,
                  letterSpacing: 2,
                ),
              ),
              Text(
                widget.recipientName.toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white60),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildBoostList() {
    return Column(
      children: _boostOptions.map((boost) => _buildBoostCard(boost)).toList(),
    );
  }

  Widget _buildBoostCard(Map<String, dynamic> boost) {
    final bool isOverdrive = boost['id'] == 'artbeat_boost_overdrive';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        blur: 20,
        showAccentGlow: isOverdrive,
        accentColor: isOverdrive ? Colors.cyanAccent : Colors.white24,
        onTap: _isLoading
            ? null
            : () {
                AppLogger.info('🎯 Boost card tapped: ${boost['id']}');
                _activateBoost(boost['id'] as String, boost['price'] as double);
              },
        child: Row(
          children: [
            _buildIconBox(
              boost['image'] as String,
              boost['gradient'] as LinearGradient,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          boost['name'] as String,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          boost['powerLevel'] as String,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white60,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    boost['description'] as String,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${boost['price']}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  boost['momentum'] as String,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBox(String imagePath, LinearGradient gradient) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          imagePath,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          const SizedBox(height: 12),
          Text(
            _initError!,
            style: GoogleFonts.spaceGrotesk(color: Colors.white70),
          ),
          TextButton(
            onPressed: _checkAvailability,
            child: Text(
              'common_retry'.tr().toUpperCase(),
              style: const TextStyle(color: Colors.cyanAccent),
            ),
          ),
        ],
      ),
    );
  }
}
