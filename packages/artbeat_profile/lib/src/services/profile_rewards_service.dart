import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' show AppLogger;
import 'profile_rewards_catalog.dart';

class ProfileRewardsService {
  static const Map<String, Map<String, dynamic>> badges = profileBadgeCatalog;

  final FirebaseFirestore _firestore;

  ProfileRewardsService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getUserBadges(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.data()?['badges'] as Map<String, dynamic>? ?? {};
    } catch (e) {
      AppLogger.error('Error getting user badges: $e');
      return {};
    }
  }

  Future<List<String>> getUnviewedBadges(String userId) async {
    try {
      final badges = await getUserBadges(userId);
      return badges.entries
          .where((entry) {
            final value = entry.value;
            return value is Map && value['viewed'] == false;
          })
          .map((entry) => entry.key)
          .toList();
    } catch (e) {
      AppLogger.error('Error getting unviewed badges: $e');
      return [];
    }
  }
}
