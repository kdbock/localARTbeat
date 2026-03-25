enum LocalAdZone { home, events, artists, community, featured }

extension LocalAdZoneExtension on LocalAdZone {
  static const launchPlacements = <LocalAdZone>[
    LocalAdZone.community,
    LocalAdZone.artists,
    LocalAdZone.events,
  ];

  bool get isLaunchPlacement => launchPlacements.contains(this);

  String get displayName {
    switch (this) {
      case LocalAdZone.home:
        return 'Home (not in launch rotation)';
      case LocalAdZone.events:
        return 'Events';
      case LocalAdZone.artists:
        return 'Artists and artwork';
      case LocalAdZone.community:
        return 'Community feed';
      case LocalAdZone.featured:
        return 'Featured (not in launch rotation)';
    }
  }

  String get description {
    switch (this) {
      case LocalAdZone.home:
        return 'Reserved for a future launch phase.';
      case LocalAdZone.events:
        return 'Shown between event sections and event discovery content.';
      case LocalAdZone.artists:
        return 'Shown beside artist and artwork browsing surfaces.';
      case LocalAdZone.community:
        return 'Shown between community posts and social content.';
      case LocalAdZone.featured:
        return 'Reserved for a future launch phase.';
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
