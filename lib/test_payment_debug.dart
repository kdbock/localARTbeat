import 'package:artbeat_core/artbeat_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Simple debug screen to test payment functionality
class PaymentDebugScreen extends StatefulWidget {
  const PaymentDebugScreen({super.key});

  @override
  State<PaymentDebugScreen> createState() => _PaymentDebugScreenState();
}

class _PaymentDebugScreenState extends State<PaymentDebugScreen> {
  final UnifiedPaymentService _paymentService = UnifiedPaymentService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _debugOutput = '';
  bool _isLoading = false;

  void _addDebugLine(String line) {
    setState(() {
      _debugOutput += '${DateTime.now().toIso8601String()}: $line\n';
    });
    AppLogger.debug('🔍 DEBUG: $line');
  }

  Future<void> _testStripeInitialization() async {
    setState(() {
      _isLoading = true;
      _debugOutput = '';
    });

    _addDebugLine('Testing Stripe initialization...');

    try {
      // Test environment loading
      final envLoader = EnvLoader();
      await envLoader.init();
      final stripeKey = envLoader.get('STRIPE_PUBLISHABLE_KEY');
      _addDebugLine(
        'Stripe key loaded: ${stripeKey.isNotEmpty ? 'YES (${stripeKey.substring(0, 10)}...)' : 'NO'}',
      );

      // Test user authentication
      final user = _auth.currentUser;
      _addDebugLine(
        'User authenticated: ${user != null ? 'YES (${user.uid})' : 'NO'}',
      );

      if (user != null) {
        // Test customer creation/retrieval
        try {
          final customerId = await _paymentService.getOrCreateCustomerId();
          _addDebugLine('Customer ID: $customerId');

          // Test payment methods retrieval
          final paymentMethods = await _paymentService.getPaymentMethods(
            customerId,
          );
          _addDebugLine('Payment methods found: ${paymentMethods.length}');

          for (int i = 0; i < paymentMethods.length; i++) {
            final pm = paymentMethods[i];
            _addDebugLine(
              '  PM $i: ${pm.id} (${pm.card?.brand} ****${pm.card?.last4})',
            );
          }

          // Test default payment method
          final defaultPM = await _paymentService.getDefaultPaymentMethodId();
          _addDebugLine('Default payment method: ${defaultPM ?? 'NONE'}');
        } on Exception catch (e) {
          _addDebugLine('ERROR in payment service: $e');
        }
      }
    } on Exception catch (e) {
      _addDebugLine('ERROR: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testAddPaymentMethod() async {
    setState(() {
      _isLoading = true;
    });

    _addDebugLine('Testing add payment method...');

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _addDebugLine('ERROR: User not authenticated');
        return;
      }

      final customerId = await _paymentService.getOrCreateCustomerId();
      _addDebugLine('Got customer ID: $customerId');

      // Create setup intent
      final setupIntentClientSecret = await _paymentService.createSetupIntent(
        customerId,
      );
      _addDebugLine(
        'Setup intent created: ${setupIntentClientSecret.substring(0, 20)}...',
      );

      // Setup payment sheet
      await _paymentService.setupPaymentSheet(
        customerId: customerId,
        setupIntentClientSecret: setupIntentClientSecret,
      );
      _addDebugLine('Payment sheet setup complete');

      // Present payment sheet
      // await Stripe.instance.presentPaymentSheet(); // Replaced with in-app purchases
      _addDebugLine('Payment sheet presented successfully (simulated)');

      // Reload payment methods
      final paymentMethods = await _paymentService.getPaymentMethods(
        customerId,
      );
      _addDebugLine('Payment methods after adding: ${paymentMethods.length}');
    } on Exception catch (e) {
      _addDebugLine('ERROR adding payment method: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Payment Debug'),
      backgroundColor: Colors.blue,
    ),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: _isLoading ? null : _testStripeInitialization,
            child: const Text('Test Stripe Initialization'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _isLoading ? null : _testAddPaymentMethod,
            child: const Text('Test Add Payment Method'),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _debugOutput.isEmpty
                        ? 'No debug output yet...'
                        : _debugOutput,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _debugOutput = '';
              });
            },
            child: const Text('Clear Output'),
          ),
        ],
      ),
    ),
  );
}
