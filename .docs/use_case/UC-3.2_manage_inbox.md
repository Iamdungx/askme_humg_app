# UC-3.2 – Manage Inbox

> **Module:** Core Q&A
> **SRS Reference:** FR-03
> **Actor:** Host
> **Priority:** High

---

## 1. Pre-conditions

- User is logged in as Host
- User navigates to `/inbox`

## 2. Main Flow

```
1. InboxScreen loads with two tabs: "Unanswered" | "Answered"
2. inboxProvider streams questions from Firestore:
   - Query: questions where toUserId == currentUser.uid, orderBy createdAt desc
3. Questions are split into two lists:
   - Tab 0 "Unanswered": status == 'unanswered'
   - Tab 1 "Answered":   status == 'answered'
4. Each QuestionCard displays:
   - Question content (truncated if > 2 lines)
   - Time ago (timeago package)
   - Status badge
5. On "Unanswered" tab: each card has "Reply" action button
   → Tapping "Reply" navigates to /inbox/answer/:questionId (UC-3.3)
6. On any card: long-press or swipe → "Delete" action
   → Calls deleteQuestion(questionId) → removes document from Firestore
7. Real-time updates: stream auto-refreshes when new questions arrive
```

## 3. Alternative Flow – Empty Inbox

```
A1. No questions returned by query
A2. Display EmptyState widget:
   - Tab "Unanswered": illustration + l10n.inboxEmptyUnanswered
   - Tab "Answered":   illustration + l10n.inboxEmptyAnswered
```

## 4. Alternative Flow – Network Error

```
B1. Stream emits error → AsyncError state
B2. Display ErrorState with retry button
```

---

## 5. Database Impact

### Collection: `questions`

| Operation | Description |
|---|---|
| `stream` query | `where('toUserId', isEqualTo: uid)`, `orderBy('createdAt', descending: true)` |
| `delete` (optional) | Host can delete a question they don't want to answer |

> **Firestore Index required:** Composite index on `questions(toUserId ASC, createdAt DESC)`

---

## 6. Files to Create / Modify

```
lib/app/modules/qna_core/
├── domain/
│   └── use_cases/get_inbox_questions.dart           [CREATE]
├── data/
│   └── datasources/qna_datasource.dart              [MODIFY] add getInboxQuestions stream
└── presentation/
    ├── screens/inbox_screen.dart                    [CREATE]
    ├── widgets/
    │   ├── question_card.dart                       [CREATE]
    │   └── inbox_tab_bar.dart                       [CREATE]
    └── providers/qna_providers.dart                 [MODIFY] add inboxProvider
```

---

## 7. Key Code Contracts

### Use Case: `get_inbox_questions.dart`
```dart
class GetInboxQuestions {
  const GetInboxQuestions(this._repo);
  final IQnaRepository _repo;

  Stream<List<Question>> call(String userId) =>
      _repo.getInboxQuestions(userId);
}
```

### Data Source query
```dart
Stream<List<Question>> getInboxQuestions(String userId) {
  return firestore
      .collection('questions')
      .where('toUserId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => QuestionModel.fromFirestore(d).toDomain())
          .toList());
}
```

### Provider
```dart
@riverpod
Stream<List<Question>> inbox(InboxRef ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value([]);
  return ref.read(getInboxQuestionsProvider).call(uid);
}
```

### InboxScreen tab split
```dart
// Split the stream list into two lists by status
final unanswered = questions.where((q) => q.status == 'unanswered').toList();
final answered   = questions.where((q) => q.status == 'answered').toList();
```

---

## 8. InboxScreen Layout Spec

```
AppBar: "Inbox"  [optional filter icon]
┌──────────────────────────────────┐
│  Unanswered (12)  │  Answered   │  ← TabBar
├──────────────────────────────────┤
│ ┌────────────────────────────┐  │
│ │ "What is your major?"      │  │
│ │ 2 hours ago                │  │
│ │            [Reply] [Delete]│  │
│ └────────────────────────────┘  │
│ ┌────────────────────────────┐  │
│ │ ...more cards...           │  │
│ └────────────────────────────┘  │
└──────────────────────────────────┘
```

---

## 9. Acceptance Criteria (from SRS FR-03)

- [ ] Only questions where `toUserId == currentUser.uid` are shown
- [ ] Two tabs: Unanswered and Answered, with correct counts
- [ ] New question received via Firestore stream → appears immediately (real-time)
- [ ] Question card shows content, timestamp (timeago), status
- [ ] Tapping "Reply" on unanswered card → navigates to answer compose screen
- [ ] Empty state shown per tab when no questions exist
- [ ] Route `/inbox` is protected (requires login, redirects to `/login` if not authenticated)
