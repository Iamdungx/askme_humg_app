# AskmeHUMG – Architecture Guide

> **Pattern:** Feature-First Clean Architecture
> **State Management:** Riverpod (`riverpod_annotation` codegen)
> **Routing:** GoRouter (Riverpod provider, `keepAlive: true`)
> **Updated:** 27-02-2026

---

## Guiding Principles

1. **Feature-first, not layer-first.** Each feature is a self-contained vertical slice under `lib/app/modules/<feature>/`.
2. **Dependency rule.** `domain` knows nothing about Flutter or Firebase. `data` depends on `domain`. `presentation` depends on `domain` via providers — never on `data` directly.
3. **One direction.** `presentation → domain ← data`.
4. **Riverpod as glue.** Providers wire `data` implementations into `domain` interfaces. Screens only interact with providers.
5. **Flat layers.** Each layer (`domain/`, `data/`, `presentation/`) contains files directly — no sub-folders.

---

## Actual Folder Tree (as implemented)

```
lib/
├── main.dart                            # ProviderScope + MaterialApp.router + error handlers
│
├── config/
│   ├── bootstrap.dart                   # Firebase init, AppCheck, dotenv, SharedPreferences
│   ├── di.dart                          # GetIt service locator
│   ├── env_reader.dart                  # dart-define & .env reader
│   ├── languages.dart                   # Supported locales + defaultLocale
│   ├── router.dart                      # appRouterProvider (keepAlive) + _RouterNotifier
│   └── app_routes.dart                  # Route name constants
│
├── l10n/                                # ARB files + generated (do not edit generated)
│   ├── app_vi.arb
│   ├── app_en.arb
│   ├── app_ja.arb
│   └── app_localizations*.dart
│
├── generated/                           # flutter_gen output (type-safe assets)
│   ├── assets.gen.dart
│   └── fonts.gen.dart
│
└── app/
    ├── core/
    │   ├── error/
    │   │   ├── failures.dart            # sealed class Failure hierarchy
    │   │   └── exceptions.dart          # Raw exceptions thrown in data layer
    │   ├── network/
    │   │   └── firebase_providers.dart  # @riverpod FirebaseAuth, Firestore, Storage
    │   ├── providers/
    │   │   └── theme_provider.dart      # ThemeModeNotifier + sharedPreferencesProvider
    │   ├── utils/
    │   │   ├── logger.dart              # Global logger instance (logger package)
    │   │   └── validator.dart           # Input validation helpers
    │   └── values/
    │       ├── app_colors.dart          # AppDarkColors, AppLightColors, AppSemanticColors
    │       ├── app_theme.dart           # AppTheme.light / AppTheme.dark (Material 3)
    │       ├── app_typography.dart      # Inter TextTheme
    │       ├── app_spacing.dart         # AppSpacing + AppRadius constants
    │       └── app_fontsize.dart        # Font size constants
    │
    ├── global_widgets/                  # Reusable across all features
    │   ├── global_widgets.dart          # Barrel export (imports all sub-folders)
    │   ├── states/                    # Loading, error, empty states
    │   │   ├── empty_state.dart
    │   │   ├── error_state.dart
    │   │   └── loading_shimmer.dart
    │   ├── input/                       # Text input widgets
    │   │   ├── app_text_input.dart      # Filled multi-line input + AppTextInputWithCounter
    │   │   └── app_comment_input.dart   # Compact pill-shape comment input
    │   ├── layout/                      # Structural / container widgets
    │   │   ├── app_bottom_sheet.dart    # showAppBottomSheet / showAppScrollableSheet
    │   │   ├── app_card.dart
    │   │   └── left_accent_block.dart   # Left-border accent container (answers, reports)
    │   └── ui/                          # Visual / interactive components
    │       ├── anonymous_badge.dart
    │       ├── app_avatar.dart
    │       ├── app_brand_wordmark.dart  # "AskmeHUMG" branded text
    │       ├── app_button.dart          # AppButton – 5 variants: primary/secondary/ghost/danger/google
    │       └── language_switch.dart
    │
    ├── services/
    │   └── api_client.dart              # Dio + interceptors for Cloud Functions
    │
    └── modules/
        │
        ├── splash/
        │   └── presentation/
        │       └── screens/
        │           └── splash_screen.dart   # ConsumerStatefulWidget, navigates by auth state
        │
        ├── auth/                            # UC-1.1, UC-1.2, UC-1.3
        │   ├── domain/                      # ← flat, no sub-folders
        │   │   ├── auth_user.dart           # @freezed entity
        │   │   ├── i_auth_repository.dart   # abstract interface
        │   │   └── auth_use_cases.dart      # SignInWithGoogle, SignOut
        │   ├── data/                        # ← flat
        │   │   ├── auth_user_model.dart     # fromFirebaseUser(), fromFirestore(), toFirestoreUpsert()
        │   │   ├── firebase_auth_datasource.dart
        │   │   └── auth_repository_impl.dart
        │   └── presentation/
        │       ├── auth_providers.dart      # all providers in one file
        │       └── screens/
        │           └── login_screen.dart
        │
        ├── profile/                         # UC-2.1, UC-2.2 (pending)
        │   ├── domain/
        │   │   ├── user_profile.dart
        │   │   ├── i_profile_repository.dart
        │   │   └── profile_use_cases.dart   # GetUserProfile, GenerateDeepLink
        │   ├── data/
        │   │   ├── user_profile_model.dart
        │   │   ├── profile_datasource.dart
        │   │   └── profile_repository_impl.dart
        │   └── presentation/
        │       ├── profile_providers.dart
        │       └── screens/
        │           └── profile_screen.dart
        │
        ├── qna_core/                        # UC-3.1, UC-3.2, UC-3.3 (pending)
        │   ├── domain/
        │   │   ├── question.dart
        │   │   ├── answer.dart
        │   │   ├── i_qna_repository.dart
        │   │   └── qna_use_cases.dart       # SubmitQuestion, GetInboxQuestions, AnswerQuestion
        │   ├── data/
        │   │   ├── question_model.dart
        │   │   ├── answer_model.dart
        │   │   ├── qna_datasource.dart
        │   │   └── qna_repository_impl.dart
        │   └── presentation/
        │       ├── qna_providers.dart
        │       └── screens/
        │           ├── inbox_screen.dart
        │           └── answer_compose_screen.dart
        │
        ├── feed/                            # UC-4.1, UC-4.2, UC-4.3 (pending)
        │   ├── domain/
        │   │   ├── feed_item.dart
        │   │   ├── comment.dart
        │   │   ├── i_feed_repository.dart
        │   │   └── feed_use_cases.dart      # GetPublicFeed, ToggleLike, PostComment
        │   ├── data/
        │   │   ├── feed_item_model.dart
        │   │   ├── comment_model.dart
        │   │   ├── feed_datasource.dart
        │   │   └── feed_repository_impl.dart
        │   └── presentation/
        │       ├── feed_providers.dart
        │       └── screens/
        │           └── feed_screen.dart
        │
        └── moderation/                      # UC-5.1, UC-5.2 (pending)
            ├── domain/
            │   ├── report.dart
            │   ├── i_moderation_repository.dart
            │   └── moderation_use_cases.dart  # SubmitReport, ResolveReport
            ├── data/
            │   ├── report_model.dart
            │   ├── moderation_datasource.dart
            │   └── moderation_repository_impl.dart
            └── presentation/
                ├── moderation_providers.dart
                └── screens/
                    └── admin_dashboard_screen.dart
```

---

## Layer Responsibilities

### `domain/` — Business Contract Layer
- **Pure Dart only.** Zero Flutter or Firebase imports.
- Entity: `@freezed abstract class` (freezed v3 requirement)
- Repository interface: `abstract interface class I*Repository`
- Use cases: consolidated in one file `*_use_cases.dart`, each class has a `call()` method

```dart
// Entity (freezed v3)
@freezed
abstract class AuthUser with _$AuthUser {
  const factory AuthUser({
    required String uid,
    required String email,
    @Default(false) bool isHumgVerified,
  }) = _AuthUser;
}

// Use case
class SignInWithGoogle {
  const SignInWithGoogle(this._repo);
  final IAuthRepository _repo;
  Future<void> call() => _repo.signInWithGoogle();
}
```

### `data/` — Firebase Implementation Layer
- Implements domain repository interfaces
- Datasource: raw Firebase calls, returns domain entities
- Model: mapper between Firestore `Map` ↔ domain entity (no `@freezed` required for mappers)
- Repository: catches `FirebaseException`/`AuthException`, maps to `Failure`

```dart
class AuthRepositoryImpl implements IAuthRepository {
  @override
  Future<void> signInWithGoogle() async {
    try {
      await _datasource.signInWithGoogle();
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }
}
```

### `presentation/` — UI Layer
- Screens: `ConsumerWidget` or `ConsumerStatefulWidget`
- All providers in one file: `<feature>_providers.dart`
- No direct Firestore/Firebase calls
- Use `AppButton` variants instead of creating new button widgets

```dart
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> signIn() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(signInWithGoogleProvider).call(),
    );
  }
}
```

---

## Routing (GoRouter)

```dart
// config/router.dart
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final notifier = _RouterNotifier(ref);
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,   // reactive to auth state changes
    redirect: notifier.redirect,
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/',       builder: (_, __) => const FeedScreen()),
      GoRoute(path: '/login',  builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/inbox',  builder: (_, __) => const InboxScreen()),
      GoRoute(path: '/u/:userId', builder: (ctx, state) =>
          ProfileScreen(userId: state.pathParameters['userId']!)),
      GoRoute(path: '/admin',  builder: (_, __) => const AdminDashboardScreen()),
    ],
  );
}
```

Auth guard: `/inbox` and `/admin` redirect to `/login` if unauthenticated. `/login` redirects to `/` if already authenticated.

---

## Shell Navigation (Bottom NavigationBar)

### Why ShellRoute

The app has a persistent 4-tab bottom nav (`Feed` / `Inbox` / `Profile` / `Settings`). GoRouter's `StatefulShellRoute` wraps these 4 routes in a shared `AppShell` scaffold so:
- The `NavigationBar` persists across tab switches
- Each tab keeps its own scroll position and state (`IndexedStack`)
- Full-screen routes (Login, AnswerCompose, deep-link Profile) render **outside** the shell — no bottom nav visible

### Route tree

```
ShellRoute(builder: AppShell)
├── GoRoute(path: '/')           → FeedScreen         [tab 0]
├── GoRoute(path: '/inbox')      → InboxScreen        [tab 1]
├── GoRoute(path: '/me')         → ProfileScreen(myUserId) [tab 2]
└── GoRoute(path: '/settings')   → SettingsScreen     [tab 3]

GoRoute(path: '/splash')         → SplashScreen            (outside shell)
GoRoute(path: '/login')          → LoginScreen              (outside shell)
GoRoute(path: '/u/:userId')      → ProfileScreen(userId)    (outside shell — deep link / other user)
GoRoute(path: '/inbox/answer/:questionId') → AnswerComposeScreen (outside shell — full-screen)
GoRoute(path: '/me/edit')        → EditProfileScreen         (outside shell — full-screen)
GoRoute(path: '/admin')          → AdminDashboardScreen      (outside shell)
```

> **Key distinction:** `/me` (shell tab 2) always shows the **logged-in user's** own profile. `/u/:userId` is a full-screen push, used when tapping another user's avatar in the feed.

### AppShell widget (`lib/app/core/widgets/app_shell.dart`)

```dart
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).asData?.value;

    return Scaffold(
      body: navigationShell,  // renders current tab's screen
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(icon: Icon(LucideIcons.home),     label: l10n.navFeed),
          NavigationDestination(icon: Icon(LucideIcons.mailbox),  label: l10n.navInbox),
          NavigationDestination(icon: Icon(LucideIcons.user),     label: l10n.navProfile),
          NavigationDestination(icon: Icon(LucideIcons.settings), label: l10n.navSettings),
        ],
      ),
    );
  }
}
```

### Tab index mapping

| Index | Route | Visibility |
|-------|-------|------------|
| 0 | `/` (Feed) | Always visible |
| 1 | `/inbox` | Always visible; redirect to `/login` if unauthenticated |
| 2 | `/me` (own Profile) | Always visible; shows sign-in prompt if unauthenticated |
| 3 | `/settings` | Always visible; account-specific items hidden when guest |

### Auth edge cases

| Scenario | Behavior |
|----------|----------|
| Guest taps Inbox tab | `_RouterNotifier.redirect` sends to `/login`; after login, GoRouter resumes `/inbox` |
| Guest taps Profile tab | Shell renders Profile tab; `ProfileScreen` detects `user == null` and shows sign-in CTA instead of profile content |
| Deep link `/u/{otherId}` | Navigates to full-screen `ProfileScreen` **outside** the shell (no bottom nav) |
| Deep link `/u/{myId}` | Same as above — resolves to full-screen for consistency; alternatively `context.go('/me')` if IDs match |

### Navigation conventions

```dart
// Switch tab (stays in shell)
context.go('/');          // → Feed tab
context.go('/inbox');     // → Inbox tab
context.go('/me');        // → Profile tab
context.go('/settings');  // → Settings tab

// Push full-screen over shell (back button returns to shell)
context.push('/u/$userId');                     // Other user profile
context.push('/inbox/answer/$questionId');      // Answer compose
context.push('/me/edit');                       // Edit profile
```

### Firestore index note

The `answers` query powering the Feed tab requires a composite index:
```
Collection: answers
Fields: isPublished ASC, createdAt DESC, __name__ DESC
```
This is declared in `firestore.indexes.json` and must be deployed with `firebase deploy --only firestore:indexes` before the Feed tab works.

---

## Key Conventions

| What | Convention |
|---|---|
| State management | `AsyncNotifier` for async, `Notifier` for sync |
| Watching state | `ref.watch` in `build()`, `ref.read` in callbacks |
| Multi-collection writes | Always `WriteBatch` (UC-3.3, UC-4.3, UC-5.2) |
| Atomic counters | `FieldValue.increment()` only |
| Error handling | Map `FirebaseException` → `Failure`, never swallow |
| Strings | `AppLocalizations.of(context).*` — no hardcoded strings |
| Logging | `logger.d/e/w` — never `print()` |
| Theme colors | `Theme.of(context).colorScheme.*` — never hardcode colors |
| Dark mode | Default `ThemeMode.dark`, persisted via `SharedPreferences` |
| Global widgets | Use `AppButton(variant: ...)` — never create one-off button widgets |
