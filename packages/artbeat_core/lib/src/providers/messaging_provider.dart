import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../utils/logger.dart';
import '../services/messaging_status_service.dart';

/// Provider for managing messaging state across the app
/// Specifically handles unread message counts for the header
class MessagingProvider extends ChangeNotifier {
  final MessagingStatusService _messagingStatusService;
  int _unreadCount = 0;
  bool _hasUnreadMessages = false;
  StreamSubscription<int>? _unreadCountSubscription;
  StreamSubscription<User?>? _authSubscription;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _currentUserId;

  MessagingProvider(this._messagingStatusService) {
    AppLogger.info(
      'MessagingProvider: Initializing with MessagingStatusService',
    );
    // Initialize current user ID to prevent unnecessary reset on first auth state change
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _setupAuthListener();
    _initializeUnreadCount();
  }

  /// Listen to authentication state changes
  void _setupAuthListener() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      final newUserId = user?.uid;
      debugPrint(
        'MessagingProvider: Auth state changed, user: ${newUserId ?? 'null'}',
      );

      // Only reset if the user actually changed
      if (newUserId != _currentUserId) {
        _currentUserId = newUserId;

        if (user != null) {
          // User logged in or switched, initialize/reset the unread count
          reset();
        } else {
          // User logged out, clear state
          _clearState();
        }
      } else {
        AppLogger.info('MessagingProvider: Same user, skipping reset');
      }
    });
  }

  /// Clear state when user logs out
  void _clearState() {
    AppLogger.info('MessagingProvider: Clearing state for logged out user');
    _unreadCountSubscription?.cancel();
    _unreadCount = 0;
    _hasUnreadMessages = false;
    _isInitialized = false;
    _hasError = false;
    notifyListeners();
  }

  int get unreadCount => _unreadCount;
  bool get hasUnreadMessages => _hasUnreadMessages;
  bool get isInitialized => _isInitialized;
  bool get hasError => _hasError;

  void _initializeUnreadCount() {
    AppLogger.info('MessagingProvider: Setting up unread count stream');
    try {
      _unreadCountSubscription = _messagingStatusService
          .getTotalUnreadCount()
          .listen(
            (count) {
              AppLogger.info(
                'MessagingProvider: Unread count updated to $count',
              );
              _unreadCount = count;
              _hasUnreadMessages = count > 0;
              _isInitialized = true;
              _hasError = false;
              notifyListeners();
            },
            onError: (Object error) {
              AppLogger.error(
                'MessagingProvider: Error in unread count stream: $error',
              );
              _hasError = true;
              _isInitialized = true;
              notifyListeners();
            },
          );
    } catch (e) {
      AppLogger.error(
        'MessagingProvider: Error setting up unread count stream: $e',
      );
      _hasError = true;
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Manually refresh the unread count
  Future<void> refreshUnreadCount() async {
    AppLogger.info('MessagingProvider: Manually refreshing unread count');
    try {
      final count = await _messagingStatusService.getTotalUnreadCount().first;
      _unreadCount = count;
      _hasUnreadMessages = count > 0;
      _hasError = false;
      notifyListeners();
      AppLogger.info(
        'MessagingProvider: Manual refresh completed, count = $count',
      );
    } catch (e) {
      AppLogger.error('MessagingProvider: Error during manual refresh: $e');
      _hasError = true;
      notifyListeners();
    }
  }

  /// Reset the provider state
  void reset() {
    AppLogger.info('MessagingProvider: Resetting state');
    _unreadCountSubscription?.cancel();
    _unreadCount = 0;
    _hasUnreadMessages = false;
    _isInitialized = false;
    _hasError = false;
    notifyListeners();
    _initializeUnreadCount();
  }

  /// Called when a chat is marked as read to immediately update the count
  void onChatMarkedAsRead() {
    AppLogger.info('MessagingProvider: Chat marked as read, refreshing count');
    refreshUnreadCount();
  }

  @override
  void dispose() {
    AppLogger.info('MessagingProvider: Disposing');
    _unreadCountSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
