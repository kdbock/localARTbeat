import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart' show AppLogger;

enum ReleaseSchedule {
  weekly,
  biWeekly,
  monthly,
  custom,
}

class ScheduledRelease {
  final String id;
  final String artworkId;
  final String chapterId;
  final DateTime releaseDateTime;
  final bool isScheduled;
  final bool isReleased;
  final DateTime? releasedAt;

  ScheduledRelease({
    required this.id,
    required this.artworkId,
    required this.chapterId,
    required this.releaseDateTime,
    this.isScheduled = true,
    this.isReleased = false,
    this.releasedAt,
  });

  factory ScheduledRelease.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScheduledRelease(
      id: doc.id,
      artworkId: data['artworkId'] as String? ?? '',
      chapterId: data['chapterId'] as String? ?? '',
      releaseDateTime:
          (data['releaseDateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isScheduled: data['isScheduled'] as bool? ?? true,
      isReleased: data['isReleased'] as bool? ?? false,
      releasedAt: (data['releasedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'artworkId': artworkId,
      'chapterId': chapterId,
      'releaseDateTime': Timestamp.fromDate(releaseDateTime),
      'isScheduled': isScheduled,
      'isReleased': isReleased,
      if (releasedAt != null) 'releasedAt': Timestamp.fromDate(releasedAt!),
    };
  }
}

class ScheduleService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Future<ScheduledRelease> scheduleChapterRelease({
    required String artworkId,
    required String chapterId,
    required DateTime releaseDateTime,
  }) async {
    try {
      final releaseId = _firestore.collection('scheduled_releases').doc().id;

      final scheduledRelease = ScheduledRelease(
        id: releaseId,
        artworkId: artworkId,
        chapterId: chapterId,
        releaseDateTime: releaseDateTime,
        isScheduled: true,
      );

      await _firestore
          .collection('scheduled_releases')
          .doc(releaseId)
          .set(scheduledRelease.toFirestore());

      AppLogger.info(
          'Chapter scheduled for release: $chapterId at $releaseDateTime');
      return scheduledRelease;
    } catch (e) {
      AppLogger.error('Error scheduling chapter release: $e');
      throw Exception('Failed to schedule chapter release: $e');
    }
  }

  Future<void> updateSchedule({
    required String releaseId,
    required DateTime newReleaseDateTime,
  }) async {
    try {
      await _firestore.collection('scheduled_releases').doc(releaseId).update({
        'releaseDateTime': Timestamp.fromDate(newReleaseDateTime),
        'updatedAt': Timestamp.now(),
      });

      AppLogger.info('Schedule updated: $releaseId to $newReleaseDateTime');
    } catch (e) {
      AppLogger.error('Error updating schedule: $e');
      throw Exception('Failed to update schedule: $e');
    }
  }

  Future<List<ScheduledRelease>> getScheduledReleases(String artworkId) async {
    try {
      final snapshot = await _firestore
          .collection('scheduled_releases')
          .where('artworkId', isEqualTo: artworkId)
          .where('isScheduled', isEqualTo: true)
          .orderBy('releaseDateTime', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => ScheduledRelease.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching scheduled releases: $e');
      return [];
    }
  }

  Future<List<ScheduledRelease>> getUpcomingReleases({
    int limit = 50,
  }) async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('scheduled_releases')
          .where('releaseDateTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .where('isScheduled', isEqualTo: true)
          .orderBy('releaseDateTime', descending: false)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ScheduledRelease.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching upcoming releases: $e');
      return [];
    }
  }

  Future<List<ScheduledRelease>> getDueForRelease() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('scheduled_releases')
          .where('releaseDateTime',
              isLessThanOrEqualTo: Timestamp.fromDate(now))
          .where('isReleased', isEqualTo: false)
          .orderBy('releaseDateTime', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => ScheduledRelease.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching due releases: $e');
      return [];
    }
  }

  Future<void> markAsReleased(String releaseId) async {
    try {
      await _firestore.collection('scheduled_releases').doc(releaseId).update({
        'isReleased': true,
        'releasedAt': Timestamp.now(),
      });

      AppLogger.info('Schedule marked as released: $releaseId');
    } catch (e) {
      AppLogger.error('Error marking as released: $e');
      throw Exception('Failed to mark as released: $e');
    }
  }

  Future<void> cancelSchedule(String releaseId) async {
    try {
      await _firestore.collection('scheduled_releases').doc(releaseId).update({
        'isScheduled': false,
      });

      AppLogger.info('Schedule cancelled: $releaseId');
    } catch (e) {
      AppLogger.error('Error cancelling schedule: $e');
      throw Exception('Failed to cancel schedule: $e');
    }
  }

  Future<void> deleteSchedule(String releaseId) async {
    try {
      await _firestore.collection('scheduled_releases').doc(releaseId).delete();
      AppLogger.info('Schedule deleted: $releaseId');
    } catch (e) {
      AppLogger.error('Error deleting schedule: $e');
      throw Exception('Failed to delete schedule: $e');
    }
  }

  Future<DateTime?> getNextScheduledRelease(String artworkId) async {
    try {
      final schedules = await getScheduledReleases(artworkId);
      if (schedules.isEmpty) return null;
      return schedules.first.releaseDateTime;
    } catch (e) {
      AppLogger.error('Error getting next scheduled release: $e');
      return null;
    }
  }

  Future<void> generateScheduleForSeries({
    required String artworkId,
    required List<String> chapterIds,
    required DateTime startDate,
    required ReleaseSchedule schedule,
    int? daysBetweenReleases,
  }) async {
    try {
      DateTime currentDate = startDate;
      final increment =
          daysBetweenReleases ?? _getDefaultDayIncrement(schedule);

      for (int i = 0; i < chapterIds.length; i++) {
        await scheduleChapterRelease(
          artworkId: artworkId,
          chapterId: chapterIds[i],
          releaseDateTime: currentDate,
        );
        currentDate = currentDate.add(Duration(days: increment));
      }

      AppLogger.info('Generated schedule for ${chapterIds.length} chapters');
    } catch (e) {
      AppLogger.error('Error generating schedule: $e');
      throw Exception('Failed to generate schedule: $e');
    }
  }

  int _getDefaultDayIncrement(ReleaseSchedule schedule) {
    switch (schedule) {
      case ReleaseSchedule.weekly:
        return 7;
      case ReleaseSchedule.biWeekly:
        return 14;
      case ReleaseSchedule.monthly:
        return 30;
      case ReleaseSchedule.custom:
        return 7;
    }
  }
}
