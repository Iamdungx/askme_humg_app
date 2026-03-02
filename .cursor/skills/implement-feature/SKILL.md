---
name: implement-feature
description: Implements a new feature module (domain + data + presentation layers) for AskmeHUMG following Clean Architecture. Use when implementing a Phase 2–5 feature, creating a new module folder, writing entities, repositories, use cases, Firestore datasources, or Riverpod providers. Trigger words: "implement", "create feature", "add module", "domain layer", "data layer", "UC-2", "UC-3", "UC-4", "UC-5".
---

# Implement Feature Module (AskmeHUMG)

## Flat folder structure — always

```
lib/app/modules/<feature>/
  domain/
    <feature>.dart                  @freezed abstract class entity
    i_<feature>_repository.dart     abstract interface
    <feature>_use_cases.dart        all use cases in one file
  data/
    <feature>_model.dart            Firestore ↔ entity mapper
    firebase_<feature>_datasource.dart
    <feature>_repository_impl.dart
  presentation/
    <feature>_providers.dart        all Riverpod providers
    screens/
      <feature>_screen.dart
    widgets/                        only if screen file exceeds ~80 lines of UI
```

No sub-folders inside `domain/`, `data/`, or root `presentation/`.

## Step-by-step

**Step 1 — Read the UC file first**
`.docs/use_case/UC-X.X_*.md` → check Database Impact section before writing any code.

**Step 2 — Domain layer**

Entity (Freezed 3.x — MUST use `abstract class`):
```dart
@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String userId,
    required String name,
    required String avatar,
    @Default(0) int answerCount,
    @Default(0) int totalLikes,
    @Default(false) bool isBlocked,
  }) = _UserProfile;
}
```

Repository interface:
```dart
abstract class IProfileRepository {
  Future<UserProfile> getUserProfile(String userId);
}
```

Use cases (all in one file):
```dart
class GetUserProfile {
  const GetUserProfile(this._repo);
  final IProfileRepository _repo;
  Future<UserProfile> call(String userId) => _repo.getUserProfile(userId);
}
```

**Step 3 — Data layer**

Model (always include `fromFirestore` + `toDomain`):
```dart
@freezed
abstract class UserProfileModel with _$UserProfileModel {
  const factory UserProfileModel({...}) = _UserProfileModel;
  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      _$UserProfileModelFromJson(json);
}

extension UserProfileModelX on UserProfileModel {
  UserProfile toDomain() => UserProfile(userId: userId, ...);
}
```

Datasource (all Firebase calls here, never in presentation):
```dart
class FirebaseProfileDatasource {
  FirebaseProfileDatasource({required FirebaseFirestore firestore})
      : _firestore = firestore;
  final FirebaseFirestore _firestore;

  Future<UserProfile> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) throw const FirestoreException('User not found');
      return UserProfileModel.fromJson(doc.data()!).toDomain();
    } on FirebaseException catch (e, s) {
      logger.e('getUserProfile failed', error: e, stackTrace: s);
      throw FirestoreException(e.message ?? 'Firestore error');
    }
  }
}
```

Repository impl — catches exceptions, never exposes them raw:
```dart
class ProfileRepositoryImpl implements IProfileRepository {
  ProfileRepositoryImpl(this._datasource);
  final FirebaseProfileDatasource _datasource;

  @override
  Future<UserProfile> getUserProfile(String userId) =>
      _datasource.getUserProfile(userId);
}
```

**Step 4 — Presentation providers**

```dart
// All providers in one file: <feature>_providers.dart
@riverpod
FirebaseProfileDatasource profileDatasource(Ref ref) =>
    FirebaseProfileDatasource(firestore: ref.watch(firestoreProvider));

@riverpod
IProfileRepository profileRepository(Ref ref) =>
    ProfileRepositoryImpl(ref.watch(profileDatasourceProvider));

@riverpod
GetUserProfile getUserProfile(Ref ref) =>
    GetUserProfile(ref.watch(profileRepositoryProvider));

// Family provider for parameterized data
@riverpod
Future<UserProfile> userProfile(Ref ref, String userId) =>
    ref.watch(getUserProfileProvider).call(userId);
```

**Step 5 — Localization strings**

Every user-facing string must go through ARB. Never hardcode strings in widgets.

Follow the `add-l10n-string` skill (`.cursor/skills/add-l10n-string/SKILL.md`) for full rules. Key points:

- Add key to **all 3** files: `app_en.arb`, `app_vi.arb`, `app_ja.arb`
- Every key requires an `@key` block with `description` — **no exceptions**
- Strings with `{param}` require a `placeholders` entry in the `@` block in all 3 files
- Run `flutter gen-l10n` after every ARB edit

```json
// Minimal correct entry (all 3 files)
"myScreenEmpty": "Nothing here yet",
"@myScreenEmpty": { "description": "Empty state on MyScreen" },
```

**Step 6 — Screen**

```dart
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(userId));
    return Scaffold(
      body: profileAsync.when(
        loading: () => const LoadingShimmer(),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(userProfileProvider(userId)),
        ),
        data: (profile) => _ProfileContent(profile: profile),
      ),
    );
  }
}
```

## Critical rules

| Rule | Detail |
|---|---|
| Multi-collection write | Always `WriteBatch` — UC-3.3, UC-4.3, UC-5.2 |
| Counter update | `FieldValue.increment(±1)` — never `.length` |
| Error handling | Catch `FirebaseException` → throw typed `*Exception` from `core/error/exceptions.dart` |
| State | `AsyncNotifier` for async mutations, `FutureProvider` / `StreamProvider` for reads |
| Strings | `context.l10n.*` only — add key to all 3 ARB files with `@key { "description": "..." }` block, then run `flutter gen-l10n` |
| Colors | `AppColors.*` or `Theme.of(context).colorScheme.*` — no hex |
| Logging | `logger.d/i/w/e` — no `print()` |
| `withOpacity` | BANNED → `Color.withValues(alpha: x)` |

## After creating files

```bash
dart run build_runner build --delete-conflicting-outputs
```

Required after any new `@freezed`, `@riverpod`, or `@TypedGoRoute` annotation.

## Reference files

- UC details: `.docs/use_case/UC-X.X_*.md`
- Error classes: `lib/app/core/error/exceptions.dart` + `failures.dart`
- Firebase providers: `lib/app/core/network/firebase_providers.dart`
- Auth example: `lib/app/modules/auth/` (complete working example)
