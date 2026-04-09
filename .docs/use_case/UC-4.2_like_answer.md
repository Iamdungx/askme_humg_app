# UC-4.2 – Like / Unlike an Answer

> **Module:** Feed & Interaction
> **SRS Reference:** FR-06
> **Actor:** Logged-in Viewer / Host
> **Priority:** Medium

---

## 1. Pre-conditions

- User is logged in (like requires authentication)
- User is **`isHumgVerified == true`** (in-app guard; unverified users see `verifyRequiredToLike`)
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
4. System calls toggleLike(answerId, userId, isCurrentlyLiked) → Firestore **runTransaction**:
   - Read answers/{answerId}
   - Build new likedBy list (add uid if not liked on server)
   - Set likeCount == newLikedBy.length
   - If createdAt exists: set hotScore = computeAnswerHotScore(likeCount, commentCount, createdAt)
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
4. Same toggleLike → transaction removes uid from likedBy, syncs likeCount and hotScore
5. On success: confirmed
6. On failure: revert optimistic update
```

## 4. Alternative Flow A – Unauthenticated User Taps Like

```
A1. currentUser is null
A2. Show snackbar: l10n.loginRequiredToLike
A3. Like is NOT applied
```

## 4b. Alternative Flow B – Authenticated but Unverified User Taps Like

```
B1. currentUser != null BUT isHumgVerified == false
B2. Show snackbar: l10n.verifyRequiredToLike
B3. Like is NOT applied
B4. User can navigate to /settings → HUMG Verification to verify
```

---

## 5. Database Impact

### Collection: `answers`

| Operation | Fields Updated |
|---|---|
| `runTransaction` + `update` | `likedBy` (full list), `likeCount` (equals `likedBy.length`), `hotScore` (when `createdAt` is set) |

> **One-like-per-user enforcement (SRS FR-06):** The `likedBy` array stores UIDs. The transaction reads the current array, toggles membership, and writes the new list — concurrent toggles stay consistent.

> **Note:** `likeCount` is kept **equal** to `likedBy.length` in the same write. `hotScore` is recomputed from engagement + time decay (`computeAnswerHotScore` in `answer_hot_score.dart`).

**Implementation:** `lib/app/modules/feed/data/firebase_feed_datasource.dart` → `toggleLike`.

---

## 6. Files to Create / Modify

```
lib/app/modules/feed/
├── domain/
│   └── use_cases/toggle_like.dart
├── data/
│   └── datasources/firebase_feed_datasource.dart   # toggleLike (transaction)
└── presentation/
    ├── widgets/like_button.dart
    └── providers/feed_providers.dart               # ToggleLikeNotifier
```

---

## 7. Key Code Contracts

### Use Case: `toggle_like.dart`

Delegates to `IFeedRepository.toggleLike` → datasource `toggleLike`.

### Data source (conceptual)

Use `FirebaseFirestore.runTransaction`: read answer, mutate `likedBy`, set `likeCount`, optionally `hotScore`. Do **not** use `arrayUnion` + `increment` alone — they can drift if data was inconsistent.

---

## 8. Firestore Security Rule

Like/unlike updates must allow `likedBy`, `likeCount`, and `hotScore`:

```javascript
match /answers/{answerId} {
  allow update: if isSignedIn() && (
    // ...
    (request.resource.data.diff(resource.data).affectedKeys()
      .hasOnly(['likeCount', 'likedBy', 'hotScore']))
  );
}
```

(See `firestore.rules` in repo for full `answers` match.)

---

## 9. Acceptance Criteria (from SRS FR-06)

- [ ] Unauthenticated user taps like → snackbar `loginRequiredToLike`, no Firestore write
- [ ] Authenticated but unverified (HUMG) user taps like → snackbar `verifyRequiredToLike`, no Firestore write
- [ ] Like/unlike: **transaction** updates `likedBy`, `likeCount` (synced with array), `hotScore` when applicable
- [ ] Tapping like twice → no net change (server-side list reflects final state)
- [ ] Like icon: filled red when `likedBy.contains(currentUser.uid)`, outline otherwise
- [ ] likeCount display updates immediately (optimistic UI)
- [ ] On write failure: optimistic update reverted
- [ ] Like button uses project styling (e.g. Lucide + `flutter_animate` where applicable)
