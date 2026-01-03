import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart';
import 'package:artbeat_core/shared_widgets.dart';
import 'package:artbeat_core/artbeat_core.dart' as core
    show StripePaymentService;

/// Screen shown when user wins an auction
class AuctionWinScreen extends StatefulWidget {
  final String artworkId;
  final ArtworkModel artwork;
  final double finalPrice;

  const AuctionWinScreen({
    super.key,
    required this.artworkId,
    required this.artwork,
    required this.finalPrice,
  });

  @override
  State<AuctionWinScreen> createState() => _AuctionWinScreenState();
}

class _AuctionWinScreenState extends State<AuctionWinScreen> {
  final core.StripePaymentService _paymentService = core.StripePaymentService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  String? _errorMessage;
  Duration _timeRemaining = const Duration(hours: 24);

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    // Calculate time remaining until 24 hours from auction close
    // For simplicity, assume 24 hours from now
    // In real implementation, calculate from auction close time
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _timeRemaining = _timeRemaining - const Duration(seconds: 1);
        });
        if (_timeRemaining.inSeconds > 0) {
          _startCountdown();
        }
      }
    });
  }

  Future<void> _payForArtwork() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create payment intent for auction
      final paymentIntent = await _paymentService.createAuctionPaymentIntent(
        artworkId: widget.artworkId,
        artistId: widget.artwork.userId,
        amount: widget.finalPrice,
        currency: 'usd',
      );

      // Confirm payment
      final paymentId = await _paymentService.confirmAuctionPayment(
        paymentIntentId: paymentIntent['id'] as String,
        artworkId: widget.artworkId,
        artistId: widget.artwork.userId,
        amount: widget.finalPrice,
      );

      if (paymentId.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('auction.payment_successful'.tr()),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(); // Return to previous screen
        }
      } else {
        setState(() {
          _errorMessage = 'auction.payment_failed'.tr();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'auction.payment_error'.tr();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF07060F), // World background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'auction.congratulations'.tr(),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontFamily: 'SpaceGrotesk',
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF07060F),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Trophy icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF7C4DFF),
                        Color(0xFF22D3EE),
                        Color(0xFF34D399)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    size: 60,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 32),

                // Congratulations message
                Text(
                  'auction.you_won'.tr(),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontFamily: 'SpaceGrotesk',
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Artwork info
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Artwork image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.artwork.imageUrl,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Artwork details
                      Text(
                        widget.artwork.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontFamily: 'SpaceGrotesk',
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'auction.by_artist'
                            .tr(args: [widget.artwork.artistName]),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontFamily: 'SpaceGrotesk',
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      // Final price
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF7C4DFF),
                              Color(0xFF22D3EE),
                              Color(0xFF34D399)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'auction.final_price'.tr(args: [
                            '\$${widget.finalPrice.toStringAsFixed(2)}'
                          ]),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontFamily: 'SpaceGrotesk',
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Payment deadline
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.timer,
                        color: Color(0xFF22D3EE),
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'auction.payment_deadline'.tr(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontFamily: 'SpaceGrotesk',
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDuration(_timeRemaining),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontFamily: 'SpaceGrotesk',
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF22D3EE),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'auction.hours_remaining'.tr(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Pay Now button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _payForArtwork,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ).copyWith(
                      backgroundColor: WidgetStateProperty.resolveWith<Color>(
                        (states) {
                          if (states.contains(WidgetState.disabled)) {
                            return Colors.grey.withValues(alpha: 0.3);
                          }
                          return Colors.transparent;
                        },
                      ),
                      foregroundColor: WidgetStateProperty.all(Colors.white),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF7C4DFF),
                            Color(0xFF22D3EE),
                            Color(0xFF34D399)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(
                                'auction.pay_now'.tr(),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontFamily: 'SpaceGrotesk',
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Note about deadline
                Text(
                  'auction.payment_note'.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
