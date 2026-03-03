import 'package:flutter_test/flutter_test.dart';

import 'package:artbeat_messaging/src/models/notification_preferences_model.dart';

void main() {
  group('NotificationPreferencesModel', () {
    test('createDefault sets enabled defaults and user identity', () {
      final prefs = NotificationPreferencesModel.createDefault(userId: 'u1');

      expect(prefs.id, 'u1');
      expect(prefs.userId, 'u1');
      expect(prefs.globalNotificationsEnabled, isTrue);
      expect(prefs.messageNotificationsEnabled, isTrue);
    });

    test('muteChat and unmuteChat update list as expected', () {
      final prefs = NotificationPreferencesModel.createDefault(
        userId: 'u1',
      ).muteChat('chat-a');

      expect(prefs.mutedChats, contains('chat-a'));

      final unmuted = prefs.unmuteChat('chat-a');
      expect(unmuted.mutedChats, isNot(contains('chat-a')));
    });

    test('shouldNotifyForChat respects global and muted chat flags', () {
      final prefs = NotificationPreferencesModel.createDefault(userId: 'u1')
          .copyWith(
            globalNotificationsEnabled: true,
            mutedChats: const ['chat-muted'],
          );

      expect(prefs.shouldNotifyForChat('chat-muted'), isFalse);
      expect(prefs.shouldNotifyForChat('chat-open'), isTrue);
    });

    test('chat notification sound falls back to default', () {
      final prefs = NotificationPreferencesModel.createDefault(
        userId: 'u1',
      ).copyWith(defaultNotificationSound: 'ding');
      final updated = prefs.setChatNotificationSound('chat-a', 'pop');

      expect(updated.getNotificationSoundForChat('chat-a'), 'pop');
      expect(updated.getNotificationSoundForChat('chat-b'), 'ding');
    });
  });
}
