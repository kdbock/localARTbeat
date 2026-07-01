import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
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

  Future<void> _initializeLocalNotifications(
    InitializationSettings settings,
  ) async {
    final dynamic plugin = _localNotifications;
    try {
      await plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );
    } on Object {
      await plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );
    }
  }

  Future<void> _cancelLocalNotification(int id) async {
    final dynamic plugin = _localNotifications;
    try {
      await plugin.cancel(id: id);
    } on Object {
      await plugin.cancel(id);
    }
  }

  /// Initialize notification service
  Future<void> initialize() async {
    try {
      tz_data.initializeTimeZones();

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
      await _initializeLocalNotifications(initializationSettings);

      _logger.i('Notification services initialized successfully');
    } on Exception catch (e) {
      _logger.e('Error initializing notification services: $e');
      rethrow;
    }
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    try {
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
          (localPermission ?? true) && (androidPermission ?? true);

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

      await _scheduleLocalNotification(
        id: event.id.hashCode,
        title: 'Event Reminder: ${event.title}',
        body: 'Your event starts in 1 hour at ${event.location}',
        scheduledDate: reminderTime,
        payload: 'event_reminder:${event.id}',
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
          await _scheduleLocalNotification(
            id: '${event.id}_${reminderTime.millisecondsSinceEpoch}'.hashCode,
            title: _getReminderTitle(eventTime, reminderTime),
            body: 'Event: ${event.title}\nLocation: ${event.location}',
            scheduledDate: reminderTime,
            payload: 'event_reminder:${event.id}',
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
      await _cancelLocalNotification(eventId.hashCode);

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
      await _showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Tickets Purchased!',
        body:
            'You\'ve successfully purchased $quantity $ticketType ticket${quantity > 1 ? 's' : ''} for $eventTitle',
        payload: 'ticket_purchase_confirmation',
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
      await _showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Refund Processed',
        body:
            'Your refund of \$${refundAmount.toStringAsFixed(2)} for $eventTitle has been processed',
        payload: 'refund_confirmation',
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
      await _showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Event Update: $eventTitle',
        body: updateMessage,
        payload: 'event_update:$eventId',
      );

      _logger.i('Event update notification sent');
    } on Exception catch (e) {
      _logger.e('Error sending event update notification: $e');
    }
  }

  /// Listener setup is handled during initialize for flutter_local_notifications.
  void setupNotificationListener() {}

  static void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    final logger = Logger();
    logger.i('Notification response received with payload: $payload');

    final parts = payload.split(':');
    if (parts.length >= 2 && parts.first.startsWith('event')) {
      eventNotificationNavigatorKey.currentState?.pushNamed(
        '/event/${parts[1]}',
      );
    }
  }

  NotificationDetails _notificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Event Notifications',
        channelDescription: 'Notifications for Local ARTbeat events',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) {
    return _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _notificationDetails(),
      payload: payload,
    );
  }

  Future<void> _scheduleLocalNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) {
    return _localNotifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final iosPermission = await _localNotifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.checkPermissions();
    final androidPermission = await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.areNotificationsEnabled();

    return (iosPermission?.isEnabled ?? true) && (androidPermission ?? true);
  }

  /// Get scheduled notifications
  Future<List<PendingNotificationRequest>> getScheduledNotifications() async {
    return _localNotifications.pendingNotificationRequests();
  }
}

/// Global navigator key for notification navigation
final GlobalKey<NavigatorState> eventNotificationNavigatorKey =
    GlobalKey<NavigatorState>();
