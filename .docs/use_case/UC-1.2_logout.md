# UC-1.2 – Logout

> **Module:** Authentication
> **SRS Reference:** FR-02
> **Actor:** Host, Logged-in Viewer
> **Priority:** High

---

## 1. Pre-conditions

- User is currently authenticated (FirebaseAuth.currentUser != null)

## 2. Main Flow

```
1. User taps "Logout" (from Profile screen or Settings menu)
2. System calls FirebaseAuth.instance.signOut()
3. System calls GoogleSignIn().signOut() to clear Google session cache
4. authStateChanges stream emits null
5. GoRouter redirect detects unauthenticated state
6. Navigate to /login screen
```

## 3. Alternative Flow – Error During Sign Out

```
A1. FirebaseException is caught
A2. Logged via logger.e()
A3. Still navigate to /login (best-effort logout)
```

---

## 4. Database Impact

None. No Firestore read/write required.

---

## 5. Files to Create / Modify

```
lib/app/modules/auth/
├── domain/use_cases/sign_out.dart           [CREATE]
└── presentation/providers/auth_providers.dart  [MODIFY] add signOut method

lib/config/router.dart                       [MODIFY] redirect: unauthenticated → /login
```

---

## 6. Key Code Contracts

### Use Case: `sign_out.dart`
```dart
class SignOut {
  const SignOut(this._repo);
  final IAuthRepository _repo;
  Future<void> call() => _repo.signOut();
}
```

### Router Guard
```dart
redirect: (context, state) {
  final isAuthenticated = ref.read(authStateProvider).valueOrNull != null;
  final protectedRoutes = ['/inbox', '/admin'];
  final isGoingToProtected = protectedRoutes.any((r) => state.matchedLocation.startsWith(r));

  if (!isAuthenticated && isGoingToProtected) return '/login';
  if (isAuthenticated && state.matchedLocation == '/login') return '/';
  return null;
},
```

---

## 7. Acceptance Criteria

- [ ] After logout, Firebase Auth session is cleared
- [ ] After logout, Google Sign-In cache is cleared (user must pick account again on next login)
- [ ] `authStateChanges` stream emits `null` after logout
- [ ] User is redirected to `/login` automatically
- [ ] Protected routes `/inbox`, `/admin` are inaccessible after logout
