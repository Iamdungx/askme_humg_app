# UC-4.2 – Like / Unlike an Answer

> **Module:** Feed & Interaction
> **SRS Reference:** FR-06
> **Actor:** Logged-in Viewer / Host
> **Priority:** Medium

---

## 1. Pre-conditions

- User is logged in (like requires authentication)
- User is viewing the Feed (FeedScreen)
- The answer exists in Firestore with `isPublished == true`

## 2. Main Flow – Like

```
1. User taps Like button (heart icon) on a FeedItemCard
2. System checks: currentUser.uid NOT in answer.likedBy
   → Proceed to like
3. Optimistic UI update immediately:
   - Like icon changes to filled/red
   - likeCount increments by 1 in local state
4. System calls toggleLike(answerId, userId):
   - answers/{answerId}.update({
       likedBy: FieldValue.arrayUnion([userId]),
       likeCount: FieldValue.increment(1)
     })
5. On success: state confirmed (no change needed, optimistic was correct)
6. On failure: revert optimistic update, show error snackbar
```

## 3. Main Flow – Unlike

```
1. User taps Like button again (heart icon is currently filled/red)
2. System checks: currentUser.uid IS in answer.likedBy
   → Proceed to unlike
3. Optimistic UI update immediately:
   - Like icon changes to outline/empty
   - likeCount decrements by 1 in local state
4. System calls toggleLike(answerId, userId):
   - answers/{answerId}.update({
       likedBy: FieldValue.arrayRemove([userId]),
       likeCount: FieldValue.increment(-1)
     })
5. On success: confirmed
6. On failure: revert optimistic update
```

## 4. Alternative Flow – Unauthenticated User Taps Like

```
A1. currentUser is null
A2. Show bottom sheet or dialog: l10n.loginRequiredToLike
A3. Option: "Sign In" button → navigate to /login
A4. Like is NOT applied
```

---

## 5. Database Impact

### Collection: `answers`

| Operation | Fields Updated |
|---|---|
| `update` | `likedBy: arrayUnion([userId])` + `likeCount: increment(1)` (like) |
| `update` | `likedBy: arrayRemove([userId])` + `likeCount: increment(-1)` (unlike) |

> **One-like-per-user enforcement (SRS FR-06):** The `likedBy` array stores UIDs. `arrayUnion` is idempotent — calling it twice with the same UID has no effect. This is the client-side enforcement. Firestore Security Rules should also validate this server-side.

> **Note:** `likeCount` is a denormalized cache. It is NEVER recalculated from the array length — only updated via `FieldValue.increment()`.

---

## 6. Files to Create / Modify

```
lib/app/modules/feed/
├── domain/
│   └── use_cases/toggle_like.dart                  [CREATE]
├── data/
│   └── datasources/feed_datasource.dart            [MODIFY] add toggleLike()
└── presentation/
    ├── widgets/
    │   └── like_button.dart                        [CREATE] animated like button
    └── providers/feed_providers.dart               [MODIFY] add toggleLikeNotifier
```

---

## 7. Key Code Contracts

### Use Case: `toggle_like.dart`
```dart
class ToggleLike {
  const ToggleLike(this._repo);
  final IFeedRepository _repo;

  Future<void> call({required String answerId, required String userId}) =>
      _repo.toggleLike(answerId: answerId, userId: userId);
}
```

### Data Source: `feed_datasource.dart`
```dart
Future<void> toggleLike({
  required String answerId,
  required String userId,
}) async {
  final docRef = firestore.collection('answers').doc(answerId);
  final doc = await docRef.get();
  final likedBy = List<String>.from(doc.data()?['likedBy'] ?? []);
  final isLiked = likedBy.contains(userId);

  await docRef.update({
    'likedBy': isLiked
        ? FieldValue.arrayRemove([userId])
        : FieldValue.arrayUnion([userId]),
    'likeCount': FieldValue.increment(isLiked ? -1 : 1),
  });
}
```

### LikeButton Widget (with flutter_animate)
```dart
class LikeButton extends ConsumerWidget {
  const LikeButton({super.key, required this.answerId, required this.likeCount, required this.likedBy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;
    final isLiked = uid != null && likedBy.contains(uid);

    return GestureDetector(
      onTap: () {
        if (uid == null) { /* show login prompt */ return; }
        ref.read(toggleLikeNotifierProvider.notifier).toggle(answerId, uid);
      },
      child: Row(children: [
        Icon(isLiked ? Icons.favorite : Icons.favorite_border,
             color: isLiked ? AppColors.like : AppColors.textSecondary)
            .animate(target: isLiked ? 1 : 0)
            .scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 150.ms)
            .then()
            .scale(begin: const Offset(1.3, 1.3), end: const Offset(1, 1), duration: 100.ms),
        const SizedBox(width: 4),
        Text('$likeCount'),
      ]),
    );
  }
}
```

---

## 8. Firestore Security Rule

```javascript
match /answers/{answerId} {
  // Like/unlike: only update likedBy and likeCount
  allow update: if request.auth != null
    && request.resource.data.diff(resource.data).affectedKeys()
         .hasOnly(['likedBy', 'likeCount']);
}
```

---

## 9. Acceptance Criteria (from SRS FR-06)

- [ ] Unauthenticated user taps like → login prompt shown, no Firestore write
- [ ] Like: `arrayUnion([uid])` + `increment(1)` in single `update()` call
- [ ] Unlike: `arrayRemove([uid])` + `increment(-1)` in single `update()` call
- [ ] Tapping like twice → no net change (idempotent via arrayUnion)
- [ ] Like icon: filled red when `likedBy.contains(currentUser.uid)`, outline otherwise
- [ ] likeCount display updates immediately (optimistic UI)
- [ ] On write failure: optimistic update reverted
- [ ] Like button has bounce animation (flutter_animate)
