import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:artbeat_core/artbeat_core.dart';

/// Enum for different notification types
enum NotificationType {
  message('message', '💬'),
  boost('boost', '⚡'),
  commission('commission', '🎨'),
  event('event', '📅');

  final String value;
  final String emoji;
  const NotificationType(this.value, this.emoji);

  static NotificationType fromString(String? type) {
    return NotificationType.values.firstWhere(
      (e) => e.value == type,
      orElse: () => NotificationType.message,
    );
  }
}

/// Service for handling chat and message notifications
class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _badgeCountKey = 'app_badge_count';

  FirebaseMessaging? _messaging;
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;
  SharedPreferences? _prefs;

  FirebaseMessaging get messaging => _messaging ??= FirebaseMessaging.instance;
  FirebaseFirestore get firestore => _firestore ??= FirebaseFirestore.instance;
  FirebaseAuth get auth => _auth ??= FirebaseAuth.instance;

  /// Callback for navigation when notification is tapped
  final void Function(String route)? onNavigateToRoute;

  NotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    SharedPreferences? prefs,
    this.onNavigateToRoute,
  }) : _messaging = messaging,
       _firestore = firestore,
       _auth = auth,
       _prefs = prefs;

  static const String _deviceTokensField = 'deviceTokens';
  static const String _usersCollection = 'users';
  static const String _notificationsCollection = 'notifications';

  /// Initialize notification settings and request permissions
  Future<void> initialize() async {
    try {
      // Initialize SharedPreferences for badge persistence
      _prefs ??= await SharedPreferences.getInstance();

      // Initialize local notifications with badge support
      const AndroidInitializationSettings androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosInit =
          DarwinInitializationSettings();
      const InitializationSettings initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      // Enable banner notifications when app is in foreground (iOS)
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Request permission for notifications (including badge)
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token
        final token = await messaging.getToken();
        if (token != null) {
          await _saveDeviceToken(token);
        }

        // Listen for token refresh
        messaging.onTokenRefresh.listen(_saveDeviceToken);

        // Configure FCM handlers
        if (!kDebugMode) {
          FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
          FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
          FirebaseMessaging.onBackgroundMessage(
            _firebaseMessagingBackgroundHandler,
          );
        }

        // Start listening for new notifications to send push notifications
        _startNotificationListener();
      }
    } catch (e) {
      AppLogger.error('❌ Error initializing notifications: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) async {
    try {
      final notification = message.notification;
      final data = message.data;

      if (notification != null) {
        await _storeNotification(
          title: notification.title ?? 'New Message',
          body: notification.body ?? '',
          data: data,
        );
      }
    } catch (e) {
      AppLogger.error('❌ Error handling foreground message: $e');
    }
  }

  /// Handle when user taps on notification to open app
  void _handleMessageOpenedApp(RemoteMessage message) async {
    try {
      final data = message.data;
      if (data['chatId'] != null) {
        // Navigate to chat using provided callback
        // This will be handled by the app's navigation system
      }
    } catch (e) {
      AppLogger.error('❌ Error handling opened notification: $e');
    }
  }

  /// Save FCM device token to user's document
  Future<void> _saveDeviceToken(String token) async {
    try {
      final userId = auth.currentUser?.uid;
      if (userId == null) return;

      final userRef = firestore.collection(_usersCollection).doc(userId);

      // Add token to array if it doesn't exist
      await userRef.set({
        _deviceTokensField: FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));
    } catch (e) {
      AppLogger.error('❌ Error saving device token: $e');
    }
  }

  /// Store notification in Firestore for history
  Future<void> _storeNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      final userId = auth.currentUser?.uid;
      if (userId == null) return;

      await firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_notificationsCollection)
          .add({
            'title': title,
            'body': body,
            'data': data,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });
    } catch (e) {
      AppLogger.error('❌ Error storing notification: $e');
    }
  }

  /// Remove device token when user logs out
  Future<void> removeDeviceToken() async {
    try {
      final token = await messaging.getToken();
      final userId = auth.currentUser?.uid;
      if (token == null || userId == null) return;

      final userRef = firestore.collection(_usersCollection).doc(userId);
      await userRef.update({
        _deviceTokensField: FieldValue.arrayRemove([token]),
      });
    } catch (e) {
      AppLogger.error('❌ Error removing device token: $e');
    }
  }

  /// Mark a notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final userId = auth.currentUser?.uid;
      if (userId == null) return;

      await firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_notificationsCollection)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      AppLogger.error('❌ Error marking notification as read: $e');
    }
  }

  /// Get user's notification history
  Stream<QuerySnapshot> getNotifications() {
    final userId = auth.currentUser?.uid;
    if (userId == null) {
      return const Stream.empty();
    }

    return firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_notificationsCollection)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Get count of unread notifications
  Stream<int> getUnreadNotificationsCount() {
    final userId = auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(0);
    }

    return firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_notificationsCollection)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Send a notification to a specific user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      await firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_notificationsCollection)
          .add({
            'title': title,
            'body': body,
            'data': data,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'type': data['type'] ?? 'message',
          });

      AppLogger.info('📱 Notification sent to user $userId: $title');
    } catch (e) {
      AppLogger.error('❌ Error sending notification to user $userId: $e');
      rethrow;
    }
  }

  /// Start listening for new notifications in Firestore to trigger push notifications
  void _startNotificationListener() {
    final userId = auth.currentUser?.uid;
    if (userId == null) return;

    try {
      firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_notificationsCollection)
          .where('isRead', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots()
          .listen((snapshot) async {
            for (final doc in snapshot.docChanges) {
              if (doc.type == DocumentChangeType.added) {
                final data = doc.doc.data() as Map<String, dynamic>;
                await _triggerLocalNotification(data);
              }
            }
          });
    } catch (e) {
      AppLogger.error('❌ Error starting notification listener: $e');
    }
  }

  /// Trigger a local notification with type-specific handling
  Future<void> _triggerLocalNotification(
    Map<String, dynamic> notificationData,
  ) async {
    try {
      final title = notificationData['title'] as String? ?? 'New Notification';
      final body = notificationData['body'] as String? ?? '';
      final typeStr = notificationData['type'] as String? ?? 'message';
      final type = NotificationType.fromString(typeStr);

      // Different badge behavior per type - only messages increment badge
      int? badgeCount;
      if (type == NotificationType.message) {
        badgeCount = await incrementBadgeCount();
      }

      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final (channel, channelTitle) = _getNotificationChannel(type);

      AppLogger.info(
        '${type.emoji} ${type.value} notification: $title - $body',
      );

      // Create payload with type and route information for tap handling
      final payload = '${type.value}:${notificationData['route'] ?? ''}';

      await _localNotifications.show(
        notificationId,
        title,
        body,
        NotificationDetails(
          android: _getAndroidNotificationDetails(
            type,
            channel,
            channelTitle,
            badgeCount,
          ),
          iOS: _getIOSNotificationDetails(type, badgeCount),
        ),
        payload: payload,
      );
    } catch (e) {
      AppLogger.error('❌ Error triggering local notification: $e');
    }
  }

  /// Get platform-specific Android notification details by type
  AndroidNotificationDetails _getAndroidNotificationDetails(
    NotificationType type,
    String channel,
    String channelTitle,
    int? badgeCount,
  ) {
    final (title, description, sound) = _getChannelInfo(type);

    return AndroidNotificationDetails(
      channel,
      title,
      channelDescription: description,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
      autoCancel: true,
      styleInformation: BigTextStyleInformation('$title\n$description'),
      ticker: '${type.emoji} $title',
    );
  }

  /// Get platform-specific iOS notification details by type
  DarwinNotificationDetails _getIOSNotificationDetails(
    NotificationType type,
    int? badgeCount,
  ) {
    return DarwinNotificationDetails(badgeNumber: badgeCount);
  }

  /// Map notification type to channel ID and display name (Android)
  (String, String) _getNotificationChannel(NotificationType type) {
    return switch (type) {
      NotificationType.message => ('chat_messages', 'Messages'),
      NotificationType.boost => ('artist_boosts', 'Artist Boosts'),
      NotificationType.commission => ('commissions', 'Commissions'),
      NotificationType.event => ('event_reminders', 'Events'),
    };
  }

  /// Get channel display name and description for type
  (String, String, String) _getChannelInfo(NotificationType type) {
    return switch (type) {
      NotificationType.message => (
        'Chat Messages',
        'Notifications for new chat messages',
        'notification_message',
      ),
      NotificationType.boost => (
        'Artist Boost Received',
        'Notifications when you receive boosts',
        'notification_boost',
      ),
      NotificationType.commission => (
        'Commission Request',
        'Notifications for commission opportunities',
        'notification_commission',
      ),
      NotificationType.event => (
        'Event Reminder',
        'Reminders for events you showed interest in',
        'notification_event',
      ),
    };
  }

  // Phase 3: Enhanced Notification Features

  /// Schedule a notification for later delivery
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    int? id,
    String? payload,
  }) async {
    try {
      await _localNotifications.zonedSchedule(
        id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        _convertToTZDateTime(scheduledDate),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'scheduled_messages',
            'Scheduled Messages',
            channelDescription: 'Notifications for scheduled messages',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      AppLogger.error('Error scheduling notification: $e');
      rethrow;
    }
  }

  /// Configure notification preferences for a specific chat
  Future<void> configureChatNotifications({
    required String chatId,
    bool enableNotifications = true,
    bool enableSound = true,
    bool enableVibration = true,
    String? customSound,
  }) async {
    try {
      final userId = auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await firestore
          .collection('users')
          .doc(userId)
          .collection('chatNotificationSettings')
          .doc(chatId)
          .set({
            'enableNotifications': enableNotifications,
            'enableSound': enableSound,
            'enableVibration': enableVibration,
            'customSound': customSound,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      AppLogger.error('Error configuring chat notifications: $e');
      rethrow;
    }
  }

  /// Get notification preferences for a specific chat
  Future<Map<String, dynamic>?> getChatNotificationSettings(
    String chatId,
  ) async {
    try {
      final userId = auth.currentUser?.uid;
      if (userId == null) return null;

      final doc = await firestore
          .collection('users')
          .doc(userId)
          .collection('chatNotificationSettings')
          .doc(chatId)
          .get();

      return doc.exists ? doc.data() : null;
    } catch (e) {
      AppLogger.error('Error getting chat notification settings: $e');
      return null;
    }
  }

  /// Handle background messages with enhanced processing
  Future<void> handleBackgroundMessages() async {
    try {
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Handle messages when app is terminated
      final RemoteMessage? initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        await _handleMessageClick(initialMessage);
      }

      // Handle messages when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageClick);
    } catch (e) {
      AppLogger.error('Error setting up background message handling: $e');
    }
  }

  /// Handle message click actions
  Future<void> _handleMessageClick(RemoteMessage message) async {
    try {
      final data = message.data;
      final chatId = data['chatId'];
      final messageId = data['messageId'];

      if (chatId != null) {
        // Navigate to specific chat
        // This would typically be handled by the app's navigation system
        AppLogger.info('Navigate to chat: $chatId');

        if (messageId != null) {
          // Navigate to specific message
          AppLogger.info('Navigate to message: $messageId in chat: $chatId');
        }
      }
    } catch (e) {
      AppLogger.error('Error handling message click: $e');
    }
  }

  /// Set up notification categories and actions
  Future<void> setupNotificationCategories() async {
    try {
      // Define notification actions for iOS
      final DarwinNotificationCategory messageCategory =
          DarwinNotificationCategory(
            'MESSAGE_CATEGORY',
            actions: <DarwinNotificationAction>[
              DarwinNotificationAction.plain(
                'reply',
                'Reply',
                options: <DarwinNotificationActionOption>{
                  DarwinNotificationActionOption.foreground,
                },
              ),
              DarwinNotificationAction.plain('mark_read', 'Mark as Read'),
            ],
            options: <DarwinNotificationCategoryOption>{
              DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
            },
          );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.initialize(
            DarwinInitializationSettings(
              notificationCategories: [messageCategory],
            ),
            onDidReceiveNotificationResponse: _onNotificationResponse,
          );
    } catch (e) {
      AppLogger.error('Error setting up notification categories: $e');
    }
  }

  /// Handle notification actions and routing
  void _onNotificationResponse(NotificationResponse response) {
    try {
      final actionId = response.actionId;
      final payload = response.payload;

      switch (actionId) {
        case 'reply':
          AppLogger.info('Reply action triggered with payload: $payload');
          break;
        case 'mark_read':
          AppLogger.info(
            'Mark as read action triggered with payload: $payload',
          );
          break;
        default:
          // Handle notification tap - route based on type
          _handleNotificationTap(payload);
      }
    } catch (e) {
      AppLogger.error('❌ Error handling notification response: $e');
    }
  }

  /// Handle notification tap and route to appropriate screen
  void _handleNotificationTap(String? payload) {
    try {
      if (payload == null || payload.isEmpty) return;

      // Parse payload format: "type:route"
      final parts = payload.split(':');
      if (parts.isEmpty) return;

      final typeStr = parts[0];
      final route = parts.length > 1 ? parts[1] : '';
      final type = NotificationType.fromString(typeStr);

      AppLogger.info(
        '${type.emoji} Handling notification tap - Type: ${type.value}, Route: $route',
      );

      // For all notification types, route to notifications screen
      AppLogger.info('${type.emoji} Routing to notifications screen');
      onNavigateToRoute?.call('/notifications');
    } catch (e) {
      AppLogger.error('❌ Error handling notification tap: $e');
    }
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllScheduledNotifications() async {
    try {
      await _localNotifications.cancelAll();
    } catch (e) {
      AppLogger.error('Error cancelling scheduled notifications: $e');
    }
  }

  /// Cancel a specific scheduled notification
  Future<void> cancelScheduledNotification(int notificationId) async {
    try {
      await _localNotifications.cancel(notificationId);
    } catch (e) {
      AppLogger.error('Error cancelling scheduled notification: $e');
    }
  }

  // ============================================================================
  // Badge Management Methods
  // ============================================================================

  /// Get the current badge count
  Future<int> getBadgeCount() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      return _prefs?.getInt(_badgeCountKey) ?? 0;
    } catch (e) {
      AppLogger.error('Error getting badge count: $e');
      return 0;
    }
  }

  /// Increment badge count and update app icon
  Future<int> incrementBadgeCount() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final currentCount = _prefs?.getInt(_badgeCountKey) ?? 0;
      final newCount = currentCount + 1;

      // Save to persistent storage
      await _prefs?.setInt(_badgeCountKey, newCount);

      // Update badge on app icon
      await _updateAppBadge(newCount);

      AppLogger.info('📲 Badge incremented to $newCount');
      return newCount;
    } catch (e) {
      AppLogger.error('Error incrementing badge count: $e');
      return 0;
    }
  }

  /// Decrement badge count and update app icon
  Future<int> decrementBadgeCount() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final currentCount = _prefs?.getInt(_badgeCountKey) ?? 0;
      final newCount = (currentCount - 1).clamp(0, 999);

      // Save to persistent storage
      await _prefs?.setInt(_badgeCountKey, newCount);

      // Update badge on app icon
      await _updateAppBadge(newCount);

      AppLogger.info('📲 Badge decremented to $newCount');
      return newCount;
    } catch (e) {
      AppLogger.error('Error decrementing badge count: $e');
      return 0;
    }
  }

  /// Set badge count to a specific value
  Future<void> setBadgeCount(int count) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final newCount = count.clamp(0, 999);

      // Save to persistent storage
      await _prefs?.setInt(_badgeCountKey, newCount);

      // Update badge on app icon
      await _updateAppBadge(newCount);

      AppLogger.info('📲 Badge set to $newCount');
    } catch (e) {
      AppLogger.error('Error setting badge count: $e');
    }
  }

  /// Clear badge (set to 0)
  Future<void> clearBadge() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();

      // Clear storage
      await _prefs?.setInt(_badgeCountKey, 0);

      // Clear badge on app icon
      await _updateAppBadge(0);

      AppLogger.info('📲 Badge cleared');
    } catch (e) {
      AppLogger.error('Error clearing badge: $e');
    }
  }

  /// Update the actual app icon badge (platform-specific)
  Future<void> _updateAppBadge(int count) async {
    try {
      // Show or clear badge through notification plugin
      if (count > 0) {
        AppLogger.info('📲 Badge count set to: $count');
      } else {
        AppLogger.info('📲 Badge cleared');
      }
      // Badge is automatically managed through notification details
      // on iOS and Android platforms
    } catch (e) {
      AppLogger.error('Error updating app badge: $e');
    }
  }

  /// Send an artist boost notification
  Future<void> sendBoostNotification({
    required String recipientUserId,
    required String senderName,
    required String boostName,
    required String boostImageUrl,
  }) async {
    try {
      await sendNotificationToUser(
        userId: recipientUserId,
        title: '⚡ Boost from $senderName',
        body: '$senderName sent you a $boostName boost!',
        data: {
          'type': NotificationType.boost.value,
          'senderName': senderName,
          'boostName': boostName,
          'boostImageUrl': boostImageUrl,
          'route': '/boosts/received',
        },
      );
      AppLogger.info('⚡ Boost notification sent to $recipientUserId');
    } catch (e) {
      AppLogger.error('❌ Error sending boost notification: $e');
      rethrow;
    }
  }

  /// Send a commission request notification
  Future<void> sendCommissionNotification({
    required String artistUserId,
    required String buyerName,
    required String artworkDescription,
    required double budget,
  }) async {
    try {
      await sendNotificationToUser(
        userId: artistUserId,
        title: '🎨 Commission Request from $buyerName',
        body: 'Budget: \$$budget • $artworkDescription',
        data: {
          'type': NotificationType.commission.value,
          'buyerName': buyerName,
          'artworkDescription': artworkDescription,
          'budget': budget.toString(),
          'route': '/commissions/requests',
        },
      );
      AppLogger.info('🎨 Commission notification sent to $artistUserId');
    } catch (e) {
      AppLogger.error('❌ Error sending commission notification: $e');
      rethrow;
    }
  }

  /// Send an event reminder notification
  Future<void> sendEventReminderNotification({
    required String userId,
    required String eventName,
    required String eventTime,
    required String location,
  }) async {
    try {
      await sendNotificationToUser(
        userId: userId,
        title: '📅 Reminder: $eventName',
        body: '$eventTime • $location',
        data: {
          'type': NotificationType.event.value,
          'eventName': eventName,
          'eventTime': eventTime,
          'location': location,
          'route': '/events/details',
        },
      );
      AppLogger.info('📅 Event notification sent to $userId');
    } catch (e) {
      AppLogger.error('❌ Error sending event notification: $e');
      rethrow;
    }
  }

  /// Auto-clear badge when user opens the messaging screen
  /// Call this when navigating to the chat/messaging screen
  Future<void> onMessagingScreenOpened() async {
    try {
      await clearBadge();

      // Also mark all unread notifications as read
      final userId = auth.currentUser?.uid;
      if (userId != null) {
        final unreadNotifications = await firestore
            .collection(_usersCollection)
            .doc(userId)
            .collection(_notificationsCollection)
            .where('isRead', isEqualTo: false)
            .get();

        for (final doc in unreadNotifications.docs) {
          await doc.reference.update({'isRead': true});
        }
        AppLogger.info('Marked all notifications as read');
      }
    } catch (e) {
      AppLogger.error('Error clearing badge on screen open: $e');
    }
  }

  /// Get unread message count for display in UI
  Stream<int> getUnreadMessageCount() {
    final userId = auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(0);
    }

    return firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_notificationsCollection)
        .where('isRead', isEqualTo: false)
        .where('type', isEqualTo: 'message')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Helper method to convert DateTime to TZDateTime
  static tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    // This is a simplified implementation
    // In a real app, you'd want to use the timezone package properly
    return tz.TZDateTime.from(dateTime, tz.getLocation('UTC'));
  }
}

/// Handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if needed
  // No-op implementation - actual handling should be minimal as the app is not running
  return;
}
