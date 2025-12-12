enum LocalAdZone { home, events, artists, community, featured }

extension LocalAdZoneExtension on LocalAdZone {
  String get displayName {
    switch (this) {
      case LocalAdZone.home:
        return 'Home';
      case LocalAdZone.events:
        return 'Events';
      case LocalAdZone.artists:
        return 'Artists';
      case LocalAdZone.community:
        return 'Community';
      case LocalAdZone.featured:
        return 'Featured';
    }
  }

  String get description {
    switch (this) {
      case LocalAdZone.home:
        return 'Main dashboard - high visibility';
      case LocalAdZone.events:
        return 'Events & experiences section';
      case LocalAdZone.artists:
        return 'Artists profiles area';
      case LocalAdZone.community:
        return 'Community hub & feeds';
      case LocalAdZone.featured:
        return 'Premium featured placement';
    }
  }

  int get index {
    switch (this) {
      case LocalAdZone.home:
        return 0;
      case LocalAdZone.events:
        return 1;
      case LocalAdZone.artists:
        return 2;
      case LocalAdZone.community:
        return 3;
      case LocalAdZone.featured:
        return 4;
    }
  }

  static LocalAdZone fromIndex(int idx) {
    return LocalAdZone.values[idx];
  }
}
