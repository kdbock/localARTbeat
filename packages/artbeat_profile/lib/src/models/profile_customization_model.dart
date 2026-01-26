import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Model for profile customization settings
class ProfileCustomizationModel {
  final String userId;
  final String? selectedTheme;
  final String? primaryColor;
  final String? secondaryColor;
  final String? coverPhotoUrl;
  final bool showBio;
  final bool showLocation;
  final bool showAchievements;
  final bool showActivity;
  final String? layoutStyle;
  final Map<String, bool> visibilitySettings;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProfileCustomizationModel({
    required this.userId,
    this.selectedTheme,
    this.primaryColor,
    this.secondaryColor,
    this.coverPhotoUrl,
    this.showBio = true,
    this.showLocation = true,
    this.showAchievements = true,
    this.showActivity = true,
    this.layoutStyle,
    this.visibilitySettings = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProfileCustomizationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ProfileCustomizationModel(
      userId: doc.id,
      selectedTheme: FirestoreUtils.getOptionalString(data, 'selectedTheme'),
      primaryColor: FirestoreUtils.getOptionalString(data, 'primaryColor'),
      secondaryColor: FirestoreUtils.getOptionalString(data, 'secondaryColor'),
      coverPhotoUrl: FirestoreUtils.getOptionalString(data, 'coverPhotoUrl'),
      showBio: FirestoreUtils.getBool(data, 'showBio', true),
      showLocation: FirestoreUtils.getBool(data, 'showLocation', true),
      showAchievements: FirestoreUtils.getBool(data, 'showAchievements', true),
      showActivity: FirestoreUtils.getBool(data, 'showActivity', true),
      layoutStyle: FirestoreUtils.getOptionalString(data, 'layoutStyle'),
      visibilitySettings: Map<String, bool>.from(
        FirestoreUtils.getOptionalMap(data, 'visibilitySettings') ?? {},
      ),
      createdAt: FirestoreUtils.getDateTime(data, 'createdAt'),
      updatedAt: FirestoreUtils.getDateTime(data, 'updatedAt'),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'selectedTheme': selectedTheme,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'coverPhotoUrl': coverPhotoUrl,
      'showBio': showBio,
      'showLocation': showLocation,
      'showAchievements': showAchievements,
      'showActivity': showActivity,
      'layoutStyle': layoutStyle,
      'visibilitySettings': visibilitySettings,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ProfileCustomizationModel copyWith({
    String? selectedTheme,
    String? primaryColor,
    String? secondaryColor,
    String? coverPhotoUrl,
    bool? showBio,
    bool? showLocation,
    bool? showAchievements,
    bool? showActivity,
    String? layoutStyle,
    Map<String, bool>? visibilitySettings,
    DateTime? updatedAt,
  }) {
    return ProfileCustomizationModel(
      userId: userId,
      selectedTheme: selectedTheme ?? this.selectedTheme,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      showBio: showBio ?? this.showBio,
      showLocation: showLocation ?? this.showLocation,
      showAchievements: showAchievements ?? this.showAchievements,
      showActivity: showActivity ?? this.showActivity,
      layoutStyle: layoutStyle ?? this.layoutStyle,
      visibilitySettings: visibilitySettings ?? this.visibilitySettings,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
