/// Art Walk route constants
class ArtWalkRoutes {
  static const String map = '/art-walk/map';
  static const String list = '/art-walk/list';
  static const String detail = '/art-walk/detail';
  static const String create = '/art-walk/create';
  static const String edit = '/art-walk/edit';
  static const String review = '/art-walk/review';
  static const String experience = '/art-walk/experience';
  static const String dashboard = '/art-walk/dashboard';
  static const String enhancedCreate = '/enhanced-create-art-walk';
  static const String celebration = '/art-walk/celebration';
  static const String questHistory = '/quest-history';
  static const String weeklyGoals = '/weekly-goals';

  // Deprecated: Use 'experience' instead
  @Deprecated('Use experience instead - both routes point to the same screen')
  static const String enhancedExperience = '/art-walk/experience';
}
