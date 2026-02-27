# UC-4.3 – Comment on an Answer

> **Module:** Feed & Interaction
> **SRS Reference:** FR-07
> **Actor:** Logged-in Viewer / Host
> **Priority:** Medium

---

## 1. Pre-conditions

- User is logged in
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
8. System performs a Batch Write (MANDATORY):
   a. comments collection: ADD new document:
      { answerId, userId (null if anonymous), content, isAnonymous, createdAt: serverTimestamp() }
   b. answers collection: UPDATE answers/{answerId}:
      { commentCount: FieldValue.increment(1) }
9. On success:
   - New comment appears at bottom of list
   - CommentInputBar clears
10. On failure: show error snackbar, batch rolled back
```

## 3. Alternative Flow A – Unauthenticated User Taps Comment

```
A1. currentUser is null
A2. Show bottom sheet/dialog: l10n.loginRequiredToComment
A3. Comment is NOT submitted
```

## 4. Alternative Flow B – Empty Comment

```
B1. User taps Send with empty text
B2. Show inline validation error: l10n.errorCommentEmpty
B3. No Firebase call made
```

---

## 5. Database Impact

### MANDATORY: WriteBatch

```dart
final batch = firestore.batch();

// Operation 1: Create new comment document
final commentRef = firestore.collection('comments').doc();
batch.set(commentRef, {
  'answerId': answerId,
  'userId': isAnonymous ? null : currentUser.uid,
  'content': content,
  'isAnonymous': isAnonymous,
  'createdAt': FieldValue.serverTimestamp(),
});

// Operation 2: Increment commentCount on the answer
final answerRef = firestore.collection('answers').doc(answerId);
batch.update(answerRef, {
  'commentCount': FieldValue.increment(1),
});

await batch.commit();
```

### Collection: `comments`

| Field | Value |
|---|---|
| `answerId` | ID of the parent answer |
| `userId` | `currentUser.uid` or `null` (if anonymous) |
| `content` | comment text |
| `isAnonymous` | `true` or `false` |
| `createdAt` | `FieldValue.serverTimestamp()` |

### Collection: `answers`

| Field | Value |
|---|---|
| `commentCount` | `FieldValue.increment(1)` |

---

## 6. Files to Create / Modify

```
lib/app/modules/feed/
├── domain/
│   ├── entities/comment.dart                       [CREATE] @freezed
│   └── use_cases/post_comment.dart                 [CREATE]
├── data/
│   ├── datasources/feed_datasource.dart            [MODIFY] add getComments(), postComment()
│   └── models/comment_model.dart                   [CREATE] @freezed
└── presentation/
    ├── screens/comments_screen.dart                [CREATE] bottom sheet or full screen
    ├── widgets/
    │   ├── comment_tile.dart                       [CREATE]
    │   └── comment_input_bar.dart                  [CREATE]
    └── providers/feed_providers.dart               [MODIFY] add commentsProvider, postCommentNotifier
```

---

## 7. Key Code Contracts

### Entity: `comment.dart`
```dart
@freezed
class Comment with _$Comment {
  const factory Comment({
    required String commentId,
    required String answerId,
    String? userId,           // null if anonymous
    required String content,
    required bool isAnonymous,
    required DateTime createdAt,
  }) = _Comment;
}
```

### Use Case: `post_comment.dart`
```dart
class PostComment {
  const PostComment(this._repo);
  final IFeedRepository _repo;

  Future<void> call({
    required String answerId,
    required String? userId,
    required String content,
    required bool isAnonymous,
  }) => _repo.postComment(
    answerId: answerId,
    userId: userId,
    content: content,
    isAnonymous: isAnonymous,
  );
}
```

### Comments Provider
```dart
@riverpod
Stream<List<Comment>> comments(CommentsRef ref, String answerId) {
  return ref.read(feedDatasourceProvider)
      .getComments(answerId)
      .map((snap) => snap.docs
          .map((d) => CommentModel.fromFirestore(d).toDomain())
          .toList());
}
```

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

- [ ] Unauthenticated user taps comment → login prompt, no write
- [ ] WriteBatch ALWAYS used — `comments` add + `answers.commentCount` increment in one commit
- [ ] If batch fails, NEITHER write is applied
- [ ] `isAnonymous: true` → `userId` stored as `null` in Firestore
- [ ] `isAnonymous: false` → `userId` stores `currentUser.uid`
- [ ] Anonymous comment displays generic avatar + "Anonymous" label in UI
- [ ] Non-anonymous comment displays user's real name + avatar
- [ ] commentCount on FeedItemCard updates after successful comment
- [ ] Empty comment → submit blocked with inline error
