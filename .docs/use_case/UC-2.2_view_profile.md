# UC-2.2 – View User Profile

> **Module:** Profile & Sharing
> **SRS Reference:** FR-10
> **Actor:** Viewer, Host, Anonymous Sender
> **Priority:** High

---

## 1. Pre-conditions

- User navigates to `/u/:userId` via:
  - Deep link (from external share)
  - Tapping an avatar on the Feed
  - Bottom navigation "Profile" tab (own profile)

## 2. Main Flow

```
1. ProfileScreen receives userId as path parameter
2. profileProvider(userId) is watched by the screen
3. Provider calls GetUserProfile use case
4. Use case fetches users/{userId} document from Firestore
5. Use case queries answers collection: where('userId', isEqualTo: userId),
   where('isPublished', isEqualTo: true) to compute stats
6. Display:
   - Avatar (CachedNetworkImage with fallback initials)
   - Display name
   - Answer count (published)
   - Total likes received (sum of likeCount across user's answers)
7. If viewer is Anonymous Sender / any user:
   - Show anonymous question input area (AskQuestionSheet → triggers UC-3.1)
8. If viewer is the profile owner (currentUser.uid == userId):
   - Show "Share" button (triggers UC-2.1)
   - Show "Inbox" shortcut button → navigates to /inbox
```

## 3. Alternative Flow – User Not Found

```
A1. users/{userId} document does not exist
A2. Display ErrorState widget with message l10n.userNotFound
```

## 4. Alternative Flow – Network Error

```
B1. FirebaseException is caught → mapped to FirestoreFailure
B2. Display ErrorState widget with retry button
B3. User taps retry → re-triggers the provider
```

---

## 5. Database Impact

### Collection: `users`

| Operation | Description |
|---|---|
| `get users/{userId}` | Fetch name, avatar, email, isBlocked |

### Collection: `answers`

| Operation | Description |
|---|---|
| `query answers where userId == userId && isPublished == true` | Compute answerCount and totalLikes |

> **Optimization note (future):** Denormalize `answerCount` and `totalLikes` into `users` document to avoid aggregate query on every profile load.

---

## 6. Files to Create / Modify

```
lib/app/modules/profile/
├── domain/
│   ├── entities/user_profile.dart              [CREATE] @freezed
│   ├── repositories/i_profile_repository.dart  [CREATE]
│   └── use_cases/get_user_profile.dart         [CREATE]
├── data/
│   ├── datasources/profile_datasource.dart     [CREATE]
│   ├── models/user_profile_model.dart          [CREATE] @freezed + fromFirestore()
│   └── repositories/profile_repository_impl.dart  [CREATE]
└── presentation/
    ├── screens/profile_screen.dart              [CREATE]
    ├── widgets/
    │   ├── profile_header.dart                  [CREATE] avatar + name + stats
    │   ├── profile_stats_row.dart               [CREATE] answer count + total likes
    │   └── ask_question_sheet.dart              [CREATE] bottom sheet → UC-3.1
    └── providers/profile_providers.dart         [CREATE]
```

---

## 7. Key Code Contracts

### Entity: `user_profile.dart`
```dart
@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String userId,
    required String name,
    required String avatar,
    required String email,
    @Default(0) int answerCount,
    @Default(0) int totalLikes,
    @Default(false) bool isBlocked,
  }) = _UserProfile;
}
```

### Repository Interface
```dart
abstract class IProfileRepository {
  Future<UserProfile> getUserProfile(String userId);
}
```

### Provider
```dart
@riverpod
Future<UserProfile> userProfile(UserProfileRef ref, String userId) =>
    ref.read(getUserProfileProvider).call(userId);
```

### ProfileScreen (ConsumerWidget skeleton)
```dart
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(userId));
    return profileAsync.when(
      loading: () => const LoadingShimmer(),
      error: (e, _) => ErrorState(onRetry: () => ref.invalidate(userProfileProvider(userId))),
      data: (profile) => _ProfileContent(profile: profile),
    );
  }
}
```

---

## 8. Acceptance Criteria (from SRS FR-10)

- [ ] Display name, avatar shown correctly
- [ ] Answer count = number of published answers by this user
- [ ] Total likes = sum of `likeCount` across user's published answers
- [ ] If `isBlocked == true`, show blocked account notice instead of profile
- [ ] Unauthenticated users CAN view profile (no auth required for read)
- [ ] Deep link `/u/:userId` resolves to correct user's profile
- [ ] LoadingShimmer shown while data is loading
- [ ] ErrorState shown with retry on network error
