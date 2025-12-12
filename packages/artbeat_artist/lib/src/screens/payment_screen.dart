import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show PaymentService, SubscriptionTier, EnhancedUniversalHeader, MainLayout;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'payment_methods_screen.dart';

/// Screen for handling subscription payments
class PaymentScreen extends StatefulWidget {
  final SubscriptionTier tier;

  const PaymentScreen({
    super.key,
    required this.tier,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1,
      child: Scaffold(
        appBar: EnhancedUniversalHeader(
          title: 'Subscribe to ${_getTierName(widget.tier)}',
          showLogo: false,
          showBackButton: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPlanDetails(),
                    const SizedBox(height: 24),
                    _buildFeaturesList(),
                    const SizedBox(height: 32),
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        margin: const EdgeInsets.only(bottom: 16.0),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handlePayment,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                            'Subscribe Now - ${_getPriceString(widget.tier)}'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(tr('admin_admin_payment_text_cancel')),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPlanDetails() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getTierName(widget.tier),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getPriceString(widget.tier),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getPlanDescription(widget.tier),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Plan Features',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._getPlanFeatures(widget.tier).map(
          (feature) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feature,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handlePayment() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      setState(() {
        _errorMessage =
            'User email not available. Please update your profile email.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get the stripe customer ID for the current user
      final customerDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get();

      final String? stripeCustomerId =
          customerDoc.data()?['stripeCustomerId'] as String?;
      final String? defaultPaymentMethodId =
          customerDoc.data()?['defaultPaymentMethodId'] as String?;

      if (stripeCustomerId == null || defaultPaymentMethodId == null) {
        // Navigate to payment methods screen to add a payment method
        if (mounted) {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute<bool>(
              builder: (context) => const PaymentMethodsScreen(),
            ),
          );

          // If user added a payment method, retry the payment
          if (result == true) {
            _handlePayment();
            return;
          } else {
            // User cancelled or didn't add a payment method
            setState(() {
              _errorMessage =
                  'A payment method is required to subscribe. Please add one to continue.';
            });
            return;
          }
        }
        return;
      }

      // Get the amount based on the subscription tier
      final amount = widget.tier.monthlyPrice;
      final description = 'Subscription to ${widget.tier.displayName}';

      final success = await _paymentService.processPayment(
        paymentMethodId: defaultPaymentMethodId,
        amount: amount,
        description: description,
      );

      if (success) {
        if (mounted) {
          // Show success dialog
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(tr('artist_payment_success_subscription_successful')),
              content: Text(
                  'You\'ve successfully subscribed to the ${_getTierName(widget.tier)}!'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(tr('common_ok')),
                ),
              ],
            ),
          );

          // Return to artist dashboard with refresh
          if (mounted) {
            Navigator.pop(context, true); // Return true to trigger refresh
          }
        }
      } else {
        throw Exception('Payment processing failed');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Payment failed: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper methods
  String _getTierName(SubscriptionTier tier) {
    return tier.displayName;
  }

  String _getPriceString(SubscriptionTier tier) {
    final double price = tier.monthlyPrice;
    return '\$${price.toStringAsFixed(2)}';
  }

  String _getPlanDescription(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 'Basic features for artists';
      case SubscriptionTier.starter:
        return 'Essential features for emerging artists';
      case SubscriptionTier.creator:
        return 'Advanced features for professional artists';
      case SubscriptionTier.business:
        return 'Premium features for art businesses';
      case SubscriptionTier.enterprise:
        return 'Enterprise features with unlimited access';
    }
  }

  List<String> _getPlanFeatures(SubscriptionTier tier) {
    return tier.features;
  }
}
