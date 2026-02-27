# UC-4.1 – View Public Feed

> **Module:** Feed & Interaction
> **SRS Reference:** FR-05, NFR-02 (Performance)
> **Actor:** Viewer (Guest and Logged-in)
> **Priority:** High

---

## 1. Pre-conditions

- User opens the app (no login required)
- At least one published answer exists in Firestore

## 2. Main Flow

```
1. FeedScreen is the initial route /
2. feedProvider loads first page of data:
   - Query: answers where isPublished == true, orderBy createdAt desc, limit 20
3. For each answer, also fetch the corresponding question content and host user info
   (either via separate query or denormalized into FeedItem)
4. Display FeedItemCard for each item:
   - Host avatar + display name (tap → navigate to /u/:userId)
   - Question content (anonymous badge shown)
   - Answer content
   - Like count (likeCount field) + Like button (filled if currentUser liked it)
   - Comment count (commentCount field) + Comment button
   - "..." more menu (Report option → UC-5.1)
5. User scrolls to bottom of list → load next page (cursor pagination):
   - query.startAfterDocument(lastDocument), limit 20
   - Append new items to list
6. Pull-to-refresh → re-fetch from beginning
```

## 3. Alternative Flow – Empty Feed

```
A1. No published answers exist
A2. Display EmptyState: illustration + l10n.feedEmpty
```

## 4. Alternative Flow – Network Error

```
B1. Firestore query fails → AsyncError
B2. Display ErrorState with retry button
B3. Retry → re-fetch
```

---

## 5. Database Impact

### Collection: `answers`

| Operation | Condition |
|---|---|
| `query` | `where('isPublished', isEqualTo: true)`, `orderBy('createdAt', descending: true)`, `limit(20)` |
| Pagination | `startAfterDocument(lastDoc)` |

### Collection: `questions` (for question content per feed item)

| Operation | Description |
|---|---|
| `get questions/{questionId}` | Per answer, fetch the question text |

### Collection: `users` (for host info per feed item)

| Operation | Description |
|---|---|
| `get users/{userId}` | Per answer, fetch host name and avatar |

> **Performance note (SRS NFR-02):** Consider denormalizing `questionContent`, `hostName`, `hostAvatar` into the `answers` document at write-time (UC-3.3) to reduce reads per feed item from 3 to 1.

---

## 6. Files to Create / Modify

```
lib/app/modules/feed/
├── domain/
│   ├── entities/
│   │   ├── feed_item.dart                           [CREATE] @freezed
│   │   └── comment.dart                             [CREATE] @freezed
│   ├── repositories/i_feed_repository.dart          [CREATE]
│   └── use_cases/get_public_feed.dart               [CREATE]
├── data/
│   ├── datasources/feed_datasource.dart             [CREATE]
│   ├── models/
│   │   ├── feed_item_model.dart                     [CREATE] @freezed
│   │   └── comment_model.dart                       [CREATE] @freezed
│   └── repositories/feed_repository_impl.dart       [CREATE]
└── presentation/
    ├── screens/feed_screen.dart                     [CREATE]
    ├── widgets/
    │   ├── feed_item_card.dart                      [CREATE]
    │   └── feed_loading_shimmer.dart                [CREATE]
    └── providers/feed_providers.dart                [CREATE]
```

---

## 7. Key Code Contracts

### Entity: `feed_item.dart`
```dart
@freezed
class FeedItem with _$FeedItem {
  const factory FeedItem({
    required String answerId,
    required String questionId,
    required String questionContent,
    required String answerContent,
    required String hostUserId,
    required String hostName,
    required String hostAvatar,
    required DateTime createdAt,
    required int likeCount,
    required List<String> likedBy,
    required int commentCount,
    required bool isPublished,
  }) = _FeedItem;
}
```

### Cursor Pagination State
```dart
@freezed
class FeedState with _$FeedState {
  const factory FeedState({
    @Default([]) List<FeedItem> items,
    @Default(false) bool isLoadingMore,
    @Default(false) bool hasReachedEnd,
    DocumentSnapshot? lastDocument,
  }) = _FeedState;
}
```

### Provider
```dart
@riverpod
class FeedNotifier extends _$FeedNotifier {
  @override
  Future<FeedState> build() async {
    final items = await ref.read(getPublicFeedProvider).call(lastDoc: null);
    return FeedState(items: items.items, lastDocument: items.lastDoc);
  }

  Future<void> loadMore() async { ... }
  Future<void> refresh() async { state = await AsyncValue.guard(() => build()); }
}
```

### FeedScreen pagination trigger
```dart
// In FeedScreen build():
NotificationListener<ScrollNotification>(
  onNotification: (notification) {
    if (notification is ScrollEndNotification &&
        notification.metrics.extentAfter < 200) {
      ref.read(feedNotifierProvider.notifier).loadMore();
    }
    return false;
  },
  child: ListView.builder(...),
)
```

---

## 8. FeedItemCard Layout Spec

```
┌─────────────────────────────────────────┐
│  [Avatar] HostName          [•••]       │
│           @humg.edu.vn                  │
├─────────────────────────────────────────┤
│  [?] QUESTION                           │
│  "What is your major?"                  │
├─────────────────────────────────────────┤
│  ANSWER                                 │
│  "I study Computer Science at HUMG..."  │
├─────────────────────────────────────────┤
│  [♥ 24]    [💬 8]          2h ago      │
└─────────────────────────────────────────┘
```

---

## 9. Firestore Composite Index Required

```
Collection: answers
Fields: isPublished (ASC), createdAt (DESC)
```

---

## 10. Acceptance Criteria (from SRS FR-05, NFR-02)

- [ ] Only answers with `isPublished == true` shown
- [ ] Sorted by `createdAt` descending (newest first)
- [ ] First page loads 20 items max
- [ ] Scrolling to bottom loads next 20 (cursor pagination, no duplicate items)
- [ ] Pull-to-refresh resets feed from beginning
- [ ] FeedItemCard shows: host avatar, host name, question content, answer content, likeCount, commentCount
- [ ] Unauthenticated users (Guest Viewer) CAN view the Feed
- [ ] LoadingShimmer shown on initial load
- [ ] EmptyState shown when no published answers exist
- [ ] Response time < 2 seconds (SRS NFR-02)
