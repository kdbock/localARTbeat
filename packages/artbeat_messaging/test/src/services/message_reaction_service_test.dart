import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:artbeat_messaging/src/models/message_reaction_model.dart';
import 'package:artbeat_messaging/src/services/message_reaction_service.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _FakeUser extends Fake implements User {
  _FakeUser(this._uid, {this.name, this.avatar});

  final String _uid;
  final String? name;
  final String? avatar;

  @override
  String get uid => _uid;

  @override
  String? get displayName => name;

  @override
  String? get photoURL => avatar;
}

void main() {
  group('MessageReactionService', () {
    late FakeFirebaseFirestore firestore;
    late _MockFirebaseAuth auth;
    late MessageReactionService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      auth = _MockFirebaseAuth();
      service = MessageReactionService(firestore: firestore, auth: auth);
    });

    test('currentUserId throws when user is not authenticated', () {
      when(auth.currentUser).thenReturn(null);

      expect(() => service.currentUserId, throwsA(isA<Exception>()));
    });

    test('addReaction persists reaction and updates message reactionCount', () async {
      final user = _FakeUser(
        'u1',
        name: 'User One',
        avatar: 'https://example.com/u1.png',
      );
      when(auth.currentUser).thenReturn(user);

      await firestore.collection('chats').doc('c1').collection('messages').doc('m1').set({
        'text': 'hello',
        'senderId': 'u2',
      });

      await service.addReaction(
        messageId: 'm1',
        chatId: 'c1',
        reactionType: ReactionTypes.like,
      );

      final reactionDoc = await firestore
          .collection('chats')
          .doc('c1')
          .collection('messages')
          .doc('m1')
          .collection('reactions')
          .doc('m1_u1_like')
          .get();
      final messageDoc = await firestore
          .collection('chats')
          .doc('c1')
          .collection('messages')
          .doc('m1')
          .get();

      expect(reactionDoc.exists, isTrue);
      expect(reactionDoc.data()!['emoji'], '👍');
      expect(messageDoc.data()!['reactionCount'], 1);
    });

    test('toggleReaction removes existing reaction on second toggle', () async {
      final user = _FakeUser('u1', name: 'User One');
      when(auth.currentUser).thenReturn(user);

      await firestore.collection('chats').doc('c1').collection('messages').doc('m2').set({
        'text': 'hi',
        'senderId': 'u3',
      });

      await service.toggleReaction(
        messageId: 'm2',
        chatId: 'c1',
        reactionType: ReactionTypes.sad,
      );
      await service.toggleReaction(
        messageId: 'm2',
        chatId: 'c1',
        reactionType: ReactionTypes.sad,
      );

      final reactionDoc = await firestore
          .collection('chats')
          .doc('c1')
          .collection('messages')
          .doc('m2')
          .collection('reactions')
          .doc('m2_u1_sad')
          .get();
      final messageDoc = await firestore
          .collection('chats')
          .doc('c1')
          .collection('messages')
          .doc('m2')
          .get();

      expect(reactionDoc.exists, isFalse);
      expect(messageDoc.data()!['reactionCount'], 0);
    });
  });
}
