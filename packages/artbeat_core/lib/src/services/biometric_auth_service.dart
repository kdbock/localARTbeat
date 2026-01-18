import 'dart:io' show Platform;
import 'package:local_auth/local_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

/// Biometric authentication result
class BiometricAuthResult {
  final bool success;
  final String? error;
  final BiometricType? type;

  BiometricAuthResult({required this.success, this.error, this.type});
}

/// Biometric settings for user preferences
class BiometricSettings {
  final bool enabled;
  final bool requireForHighValue;
  final double highValueThreshold;
  final List<String> allowedBiometricTypes;

  BiometricSettings({
    required this.enabled,
    required this.requireForHighValue,
    required this.highValueThreshold,
    required this.allowedBiometricTypes,
  });

  factory BiometricSettings.defaultSettings() {
    return BiometricSettings(
      enabled: false,
      requireForHighValue: true,
      highValueThreshold: 100.0,
      allowedBiometricTypes: ['fingerprint', 'face'],
    );
  }

  factory BiometricSettings.fromJson(Map<String, dynamic> json) {
    return BiometricSettings(
      enabled: json['enabled'] as bool? ?? false,
      requireForHighValue: json['requireForHighValue'] as bool? ?? true,
      highValueThreshold:
          (json['highValueThreshold'] as num?)?.toDouble() ?? 100.0,
      allowedBiometricTypes:
          (json['allowedBiometricTypes'] as List<dynamic>?)?.cast<String>() ??
          ['fingerprint', 'face'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'requireForHighValue': requireForHighValue,
      'highValueThreshold': highValueThreshold,
      'allowedBiometricTypes': allowedBiometricTypes,
    };
  }
}

/// Enhanced biometric authentication service for ARTbeat
/// Provides fingerprint, face ID, and iris authentication
class BiometricAuthService {
  static final BiometricAuthService _instance =
      BiometricAuthService._internal();

  factory BiometricAuthService() {
    return _instance;
  }

  BiometricAuthService._internal() {
    _initializeBiometricAuth();
  }

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isInitialized = false;
  List<BiometricType> _availableBiometrics = [];
  BiometricSettings _settings = BiometricSettings.defaultSettings();

  /// Initialize biometric authentication
  Future<void> _initializeBiometricAuth() async {
    try {
      final canAuthenticate = await _localAuth.isDeviceSupported();
      if (canAuthenticate) {
        final availableBiometrics = await _localAuth.getAvailableBiometrics();
        _availableBiometrics = availableBiometrics;
        _isInitialized = true;
        AppLogger.info(
          '✅ Biometric authentication initialized: $_availableBiometrics',
        );
      } else {
        AppLogger.warning('⚠️ Biometric authentication not available');
      }
    } catch (e) {
      AppLogger.error('❌ Error initializing biometric auth: $e');
    }
  }

  /// Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    if (!_isInitialized) {
      await _initializeBiometricAuth();
    }
    return _availableBiometrics.isNotEmpty;
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (!_isInitialized) {
      await _initializeBiometricAuth();
    }
    return _availableBiometrics;
  }

  /// Authenticate user with biometrics
  Future<BiometricAuthResult> authenticateUser({
    required String reason,
    bool useErrorDialogs = true,
    bool stickyAuth = false,
    bool biometricOnly = false,
  }) async {
    try {
      if (!await isBiometricAvailable()) {
        return BiometricAuthResult(
          success: false,
          error: 'Biometric authentication not available',
        );
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: biometricOnly,
        persistAcrossBackgrounding: stickyAuth,
      );

      if (authenticated) {
        // Log successful biometric authentication
        await _logBiometricEvent('success', reason);

        return BiometricAuthResult(
          success: true,
          type: _availableBiometrics.first,
        );
      } else {
        // Log failed biometric authentication
        await _logBiometricEvent('failed', reason, error: 'User cancelled');

        return BiometricAuthResult(
          success: false,
          error: 'Authentication cancelled by user',
        );
      }
    } catch (e) {
      // Log biometric authentication error
      await _logBiometricEvent('error', reason, error: e.toString());

      return BiometricAuthResult(success: false, error: e.toString());
    }
  }

  /// Authenticate for payment with risk-based requirements
  Future<BiometricAuthResult> authenticateForPayment({
    required double amount,
    required String currency,
    String? description,
  }) async {
    try {
      // Load user biometric settings
      await _loadBiometricSettings();

      // Check if biometric auth is required for this payment
      final requiresBiometric =
          _settings.enabled &&
          (!_settings.requireForHighValue ||
              amount >= _settings.highValueThreshold);

      if (!requiresBiometric) {
        return BiometricAuthResult(success: true);
      }

      final reason =
          description ??
          'Confirm payment of ${amount.toStringAsFixed(2)} $currency';

      return await authenticateUser(
        reason: reason,
        useErrorDialogs: true,
        biometricOnly: true,
      );
    } catch (e) {
      AppLogger.error('❌ Error in payment biometric auth: $e');
      return BiometricAuthResult(success: false, error: e.toString());
    }
  }

  /// Enable biometric authentication for payments
  Future<bool> enableBiometricPayments() async {
    try {
      if (!await isBiometricAvailable()) {
        return false;
      }

      // Test biometric authentication
      final testResult = await authenticateUser(
        reason: 'Enable biometric payments for ARTbeat',
        useErrorDialogs: true,
      );

      if (testResult.success) {
        _settings = BiometricSettings(
          enabled: true,
          requireForHighValue: _settings.requireForHighValue,
          highValueThreshold: _settings.highValueThreshold,
          allowedBiometricTypes: _settings.allowedBiometricTypes,
        );

        await _saveBiometricSettings();
        AppLogger.info('✅ Biometric payments enabled');
        return true;
      }

      return false;
    } catch (e) {
      AppLogger.error('❌ Error enabling biometric payments: $e');
      return false;
    }
  }

  /// Disable biometric authentication
  Future<void> disableBiometricPayments() async {
    _settings = BiometricSettings(
      enabled: false,
      requireForHighValue: _settings.requireForHighValue,
      highValueThreshold: _settings.highValueThreshold,
      allowedBiometricTypes: _settings.allowedBiometricTypes,
    );

    await _saveBiometricSettings();
    AppLogger.info('✅ Biometric payments disabled');
  }

  /// Update biometric settings
  Future<void> updateBiometricSettings(BiometricSettings settings) async {
    _settings = settings;
    await _saveBiometricSettings();
    AppLogger.info('✅ Biometric settings updated');
  }

  /// Get current biometric settings
  Future<BiometricSettings> getBiometricSettings() async {
    await _loadBiometricSettings();
    return _settings;
  }

  /// Load biometric settings from Firestore
  Future<void> _loadBiometricSettings() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final doc = await _firestore
          .collection('user_biometric_settings')
          .doc(userId)
          .get();

      if (doc.exists) {
        _settings = BiometricSettings.fromJson(doc.data()!);
      } else {
        // Create default settings
        _settings = BiometricSettings.defaultSettings();
        await _saveBiometricSettings();
      }
    } catch (e) {
      AppLogger.error('❌ Error loading biometric settings: $e');
      _settings = BiometricSettings.defaultSettings();
    }
  }

  /// Save biometric settings to Firestore
  Future<void> _saveBiometricSettings() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('user_biometric_settings')
          .doc(userId)
          .set(_settings.toJson());
    } catch (e) {
      AppLogger.error('❌ Error saving biometric settings: $e');
    }
  }

  /// Log biometric authentication events
  Future<void> _logBiometricEvent(
    String event,
    String reason, {
    String? error,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore.collection('biometric_events').add({
        'userId': userId,
        'event': event,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': Platform.operatingSystem,
        'availableBiometrics': _availableBiometrics
            .map((e) => e.toString())
            .toList(),
        if (error != null) 'error': error,
      });
    } catch (e) {
      AppLogger.error('❌ Error logging biometric event: $e');
    }
  }

  /// Check if biometric authentication should be required for amount
  bool shouldRequireBiometric(double amount) {
    return _settings.enabled &&
        (!_settings.requireForHighValue ||
            amount >= _settings.highValueThreshold);
  }

  /// Get biometric authentication status
  Future<Map<String, dynamic>> getBiometricStatus() async {
    return {
      'available': await isBiometricAvailable(),
      'enabled': _settings.enabled,
      'availableTypes': _availableBiometrics.map((e) => e.toString()).toList(),
      'requireForHighValue': _settings.requireForHighValue,
      'highValueThreshold': _settings.highValueThreshold,
    };
  }
}
