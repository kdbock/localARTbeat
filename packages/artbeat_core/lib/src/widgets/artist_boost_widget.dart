import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/artist_boost_service.dart';
import '../utils/logger.dart';
import '../theme/artbeat_colors.dart';
import '../theme/glass_card.dart';

class ArtistBoostWidget extends StatefulWidget {
  final String recipientId;
  final String recipientName;

  const ArtistBoostWidget({
    super.key,
    required this.recipientId,
    required this.recipientName,
  });

  @override
  State<ArtistBoostWidget> createState() => _ArtistBoostWidgetState();
}

class _ArtistBoostWidgetState extends State<ArtistBoostWidget> {
  final ArtistBoostService _boostService = ArtistBoostService();
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _initError;

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

    await Future.delayed(const Duration(milliseconds: 300));

    if (!_boostService.isAvailable) {
      setState(() {
        _initError = 'Store unavailable. Check your connection.';
        _isInitializing = false;
      });
      return;
    }

    setState(() {
      _isInitializing = false;
    });
  }

  final List<Map<String, dynamic>> _boosts = [
    {
      'id': 'artbeat_gift_small',
      'name': 'The Quick Spark',
      'icon': '⚡',
      'price': 4.99,
      'xp': '+50 XP',
      'powerLevel': 'BASIC BUFF',
      'description': '30 Days "Glow" effect + Featured artist status!',
      'gradient': const LinearGradient(colors: [Color(0xFF8C52FF), Color(0xFF00BFA5)]),
    },
    {
      'id': 'artbeat_gift_medium',
      'name': 'The Neon Surge',
      'icon': '🌈',
      'price': 9.99,
      'xp': '+100 XP',
      'powerLevel': 'RARE EXPANSION',
      'description': '90 Days Featured Artist + 1 "Shiny" Artwork slot!',
      'gradient': const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFFD700)]),
    },
    {
      'id': 'artbeat_gift_large',
      'name': 'The Titan Overdrive',
      'icon': '🛡️',
      'price': 24.99,
      'xp': '+250 XP',
      'powerLevel': 'EPIC GEAR',
      'description': 'Max Visibility + 5 Slots + Global Ad Rotation!',
      'gradient': const LinearGradient(colors: [Color(0xFF00BFA5), Color(0xFF007BFF)]),
    },
    {
      'id': 'artbeat_gift_premium',
      'name': 'The Mythic Expansion',
      'icon': '💎',
      'price': 49.99,
      'xp': '+500 XP',
      'powerLevel': 'MYTHIC LEGACY',
      'description': '1 Year "Legendary" status + Zero Commission Sales!',
      'gradient': const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFF8C52FF)]),
    },
  ];

  Future<void> _activateBoost(String boostId, double price) async {
    AppLogger.info('🚀 Activating boost: $boostId (\$${price.toStringAsFixed(2)})');
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('Sign in to power-up this artist!');
        setState(() => _isLoading = false);
        return;
      }

      if (user.uid == widget.recipientId) {
        _showError('You cannot boost yourself! 🛡️');
        setState(() => _isLoading = false);
        return;
      }

      final success = await _boostService.purchaseBoost(
        recipientId: widget.recipientId,
        boostProductId: boostId,
        message: 'POWERED UP BY ${user.displayName ?? "A FAN"}!',
      );

      if (!mounted) return;

      if (success) {
        _showSuccess('BOOST ACTIVATED! 🚀');
        // Placeholder for the splash effect animation hook
        _triggerSplashEffect();
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        _showError('Activation failed. Check store settings.');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      AppLogger.error('Error activating boost: $e');
      _showError('An error occurred during activation.');
      setState(() => _isLoading = false);
    }
  }

  void _triggerSplashEffect() {
    // This will be connected to the visual celebration service later
    AppLogger.info('✨ TRIGGER: Global profile splash effect for ${widget.recipientId}');
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
        backgroundColor: ArtbeatColors.primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
            const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
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
                'POWER-UP ARTIST',
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
      children: _boosts.map((boost) => _buildBoostCard(boost)).toList(),
    );
  }

  Widget _buildBoostCard(Map<String, dynamic> boost) {
    final bool isTitan = boost['id'] == 'artbeat_gift_large';
    final bool isMythic = boost['id'] == 'artbeat_gift_premium';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        blur: 20,
        showAccentGlow: isTitan || isMythic,
        accentColor: isMythic ? Colors.pinkAccent : Colors.cyanAccent,
        onTap: _isLoading ? null : () => _activateBoost(boost['id'] as String, boost['price'] as double),
        child: Row(
          children: [
            _buildIconBox(boost['icon'] as String, boost['gradient'] as LinearGradient),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        boost['name'] as String,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                  boost['xp'] as String,
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

  Widget _buildIconBox(String icon, LinearGradient gradient) {
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
      child: Center(
        child: Text(
          icon,
          style: const TextStyle(fontSize: 28),
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
            child: const Text('RETRY', style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }
}
