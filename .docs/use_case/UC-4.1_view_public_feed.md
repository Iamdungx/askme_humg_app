# UC-4.1 – View Public Feed

> **Module:** Feed & Interaction
> **SRS Reference:** FR-05, NFR-02 (Performance)
> **Actor:** Viewer (Guest and Logged-in)
> **Priority:** High

---

## 1. Pre-conditions

- User opens the app (no login required)
- At least one published answer exists in Firestore

## 2. Feed ordering & filters (SRS FR-05)

**Implemented:**
- **Default sort (trending):** `isPublished == true`, **`orderBy('hotScore', descending: true)`** — denormalized score (engagement + time decay; see `answer_hot_score.dart`).
- **Fallback:** If Firestore reports a missing/building index for `hotScore`, or another query failure for trending, the client may retry with **`orderBy('createdAt', descending: true)`** so the feed stays usable (see `firebase_feed_datasource.getPublicFeed`).
- **Pagination:** `limit(20)`, cursor via `startAfterDocument(lastDoc)` where `lastDoc` is the previous page’s answer document id.
- **Optional topic filter:** When user selects a main category or tag chip, add `where` on `aiCategory` and/or `array-contains` on `aiTagIds` (composite indexes in `firestore.indexes.json`; may fall back to unfiltered feed while indexes build).
- **UI:** No segmented control for “Newest vs Trending” — the home feed is **trending-only** by product decision.

## 3. Main Flow

```
1. FeedScreen is the initial route /
2. feedProvider loads first page of data:
   - Query: answers where isPublished == true, orderBy hotScore desc (fallback: createdAt desc), limit 20
   - (Optional) AND topic predicates when a category/tag is selected
3. Question text and host info are read from fields **denormalized on `answers`** (`questionContent`, `hostName`, `hostAvatar`, …) — no per-item extra reads (UC-3.3 / NFR-02).
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

## 4. Alternative Flow – Empty Feed

```
A1. No published answers exist
A2. Display EmptyState: illustration + l10n.feedEmpty
```

## 5. Alternative Flow – Network Error

```
B1. Firestore query fails → AsyncError
B2. Display ErrorState with retry button
B3. Retry → re-fetch
```

---

## 6. Database Impact

### Collection: `answers`

| Operation | Condition |
|---|---|
| `query` | `where('isPublished', isEqualTo: true)`, **`orderBy('hotScore', descending: true)`** (default); optional `where` on `aiCategory` / `aiTagIds` |
| Pagination | `startAfterDocument(lastDoc)` |
| Fallback | `orderBy('createdAt', descending: true)` when trending query/index unavailable |

### Collection: `questions` / `users`

Not required for each feed row when UC-3.3 denormalizes `questionContent`, `hostName`, `hostAvatar`, `hostIsHumgVerified` onto `answers`.

---

## 7. Files to Create / Modify

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

## 8. Key Code Contracts

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

## 9. FeedItemCard Layout Spec

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

## 10. Firestore Composite Indexes

Align with `firestore.indexes.json`, including:

- `isPublished` + `hotScore` (default feed)
- `isPublished` + `createdAt` (fallback / profile “recent answers”)
- Topic filter variants: `aiCategory` or `aiTagIds` with `hotScore` or `createdAt` as ordered field

---

## 11. Acceptance Criteria (from SRS FR-05, NFR-02)

- [ ] Only answers with `isPublished == true` shown
- [ ] Sorted by `hotScore` descending by default (trending); graceful fallback to `createdAt` when needed
- [ ] First page loads 20 items max
- [ ] Scrolling to bottom loads next 20 (cursor pagination, no duplicate items)
- [ ] Pull-to-refresh resets feed from beginning
- [ ] FeedItemCard shows: host avatar, host name, question content, answer content, likeCount, commentCount
- [ ] Unauthenticated users (Guest Viewer) CAN view the Feed — read-only
- [ ] Authenticated but unverified users CAN view the Feed — read-only (like/comment blocked)
- [ ] HUMG-verified users can like and comment
- [ ] `VerifiedBadge` displayed next to host name when `hostIsHumgVerified == true`
- [ ] LoadingShimmer shown on initial load
- [ ] EmptyState shown when no published answers exist
- [ ] Response time < 2 seconds (SRS NFR-02)
- [ ] (Optional) Topic chip filter narrows results when AI labels exist; unfiltered feed still works if indexes missing (graceful fallback)
