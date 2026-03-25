enum LocalAdSize { small, big }

extension LocalAdSizeExtension on LocalAdSize {
  String get displayName {
    switch (this) {
      case LocalAdSize.small:
        return 'Banner Ad';
      case LocalAdSize.big:
        return 'Inline Ad';
    }
  }

  String get description {
    switch (this) {
      case LocalAdSize.small:
        return 'Best for section breaks across key dashboards';
      case LocalAdSize.big:
        return 'Best for feed visibility between local content cards';
    }
  }

  int get index {
    switch (this) {
      case LocalAdSize.small:
        return 0;
      case LocalAdSize.big:
        return 1;
    }
  }

  static LocalAdSize fromIndex(int idx) {
    return LocalAdSize.values[idx];
  }
}
