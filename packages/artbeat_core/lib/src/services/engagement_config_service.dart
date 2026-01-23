import '../models/engagement_model.dart';

/// Service to configure which engagement types are available for each content type
class EngagementConfigService {
  /// Get available engagement types for a specific content type
  static List<EngagementType> getEngagementTypesForContent(String contentType) {
    switch (contentType) {
      case 'capture':
        return [
          EngagementType.like,
          EngagementType.comment,
          EngagementType.share,
          EngagementType.seen,
          EngagementType.rate,
          EngagementType.review,
        ];
      case 'artwork':
        return [
          EngagementType.like,
          EngagementType.share,
          EngagementType.boost,
          EngagementType.commission,
        ];
      case 'artist':
      case 'profile':
        return [
          EngagementType.like,
          EngagementType.follow,
          EngagementType.boost,
          EngagementType.sponsor,
          EngagementType.message,
          EngagementType.commission,
        ];
      case 'event':
        return [
          EngagementType.like,
          EngagementType.comment,
          EngagementType.reply,
          EngagementType.share,
          EngagementType.seen,
          EngagementType.rate,
          EngagementType.review,
        ];
      case 'post':
        return [
          EngagementType.like,
          EngagementType.comment,
          EngagementType.reply,
          EngagementType.share,
        ];
      case 'comment':
        return [
          EngagementType.like,
          EngagementType.comment,
          EngagementType.reply,
        ];
      default:
        return [EngagementType.like];
    }
  }

  /// Check if an engagement type is available for a content type
  static bool isEngagementTypeAvailable(
    String contentType,
    EngagementType engagementType,
  ) {
    final availableTypes = getEngagementTypesForContent(contentType);
    return availableTypes.contains(engagementType);
  }

  /// Get primary engagement types (most commonly used) for a content type
  static List<EngagementType> getPrimaryEngagementTypes(String contentType) {
    switch (contentType) {
      case 'capture':
        return [
          EngagementType.like,
          EngagementType.comment,
          EngagementType.share,
          EngagementType.seen,
        ];
      case 'artwork':
        return [
          EngagementType.like,
          EngagementType.share,
          EngagementType.boost,
          EngagementType.commission,
        ];
      case 'artist':
      case 'profile':
        return [
          EngagementType.like,
          EngagementType.follow,
          EngagementType.boost,
          EngagementType.message,
        ];
      case 'event':
        return [
          EngagementType.like,
          EngagementType.comment,
          EngagementType.share,
          EngagementType.seen,
        ];
      case 'post':
        return [
          EngagementType.like,
          EngagementType.comment,
          EngagementType.reply,
          EngagementType.share,
        ];
      case 'comment':
        return [
          EngagementType.like,
          EngagementType.comment,
          EngagementType.reply,
        ];
      default:
        return [EngagementType.like];
    }
  }

  /// Get secondary engagement types (less commonly used) for a content type
  static List<EngagementType> getSecondaryEngagementTypes(String contentType) {
    final allTypes = getEngagementTypesForContent(contentType);
    final primaryTypes = getPrimaryEngagementTypes(contentType);
    return allTypes.where((type) => !primaryTypes.contains(type)).toList();
  }

  /// Check if engagement type requires special handling (e.g., payment, forms)
  static bool requiresSpecialHandling(EngagementType engagementType) {
    switch (engagementType) {
      case EngagementType.boost:
      case EngagementType.sponsor:
      case EngagementType.commission:
      case EngagementType.message:
      case EngagementType.review:
      case EngagementType.rate:
      case EngagementType.comment:
      case EngagementType.share:
        return true;
      default:
        return false;
    }
  }

  /// Check if engagement type should be automatically tracked
  static bool isAutoTracked(EngagementType engagementType) {
    switch (engagementType) {
      case EngagementType.seen:
        return true;
      default:
        return false;
    }
  }

  /// Get engagement types that support counts (vs binary states)
  static bool supportsCount(EngagementType engagementType) {
    switch (engagementType) {
      case EngagementType.like:
      case EngagementType.comment:
      case EngagementType.reply:
      case EngagementType.share:
      case EngagementType.seen:
      case EngagementType.rate:
      case EngagementType.review:
      case EngagementType.follow:
      case EngagementType.boost:
      case EngagementType.sponsor:
      case EngagementType.message:
        return true;
      case EngagementType.commission:
        return false; // Commission is more of a status/availability toggle
    }
  }
}
