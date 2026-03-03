# artbeat_messaging

Messaging package for ARTbeat. This package provides chat models, messaging services, navigation helpers, and screens/widgets for direct and group conversations.

## Public API

Entrypoint: `lib/artbeat_messaging.dart`

- Controllers
  - `ChatController`
  - `MessageController`
  - `TypingIndicatorController`
- Models
  - `ChatModel`
  - `MessageModel`
  - `Message`
  - `UserModel`
  - `MessageThreadModel`
  - `ChatSettingsModel`
  - `NotificationPreferencesModel`
  - `MessageReactionModel`
  - `SearchResultModel`
- Services
  - `ChatService`
  - `AdminMessagingService`
  - `PresenceService`
  - `MessageReactionService`
  - `NotificationService`
- Screens
  - `ChatListScreen`
  - `ChatScreen`
  - `ContactSelectionScreen`
  - `GroupChatScreen`
  - `GroupCreationScreen`
  - `UserProfileScreen`
  - `MediaViewerScreen`
  - `ChatSettingsScreen`
  - `ChatInfoScreen`
  - `BlockedUsersScreen`
  - `StarredMessagesScreen`
  - `MessageThreadViewScreen`
  - `EnhancedMessagingDashboardScreen`
  - `ArtisticMessagingScreen`
- Widgets
  - `MessageBubble`
  - `ChatInput`
  - `ChatBubble`
  - `ChatListTile`
  - `MessageInputField`
  - `MessagingHeader`
  - `AttachmentButton`
  - `TypingIndicator`
  - `MessageReactionsWidget`
  - `QuickReactionPicker`
  - `MessageInteractions`
  - `ThreadReplyWidget`

## Core Behavior

- Conversation list and message streams are Firestore-backed (`ChatService`).
- Presence/online state tracking is handled by `PresenceService`.
- Reactions are managed under per-message `reactions` subcollections (`MessageReactionService`).
- Messaging notification setup and delivery is handled by `NotificationService`.
- Utility layers include date formatting and model conversion (`DateFormatter`, `MessageConverter`).

## Firebase Collections Used

Key collections referenced by package services:

- `chats`
- `chats/{chatId}/messages`
- `chats/{chatId}/messages/{messageId}/reactions`
- `users`
- `artistProfiles`

## Dependencies

Primary dependencies currently used in this package:

- Firebase (`firebase_auth`, `cloud_firestore`, `firebase_messaging`, `firebase_storage`)
- Local notifications (`flutter_local_notifications`)
- State and app utilities (`provider`, `shared_preferences`, `intl`)
- ARTbeat shared package (`artbeat_core`)

## Testing

From repository root:

```bash
flutter test packages/artbeat_messaging
flutter analyze packages/artbeat_messaging
```
