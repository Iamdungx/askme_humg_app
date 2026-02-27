# UC-1.1 – Google Sign-In

> **Module:** Authentication
> **SRS Reference:** FR-02, NFR-03
> **Actor:** Host / Any Google user
> **Priority:** Critical (blocker for all authenticated features)

---

## 1. Pre-conditions

- App is installed and running
- Internet connection is available
- Firebase Auth and Google Sign-In are configured in the project

## 2. Main Flow

```
1. User taps "Sign in with Google" button
2. System launches Google Sign-In OAuth flow (GoogleSignIn().signIn())
3. User selects/confirms their Google account
4. System retrieves GoogleSignInAuthentication credentials
5. System creates a FirebaseCredential and calls FirebaseAuth.signInWithCredential()
6. Firebase Auth returns the authenticated user
7. System checks if document users/{uid} already exists in Firestore
   → If NOT exists (first login): Create document (goto step 8)
   → If exists: Update document (goto step 9)
8. [First Login] Create Firestore document users/{uid}:
   { name, email, avatar, role: 'user', createdAt: Timestamp.now(),
     isBlocked: false, isHumgVerified: false, humgEmail: null }
9. [Return Login] Update fields: name, avatar (in case Google profile changed)
10. Check users/{uid}.isHumgVerified
    → false: Navigate to /verify-humg-email (UC-1.3)
    → true : Navigate to Feed screen (/)
```

## 3. Alternative Flow A – User Cancels Google Sign-In

```
A1. GoogleSignIn().signIn() returns null
A2. No Firebase call is made
A3. User remains on Login screen (no error shown)
```

## 4. Alternative Flow B – Network / Firebase Error

```
B1. FirebaseException is caught in the data layer
B2. Mapped to AuthFailure / NetworkFailure
B3. UI displays error snackbar via AsyncError state
B4. User can retry
```

---

## 5. Database Impact

### Collection: `users`

| Operation | Condition | Fields Written |
|---|---|---|
| `set` (with merge) | First login OR return login | `name`, `email`, `avatar`, `role: 'user'`, `createdAt` (only on first create), `isBlocked: false`, `isHumgVerified: false` (only on first create), `humgEmail: null` (only on first create) |

```dart
// SetOptions(merge: true) ensures createdAt / isHumgVerified NOT overwritten on return login
await firestore.collection('users').doc(uid).set({
  'name': user.displayName ?? '',
  'email': user.email ?? '',
  'avatar': user.photoURL ?? '',
  'role': 'user',
  'createdAt': FieldValue.serverTimestamp(),
  'isBlocked': false,
  'isHumgVerified': false,
  'humgEmail': null,
}, SetOptions(merge: true));
```

---

## 6. Files to Create / Modify

```
lib/app/modules/auth/
├── domain/
│   ├── entities/auth_user.dart              [CREATE] @freezed
│   ├── repositories/i_auth_repository.dart  [CREATE] abstract interface
│   └── use_cases/
│       ├── sign_in_with_google.dart         [CREATE]
│       └── sign_out.dart                    [CREATE]
├── data/
│   ├── datasources/firebase_auth_datasource.dart  [CREATE]
│   ├── models/auth_user_model.dart                [CREATE] @freezed + fromFirebaseUser()
│   └── repositories/auth_repository_impl.dart     [CREATE]
└── presentation/
    ├── screens/login_screen.dart                  [CREATE]
    ├── widgets/google_sign_in_button.dart         [CREATE]
    └── providers/auth_providers.dart              [CREATE]

lib/config/router.dart                            [MODIFY] add auth guard redirect
```

---

## 7. Key Code Contracts

### Entity: `auth_user.dart`
```dart
@freezed
class AuthUser with _$AuthUser {
  const factory AuthUser({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
  }) = _AuthUser;
}
```

### Repository Interface: `i_auth_repository.dart`
```dart
abstract class IAuthRepository {
  Stream<AuthUser?> get authStateChanges;
  Future<void> signInWithGoogle();
  Future<void> signOut();
}
```

### Provider: `auth_providers.dart`
```dart
@riverpod
Stream<AuthUser?> authState(Ref ref) =>
    ref.read(authRepositoryProvider).authStateChanges;

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

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(signOutProvider).call(),
    );
  }
}
```

---

## 8. Firestore Security Rule

```javascript
match /users/{userId} {
  allow read: if request.auth != null;
  allow write: if request.auth.uid == userId;
}
```

---

## 9. Acceptance Criteria

- [ ] Any Google account → accepted, `users/{uid}` document created/updated
- [ ] First-time login creates doc with `role: 'user'`, `isBlocked: false`, `isHumgVerified: false`
- [ ] Return login does NOT overwrite `createdAt`, `isHumgVerified`, `humgEmail`
- [ ] `isHumgVerified: false` → redirect `/verify-humg-email` (UC-1.3)
- [ ] `isHumgVerified: true` → redirect `/` (Feed)
- [ ] User cancels → stays on Login screen, no error shown
- [ ] Network error → snackbar via `AsyncError`, can retry
- [ ] All strings via `context.l10n.*`
- [ ] No `print()` — logger only
