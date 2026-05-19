import 'package:shared_preferences/shared_preferences.dart';

enum MotionMode { full, balanced, reduced }

class MotionPreferencesService {
  factory MotionPreferencesService() => _instance;
  MotionPreferencesService._internal();
  static final MotionPreferencesService _instance =
      MotionPreferencesService._internal();

  static const _kMotionMode = 'ux_motion_mode';

  Future<MotionMode> getMotionMode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kMotionMode);
    return MotionMode.values.where((m) => m.name == raw).firstOrNull ??
        MotionMode.full;
  }

  Future<void> setMotionMode(MotionMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMotionMode, mode.name);
  }
}

