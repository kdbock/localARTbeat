# artbeat_community

Community and social package for ARTbeat. This package provides social feed flows, posts/comments, artist discovery, studios/groups, and direct commission workflows.

## Public API

Entrypoint: `lib/artbeat_community.dart`

- Screens
  - barrel export from `screens/screens.dart`
  - additional community entry screens like `ArtCommunityHub` and `CreateArtPostScreen`
- Models
  - core community models from `models/models.dart`
  - direct exports including `PostModel`, `CommentModel`, `ArtworkModel`, `StudioModel`, `DirectCommissionModel`, and `GroupType`
- Services
  - services barrel from `services/services.dart`
  - direct exports including `CommunityService`, `StorageService`, `DirectCommissionService`, `StripeService`, `ModerationService`, and `ArtCommunityService`
- Widgets
  - widgets barrel (`widgets/widgets.dart`) plus direct exports for post/feed/drawer/report/action-menu components
- Controllers
  - controllers barrel (`controllers/controllers.dart`)

## Core Behavior

- `CommunityService` handles feed posts, comments, likes, and unread feed activity.
- `ArtCommunityService` provides artist/feed stream orchestration and location-weighted artist sorting.
- `DirectCommissionService` handles direct commission lifecycle actions (request, quote, accept, milestone progress, delivery).
- `ModerationService` provides automated rule checks and moderation queue operations.

## Firestore Collections Used

Common collections used by this package include:

- `posts`
- `posts/{postId}/comments`
- `comments`
- `likes`
- `followers` / `follows`
- `users`
- `direct_commissions`
- `profile_connections`
- `profile_activities`

## Testing

From repository root:

```bash
flutter test packages/artbeat_community
flutter analyze packages/artbeat_community
```
