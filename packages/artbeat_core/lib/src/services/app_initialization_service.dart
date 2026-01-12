import 'image_management_service.dart';
import '../utils/logger.dart';
import '../utils/device_utils.dart';

/// Service to handle app initialization tasks
class AppInitializationService {
  static final AppInitializationService _instance =
      AppInitializationService._internal();
  factory AppInitializationService() => _instance;
  AppInitializationService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize all core services
  Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.warning('⚠️ AppInitializationService already initialized');
      return;
    }

    AppLogger.info('🚀 Initializing ARTbeat Core Services...');

    try {
      // Initialize device info
      await DeviceUtils.initialize();

      // Initialize image management service
      await ImageManagementService().initialize();

      // Add other service initializations here

      _isInitialized = true;
      AppLogger.info('✅ ARTbeat Core Services initialized successfully');
    } catch (e) {
      AppLogger.error('❌ Failed to initialize ARTbeat Core Services: $e');
      rethrow;
    }
  }

  /// Reset initialization state (for testing)
  void reset() {
    _isInitialized = false;
    AppLogger.info('🔄 AppInitializationService reset');
  }
}
