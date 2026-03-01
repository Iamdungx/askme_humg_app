# AskmeHUMG – Tech Stack

> **Flutter SDK:** 3.35.7 | **Dart SDK:** >=3.10.3 | **Updated:** 01-03-2026

---

## 1. Module Folder Structure

```
lib/app/modules/<feature>/
  domain/                          ← pure Dart, flat (no sub-folders)
    <feature>.dart                 ← @freezed abstract class entity
    i_<feature>_repository.dart    ← abstract interface
    <feature>_use_cases.dart       ← all use cases in one file
  data/                            ← flat
    <feature>_model.dart           ← Firestore ↔ entity mapper
    firebase_<feature>_datasource.dart
    <feature>_repository_impl.dart
  presentation/
    <feature>_providers.dart       ← all Riverpod providers in one file
    screens/
      <feature>_screen.dart
```

Layer rules:
- `domain/` — pure Dart only, no Flutter/Firebase imports
- `data/` — all Firebase calls live here
- `presentation/` — no direct Firestore calls

---

## 2. Dependencies

### Runtime

| Package | Version | Purpose |
|---|---|---|
| `firebase_core` | ^4.4.0 | Firebase init |
| `firebase_auth` | ^6.1.4 | Google Sign-In |
| `cloud_firestore` | ^6.1.2 | Database |
| `firebase_storage` | ^13.0.6 | Avatar uploads |
| `firebase_app_check` | ^0.4.1+4 | Bot protection |
| `firebase_messaging` | ^16.1.1 | Push notifications |
| `google_sign_in` | ^7.2.0 | Google OAuth |
| `flutter_riverpod` | ^3.1.0 | State management |
| `hooks_riverpod` | ^3.1.0 | HookConsumerWidget |
| `flutter_hooks` | ^0.21.3+1 | React-style hooks |
| `riverpod_annotation` | ^4.0.0 | @riverpod codegen |
| `go_router` | ^17.1.0 | Routing + deep links |
| `dio` | ^5.7.0 | HTTP / Cloud Functions |
| `freezed_annotation` | ^3.0.0 | Immutable models |
| `json_annotation` | ^4.9.0 | JSON serialization |
| `get_it` | 7.7.0 | DI / service locator |
| `shared_preferences` | ^2.5.4 | Local key-value storage |
| `cached_network_image` | ^3.4.1 | Image caching |
| `shimmer` | ^3.0.0 | Skeleton loading |
| `share_plus` | ^12.0.1 | Share link / image |
| `qr_flutter` | ^4.1.0 | Profile QR code |
| `flutter_animate` | ^4.5.0 | Micro-animations |
| `lottie` | ^3.3.0 | Lottie animations |
| `gap` | ^3.0.1 | Spacing shorthand |
| `logger` | ^2.5.0 | Structured logging |
| `timeago` | ^3.7.0 | Relative timestamps |
| `url_launcher` | ^6.3.1 | Open web links |
| `package_info_plus` | ^8.3.0 | App version/build number |
| `intl` | ^0.20.2 | l10n formatting |
| `flutter_dotenv` | ^6.0.0 | .env config |
| `flutter_svg` | ^2.2.3 | SVG rendering |
| `flutter_gen` | ^5.12.0 | Type-safe asset accessors |
| `lucide_icons_flutter` | ^3.1.10 | Icon set |

### Dev

| Package | Version | Purpose |
|---|---|---|
| `build_runner` | ^2.4.15 | Codegen runner |
| `freezed` | ^3.1.0 | Immutable model codegen |
| `json_serializable` | ^6.9.4 | JSON codegen |
| `riverpod_generator` | ^4.0.0+1 | Provider codegen |
| `flutter_gen_runner` | ^5.12.0 | Asset codegen |
| `go_router_builder` | ^4.2.0 | Route codegen |
| `custom_lint` | ^0.8.1 | Lint runner |
| `riverpod_lint` | ^3.1.0 | Riverpod lint rules |
| `mocktail` | ^1.0.4 | Unit test mocking |
| `fake_cloud_firestore` | ^4.0.1 | Firestore mock |
| `firebase_auth_mocks` | ^0.15.1 | Auth mock |
| `flutter_lints` | ^6.0.0 | Flutter lint rules |
| `flutter_launcher_icons` | ^0.14.4 | App icon gen |
| `flutter_native_splash` | ^2.4.1 | Splash screen gen |

---

## 3. Correct API Patterns

### Material 3 — renamed classes (Flutter 3.19+)

| Old | New |
|---|---|
| `CardTheme` | `CardThemeData` |
| `TabBarTheme` | `TabBarThemeData` |
| `MaterialStateProperty` | `WidgetStateProperty` |
| `MaterialState` | `WidgetState` |
| `ColorScheme.background` | `scaffoldBackgroundColor` |
| `ColorScheme.onBackground` | `ColorScheme.onSurface` |
| `color.withOpacity(x)` | `color.withValues(alpha: x)` |

### Freezed 3.x — requires `abstract class`

```dart
@freezed
abstract class AuthUser with _$AuthUser {
  const factory AuthUser({
    required String uid,
    required String email,
    @Default(false) bool isHumgVerified,
    String? humgEmail,
  }) = _AuthUser;
}
```

### Riverpod 3.x

```dart
// AsyncNotifier
@riverpod
class FeedNotifier extends _$FeedNotifier {
  @override
  Future<List<FeedItem>> build() async =>
      ref.read(getFeedUseCaseProvider).call();
}

// In widget: ref.watch in build(), ref.read in callbacks
final feed = ref.watch(feedNotifierProvider);
ref.read(feedNotifierProvider.notifier).refresh();
```

### Router — keepAlive + _RouterNotifier

```dart
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final notifier = _RouterNotifier(ref);
  return GoRouter(
    refreshListenable: notifier,
    redirect: notifier.redirect,
    ...
  );
}
```

### Firebase write patterns

```dart
// Multi-collection → WriteBatch (UC-3.3, UC-4.3)
final batch = FirebaseFirestore.instance.batch();
batch.set(answersCol.doc(), answerData);
batch.update(questionsCol.doc(questionId), {'status': 'answered'});
await batch.commit();

// Like toggle (UC-4.2)
await answersCol.doc(answerId).update({
  'likedBy': FieldValue.arrayUnion([userId]),
  'likeCount': FieldValue.increment(1),
});

// Cursor pagination (UC-4.1)
Query query = firestore
    .collection('answers')
    .where('isPublished', isEqualTo: true)
    .orderBy('createdAt', descending: true)
    .limit(20);
if (lastDoc != null) query = query.startAfterDocument(lastDoc);
```

### Icons — always LucideIcons

```dart
import 'package:lucide_icons_flutter/lucide_icons.dart';

Icon(LucideIcons.circleAlert)  // error state
Icon(LucideIcons.inbox)        // empty state
Icon(LucideIcons.lock)         // anonymous/locked
Icon(LucideIcons.chevronRight) // navigation
Icon(LucideIcons.circleX)      // dismiss/error action
```

Never use `Icons.*` from Flutter Material — always use `LucideIcons.*`.

### AppButton variants

```dart
AppButton(label: l10n.authSignInWithGoogle, variant: AppButtonVariant.google, onPressed: ...)
```

Current variants: `primary`, `secondary`, `ghost`, `danger`, `google`.

### Type-safe assets (flutter_gen)

```dart
// ✅ Use generated accessors — never hardcode asset paths
Assets.imagesAppIcon.image(width: 180, height: 180)  // PNG/JPG
Assets.svgsGoogleLogo.svg(width: 20, height: 20)     // SVG
```

### Logger

```dart
import 'package:askme_humg/app/core/utils/logger.dart';

logger.d('debug');
logger.i('info');
logger.w('warning');
logger.e('error', error: e, stackTrace: s);
```

---

## 4. Firebase Services

| Service | Package | Purpose |
|---|---|---|
| Auth | `firebase_auth ^6.1.4` | Google Sign-In, Admin custom claims |
| Firestore | `cloud_firestore ^6.1.2` | All data, WriteBatch, cursor pagination |
| Storage | `firebase_storage ^13.0.6` | Avatar uploads |
| App Check | `firebase_app_check ^0.4.1+4` | debug in dev, playIntegrity/deviceCheck in prod |
| Cloud Functions | via `dio ^5.7.0` | Rate limiting, OTP (UC-1.3), moderation |
| Messaging | `firebase_messaging ^16.1.1` | Push (wired, not active yet) |

---

## 5. Code Generation

```bash
dart run build_runner build --delete-conflicting-outputs  # after @freezed / @riverpod changes
dart run build_runner watch --delete-conflicting-outputs  # during development
flutter gen-l10n                                          # after .arb changes
```

---

## 6. Deprecated Packages

| Package | Replacement |
|---|---|
| `firebase_dynamic_links` | `app_links ^6.x` + redirect at `askme.humg.edu.vn/u/{userId}` |
| `image_gallery_saver` | `share_plus` |
| `provider` / GetX | `flutter_riverpod` + `go_router` |
