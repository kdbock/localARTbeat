import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';
import '../models/artbeat_event.dart';

/// Service for handling event-related notifications
class EventNotificationService {
  static final EventNotificationService _instance =
      EventNotificationService._();
  factory EventNotificationService() => _instance;
  EventNotificationService._();

  final String _channelId = 'artbeat_events';
  final Logger _logger = Logger();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize notification service
  Future<void> initialize() async {
    try {
      // Initialize awesome_notifications
      await AwesomeNotifications().initialize(null, [
        NotificationChannel(
          channelKey: _channelId,
          channelName: 'Event Notifications',
          channelDescription: 'Notifications for ARTbeat events',
          defaultColor: const Color(0xFF6F42C1),
          importance: NotificationImportance.High,
          playSound: true,
          enableVibration: true,
        ),
      ]);

      // Initialize local notifications
      const initializationSettingsAndroid = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      await _localNotifications.initialize(settings: initializationSettings);

      _logger.i('Notification services initialized successfully');
    } on Exception catch (e) {
      _logger.e('Error initializing notification services: $e');
      rethrow;
    }
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    try {
      // Check if already allowed
      final isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (isAllowed) {
        _logger.i('Notification permissions already granted');
        return true;
      }

      // Request permissions for awesome_notifications
      final granted = await AwesomeNotifications()
          .requestPermissionToSendNotifications();

      // Request permissions for local_notifications on iOS
      final localPermission = await _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions();

      // Request permissions for Android
      final androidPermission = await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();

      final finalResult =
          granted && (localPermission ?? true) && (androidPermission ?? true);

      if (finalResult) {
        _logger.i('Notification permissions granted successfully');
      } else {
        _logger.w('Notification permissions denied or partially granted');
      }

      return finalResult;
    } on Exception catch (e) {
      _logger.e('Error requesting notification permissions: $e');
      return false;
    }
  }

  /// Schedule event reminder notification
  Future<void> scheduleEventReminder(ArtbeatEvent event) async {
    if (!event.reminderEnabled) return;

    // Check and request notification permissions first
    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      _logger.w(
        'Notification permissions not granted, skipping event reminder for: ${event.title}',
      );
      return;
    }

    try {
      // Schedule 1 hour before event
      final reminderTime = event.dateTime.subtract(const Duration(hours: 1));

      // Don't schedule if the reminder time is in the past
      if (reminderTime.isBefore(DateTime.now())) {
        _logger.w('Event reminder time is in the past: ${event.title}');
        return;
      }

      // Schedule with awesome_notifications for better cross-platform support
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: event.id.hashCode,
          channelKey: _channelId,
          title: 'Event Reminder: ${event.title}',
          body: 'Your event starts in 1 hour at ${event.location}',
          bigPicture: event.eventBannerUrl.isNotEmpty
              ? event.eventBannerUrl
              : null,
          notificationLayout: event.eventBannerUrl.isNotEmpty
              ? NotificationLayout.BigPicture
              : NotificationLayout.Default,
          payload: {'eventId': event.id, 'type': 'event_reminder'},
        ),
        schedule: NotificationCalendar.fromDate(date: reminderTime),
      );

      _logger.i('Event reminder scheduled for: ${event.title}');
    } on Exception catch (e) {
      _logger.e('Error scheduling event reminder: $e');
    }
  }

  /// Schedule multiple reminders for an event
  Future<void> scheduleEventReminders(ArtbeatEvent event) async {
    if (!event.reminderEnabled) return;

    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      _logger.w('Notification permissions not granted');
      return;
    }

    try {
      final now = DateTime.now();
      final eventTime = event.dateTime;

      // Schedule reminders at different intervals
      final reminderTimes = [
        eventTime.subtract(const Duration(days: 1)), // 1 day before
        eventTime.subtract(const Duration(hours: 2)), // 2 hours before
        eventTime.subtract(const Duration(minutes: 30)), // 30 minutes before
      ];

      for (final reminderTime in reminderTimes) {
        if (reminderTime.isAfter(now)) {
          await AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: '${event.id}_${reminderTime.millisecondsSinceEpoch}'.hashCode,
              channelKey: _channelId,
              title: _getReminderTitle(eventTime, reminderTime),
              body: 'Event: ${event.title}\nLocation: ${event.location}',
              bigPicture: event.eventBannerUrl,
              notificationLayout: event.eventBannerUrl.isNotEmpty
                  ? NotificationLayout.BigPicture
                  : NotificationLayout.Default,
              payload: {'eventId': event.id, 'type': 'event_reminder'},
            ),
            schedule: NotificationCalendar.fromDate(date: reminderTime),
          );
        }
      }

      _logger.i('Event reminders scheduled for: ${event.title}');
    } on Exception catch (e) {
      _logger.e('Error scheduling event reminders: $e');
      rethrow;
    }
  }

  /// Get appropriate reminder title based on time until event
  String _getReminderTitle(DateTime eventTime, DateTime reminderTime) {
    final difference = eventTime.difference(reminderTime);

    if (difference.inDays >= 1) {
      return 'Event Tomorrow: ${DateFormat('h:mm a').format(eventTime)}';
    } else if (difference.inHours >= 1) {
      return 'Event in ${difference.inHours} hours';
    } else {
      return 'Event starting soon!';
    }
  }

  /// Cancel event reminders
  Future<void> cancelEventReminders(String eventId) async {
    try {
      // Cancel awesome_notifications
      await AwesomeNotifications().cancel(eventId.hashCode);
      await AwesomeNotifications().cancel('${eventId}_day'.hashCode);
      await AwesomeNotifications().cancel('${eventId}_hour'.hashCode);

      // Cancel local notifications
      await _localNotifications.cancel(id: eventId.hashCode);

      _logger.i('Event reminders cancelled for: $eventId');
    } on Exception catch (e) {
      _logger.e('Error cancelling event reminders: $e');
    }
  }

  /// Send immediate notification for ticket purchase confirmation
  Future<void> sendTicketPurchaseConfirmation({
    required String eventTitle,
    required int quantity,
    required String ticketType,
  }) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch,
          channelKey: _channelId,
          title: 'Tickets Purchased!',
          body:
              'You\'ve successfully purchased $quantity $ticketType ticket${quantity > 1 ? 's' : ''} for $eventTitle',
          payload: {'type': 'ticket_purchase_confirmation'},
        ),
      );

      _logger.i('Ticket purchase confirmation sent');
    } on Exception catch (e) {
      _logger.e('Error sending ticket purchase confirmation: $e');
    }
  }

  /// Send refund confirmation notification
  Future<void> sendRefundConfirmation({
    required String eventTitle,
    required double refundAmount,
  }) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch,
          channelKey: _channelId,
          title: 'Refund Processed',
          body:
              'Your refund of \$${refundAmount.toStringAsFixed(2)} for $eventTitle has been processed',
          payload: {'type': 'refund_confirmation'},
        ),
      );

      _logger.i('Refund confirmation sent');
    } on Exception catch (e) {
      _logger.e('Error sending refund confirmation: $e');
    }
  }

  /// Send event update notification
  Future<void> sendEventUpdateNotification({
    required String eventTitle,
    required String updateMessage,
    required String eventId,
  }) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch,
          channelKey: _channelId,
          title: 'Event Update: $eventTitle',
          body: updateMessage,
          payload: {'eventId': eventId, 'type': 'event_update'},
        ),
      );

      _logger.i('Event update notification sent');
    } on Exception catch (e) {
      _logger.e('Error sending event update notification: $e');
    }
  }

  /// Set up listener for awesome_notifications
  void setupNotificationListener() {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onActionReceived,
      onNotificationCreatedMethod: _onNotificationCreated,
      onNotificationDisplayedMethod: _onNotificationDisplayed,
      onDismissActionReceivedMethod: _onDismissActionReceived,
    );
  }

  /// Handle notification action received
  static Future<void> _onActionReceived(ReceivedAction receivedAction) async {
    final payload = receivedAction.payload;
    if (payload != null) {
      final logger = Logger();
      logger.i('Notification action received with payload: $payload');
      final eventId = payload['eventId'];
      if (eventId != null) {
        eventNotificationNavigatorKey.currentState?.pushNamed(
          '/event/$eventId',
        );
      }
    }
  }

  static Future<void> _onNotificationCreated(
    ReceivedNotification receivedNotification,
  ) async {
    // Optional: Handle when notification is created
  }

  static Future<void> _onNotificationDisplayed(
    ReceivedNotification receivedNotification,
  ) async {
    // Optional: Handle when notification is displayed
  }

  static Future<void> _onDismissActionReceived(
    ReceivedAction receivedAction,
  ) async {
    // Optional: Handle when notification is dismissed
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    return await AwesomeNotifications().isNotificationAllowed();
  }

  /// Get scheduled notifications
  Future<List<NotificationModel>> getScheduledNotifications() async {
    return await AwesomeNotifications().listScheduledNotifications();
  }
}

/// Global navigator key for notification navigation
final GlobalKey<NavigatorState> eventNotificationNavigatorKey =
    GlobalKey<NavigatorState>();
