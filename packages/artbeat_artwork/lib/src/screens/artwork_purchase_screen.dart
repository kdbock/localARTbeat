import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show
        AppLogger,
        GlassCard,
        GlassInputDecoration,
        GradientCTAButton,
        HudTopBar,
        MainLayout,
        SecureNetworkImage,
        UnifiedPaymentService,
        WorldBackground;
import '../models/artwork_model.dart';
import '../services/artwork_service.dart';

/// Screen for purchasing artwork with Stripe integration
class ArtworkPurchaseScreen extends StatefulWidget {
  final String artworkId;

  const ArtworkPurchaseScreen({super.key, required this.artworkId});

  @override
  State<ArtworkPurchaseScreen> createState() => _ArtworkPurchaseScreenState();
}

class _ArtworkPurchaseScreenState extends State<ArtworkPurchaseScreen> {
  final ArtworkService _artworkService = ArtworkService();
  final UnifiedPaymentService _paymentService = UnifiedPaymentService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ArtworkModel? _artwork;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _error;

  // Payment form state
  final _formKey = GlobalKey<FormState>();
  // ignore: unused_field
  String _cardNumber = '';
  // ignore: unused_field
  String _expiryDate = '';
  // ignore: unused_field
  String _cvv = '';
  // ignore: unused_field
  String _cardholderName = '';

  @override
  void initState() {
    super.initState();
    _loadArtworkData();
  }

  Future<void> _loadArtworkData() async {
    try {
      final artwork = await _artworkService.getArtworkById(widget.artworkId);

      if (mounted) {
        setState(() {
          _artwork = artwork;
          _isLoading = false;
        });
      }

      if (artwork == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('artwork_detail_not_found'.tr())),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      AppLogger.error('Error loading artwork for purchase: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _processPurchase() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('artwork_purchase_login_required'.tr())),
      );
      return;
    }

    try {
      setState(() {
        _isProcessing = true;
      });

      final double totalAmount =
          (_artwork!.price ?? 0) * 1.15; // Including 15% platform fee

      // 1. Create payment intent
      final intentData = await _paymentService.createPaymentIntent(
        amount: totalAmount,
        currency: 'USD',
        description: 'Purchase of artwork: ${_artwork!.title}',
        metadata: {'artworkId': widget.artworkId, 'artistId': _artwork!.userId},
        artworkId: '',
      );

      final String? clientSecret = intentData['clientSecret'] as String?;
      final String? paymentIntentId = intentData['paymentIntentId'] as String?;

      if (clientSecret == null || paymentIntentId == null) {
        throw Exception('Failed to initialize payment intent');
      }

      // 2. Initialize and present payment sheet
      await _paymentService.initPaymentSheetForPayment(
        paymentIntentClientSecret: clientSecret,
      );

      await _paymentService.presentPaymentSheet();

      // 3. Complete purchase on backend
      final result = await _paymentService.processArtworkSalePayment(
        artworkId: widget.artworkId,
        artistId: _artwork!.userId,
        amount: totalAmount,
        paymentIntentId: paymentIntentId,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'artwork_purchase_success'.tr(
                  namedArgs: {'id': paymentIntentId},
                ),
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate back after brief delay
          await Future<void>.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.pop(context, true);
          }
        } else {
          throw Exception(result.error ?? 'Payment verification failed');
        }
      }
    } catch (e) {
      AppLogger.error('Error processing purchase: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'artwork_purchase_failed'.tr(namedArgs: {'error': e.toString()}),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 0,
      appBar: HudTopBar(
        title: 'artwork_purchase_title'.tr(),
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
        subtitle: '',
      ),
      child: WorldBackground(child: SafeArea(child: _buildContent())),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22D3EE)),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GlassCard(
              radius: 24,
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Color(0xFFFF3D8D),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'error_generic'.tr(),
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GradientCTAButton(
                    height: 44,
                    text: 'common_back'.tr(),
                    icon: Icons.arrow_back,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_artwork == null) {
      return Center(child: Text('artwork_detail_not_found'.tr()));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            radius: 26,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 90,
                    width: 90,
                    child: SecureNetworkImage(
                      imageUrl: _artwork!.imageUrl,
                      fit: BoxFit.cover,
                      enableThumbnailFallback: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _artwork!.title,
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'artwork_purchase_by'.tr(
                          namedArgs: {'artist': _artwork!.artistName},
                        ),
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildPriceRow(
                        label: 'artwork_price_label'.tr(),
                        value:
                            '\$${_artwork!.price?.toStringAsFixed(2) ?? '0.00'}',
                      ),
                      const SizedBox(height: 6),
                      _buildPriceRow(
                        label: 'artwork_purchase_platform_fee'.tr(),
                        value:
                            '\$${((_artwork!.price ?? 0) * 0.15).toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 8),
                      _buildPriceRow(
                        label: 'artwork_purchase_total'.tr(),
                        value:
                            '\$${((_artwork!.price ?? 0) * 1.15).toStringAsFixed(2)}',
                        emphasize: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            radius: 26,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'artwork_purchase_payment_info'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: GlassInputDecoration.glass(
                          labelText: 'artwork_purchase_cardholder_name'.tr(),
                          prefixIcon: const Icon(
                            Icons.person,
                            color: Colors.white70,
                          ),
                        ),
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        validator: (value) => value?.isEmpty ?? true
                            ? 'error_name_required'.tr()
                            : null,
                        onChanged: (value) => _cardholderName = value,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: GlassInputDecoration.glass(
                          labelText: 'artwork_purchase_card_number'.tr(),
                          prefixIcon: const Icon(
                            Icons.credit_card,
                            color: Colors.white70,
                          ),
                          hintText: 'artwork_purchase_card_hint'.tr(),
                        ),
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 19,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'error_card_number_required'.tr()
                            : null,
                        onChanged: (value) => _cardNumber = value,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: GlassInputDecoration.glass(
                                labelText: 'artwork_purchase_expiry'.tr(),
                                hintText: 'artwork_purchase_expiry_hint'.tr(),
                              ),
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 5,
                              validator: (value) => value?.isEmpty ?? true
                                  ? 'error_expiry_required'.tr()
                                  : null,
                              onChanged: (value) => _expiryDate = value,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              decoration: GlassInputDecoration.glass(
                                labelText: 'artwork_purchase_cvv'.tr(),
                                hintText: 'artwork_purchase_cvv_hint'.tr(),
                              ),
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              obscureText: true,
                              validator: (value) => value?.isEmpty ?? true
                                  ? 'error_cvv_required'.tr()
                                  : null,
                              onChanged: (value) => _cvv = value,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GradientCTAButton(
                  height: 52,
                  width: double.infinity,
                  text: _isProcessing
                      ? 'artwork_purchase_processing'.tr()
                      : 'artwork_purchase_complete'.tr(),
                  icon: Icons.shopping_cart,
                  isLoading: _isProcessing,
                  onPressed: _isProcessing ? null : _processPurchase,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.lock_outline, color: Colors.white70),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'artwork_purchase_secure_notice'.tr(),
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withValues(alpha: 0.76),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow({
    required String label,
    required String value,
    bool emphasize = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white.withValues(alpha: 0.78),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontSize: emphasize ? 15 : 13,
            fontWeight: emphasize ? FontWeight.w900 : FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
