import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/admin_stats_model.dart';
import '../models/user_admin_model.dart';

/// Service for admin-specific operations
class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get admin dashboard statistics
  Future<AdminStatsModel> getAdminStats() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekAgo = today.subtract(const Duration(days: 7));
      final monthAgo = DateTime(now.year, now.month - 1, now.day);

      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();
      final users = usersSnapshot.docs;

      // Calculate user type counts
      final int totalUsers = users.length;
      int totalArtists = 0;
      int totalGalleries = 0;
      int totalModerators = 0;
      int totalAdmins = 0;
      int newUsersToday = 0;
      int newUsersThisWeek = 0;
      int newUsersThisMonth = 0;
      int activeUsersToday = 0;
      int activeUsersThisWeek = 0;
      int activeUsersThisMonth = 0;

      for (var doc in users) {
        final data = doc.data();
        final userType =
            UserType.fromString(data['userType'] as String? ?? 'user');
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        final lastActiveAt = (data['lastActiveAt'] as Timestamp?)?.toDate();

        // Count user types
        switch (userType) {
          case UserType.artist:
            totalArtists++;
            break;
          case UserType.gallery:
            totalGalleries++;
            break;
          case UserType.moderator:
            totalModerators++;
            break;
          case UserType.admin:
            totalAdmins++;
            break;
          default:
            break;
        }

        // Count new users
        if (createdAt != null) {
          if (createdAt.isAfter(today)) {
            newUsersToday++;
          }
          if (createdAt.isAfter(weekAgo)) {
            newUsersThisWeek++;
          }
          if (createdAt.isAfter(monthAgo)) {
            newUsersThisMonth++;
          }
        }

        // Count active users
        if (lastActiveAt != null) {
          if (lastActiveAt.isAfter(today)) {
            activeUsersToday++;
          }
          if (lastActiveAt.isAfter(weekAgo)) {
            activeUsersThisWeek++;
          }
          if (lastActiveAt.isAfter(monthAgo)) {
            activeUsersThisMonth++;
          }
        }
      }

      // Get artwork count
      final artworksSnapshot = await _firestore.collection('artwork').get();
      final totalArtworks = artworksSnapshot.docs.length;

      // Get captures count
      final capturesSnapshot = await _firestore.collection('captures').get();
      final totalCaptures = capturesSnapshot.docs.length;

      // Get events count
      final eventsSnapshot = await _firestore.collection('events').get();
      final totalEvents = eventsSnapshot.docs.length;

      return AdminStatsModel(
        totalUsers: totalUsers,
        totalArtists: totalArtists,
        totalGalleries: totalGalleries,
        totalModerators: totalModerators,
        totalAdmins: totalAdmins,
        totalArtworks: totalArtworks,
        totalCaptures: totalCaptures,
        totalEvents: totalEvents,
        newUsersToday: newUsersToday,
        newUsersThisWeek: newUsersThisWeek,
        newUsersThisMonth: newUsersThisMonth,
        activeUsersToday: activeUsersToday,
        activeUsersThisWeek: activeUsersThisWeek,
        activeUsersThisMonth: activeUsersThisMonth,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to get admin stats: $e');
    }
  }

  /// Get all users with admin functionality
  Future<List<UserAdminModel>> getAllUsers({
    int? limit,
    String? orderBy,
    bool? descending,
    UserType? filterByType,
    String? searchQuery,
  }) async {
    try {
      Query query = _firestore.collection('users');

      // Apply filters
      if (filterByType != null) {
        query = query.where('userType', isEqualTo: filterByType.name);
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending ?? false);
      } else {
        query = query.orderBy('createdAt', descending: true);
      }

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      List<UserAdminModel> users = snapshot.docs
          .map((doc) => UserAdminModel.fromDocumentSnapshot(doc))
          .toList();

      // Apply search filter if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        users = users
            .where((user) =>
                user.username.toLowerCase().contains(lowerQuery) ||
                user.email.toLowerCase().contains(lowerQuery) ||
                user.fullName.toLowerCase().contains(lowerQuery))
            .toList();
      }

      return users;
    } catch (e) {
      throw Exception('Failed to get users: $e');
    }
  }

  /// Update user type
  Future<void> updateUserType(String userId, UserType newType) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'userType': newType.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user type: $e');
    }
  }

  /// Suspend user
  Future<void> suspendUser(
      String userId, String reason, String suspendedBy) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isSuspended': true,
        'suspensionReason': reason,
        'suspendedAt': FieldValue.serverTimestamp(),
        'suspendedBy': suspendedBy,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to suspend user: $e');
    }
  }

  /// Unsuspend user
  Future<void> unsuspendUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isSuspended': false,
        'suspensionReason': null,
        'suspendedAt': null,
        'suspendedBy': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to unsuspend user: $e');
    }
  }

  /// Verify user
  Future<void> verifyUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isVerified': true,
        'emailVerifiedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to verify user: $e');
    }
  }

  /// Unverify user
  Future<void> unverifyUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isVerified': false,
        'emailVerifiedAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to unverify user: $e');
    }
  }

  /// Delete user (soft delete)
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  /// Update user profile information
  Future<void> updateUserProfile(
      String userId, Map<String, dynamic> profileData) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        ...profileData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  /// Remove user profile image
  Future<void> removeUserProfileImage(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'profileImageUrl': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to remove user profile image: $e');
    }
  }

  /// Remove user cover image
  Future<void> removeUserCoverImage(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'coverImageUrl': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to remove user cover image: $e');
    }
  }

  /// Set user as featured
  Future<void> setUserFeatured(String userId, bool isFeatured) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isFeatured': isFeatured,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user featured status: $e');
    }
  }

  /// Toggle shadow ban for a user
  Future<void> toggleShadowBan(String userId, bool isShadowBanned) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isShadowBanned': isShadowBanned,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update shadow ban status: $e');
    }
  }

  /// Add admin note to user
  Future<void> addAdminNote(String userId, String note, String addedBy) async {
    try {
      final noteId = DateTime.now().millisecondsSinceEpoch.toString();
      await _firestore.collection('users').doc(userId).update({
        'adminNotes.$noteId': {
          'note': note,
          'addedBy': addedBy,
          'addedAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add admin note: $e');
    }
  }

  /// Update user experience points
  Future<void> updateUserExperience(String userId, int experiencePoints) async {
    try {
      final level = _calculateLevel(experiencePoints);
      await _firestore.collection('users').doc(userId).update({
        'experiencePoints': experiencePoints,
        'level': level,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user experience: $e');
    }
  }

  /// Calculate level based on experience points
  int _calculateLevel(int experiencePoints) {
    // Simple level calculation - can be customized
    if (experiencePoints < 100) return 1;
    if (experiencePoints < 500) return 2;
    if (experiencePoints < 1000) return 3;
    if (experiencePoints < 2500) return 4;
    if (experiencePoints < 5000) return 5;
    if (experiencePoints < 10000) return 6;
    if (experiencePoints < 25000) return 7;
    if (experiencePoints < 50000) return 8;
    if (experiencePoints < 100000) return 9;
    return 10;
  }

  /// Get user by ID
  Future<UserAdminModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserAdminModel.fromDocumentSnapshot(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  /// Bulk update users
  Future<void> bulkUpdateUsers(
      List<String> userIds, Map<String, dynamic> updates) async {
    try {
      final batch = _firestore.batch();

      for (final userId in userIds) {
        final docRef = _firestore.collection('users').doc(userId);
        batch.update(docRef, {
          ...updates,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to bulk update users: $e');
    }
  }

  /// Search users
  Future<List<UserAdminModel>> searchUsers(String query) async {
    try {
      final users = await getAllUsers();
      final lowerQuery = query.toLowerCase();

      return users
          .where((user) =>
              user.fullName.toLowerCase().contains(lowerQuery) ||
              user.email.toLowerCase().contains(lowerQuery) ||
              user.username.toLowerCase().contains(lowerQuery) ||
              user.userType.toString().toLowerCase().contains(lowerQuery))
          .toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  /// Check if the current user has admin privileges
  Future<bool> hasAdminPrivileges() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.exists && (doc.data()?['userType'] == 'admin');
  }

  /// Toggle user ban status
  Future<void> toggleUserBan(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data()!;
      final isSuspended = userData['isSuspended'] as bool? ?? false;

      await _firestore.collection('users').doc(userId).update({
        'isSuspended': !isSuspended,
        'suspendedAt': !isSuspended ? FieldValue.serverTimestamp() : null,
        'suspendedBy': !isSuspended ? _auth.currentUser?.uid : null,
        'suspensionReason': !isSuspended ? 'Admin action' : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to toggle user ban: $e');
    }
  }
}
