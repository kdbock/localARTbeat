import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/biometric_auth_service.dart';
import '../services/unified_payment_service.dart';
import '../utils/logger.dart';

/// Example integration of biometric authentication with payment flows
class BiometricPaymentIntegration {
  final BiometricAuthService _biometricService = BiometricAuthService();
  final UnifiedPaymentService _paymentService = UnifiedPaymentService();

  /// Process payment with biometric authentication
  Future<PaymentResult> processBiometricPayment({
    required String clientSecret,
    required double amount,
    required String currency,
    String? description,
  }) async {
    try {
      // Check if biometric authentication is required
      final biometricSettings = await _biometricService.getBiometricSettings();

      if (biometricSettings.enabled &&
          _biometricService.shouldRequireBiometric(amount)) {
        // Perform biometric authentication
        final authResult = await _biometricService.authenticateForPayment(
          amount: amount,
          currency: currency,
          description: description,
        );

        if (!authResult.success) {
          return PaymentResult(
            success: false,
            error: authResult.error ?? 'Biometric authentication failed',
          );
        }
      }

      // Process the payment
      return await _paymentService.processPaymentWithRiskAssessment(
        clientSecret: clientSecret,
        amount: amount,
        currency: currency,
        description: 'Biometric authenticated payment',
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        error: 'Payment processing failed: $e',
      );
    }
  }

  /// Setup biometric authentication for payments
  Future<bool> setupBiometricPayments() async {
    try {
      return await _biometricService.enableBiometricPayments();
    } catch (e) {
      AppLogger.error('❌ Failed to setup biometric payments: $e');
      return false;
    }
  }

  /// Get biometric authentication status
  Future<Map<String, dynamic>> getBiometricStatus() async {
    try {
      final biometricStatus = await _biometricService.getBiometricStatus();
      final paymentSettings = await _biometricService.getBiometricSettings();

      return {
        ...biometricStatus,
        'settings': {
          'enabled': paymentSettings.enabled,
          'requireForHighValue': paymentSettings.requireForHighValue,
          'highValueThreshold': paymentSettings.highValueThreshold,
        },
      };
    } catch (e) {
      return {'available': false, 'enabled': false, 'error': e.toString()};
    }
  }
}

/// Biometric settings screen widget
class BiometricSettingsScreen extends StatefulWidget {
  const BiometricSettingsScreen({super.key});

  @override
  State<BiometricSettingsScreen> createState() =>
      _BiometricSettingsScreenState();
}

class _BiometricSettingsScreenState extends State<BiometricSettingsScreen> {
  final BiometricAuthService _biometricService = BiometricAuthService();
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _requireForHighValue = true;
  double _highValueThreshold = 100.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBiometricSettings();
  }

  Future<void> _loadBiometricSettings() async {
    try {
      final available = await _biometricService.isBiometricAvailable();
      final settings = await _biometricService.getBiometricSettings();

      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = settings.enabled;
        _requireForHighValue = settings.requireForHighValue;
        _highValueThreshold = settings.highValueThreshold;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load biometric settings: $e');
    }
  }

  Future<void> _toggleBiometricPayments() async {
    try {
      if (!_biometricEnabled) {
        final success = await _biometricService.enableBiometricPayments();
        if (success) {
          setState(() => _biometricEnabled = true);
          _showSuccess('Biometric payments enabled!');
        }
      } else {
        await _biometricService.disableBiometricPayments();
        setState(() => _biometricEnabled = false);
        _showSuccess('Biometric payments disabled!');
      }
    } catch (e) {
      _showError('Failed to update biometric settings: $e');
    }
  }

  Future<void> _updateSettings() async {
    try {
      final settings = BiometricSettings(
        enabled: _biometricEnabled,
        requireForHighValue: _requireForHighValue,
        highValueThreshold: _highValueThreshold,
        allowedBiometricTypes: ['fingerprint', 'face'],
      );

      await _biometricService.updateBiometricSettings(settings);
      _showSuccess('Settings updated successfully!');
    } catch (e) {
      _showError('Failed to update settings: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Biometric Payment Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Biometric availability status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      _biometricAvailable ? Icons.fingerprint : Icons.block,
                      color: _biometricAvailable ? Colors.green : Colors.red,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _biometricAvailable
                                ? 'Biometric Authentication Available'
                                : 'Biometric Authentication Not Available',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _biometricAvailable
                                ? 'Secure your payments with fingerprint or face ID'
                                : 'Your device does not support biometric authentication',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            if (_biometricAvailable) ...[
              // Enable biometric payments
              SwitchListTile(
                title: const Text('Enable Biometric Payments'),
                subtitle: const Text('Use fingerprint or face ID for payments'),
                value: _biometricEnabled,
                onChanged: (value) => _toggleBiometricPayments(),
              ),

              const Divider(),

              // High-value payment settings
              SwitchListTile(
                title: const Text('Require for High-Value Payments'),
                subtitle: const Text(
                  'Always require biometric for large amounts',
                ),
                value: _requireForHighValue,
                onChanged: _biometricEnabled
                    ? (value) => setState(() => _requireForHighValue = value)
                    : null,
              ),

              // High-value threshold
              ListTile(
                title: const Text('High-Value Threshold'),
                subtitle: Text('\$${_highValueThreshold.toStringAsFixed(0)}'),
                enabled: _biometricEnabled && _requireForHighValue,
                trailing: SizedBox(
                  width: 120,
                  child: Slider(
                    value: _highValueThreshold,
                    min: 50,
                    max: 1000,
                    divisions: 19,
                    label: '\$${_highValueThreshold.toInt()}',
                    onChanged: _biometricEnabled && _requireForHighValue
                        ? (value) => setState(() => _highValueThreshold = value)
                        : null,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Save settings button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _updateSettings,
                  child: const Text('Save Settings'),
                ),
              ),
            ] else ...[
              const Text(
                'To use biometric payments, your device must support fingerprint or face recognition.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Payment confirmation dialog with biometric authentication
class BiometricPaymentDialog extends StatefulWidget {
  final double amount;
  final String currency;
  final String description;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const BiometricPaymentDialog({
    super.key,
    required this.amount,
    required this.currency,
    required this.description,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<BiometricPaymentDialog> createState() => _BiometricPaymentDialogState();
}

class _BiometricPaymentDialogState extends State<BiometricPaymentDialog> {
  final BiometricAuthService _biometricService = BiometricAuthService();
  bool _isAuthenticating = false;

  Future<void> _authenticateAndConfirm() async {
    setState(() => _isAuthenticating = true);

    try {
      final result = await _biometricService.authenticateForPayment(
        amount: widget.amount,
        currency: widget.currency,
        description:
            'Confirm payment of ${widget.amount.toStringAsFixed(2)} ${widget.currency}',
      );

      if (result.success) {
        widget.onConfirm();
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
      } else {
        _showError(result.error ?? 'Authentication failed');
      }
    } catch (e) {
      _showError('Authentication error: $e');
    } finally {
      setState(() => _isAuthenticating = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm Payment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.description, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(
            '${widget.amount.toStringAsFixed(2)} ${widget.currency}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 24),
          if (_isAuthenticating)
            const CircularProgressIndicator()
          else
            const Icon(Icons.fingerprint, size: 48, color: Colors.blue),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: Text('common_cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: _isAuthenticating ? null : _authenticateAndConfirm,
          child: const Text('Confirm with Biometric'),
        ),
      ],
    );
  }
}
