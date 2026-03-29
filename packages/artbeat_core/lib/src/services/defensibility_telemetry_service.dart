import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

enum DefensibilityEvent {
  creatorContentPublished,
  creatorContentQualityScored,
  creatorProfileVerifiedOrTrusted,
  feedImpression,
  feedItemOpen,
  recommendationClick,
  recommendationSaveOrFollow,
  sponsorCampaignView,
  sponsorCampaignClick,
  sponsorCampaignConversion,
  subscriptionStartOrRenewal,
  day1Return,
  day7Return,
  day30Return,
  activationMilestoneReached,
}

class DefensibilityTelemetryService {
  factory DefensibilityTelemetryService() => _instance;

  DefensibilityTelemetryService._internal();

  static final DefensibilityTelemetryService _instance =
      DefensibilityTelemetryService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> trackEvent(
    DefensibilityEvent event, {
    required String surface,
    String? creatorId,
    String? contentId,
    String? campaignId,
    String? experimentVariant,
    String? geoBucket,
    String? deviceBucket,
    Map<String, Object?> extra = const {},
  }) async {
    final now = DateTime.now().toUtc();
    final eventId = _generateEventId(now);
    final user = _auth.currentUser;

    final payload = <String, Object?>{
      'event_id': eventId,
      'event_name': _eventName(event),
      'event_time_utc': now.toIso8601String(),
      'timestamp': Timestamp.fromDate(now),
      'user_id': user?.uid ?? 'anonymous',
      'creator_id': creatorId,
      'content_id': contentId,
      'campaign_id': campaignId,
      'surface': surface,
      'experiment_variant': experimentVariant,
      'geo_bucket': geoBucket,
      'device_bucket': deviceBucket,
      ...extra,
    };

    try {
      await _analytics.logEvent(
        name: _eventName(event),
        parameters: _toAnalyticsParams(payload),
      );

      await _firestore.collection('defensibility_events').add(payload);
    } on Exception catch (error) {
      if (kDebugMode) {
        debugPrint('Defensibility telemetry error: $error');
      }
    }
  }

  String _eventName(DefensibilityEvent event) {
    switch (event) {
      case DefensibilityEvent.creatorContentPublished:
        return 'creator_content_published';
      case DefensibilityEvent.creatorContentQualityScored:
        return 'creator_content_quality_scored';
      case DefensibilityEvent.creatorProfileVerifiedOrTrusted:
        return 'creator_profile_verified_or_trusted';
      case DefensibilityEvent.feedImpression:
        return 'feed_impression';
      case DefensibilityEvent.feedItemOpen:
        return 'feed_item_open';
      case DefensibilityEvent.recommendationClick:
        return 'recommendation_click';
      case DefensibilityEvent.recommendationSaveOrFollow:
        return 'recommendation_save_or_follow';
      case DefensibilityEvent.sponsorCampaignView:
        return 'sponsor_campaign_view';
      case DefensibilityEvent.sponsorCampaignClick:
        return 'sponsor_campaign_click';
      case DefensibilityEvent.sponsorCampaignConversion:
        return 'sponsor_campaign_conversion';
      case DefensibilityEvent.subscriptionStartOrRenewal:
        return 'subscription_start_or_renewal';
      case DefensibilityEvent.day1Return:
        return 'day_1_return';
      case DefensibilityEvent.day7Return:
        return 'day_7_return';
      case DefensibilityEvent.day30Return:
        return 'day_30_return';
      case DefensibilityEvent.activationMilestoneReached:
        return 'activation_milestone_reached';
    }
  }

  Map<String, Object> _toAnalyticsParams(Map<String, Object?> payload) {
    final params = <String, Object>{};
    payload.forEach((key, value) {
      if (value is String) {
        params[key] = value;
      } else if (value is num) {
        params[key] = value;
      } else if (value is bool) {
        params[key] = value;
      }
    });
    return params;
  }

  String _generateEventId(DateTime now) {
    final randomPart = Random().nextInt(1 << 20).toRadixString(16);
    return '${now.microsecondsSinceEpoch}_$randomPart';
  }
}
