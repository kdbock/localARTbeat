import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart';

import '../models/artbeat_event.dart';
import '../models/ticket_type.dart';
import '../services/event_service.dart';
import '../services/event_notification_service.dart';

class TicketPurchaseSheet extends StatefulWidget {
  final ArtbeatEvent event;
  final TicketType ticketType;
  final VoidCallback onPurchaseComplete;

  const TicketPurchaseSheet({
    super.key,
    required this.event,
    required this.ticketType,
    required this.onPurchaseComplete,
  });

  @override
  State<TicketPurchaseSheet> createState() => _TicketPurchaseSheetState();
}

class _TicketPurchaseSheetState extends State<TicketPurchaseSheet> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _nameController = TextEditingController();

  final EventService _eventService = EventService();
  final EventNotificationService _notificationService =
      EventNotificationService();

  int _quantity = 1;
  bool _isProcessing = false;
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    _prefillUserInfo();
  }

  Future<void> _prefillUserInfo() async {
    final user = await UserService().getCurrentUserModel();
    if (user != null && mounted) {
      setState(() {
        _emailController.text = user.email;
        _nameController.text = user.fullName;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.55,
        builder: (context, scrollController) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: SafeBackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1220).withValues(alpha: 0.88),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildHandle(),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 24),
                              _buildTicketInfo(),
                              const SizedBox(height: 24),
                              _buildQuantitySelector(),
                              const SizedBox(height: 24),
                              _buildUserInfo(),
                              const SizedBox(height: 24),
                              _buildOrderSummary(),
                              const SizedBox(height: 24),
                              _buildTermsAndConditions(),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                      _buildPurchaseButton(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 12),
      width: 42,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'events_purchase_title'.tr(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.event.title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }

  Widget _buildTicketInfo() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.ticketType.name,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                widget.ticketType.formattedPrice,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent.shade400,
                ),
              ),
            ],
          ),
          if (widget.ticketType.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              widget.ticketType.description,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
          if (widget.ticketType.benefits.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'events_includes'.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            ...widget.ticketType.benefits.map(
              (benefit) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        benefit,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.28)),
            ),
            child: Text(
              '${widget.ticketType.remainingQuantity} ${'events_tickets_remaining'.tr()}',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.orange.shade300,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'events_quantity'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
                icon: const Icon(Icons.remove),
                style: IconButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 64,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  _quantity.toString(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: _quantity < widget.ticketType.remainingQuantity
                    ? () => setState(() => _quantity++)
                    : null,
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${'events_max'.tr()}: ${widget.ticketType.remainingQuantity}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'events_your_info'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _nameController,
            style: GoogleFonts.spaceGrotesk(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'events_full_name'.tr(),
              labelStyle: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.7),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'events_name_required'.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.spaceGrotesk(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'events_email'.tr(),
              labelStyle: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.7),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'events_email_required'.tr();
              }
              if (!value.contains('@')) {
                return 'events_email_invalid'.tr();
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    final subtotal = widget.ticketType.price * _quantity;
    final tax = subtotal * 0.08;
    final total = subtotal + tax;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'events_order_summary'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          _buildSummaryRow(
            '${widget.ticketType.name} x$_quantity',
            '\$${subtotal.toStringAsFixed(2)}',
          ),
          if (subtotal > 0) ...[
            const SizedBox(height: 6),
            _buildSummaryRow('events_tax'.tr(), '\$${tax.toStringAsFixed(2)}'),
            const Divider(color: Colors.white24),
            _buildSummaryRow(
              'events_total'.tr(),
              '\$${total.toStringAsFixed(2)}',
              isTotal: true,
            ),
          ] else ...[
            const Divider(color: Colors.white24),
            _buildSummaryRow(
              'events_total'.tr(),
              'events_free'.tr(),
              isTotal: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: isTotal ? 15 : 13,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
            color: Colors.white,
          ),
        ),
        Text(
          amount,
          style: GoogleFonts.spaceGrotesk(
            fontSize: isTotal ? 15 : 13,
            fontWeight: FontWeight.w800,
            color: isTotal ? Colors.greenAccent.shade400 : Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTermsAndConditions() {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            value: _agreedToTerms,
            onChanged: (value) =>
                setState(() => _agreedToTerms = value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              'events_terms_confirm'.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                color: Colors.white,
              ),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          Text(
            'events_refund_policy'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.event.refundPolicy.terms,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseButton() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GradientCTAButton(
          text: widget.ticketType.isFree
              ? 'events_reserve'.tr()
              : 'events_purchase'.tr(),
          // isLoading: _isProcessing, // Removed invalid parameter
          onPressed: _canPurchase() ? _purchaseTickets : null,
        ),
      ),
    );
  }

  bool _canPurchase() {
    return !_isProcessing &&
        _agreedToTerms &&
        _quantity > 0 &&
        _quantity <= widget.ticketType.remainingQuantity;
  }

  Future<void> _purchaseTickets() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      String? purchaseId;

      if (widget.ticketType.isFree) {
        purchaseId = await _eventService.purchaseTickets(
          eventId: widget.event.id,
          ticketTypeId: widget.ticketType.id,
          quantity: _quantity,
          userEmail: _emailController.text.trim(),
          userName: _nameController.text.trim(),
        );
      } else {
        // Handle paid tickets via UnifiedPaymentService
        final subtotal = widget.ticketType.price * _quantity;
        final tax = subtotal * 0.08;
        final total = subtotal + tax;

        final unifiedPaymentService = UnifiedPaymentService();

        // 1. Create Payment Intent
        final intentData = await unifiedPaymentService.createPaymentIntent(
          amount: total,
          description: 'Tickets for ${widget.event.title} x$_quantity',
          metadata: {
            'eventId': widget.event.id,
            'ticketTypeId': widget.ticketType.id,
            'quantity': _quantity.toString(),
            'type': 'event_tickets',
          },
        );

        final clientSecret = intentData['clientSecret'] as String;
        final paymentIntentId = intentData['paymentIntentId'] as String;

        // 2. Initialize Payment Sheet
        await unifiedPaymentService.initPaymentSheetForPayment(
          paymentIntentClientSecret: clientSecret,
        );

        // 3. Present Payment Sheet
        await unifiedPaymentService.presentPaymentSheet();

        // 4. Process Payment on Backend (Verification and record creation)
        final result = await unifiedPaymentService.processEventTicketPayment(
          eventId: widget.event.id,
          ticketTypeId: widget.ticketType.id,
          quantity: _quantity,
          amount: total,
          artistId: widget.event.artistId,
          paymentIntentId: paymentIntentId,
          userEmail: _emailController.text.trim(),
          userName: _nameController.text.trim(),
        );

        if (!result.success) {
          throw Exception(result.error ?? 'Failed to process ticket payment');
        }

        purchaseId = result.paymentIntentId;
      }

      await _notificationService.sendTicketPurchaseConfirmation(
        eventTitle: widget.event.title,
        quantity: _quantity,
        ticketType: widget.ticketType.name,
      );

      if (mounted) {
        _showSuccessDialog(purchaseId ?? 'confirmed');
      }
    } on Exception catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSuccessDialog(String purchaseId) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('events_tickets_purchased'.tr()),
        content: Text(
          'events_purchase_success'
              .tr()
              .replaceAll('{count}', _quantity.toString())
              .replaceAll('{title}', widget.event.title),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onPurchaseComplete();
            },
            child: Text('events_done'.tr()),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('events_purchase_failed'.tr()),
        content: Text(
          'events_purchase_error'.tr().replaceAll('{error}', error),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('events_ok'.tr()),
          ),
        ],
      ),
    );
  }
}
