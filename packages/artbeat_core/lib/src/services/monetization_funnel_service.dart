import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import '../utils/logger.dart';

/// Tracks stage-level monetization funnel events for paid product flows.
///
/// The goal is to capture business progression data without forcing UI layers
/// to know analytics transport details.
class MonetizationFunnelService {
  static final MonetizationFunnelService _instance =
      MonetizationFunnelService._internal();

  factory MonetizationFunnelService() => _instance;

  MonetizationFunnelService._internal();

  FirebaseAnalytics? _analyticsInstance;
  FirebaseFirestore? _firestoreInstance;

  FirebaseAnalytics get _analytics =>
      _analyticsInstance ??= FirebaseAnalytics.instance;
  FirebaseFirestore get _firestore =>
      _firestoreInstance ??= FirebaseFirestore.instance;

  Future<void> trackStage({
    required String flow,
    required String stage,
    String? productFamily,
    String? placement,
    String? status,
    String? userId,
    String? currencyCode,
    double? amount,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) async {
    final normalizedFlow = _normalize(flow);
    final normalizedStage = _normalize(stage);

    try {
      await _analytics.logEvent(
        name: 'monetization_funnel',
        parameters: <String, Object>{
          'flow': normalizedFlow,
          'stage': normalizedStage,
          if (productFamily != null)
            'product_family': _normalize(productFamily),
          if (placement != null) 'placement': _normalize(placement),
          if (status != null) 'status': _normalize(status),
          if (currencyCode != null) 'currency': _normalize(currencyCode),
          if (amount != null) 'amount_cents': (amount * 100).round(),
        },
      );
    } catch (error) {
      AppLogger.warning(
        'Failed to log monetization funnel analytics for $normalizedFlow/$normalizedStage: $error',
      );
    }

    try {
      await _firestore
          .collection('monetization_funnel_events')
          .add(<String, Object?>{
            'flow': normalizedFlow,
            'stage': normalizedStage,
            'productFamily': productFamily,
            'placement': placement,
            'status': status,
            'userId': userId,
            'currencyCode': currencyCode,
            'amount': amount,
            'metadata': metadata,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (error) {
      AppLogger.warning(
        'Failed to persist monetization funnel event for $normalizedFlow/$normalizedStage: $error',
      );
    }
  }

  String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]+'), '_');
}
