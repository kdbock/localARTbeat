import 'package:artbeat_core/artbeat_core.dart' show FirestoreUtils;

/// Model representing the refund policy for an event
/// Supports full refunds up to a specified deadline before the event
class RefundPolicy {
  final Duration fullRefundDeadline; // default: 24 hours before event
  final bool allowPartialRefunds; // allow partial refunds after deadline
  final double partialRefundPercentage; // percentage of refund after deadline
  final String terms; // custom refund terms/conditions
  final List<String> exceptions; // situations where refunds may not apply

  const RefundPolicy({
    this.fullRefundDeadline = const Duration(hours: 24),
    this.allowPartialRefunds = false,
    this.partialRefundPercentage = 0.0,
    this.terms =
        'Full refund available up to 24 hours before event start time.',
    this.exceptions = const [],
  });

  /// Create RefundPolicy from Map (for Firestore)
  factory RefundPolicy.fromMap(Map<String, dynamic> map) {
    return RefundPolicy(
      fullRefundDeadline: Duration(
        hours: FirestoreUtils.safeInt(map['fullRefundDeadlineHours'], 24),
      ),
      allowPartialRefunds: FirestoreUtils.safeBool(map['allowPartialRefunds']),
      partialRefundPercentage: FirestoreUtils.safeDouble(
        map['partialRefundPercentage'],
      ),
      terms: FirestoreUtils.safeStringDefault(
        map['terms'],
        'Full refund available up to 24 hours before event start time.',
      ),
      exceptions: (map['exceptions'] as List? ?? [])
          .map(FirestoreUtils.safeStringDefault)
          .toList(),
    );
  }

  /// Convert RefundPolicy to Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'fullRefundDeadlineHours': fullRefundDeadline.inHours,
      'allowPartialRefunds': allowPartialRefunds,
      'partialRefundPercentage': partialRefundPercentage,
      'terms': terms,
      'exceptions': exceptions,
    };
  }

  /// Standard 24-hour refund policy
  factory RefundPolicy.standard() {
    return const RefundPolicy();
  }

  /// No refund policy
  factory RefundPolicy.noRefunds() {
    return const RefundPolicy(
      fullRefundDeadline: Duration.zero,
      terms: 'No refunds available for this event.',
      exceptions: ['All sales are final'],
    );
  }

  /// Flexible refund policy (7 days)
  factory RefundPolicy.flexible() {
    return const RefundPolicy(
      fullRefundDeadline: Duration(days: 7),
      allowPartialRefunds: true,
      partialRefundPercentage: 50.0,
      terms:
          'Full refund available up to 7 days before event. 50% refund available up to 24 hours before event.',
    );
  }

  /// Create a copy of this RefundPolicy with the given fields replaced
  RefundPolicy copyWith({
    Duration? fullRefundDeadline,
    bool? allowPartialRefunds,
    double? partialRefundPercentage,
    String? terms,
    List<String>? exceptions,
  }) {
    return RefundPolicy(
      fullRefundDeadline: fullRefundDeadline ?? this.fullRefundDeadline,
      allowPartialRefunds: allowPartialRefunds ?? this.allowPartialRefunds,
      partialRefundPercentage:
          partialRefundPercentage ?? this.partialRefundPercentage,
      terms: terms ?? this.terms,
      exceptions: exceptions ?? this.exceptions,
    );
  }

  /// Check if full refund is available for given event date
  bool canGetFullRefund(DateTime eventDate) {
    final deadline = eventDate.subtract(fullRefundDeadline);
    return DateTime.now().isBefore(deadline);
  }

  /// Check if partial refund is available for given event date
  bool canGetPartialRefund(DateTime eventDate) {
    if (!allowPartialRefunds) return false;
    if (canGetFullRefund(eventDate)) return true; // full refund is better

    // Check if we're still before the event
    return DateTime.now().isBefore(eventDate);
  }

  /// Get refund percentage available for given event date
  double getRefundPercentage(DateTime eventDate) {
    if (canGetFullRefund(eventDate)) return 100.0;
    if (canGetPartialRefund(eventDate)) return partialRefundPercentage;
    return 0.0;
  }

  /// Get refund amount for given ticket price and event date
  double getRefundAmount(double ticketPrice, DateTime eventDate) {
    final percentage = getRefundPercentage(eventDate);
    return ticketPrice * (percentage / 100.0);
  }

  /// Get human-readable deadline description
  String get deadlineDescription {
    if (fullRefundDeadline.inDays > 0) {
      return '${fullRefundDeadline.inDays} day${fullRefundDeadline.inDays > 1 ? 's' : ''} before event';
    } else if (fullRefundDeadline.inHours > 0) {
      return '${fullRefundDeadline.inHours} hour${fullRefundDeadline.inHours > 1 ? 's' : ''} before event';
    } else {
      return 'Event start time';
    }
  }

  /// Get comprehensive refund policy description
  String get fullDescription {
    final buffer = StringBuffer();

    if (fullRefundDeadline > Duration.zero) {
      buffer.write('Full refund available up to $deadlineDescription. ');
    }

    if (allowPartialRefunds && partialRefundPercentage > 0) {
      buffer.write(
        '${partialRefundPercentage.toStringAsFixed(0)}% refund available after deadline until event start. ',
      );
    }

    if (exceptions.isNotEmpty) {
      buffer.write('Exceptions: ${exceptions.join(', ')}. ');
    }

    if (buffer.isEmpty) {
      return 'No refunds available.';
    }

    return buffer.toString().trim();
  }

  @override
  String toString() {
    return 'RefundPolicy{fullRefundDeadline: $fullRefundDeadline, allowPartialRefunds: $allowPartialRefunds}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RefundPolicy &&
          runtimeType == other.runtimeType &&
          fullRefundDeadline == other.fullRefundDeadline &&
          allowPartialRefunds == other.allowPartialRefunds &&
          partialRefundPercentage == other.partialRefundPercentage &&
          terms == other.terms;

  @override
  int get hashCode => Object.hash(
    fullRefundDeadline,
    allowPartialRefunds,
    partialRefundPercentage,
    terms,
  );
}
