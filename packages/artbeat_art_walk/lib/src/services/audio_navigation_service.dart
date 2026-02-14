import 'package:logger/logger.dart';
import 'package:artbeat_art_walk/src/models/models.dart';

/// Settings for audio navigation service
class AudioNavigationSettings {
  final bool enableVoiceDirections;
  final bool enableArtAnnouncements;
  final bool enableProgressUpdates;
  final double speechRate;
  final String voiceLanguage;
  final bool enableInBackground;
  final double volume;
  final double pitch;

  const AudioNavigationSettings({
    this.enableVoiceDirections = true,
    this.enableArtAnnouncements = true,
    this.enableProgressUpdates = true,
    this.speechRate = 0.5,
    this.voiceLanguage = 'en-US',
    this.enableInBackground = false,
    this.volume = 0.8,
    this.pitch = 1.0,
  });

  /// Create from map (for storage/retrieval)
  factory AudioNavigationSettings.fromMap(Map<String, dynamic> map) {
    return AudioNavigationSettings(
      enableVoiceDirections: map['enableVoiceDirections'] as bool? ?? true,
      enableArtAnnouncements: map['enableArtAnnouncements'] as bool? ?? true,
      enableProgressUpdates: map['enableProgressUpdates'] as bool? ?? true,
      speechRate: (map['speechRate'] as num? ?? 0.5).toDouble(),
      voiceLanguage: map['voiceLanguage'] as String? ?? 'en-US',
      enableInBackground: map['enableInBackground'] as bool? ?? false,
      volume: (map['volume'] as num? ?? 0.8).toDouble(),
      pitch: (map['pitch'] as num? ?? 1.0).toDouble(),
    );
  }

  /// Convert to map (for storage)
  Map<String, dynamic> toMap() {
    return {
      'enableVoiceDirections': enableVoiceDirections,
      'enableArtAnnouncements': enableArtAnnouncements,
      'enableProgressUpdates': enableProgressUpdates,
      'speechRate': speechRate,
      'voiceLanguage': voiceLanguage,
      'enableInBackground': enableInBackground,
      'volume': volume,
      'pitch': pitch,
    };
  }

  /// Create copy with updated values
  AudioNavigationSettings copyWith({
    bool? enableVoiceDirections,
    bool? enableArtAnnouncements,
    bool? enableProgressUpdates,
    double? speechRate,
    String? voiceLanguage,
    bool? enableInBackground,
    double? volume,
    double? pitch,
  }) {
    return AudioNavigationSettings(
      enableVoiceDirections:
          enableVoiceDirections ?? this.enableVoiceDirections,
      enableArtAnnouncements:
          enableArtAnnouncements ?? this.enableArtAnnouncements,
      enableProgressUpdates:
          enableProgressUpdates ?? this.enableProgressUpdates,
      speechRate: speechRate ?? this.speechRate,
      voiceLanguage: voiceLanguage ?? this.voiceLanguage,
      enableInBackground: enableInBackground ?? this.enableInBackground,
      volume: volume ?? this.volume,
      pitch: pitch ?? this.pitch,
    );
  }
}

/// Service for providing audio navigation and announcements during art walks
class AudioNavigationService {
  static final AudioNavigationService _instance =
      AudioNavigationService._internal();
  factory AudioNavigationService() => _instance;
  AudioNavigationService._internal();

  // final FlutterTts _tts = FlutterTts();
  final Logger _logger = Logger();

  // bool _isEnabled = false; // Default to disabled
  // final String _language = 'en-US';
  // final double _speechRate = 0.5;
  // final double _volume = 0.8;
  // final double _pitch = 1.0;

  // Audio settings
  // AudioNavigationSettings _settings = const AudioNavigationSettings(
  //   enableVoiceDirections: false,
  //   enableArtAnnouncements: false,
  //   enableProgressUpdates: false,
  // );

  /// Initialize the TTS engine
  Future<void> initialize() async {
    _logger.i('Audio navigation service initialized (NO-OP mode)');
    return;
  }

  /// Update audio settings
  Future<void> updateSettings(AudioNavigationSettings settings) async {
    // _settings = settings;
    // _isEnabled = false; // Always disabled
  }

  /// Speak a navigation direction
  Future<void> speakDirection(String instruction) async {
    return;
  }

  /// Announce approaching art piece
  Future<void> announceArtPieceApproach(
    PublicArtModel art,
    double distance,
  ) async {
    return;
  }

  /// Celebrate art visit with audio feedback
  Future<void> celebrateArtVisit(PublicArtModel art, int points) async {
    return;
  }

  /// Announce walk progress
  Future<void> announceWalkProgress(int visited, int total) async {
    return;
  }

  /// Announce milestone achievement
  Future<void> announceMilestone(String milestone, int points) async {
    return;
  }

  /// Generate approach message for art piece
  String generateApproachMessage(PublicArtModel art, double distance) {
    final distanceText =
        distance < 100
            ? '${distance.round()} meters'
            : '${(distance / 1000).toStringAsFixed(1)} kilometers';

    return 'Approaching "${art.title}" in $distanceText.';
  }

  /// Generate arrival message for art piece
  String generateArrivalMessage(PublicArtModel art, int points) {
    final messages = [
      'You\'ve arrived at "${art.title}". You earned $points points!',
      'Great! You found "${art.title}". $points points added to your score.',
      'Excellent! "${art.title}" discovered. You earned $points points.',
    ];

    // Rotate through different messages for variety
    final index = DateTime.now().millisecond % messages.length;
    return messages[index];
  }

  /// Generate direction message from navigation step
  String generateDirectionMessage(NavigationStepModel step) {
    final instruction = step.instruction;

    if (step.distanceMeters > 0) {
      final distanceText =
          step.distanceMeters < 1000
              ? '${step.distanceMeters.round()} meters'
              : '${(step.distanceMeters / 1000).toStringAsFixed(1)} kilometers';

      return '$instruction in $distanceText.';
    }

    return instruction;
  }

  /// Stop current speech
  Future<void> stop() async {
    return;
  }

  /// Pause current speech
  Future<void> pause() async {
    return;
  }

  /// Enable/disable audio navigation
  void setEnabled(bool enabled) {
    // _isEnabled = false; // Always false
  }

  /// Check if audio is currently enabled
  bool get isEnabled => false; // Always false

  /// Get available languages
  Future<List<String>> getAvailableLanguages() async {
    return ['en-US'];
  }

  /// Get available voices for current language
  Future<List<Map<String, String>>> getAvailableVoices() async {
    return [];
  }

  /// Generic speak method for custom messages
  Future<void> speak(String message) async {
    return;
  }

  /// Dispose of resources
  void dispose() {
  }
}
