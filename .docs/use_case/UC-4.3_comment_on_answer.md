# UC-4.3 – Comment on an Answer

> **Module:** Feed & Interaction
> **SRS Reference:** FR-07
> **Actor:** Logged-in Viewer / Host
> **Priority:** Medium

---

## 1. Pre-conditions

- User is logged in
- User is **`isHumgVerified == true`** (unverified → `verifyRequiredToComment`)
- User is viewing the Feed (FeedScreen)
- The answer exists with `isPublished == true`

## 2. Main Flow

```
1. User taps the Comment icon on a FeedItemCard
2. CommentsScreen (or bottom sheet) opens, showing existing comments for this answer
3. Comments are loaded: query comments where answerId == answerId, orderBy createdAt asc
4. User types comment in the CommentInputBar at the bottom
5. Optionally toggles "Comment anonymously" switch
6. User taps "Send"
7. Client validates: comment not empty, reasonable length (< 500 chars)
8. System performs a **Firestore transaction** (MANDATORY for atomicity + hotScore):
   a. Read answers/{answerId} for current commentCount, likeCount, createdAt
   b. comments collection: set new document with serverTimestamp, denormalized author fields from users/{uid}
   c. answers collection: update commentCount (prev + 1) and hotScore when createdAt exists
9. On success:
   - New comment appears at bottom of list
   - CommentInputBar clears
10. On failure: show error snackbar, no partial write
```

## 3. Alternative Flow A – Unauthenticated User Taps Comment

```
A1. currentUser is null
A2. Show snackbar: l10n.loginRequiredToComment
A3. Comment is NOT submitted
```

## 3b. Alternative Flow B – Authenticated but Unverified User Taps Comment

```
B1. currentUser != null BUT isHumgVerified == false
B2. Show snackbar: l10n.verifyRequiredToComment (both when opening sheet and when tapping Send)
B3. Comment is NOT submitted
B4. User can navigate to /settings → HUMG Verification to verify
```

## 4. Alternative Flow C – Empty Comment

```
C1. User taps Send with empty text
C2. Show inline validation error: l10n.errorCommentEmpty
C3. No Firebase call made
```

---

## 5. Database Impact

### MANDATORY: `runTransaction` (not WriteBatch alone)

`WriteBatch` cannot atomically read-increment `commentCount` under concurrent comments; use a **transaction** so `commentCount` and `hotScore` stay consistent.

```dart
final commentRef = firestore.collection('comments').doc();
await firestore.runTransaction((tx) async {
  final answerSnap = await tx.get(answerRef);
  // ... prevCc, lc, createdAt ...
  tx.set(commentRef, {
    'answerId': answerId,
    'userId': isAnonymous ? null : userId,
    'content': content,
    'isAnonymous': isAnonymous,
    'createdAt': FieldValue.serverTimestamp(),
    'authorName': authorName,
    'authorAvatar': authorAvatar,
    'authorIsHumgVerified': authorIsHumgVerified,
  });
  tx.update(answerRef, {
    'commentCount': newCc,
    if (createdAtTs != null) 'hotScore': computeAnswerHotScore(...),
  });
});
```

**Implementation:** `lib/app/modules/feed/data/firebase_feed_datasource.dart` → `postComment`.

### Collection: `comments`

| Field | Value |
|---|---|
| `answerId` | ID of the parent answer |
| `userId` | `currentUser.uid` or `null` (if anonymous) |
| `content` | comment text |
| `isAnonymous` | `true` or `false` |
| `createdAt` | `FieldValue.serverTimestamp()` |
| `authorName`, `authorAvatar`, `authorIsHumgVerified` | Denormalized from `users` for display (UC-4.3) |

### Collection: `answers`

| Field | Value |
|---|---|
| `commentCount` | Previous count + 1 (in transaction) |
| `hotScore` | Recomputed when `createdAt` present |

---

## 6. Files to Create / Modify

```
lib/app/modules/feed/
├── domain/
│   └── use_cases/post_comment.dart
├── data/
│   └── datasources/firebase_feed_datasource.dart   # postComment (transaction)
└── presentation/
    ├── screens/comments_screen.dart
    ├── widgets/comment_tile.dart, comment_input_bar.dart
    └── providers/feed_providers.dart
```

---

## 7. Key Code Contracts

### Use Case: `post_comment.dart`

Delegates to `IFeedRepository.postComment` → `postComment` on datasource.

---

## 8. CommentsScreen Layout Spec

```
AppBar: "Comments (8)"           [← close]
┌──────────────────────────────────────┐
│ ┌──────────────────────────────────┐ │
│ │ [Avatar] Username    2h ago      │ │
│ │ "Great answer!"                  │ │
│ └──────────────────────────────────┘ │
│ ┌──────────────────────────────────┐ │
│ │ [🕵️] Anonymous    1h ago        │ │
│ │ "I agree with this"              │ │
│ └──────────────────────────────────┘ │
│ ...more comments...                  │
├──────────────────────────────────────┤
│ [Anonymous toggle]  Off/On           │
│ ┌────────────────────────┐ [Send]   │
│ │  Write a comment...    │          │
│ └────────────────────────┘          │
└──────────────────────────────────────┘
```

---

## 9. Acceptance Criteria (from SRS FR-07)

- [ ] Unauthenticated user taps comment → snackbar `loginRequiredToComment`, no write
- [ ] Authenticated but unverified user taps comment → snackbar `verifyRequiredToComment`, no write (checked when opening sheet and when tapping Send)
- [ ] **Transaction** used — new `comments` doc + `answers.commentCount` / `hotScore` update commit together
- [ ] If transaction fails, neither write is applied
- [ ] `isAnonymous: true` → `userId` stored as `null` in Firestore
- [ ] `isAnonymous: false` → `userId` stores `currentUser.uid`
- [ ] Anonymous comment displays generic avatar + "Anonymous" label in UI
- [ ] Non-anonymous comment displays user's real name + avatar
- [ ] commentCount on FeedItemCard updates after successful comment
- [ ] Empty comment → submit blocked with inline error
