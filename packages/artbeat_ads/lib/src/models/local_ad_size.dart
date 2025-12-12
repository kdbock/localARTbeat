enum LocalAdSize { small, big }

extension LocalAdSizeExtension on LocalAdSize {
  String get displayName {
    switch (this) {
      case LocalAdSize.small:
        return 'Small';
      case LocalAdSize.big:
        return 'Big';
    }
  }

  String get description {
    switch (this) {
      case LocalAdSize.small:
        return 'Standard size - lower visibility';
      case LocalAdSize.big:
        return 'Large size - premium visibility';
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
