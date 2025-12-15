# Delayed Login Implementation

## Overview

The ARTbeat app now supports **delayed login**, allowing users to explore and browse the app without creating an account. Users are only prompted to sign in or create an account when they try to access features that require authentication.

## What Changed

### 1. **Splash Screen**

- Previously: Automatically redirected unauthenticated users to the login screen
- Now: Always routes to the dashboard, regardless of authentication status

### 2. **Dashboard**

- Shows a friendly welcome banner for anonymous users encouraging them to sign up
- All browsing features remain accessible
- Protected features trigger authentication prompts when accessed

### 3. **Authentication Guard**

- Previously: Blocked access to protected routes
- Now: Shows an interactive dialog prompting users to sign in

### 4. **New Components**

#### `LoginPromptDialog`

A beautiful, user-friendly dialog that appears when users try to access authenticated features:

- Explains why authentication is needed
- Offers "Continue Browsing" option
- Provides "Sign In" and "Sign Up" buttons
- Uses the app's gradient design language

#### `AuthHelper`

Utility class for easily managing authentication requirements in any widget:

```dart
// Check if user is authenticated and show prompt if not
final isAuthenticated = await AuthHelper.requireAuth(
  context,
  featureName: 'favorites', // Optional: customize the message
);

// Execute an action only if authenticated
await AuthHelper.executeIfAuthenticated(
  context,
  action: () async {
    // Your protected code here
    await saveFavorite();
  },
  featureName: 'save favorites',
);
```

## Features That Require Authentication

Add authentication checks to these types of features:

1. **User Profile Actions**

   - Viewing/editing profile
   - Following/unfollowing users
   - Saving favorites

2. **Content Creation**

   - Uploading artwork
   - Creating posts
   - Commenting

3. **Social Features**

   - Direct messaging
   - Reactions/likes
   - Sharing to profile

4. **Purchases**

   - Buying art
   - Subscriptions
   - In-app purchases

5. **Personalization**
   - Saving preferences
   - Custom collections
   - Art walk participation

## Implementation Examples

### Example 1: Simple Button Action

```dart
ElevatedButton(
  onPressed: () async {
    // Require authentication before proceeding
    final canProceed = await AuthHelper.requireAuth(
      context,
      featureName: 'save favorites',
    );

    if (canProceed) {
      // User is authenticated, proceed
      await saveFavorite(artworkId);
    }
    // If not authenticated, dialog was shown and user dismissed it
  },
  child: const Text('Save to Favorites'),
)
```

### Example 2: Navigation to Protected Screen

```dart
// In your onTap handler
onTap: () async {
  if (!AuthHelper.isAuthenticated) {
    await AuthHelper.showLoginPrompt(context);
    return;
  }

  // User is authenticated, navigate
  Navigator.pushNamed(context, '/protected-screen');
}
```

### Example 3: Using AuthGuard for Routes

```dart
// In app_router.dart
case AppRoutes.profile:
  return AuthGuard.guardRoute(
    settings: settings,
    featureName: 'your profile',
    authenticatedBuilder: () => const ProfileScreen(),
    unauthenticatedBuilder: null, // Will show login prompt
  );
```

### Example 4: Conditional UI

```dart
// Show different UI based on auth status
Widget build(BuildContext context) {
  if (AuthHelper.isAuthenticated) {
    return PersonalizedDashboard();
  } else {
    return Column(
      children: [
        // Show browse-only content
        BrowseContent(),

        // Encourage sign-up
        SignUpPromptBanner(),
      ],
    );
  }
}
```

## Benefits

1. **Lower Barrier to Entry**: Users can explore the app before committing to creating an account
2. **Better Conversion**: Users see value before being asked to sign up
3. **Improved UX**: No forced login screens blocking app exploration
4. **Clear Communication**: Users understand exactly why authentication is needed
5. **Flexible Access**: Browse freely, authenticate when needed

## Translation Keys

The following translation keys are used for the delayed login system:

```json
{
  "auth_required_title": "Authentication Required",
  "auth_required_message": "Please sign in to access this feature",
  "auth_required_feature_message": "To use {feature}, please create an account or sign in.",
  "auth_prompt_browse": "Continue Browsing",
  "auth_prompt_login": "Sign In",
  "auth_prompt_no_account": "Don't have an account?",
  "dashboard_anonymous_button": "Sign In",
  "dashboard_anonymous_message": "Create a free account to save favorites, track your art journey, and more!",
  "dashboard_anonymous_title": "Welcome to ARTbeat!"
}
```

## Best Practices

1. **Be Specific**: When showing the login prompt, specify what feature requires authentication

   ```dart
   AuthHelper.requireAuth(context, featureName: 'like artwork')
   ```

2. **Don't Over-Prompt**: Only require authentication when absolutely necessary

3. **Provide Value First**: Let users explore and see value before asking them to sign up

4. **Clear Messaging**: Always explain why authentication is needed

5. **Easy Access**: Make sign-in and sign-up buttons easily accessible throughout the app

## Testing

To test the delayed login flow:

1. **Start Fresh**: Clear app data or use an incognito session
2. **Browse Freely**: Navigate through public content without logging in
3. **Trigger Auth**: Try to access protected features (like favorites, messaging)
4. **Verify Prompt**: Ensure the login prompt appears with appropriate messaging
5. **Test Both Paths**:
   - Choose "Continue Browsing" and verify you can keep browsing
   - Choose "Sign In" and verify navigation to auth screens

## Migration Notes

For existing authenticated users:

- No changes - the app works exactly as before
- They'll remain logged in across app launches

For new users:

- Can explore immediately without signing up
- Prompted to authenticate only when needed
- Seamless conversion flow when they're ready

## Future Enhancements

Potential improvements for the future:

1. **Smart Prompts**: Track which features users try to access most and optimize prompts
2. **Progress Tracking**: Show users what they'll unlock by signing up
3. **Social Proof**: Display community stats in anonymous banner
4. **Onboarding Tour**: Guide anonymous users through key features
5. **A/B Testing**: Test different prompt messages and timings
