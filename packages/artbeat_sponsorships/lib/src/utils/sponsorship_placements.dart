class SponsorshipPlacements {
  static const String splash = 'splash';

  static const String dashboardTop = 'dashboard_top';
  static const String dashboardFooter = 'dashboard_footer';

  static const String eventHeader = 'event_header';

  static const String artWalkHeader = 'art_walk_header';
  static const String artWalkStopCard = 'art_walk_stop_card';

  static const String captureDetailBanner = 'capture_detail_banner';

  static const String discoverRadarBanner = 'discover_radar_banner';

  static const List<String> all = [
    splash,
    dashboardTop,
    dashboardFooter,
    eventHeader,
    artWalkHeader,
    artWalkStopCard,
    captureDetailBanner,
    discoverRadarBanner,
  ];

  static bool isValid(String placementKey) => all.contains(placementKey);
}
