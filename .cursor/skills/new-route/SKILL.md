---
name: new-route
description: Wires a new Flutter screen into the AskmeHUMG GoRouter typed-route system. Use when connecting a newly implemented screen to app navigation, replacing a placeholder route, adding a sub-route, or when the user says "add route", "connect screen to router", "replace placeholder", "wire up navigation".
---

# New Route (AskmeHUMG)

All routes live in one file: `lib/config/app_routes.dart`

## Replacing an existing placeholder

The existing routes already declared — just swap `_PlaceholderScreen` for the real widget:

```dart
// BEFORE
@TypedGoRoute<FeedRoute>(path: '/')
@immutable
class FeedRoute extends GoRouteData with $FeedRoute {
  const FeedRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const _PlaceholderScreen(title: 'Feed');  // ← remove this
}

// AFTER
@TypedGoRoute<FeedRoute>(path: '/')
@immutable
class FeedRoute extends GoRouteData with $FeedRoute {
  const FeedRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const FeedScreen();  // ← real screen
}
```

Add the import at the top of the file.

## Existing routes (do NOT add duplicates)

| Route class | Path | Screen status |
|---|---|---|
| `SplashRoute` | `/splash` | ✅ SplashScreen |
| `LoginRoute` | `/login` | ✅ LoginScreen |
| `FeedRoute` | `/` | ⏳ Placeholder |
| `InboxRoute` | `/inbox` | ⏳ Placeholder |
| `AnswerComposeRoute` | `/inbox/answer/:questionId` | ⏳ Placeholder |
| `ProfileRoute` | `/u/:userId` | ⏳ Placeholder |
| `AdminRoute` | `/admin` | ⏳ Placeholder |

## Adding a brand-new route

Only do this for routes NOT already in the file above.

```dart
// 1. Add @TypedGoRoute annotation + route class
@TypedGoRoute<CommentsRoute>(path: '/comments/:answerId')
@immutable
class CommentsRoute extends GoRouteData with $CommentsRoute {
  const CommentsRoute({required this.answerId});
  final String answerId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      CommentsScreen(answerId: answerId);
}
```

## Sub-route (nested)

```dart
// Parent declares child in routes: list
@TypedGoRoute<InboxRoute>(
  path: '/inbox',
  routes: [
    TypedGoRoute<AnswerComposeRoute>(path: 'answer/:questionId'),
  ],
)
```

## After editing app_routes.dart — MUST run

```bash
dart run build_runner build --delete-conflicting-outputs
```

This regenerates `app_routes.g.dart`. Never edit `.g.dart` files manually.

## Protected routes

To protect a new route, add its prefix to the constant at the bottom:

```dart
const protectedLocationPrefixes = ['/inbox', '/admin', '/your-new-route'];
```

## Navigating to a typed route

```dart
// Push (adds to stack)
ProfileRoute(userId: uid).push(context);

// Go (replaces stack)
const FeedRoute().go(context);

// Go back
context.pop();
```

Never use string paths (`context.go('/inbox')`) — always use typed route classes.
