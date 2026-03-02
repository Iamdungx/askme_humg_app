---
name: fix-bug
description: Diagnoses and fixes bugs in the AskmeHUMG Flutter/Riverpod/Firebase project. Use when the user reports an error, crash, unexpected behavior, or says "fix", "bug", "lỗi", "crash", "không hoạt động", "sửa lỗi", "debug". Covers: Dart/Flutter errors, Firestore exceptions, Riverpod state issues, navigation/GoRouter issues, build_runner code-gen errors, linter errors.
---

# Fix Bug (AskmeHUMG)

## Step 1 — Reproduce & Locate

1. Read the error message or stack trace carefully.
2. Identify the **layer** where the bug lives:

| Layer | Typical files |
|---|---|
| Domain | `lib/app/modules/<feature>/domain/` |
| Data / Firestore | `lib/app/modules/<feature>/data/` |
| Providers | `<feature>_providers.dart` |
| Presentation | `screens/`, `widgets/` |
| Router | `lib/config/router.dart` |
| Core / shared | `lib/app/core/` |

3. Read the affected file(s) before making any change.

## Step 2 — Common Bug Patterns

### Firestore / Firebase

| Symptom | Fix |
|---|---|
| `type 'Null' is not a subtype of type` | Add null check in `.fromJson` — Firestore fields may be missing |
| `FirebaseException: permission-denied` | Check Firestore Security Rules; verify `isHumgVerified` guard |
| Missing denormalized field on `answers` / `comments` | Re-check UC-3.3 / UC-4.3 — must use `WriteBatch` and copy host/author fields |
| Counter wrong after batch write | Use `FieldValue.increment(±1)`, never set from `.length` |
| `otpRequests` doc not deleted after verify | Batch must include `otpRequests/{uid}` delete — see UC-1.3 |

### Riverpod

| Symptom | Fix |
|---|---|
| Provider not updating UI | Call `ref.invalidate(provider)` after mutation; use `AsyncNotifier` for mutations |
| `ProviderNotFoundException` | Ensure provider is in scope — check `ProviderScope` wraps the widget tree |
| `StateError: bad state: Future already completed` | Don't use `ref.read` inside `build`; use `ref.watch` |
| Family provider not refreshing | Pass a stable key — avoid passing mutable objects |

### GoRouter / Navigation

| Symptom | Fix |
|---|---|
| Route not found / `404` | Verify `TypedGoRoute` annotation and run `build_runner` |
| Redirect loop on `/verify-humg` | Check `requireVerified()` guard and `isHumgVerified` value in `users` doc |
| Deep link not handled | Verify `app_links` listener in `router.dart`; check `askme-humg-app.web.app/user/{userId}` format |

### Dart / Flutter

| Symptom | Fix |
|---|---|
| `withOpacity` deprecation warning | Replace with `Color.withValues(alpha: x)` |
| `print()` found | Replace with `logger.d/i/w/e` |
| Hardcoded string in widget | Move to ARB — follow `add-l10n-string` skill |
| `abstract class` missing on `@freezed` entity | Freezed 3.x requires `abstract class` — add it |

### Code Generation

```bash
# After any @freezed, @riverpod, or @TypedGoRoute change
dart run build_runner build --delete-conflicting-outputs
```

If still broken, clean first:
```bash
dart run build_runner clean && dart run build_runner build --delete-conflicting-outputs
```

## Step 3 — Fix Rules

- **Never swallow exceptions silently** — always log with `logger.e(...)` and rethrow as a typed exception from `lib/app/core/error/exceptions.dart`.
- **Never use hex colors** — use `AppColors.*` or `Theme.of(context).colorScheme.*`.
- **Multi-collection writes** — always `WriteBatch`; never two separate `.set()`/`.update()` calls.
- **Error handling pattern**:

```dart
try {
  // Firebase call
} on FirebaseException catch (e, s) {
  logger.e('operationName failed', error: e, stackTrace: s);
  throw FirestoreException(e.message ?? 'Firestore error');
}
```

## Step 4 — Verify Fix

1. Run `ReadLints` on every file you edited.
2. If lints remain, fix them before finishing.
3. If the fix touches code-gen files, re-run `build_runner`.
4. Confirm the exact error no longer occurs (trace through the logic manually if needed).

## Reference files

- Error classes: `lib/app/core/error/exceptions.dart` + `failures.dart`
- Firebase providers: `lib/app/core/network/firebase_providers.dart`
- Router: `lib/config/router.dart`
- UC constraints: `.cursor/rules/use-case-reference.mdc`
