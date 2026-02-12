import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chapter_partner.dart';
import '../models/chapter_quest.dart';
import '../utils/logger.dart';

class ChapterPartnerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch all active chapter partners
  Future<List<ChapterPartner>> getActiveChapters() async {
    try {
      final snapshot = await _firestore
          .collection('chapters')
          .where('active_status', isEqualTo: true)
          .get();
      
      return snapshot.docs
          .map((doc) => ChapterPartner.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching active chapters: $e');
      return [];
    }
  }

  /// Get chapter partner by slug
  Future<ChapterPartner?> getChapterBySlug(String slug) async {
    try {
      final snapshot = await _firestore
          .collection('chapters')
          .where('slug', isEqualTo: slug)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return null;
      return ChapterPartner.fromFirestore(snapshot.docs.first);
    } catch (e) {
      AppLogger.error('Error fetching chapter by slug: $e');
      return null;
    }
  }

  /// Get chapter partner by ID
  Future<ChapterPartner?> getChapterById(String id) async {
    try {
      final doc = await _firestore.collection('chapters').doc(id).get();
      if (!doc.exists) return null;
      return ChapterPartner.fromFirestore(doc);
    } catch (e) {
      AppLogger.error('Error fetching chapter by ID: $e');
      return null;
    }
  }

  /// Fetch quests for a specific chapter
  Future<List<ChapterQuest>> getQuestsForChapter(String chapterId) async {
    try {
      final snapshot = await _firestore
          .collection('quests')
          .where('chapter_id', isEqualTo: chapterId)
          .get();
      
      return snapshot.docs
          .map((doc) => ChapterQuest.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching quests for chapter $chapterId: $e');
      return [];
    }
  }

  /// Fetch regional quests (no chapter_id)
  Future<List<ChapterQuest>> getRegionalQuests() async {
    try {
      final snapshot = await _firestore
          .collection('quests')
          .where('chapter_id', isNull: true)
          .get();
      
      return snapshot.docs
          .map((doc) => ChapterQuest.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching regional quests: $e');
      return [];
    }
  }

  /// Track chapter view analytics
  Future<void> trackChapterView(String chapterId, String userId) async {
    try {
      final now = DateTime.now();
      final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      
      final docRef = _firestore
          .collection('chapter_analytics')
          .doc(chapterId)
          .collection('monthly_stats')
          .doc(monthKey);
      
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) {
          transaction.set(docRef, {
            'view_count': 1,
            'unique_users': [userId],
            'last_updated': FieldValue.serverTimestamp(),
          });
        } else {
          final data = doc.data()!;
          final uniqueUsers = List<String>.from(data['unique_users'] as List? ?? []);
          
          final updateData = <String, dynamic>{
            'view_count': FieldValue.increment(1),
            'last_updated': FieldValue.serverTimestamp(),
          };
          
          if (!uniqueUsers.contains(userId)) {
            uniqueUsers.add(userId);
            updateData['unique_users'] = uniqueUsers;
          }
          
          transaction.update(docRef, updateData);
        }
      });
    } catch (e) {
      AppLogger.error('Error tracking chapter view: $e');
    }
  }
}
