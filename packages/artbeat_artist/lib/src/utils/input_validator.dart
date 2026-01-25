import 'dart:math' as math;

/// Comprehensive input validation utility for the ARTbeat Artist package
/// Provides secure validation for all user inputs and data operations
class InputValidator {
  // User ID validation pattern (alphanumeric, hyphens, underscores)
  static final RegExp _userIdPattern = RegExp(r'^[a-zA-Z0-9_-]{1,50}$');

  // Email validation pattern
  static final RegExp _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Safe text pattern (allows letters, numbers, spaces, basic punctuation)
  static final RegExp _safeTextPattern = RegExp(r"^[a-zA-Z0-9\s.,!?'-]+$");

  // URL validation pattern
  static final RegExp _urlPattern = RegExp(
    r'^https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/.*)?$',
  );

  /// Validate user ID format
  static ValidationResult<void> validateUserId(String? userId) {
    if (userId == null || userId.isEmpty) {
      return ValidationResult.invalid('User ID is required');
    }

    if (userId.length < 3) {
      return ValidationResult.invalid('User ID must be at least 3 characters');
    }

    if (!_userIdPattern.hasMatch(userId)) {
      return ValidationResult.invalid('User ID contains invalid characters');
    }

    return ValidationResult.valid();
  }

  /// Validate email address
  static ValidationResult<void> validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return ValidationResult.invalid('Email is required');
    }

    if (email.length > 254) {
      return ValidationResult.invalid('Email is too long');
    }

    if (!_emailPattern.hasMatch(email)) {
      return ValidationResult.invalid('Invalid email format');
    }

    return ValidationResult.valid();
  }

  /// Validate payment amount
  static ValidationResult<void> validatePaymentAmount(num? amount) {
    if (amount == null) {
      return ValidationResult.invalid('Payment amount is required');
    }

    if (amount <= 0) {
      return ValidationResult.invalid('Payment amount must be positive');
    }

    if (amount > 999999.99) {
      return ValidationResult.invalid('Payment amount exceeds maximum limit');
    }

    // Check for reasonable decimal places
    final amountString = amount.toString();
    if (amountString.contains('.')) {
      final decimalPlaces = amountString.split('.')[1].length;
      if (decimalPlaces > 2) {
        return ValidationResult.invalid(
          'Payment amount cannot have more than 2 decimal places',
        );
      }
    }

    return ValidationResult.valid();
  }

  /// Validate and sanitize text input
  static ValidationResult<String> validateText(
    String? text, {
    required String fieldName,
    int minLength = 1,
    int maxLength = 500,
    bool allowEmpty = false,
    bool strictMode = false,
  }) {
    if (text == null) {
      return ValidationResult.invalid('$fieldName is required');
    }

    if (text.isEmpty && !allowEmpty) {
      return ValidationResult.invalid('$fieldName cannot be empty');
    }

    // If empty text is allowed and the text is empty, return it as valid
    if (text.isEmpty && allowEmpty) {
      return ValidationResult.valid(data: '');
    }

    // First sanitize the text to remove malicious content
    final sanitized = sanitizeText(text);

    if (sanitized.length < minLength) {
      return ValidationResult.invalid(
        '$fieldName must be at least $minLength characters',
      );
    }

    if (sanitized.length > maxLength) {
      return ValidationResult.invalid(
        '$fieldName cannot exceed $maxLength characters',
      );
    }

    // In strict mode, only allow safe characters (after sanitization)
    if (strictMode && !_safeTextPattern.hasMatch(sanitized)) {
      return ValidationResult.invalid(
        '$fieldName contains unsupported characters',
      );
    }

    return ValidationResult.valid(data: sanitized);
  }

  /// Validate URL
  static ValidationResult<void> validateUrl(String? url) {
    if (url == null || url.isEmpty) {
      return ValidationResult.invalid('URL is required');
    }

    if (url.length > 2048) {
      return ValidationResult.invalid('URL is too long');
    }

    if (!_urlPattern.hasMatch(url)) {
      return ValidationResult.invalid('Invalid URL format');
    }

    // Check for suspicious patterns
    if (url.contains('<script') || url.contains('javascript:')) {
      return ValidationResult.invalid(
        'URL contains potentially malicious content',
      );
    }

    return ValidationResult.valid();
  }

  /// Validate subscription tier
  static ValidationResult<void> validateSubscriptionTier(String? tier) {
    const validTiers = ['basic', 'pro', 'gallery'];

    if (tier == null || tier.isEmpty) {
      return ValidationResult.invalid('Subscription tier is required');
    }

    if (!validTiers.contains(tier.toLowerCase())) {
      return ValidationResult.invalid('Invalid subscription tier');
    }

    return ValidationResult.valid();
  }

  /// Validate user type
  static ValidationResult<void> validateUserType(String? userType) {
    const validTypes = ['user', 'artist', 'gallery', 'admin'];

    if (userType == null || userType.isEmpty) {
      return ValidationResult.invalid('User type is required');
    }

    if (!validTypes.contains(userType.toLowerCase())) {
      return ValidationResult.invalid('Invalid user type');
    }

    return ValidationResult.valid();
  }

  /// Validate artwork medium
  static ValidationResult<void> validateArtworkMedium(String? medium) {
    const validMediums = [
      'painting',
      'sculpture',
      'photography',
      'digital',
      'mixed_media',
      'drawing',
      'printmaking',
      'ceramics',
      'textile',
      'installation',
      'performance',
      'video',
      'other',
    ];

    if (medium == null || medium.isEmpty) {
      return ValidationResult.invalid('Artwork medium is required');
    }

    if (!validMediums.contains(medium.toLowerCase())) {
      return ValidationResult.invalid('Invalid artwork medium');
    }

    return ValidationResult.valid();
  }

  /// Validate date range
  static ValidationResult<void> validateDateRange(
    DateTime? startDate,
    DateTime? endDate,
  ) {
    if (startDate == null) {
      return ValidationResult.invalid('Start date is required');
    }

    if (endDate == null) {
      return ValidationResult.invalid('End date is required');
    }

    if (endDate.isBefore(startDate)) {
      return ValidationResult.invalid('End date cannot be before start date');
    }

    // Check for reasonable date range (not more than 10 years)
    final difference = endDate.difference(startDate).inDays;
    if (difference > 3650) {
      return ValidationResult.invalid('Date range cannot exceed 10 years');
    }

    return ValidationResult.valid();
  }

  /// Sanitize text input to prevent XSS and other attacks
  static String sanitizeText(String input) {
    final result = input
        .trim()
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'[<>"`]'), '') // Remove dangerous characters
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace

    // Limit length based on processed string
    return result.substring(0, math.min(result.length, 1000));
  }

  /// Validate map data structure
  static ValidationResult<void> validateMapData(
    Map<String, dynamic>? data,
    List<String> requiredFields,
  ) {
    if (data == null || data.isEmpty) {
      return ValidationResult.invalid('Data is required');
    }

    // Check for required fields
    for (final field in requiredFields) {
      if (!data.containsKey(field) || data[field] == null) {
        return ValidationResult.invalid('Missing required field: $field');
      }
    }

    // Check for data size limits
    if (data.length > 50) {
      return ValidationResult.invalid('Too many fields in data');
    }

    return ValidationResult.valid();
  }

  /// Validate Firebase document ID
  static ValidationResult<void> validateDocumentId(String? docId) {
    if (docId == null || docId.isEmpty) {
      return ValidationResult.invalid('Document ID is required');
    }

    if (docId.length > 1500) {
      return ValidationResult.invalid('Document ID is too long');
    }

    // Check for invalid characters in Firebase document IDs
    if (docId.contains('/') || docId.contains('__')) {
      return ValidationResult.invalid(
        'Document ID contains invalid characters',
      );
    }

    return ValidationResult.valid();
  }
}

/// Result of input validation
class ValidationResult<T> {
  final bool isValid;
  final String? errorMessage;
  final T? data;

  const ValidationResult._({
    required this.isValid,
    this.errorMessage,
    this.data,
  });

  factory ValidationResult.valid({T? data}) {
    return ValidationResult._(isValid: true, data: data);
  }

  factory ValidationResult.invalid(String message) {
    return ValidationResult._(isValid: false, errorMessage: message);
  }

  /// Throw an exception if validation failed
  void throwIfInvalid() {
    if (!isValid) {
      throw ValidationException(errorMessage ?? 'Validation failed');
    }
  }

  /// Get the validated data or throw an exception
  T getOrThrow() {
    throwIfInvalid();
    return data as T;
  }
}

/// Exception thrown when input validation fails
class ValidationException implements Exception {
  final String message;

  const ValidationException(this.message);

  @override
  String toString() => 'ValidationException: $message';
}
