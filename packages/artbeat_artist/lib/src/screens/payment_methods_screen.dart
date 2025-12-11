import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;

/// Screen for managing payment methods
class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final core.PaymentService _paymentService = core.PaymentService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  String? _errorMessage;
  List<core.PaymentMethodModel> _paymentMethods = [];
  String? _defaultPaymentMethodId;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  /// Load saved payment methods
  Future<void> _loadPaymentMethods() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current user's Stripe customer ID
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get customer data from Firestore
      final customerDoc =
          await _firestore.collection('customers').doc(userId).get();

      if (!customerDoc.exists) {
        setState(() {
          _isLoading = false;
          _paymentMethods = [];
        });
        return;
      }

      final customerData = customerDoc.data();
      final stripeCustomerId = customerData?['stripeCustomerId'] as String?;
      _defaultPaymentMethodId =
          customerData?['defaultPaymentMethodId'] as String?;

      if (stripeCustomerId == null) {
        setState(() {
          _isLoading = false;
          _paymentMethods = [];
        });
        return;
      }

      // Load payment methods
      final methods = await _paymentService.getPaymentMethods(stripeCustomerId);

      setState(() {
        _isLoading = false;
        _paymentMethods = methods;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading payment methods: ${error.toString()}';
      });
    }
  }

  /// Add a new payment method
  Future<void> _addPaymentMethod() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get or create a customer
      final customerDoc =
          await _firestore.collection('customers').doc(userId).get();

      String? stripeCustomerId;
      if (customerDoc.exists) {
        stripeCustomerId = customerDoc.data()?['stripeCustomerId'] as String?;
      }

      if (stripeCustomerId == null) {
        // Create new customer
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final email = userDoc.data()?['email'] as String? ?? '';
        final name = userDoc.data()?['fullName'] as String? ?? '';

        stripeCustomerId = await _paymentService.createCustomer(
          email: email,
          name: name,
        );

        // Save customer ID
        await _firestore.collection('customers').doc(userId).set({
          'stripeCustomerId': stripeCustomerId,
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Setup payment sheet
      await _paymentService.setupPaymentSheet(
        customerId: stripeCustomerId,
        setupIntentClientSecret:
            await _paymentService.createSetupIntent(stripeCustomerId),
      );

      // Present payment sheet with crash prevention
      await core.CrashPreventionService.safeExecute(
        operation: () => Stripe.instance.presentPaymentSheet(),
        operationName: 'presentPaymentSheet_setup',
      );

      // Reload payment methods and return success
      await _loadPaymentMethods();

      // If we have payment methods now, return success to the calling screen
      if (mounted && _paymentMethods.isNotEmpty) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      setState(() {
        _errorMessage = error.toString().contains('Cancelled')
            ? null
            : 'Error adding payment method: ${error.toString()}';
      });
    }
  }

  /// Set a payment method as default
  Future<void> _setDefaultPaymentMethod(String paymentMethodId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get customer ID
      final customerDoc =
          await _firestore.collection('customers').doc(userId).get();

      if (!customerDoc.exists) {
        throw Exception('Customer not found');
      }

      final stripeCustomerId =
          customerDoc.data()?['stripeCustomerId'] as String?;
      if (stripeCustomerId == null) {
        throw Exception('Stripe customer not found');
      }

      // Set default payment method
      await _paymentService.setDefaultPaymentMethod(
        customerId: stripeCustomerId,
        paymentMethodId: paymentMethodId,
      );

      // Update local reference
      await _firestore.collection('customers').doc(userId).update({
        'defaultPaymentMethodId': paymentMethodId,
      });

      setState(() {
        _defaultPaymentMethodId = paymentMethodId;
        _isLoading = false;
      });

      // Return success to the calling screen since we now have a default payment method
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Error setting default payment method: ${error.toString()}';
      });
    }
  }

  /// Remove a payment method
  Future<void> _removePaymentMethod(String paymentMethodId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Remove payment method
      await _paymentService.detachPaymentMethod(paymentMethodId);

      // If it was the default payment method, clear the default
      if (_defaultPaymentMethodId == paymentMethodId) {
        final userId = _auth.currentUser?.uid;
        if (userId != null) {
          await _firestore.collection('customers').doc(userId).update({
            'defaultPaymentMethodId': FieldValue.delete(),
          });
          _defaultPaymentMethodId = null;
        }
      }

      // Reload payment methods
      _loadPaymentMethods();
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error removing payment method: ${error.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _addPaymentMethod,
        tooltip: 'Add Payment Method',
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadPaymentMethods,
                child: Text('admin_admin_settings_text_retry'.tr()),
              ),
            ],
          ),
        ),
      );
    }

    if (_paymentMethods.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.credit_card, size: 72, color: Colors.grey),
            const SizedBox(height: 24),
            const Text(
              'No payment methods added',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('art_walk_add_a_credit_card_or_other_payment_method_to_manage_your_subscription'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addPaymentMethod,
              icon: const Icon(Icons.add),
              label: Text('artist_payment_methods_text_add_payment_method'.tr()),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),
              ],
            ),
          ),
        Text(
          'Your Payment Methods',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text('art_walk_you_can_add__remove__or_set_a_default_payment_method_for_your_subscriptions'.tr(),
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        ..._paymentMethods.map((method) => _buildPaymentMethodItem(method)),
      ],
    );
  }

  Widget _buildPaymentMethodItem(core.PaymentMethodModel method) {
    final isDefault = _defaultPaymentMethodId == method.id;
    final card = method.card;

    return Material(
      color: Colors.white,
      elevation: isDefault ? 2 : 1,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isDefault
              ? Border.all(color: Theme.of(context).primaryColor, width: 2)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _getCardIcon(card?.brand ?? ''),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '•••• •••• •••• ${card?.last4 ?? ''}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .primaryColor
                            .withAlpha(26), // Alpha 26 is approx 0.1 opacity
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text('art_walk_default'.tr(),
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                card != null
                    ? 'Expires ${card.expMonth}/${card.expYear}'
                    : 'Payment method',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isDefault)
                    TextButton(
                      onPressed: () => _setDefaultPaymentMethod(method.id),
                      child: Text('artist_payment_methods_text_set_as_default'.tr()),
                    ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _removePaymentMethod(method.id),
                    child: const Text(
                      'Remove',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getCardIcon(String brand) {
    IconData icon;
    Color color;

    switch (brand.toLowerCase()) {
      case 'visa':
        icon = Icons.credit_card;
        color = Colors.blue;
        break;
      case 'mastercard':
        icon = Icons.credit_card;
        color = Colors.orange;
        break;
      case 'amex':
        icon = Icons.credit_card;
        color = Colors.blue;
        break;
      case 'discover':
        icon = Icons.credit_card;
        color = Colors.orange;
        break;
      default:
        icon = Icons.credit_card;
        color = Colors.grey;
    }

    return Icon(icon, color: color);
  }
}
