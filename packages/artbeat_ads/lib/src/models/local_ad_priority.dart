enum LocalAdPriority { high, medium, low }

extension LocalAdPriorityExtension on LocalAdPriority {
  String get displayName {
    switch (this) {
      case LocalAdPriority.high:
        return 'Priority 1 - High Traffic';
      case LocalAdPriority.medium:
        return 'Priority 2 - Medium Traffic';
      case LocalAdPriority.low:
        return 'Priority 3 - Low Traffic';
    }
  }

  String get description {
    switch (this) {
      case LocalAdPriority.high:
        return 'Premium placements - high engagement areas';
      case LocalAdPriority.medium:
        return 'Standard placements - medium visibility';
      case LocalAdPriority.low:
        return 'Budget placements - low traffic areas';
    }
  }

  int get value {
    switch (this) {
      case LocalAdPriority.high:
        return 1;
      case LocalAdPriority.medium:
        return 2;
      case LocalAdPriority.low:
        return 3;
    }
  }

  int get index {
    switch (this) {
      case LocalAdPriority.high:
        return 0;
      case LocalAdPriority.medium:
        return 1;
      case LocalAdPriority.low:
        return 2;
    }
  }

  static LocalAdPriority fromIndex(int idx) {
    return LocalAdPriority.values[idx];
  }
}
