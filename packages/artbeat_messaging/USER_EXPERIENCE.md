# artbeat_messaging User Experience

This document reflects the UX implemented by `packages/artbeat_messaging` today.

## Primary Journeys

1. Conversation discovery and entry
- `ChatListScreen` is the primary inbox surface.
- Users open direct chats or groups into `ChatScreen` / `GroupChatScreen`.

2. Sending and consuming messages
- Message compose and attachments are handled by `ChatInput`, `MessageInputField`, and `AttachmentButton`.
- Message rendering uses `MessageBubble` / `ChatBubble`.
- Typing feedback is shown via `TypingIndicator`.

3. Group chat setup and management
- Group creation starts in `GroupCreationScreen` with user selection from `ContactSelectionScreen`.
- Group detail and settings flows use `ChatInfoScreen` and `ChatSettingsScreen`.

4. Reactions, thread replies, and message detail
- Reaction UX is handled by `MessageReactionsWidget`, `QuickReactionPicker`, and `MessageInteractions`.
- Thread replies are surfaced through `ThreadReplyWidget` and `MessageThreadViewScreen`.
- Starred content is available in `StarredMessagesScreen`.

5. Media and profile surfaces
- Media viewing runs through `MediaViewerScreen`.
- Profile and moderation-oriented access points include `UserProfileScreen` and `BlockedUsersScreen`.

## Experience Contracts

- Real-time updates depend on Firestore listeners (chat list, messages, reactions).
- Presence information is managed through `PresenceService`.
- Notification behavior depends on `NotificationService` plus user preferences (`NotificationPreferencesModel`).
- Navigation helpers (`MessagingNavigation`, `MessagingNavigationHelper`) centralize route entry points.

## UX Notes

- Direct and group chat have separate UI entry points but shared core message components.
- Reaction and thread tools are additive interaction layers on top of base chat flow.
- Settings and notification preference screens provide per-chat and global controls where implemented.
