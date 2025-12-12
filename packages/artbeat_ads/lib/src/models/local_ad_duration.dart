enum LocalAdDuration { oneWeek, oneMonth, threeMonths }

extension LocalAdDurationExtension on LocalAdDuration {
  String get displayName {
    switch (this) {
      case LocalAdDuration.oneWeek:
        return '1 Week';
      case LocalAdDuration.oneMonth:
        return '1 Month';
      case LocalAdDuration.threeMonths:
        return '3 Months';
    }
  }

  int get days {
    switch (this) {
      case LocalAdDuration.oneWeek:
        return 7;
      case LocalAdDuration.oneMonth:
        return 30;
      case LocalAdDuration.threeMonths:
        return 90;
    }
  }

  int get index {
    switch (this) {
      case LocalAdDuration.oneWeek:
        return 0;
      case LocalAdDuration.oneMonth:
        return 1;
      case LocalAdDuration.threeMonths:
        return 2;
    }
  }

  static LocalAdDuration fromIndex(int idx) {
    return LocalAdDuration.values[idx];
  }
}
