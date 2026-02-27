# UC-3.3 – Answer Question & Publish to Feed

> **Module:** Core Q&A
> **SRS Reference:** FR-04
> **Actor:** Host
> **Priority:** Critical

---

## 1. Pre-conditions

- User is logged in as Host
- User is on AnswerComposeScreen (`/inbox/answer/:questionId`)
- The `questionId` belongs to a question with `status == 'unanswered'`

## 2. Main Flow

```
1. AnswerComposeScreen loads, displaying the original question content
2. Host types their answer in the text input (no character limit enforced, but recommend < 1000 chars)
3. Host toggles "Publish to Feed" switch (isPublished, default: true)
4. Host taps "Submit Answer"
5. Client validates: answer content is not empty
6. System performs a Batch Write (MANDATORY):
   a. answers collection: SET new document with fields:
      { questionId, userId: currentUser.uid, content, isPublished,
        likedBy: [], likeCount: 0, commentCount: 0, createdAt: serverTimestamp() }
   b. questions collection: UPDATE document {questionId}:
      { status: 'answered' }
7. Both writes commit atomically
8. On success:
   a. Navigate back to /inbox
   b. Show snackbar: l10n.answerPublished (if isPublished) or l10n.answerSaved
9. If isPublished == true: answer appears on public Feed (UC-4.1)
```

## 3. Alternative Flow A – Empty Answer

```
A1. Host taps Submit with empty text field
A2. Show inline validation error: l10n.errorAnswerEmpty
A3. Do NOT call Firestore
```

## 4. Alternative Flow B – Batch Write Failure

```
B1. FirebaseException thrown during batch.commit()
B2. NEITHER document is written (atomic guarantee)
B3. Mapped to FirestoreFailure
B4. Show error snackbar + log via logger.e()
B5. Host can retry
```

---

## 5. Database Impact

### MANDATORY: WriteBatch (both operations in one commit)

```dart
final batch = firestore.batch();

// Operation 1: Create new answer document
final answerRef = firestore.collection('answers').doc();
batch.set(answerRef, {
  'questionId': questionId,
  'userId': currentUser.uid,
  'content': content,
  'isPublished': isPublished,
  'likedBy': [],
  'likeCount': 0,
  'commentCount': 0,
  'createdAt': FieldValue.serverTimestamp(),
});

// Operation 2: Update question status
final questionRef = firestore.collection('questions').doc(questionId);
batch.update(questionRef, {'status': 'answered'});

// Commit atomically
await batch.commit();
```

### Collection: `answers`

| Field | Value |
|---|---|
| `questionId` | param from route |
| `userId` | `FirebaseAuth.currentUser!.uid` |
| `content` | host's typed answer |
| `isPublished` | `true` or `false` (toggle) |
| `likedBy` | `[]` (empty array) |
| `likeCount` | `0` |
| `commentCount` | `0` |
| `createdAt` | `FieldValue.serverTimestamp()` |

### Collection: `questions`

| Field | Value |
|---|---|
| `status` | `'answered'` |

---

## 6. Files to Create / Modify

```
lib/app/modules/qna_core/
├── domain/
│   └── use_cases/answer_question.dart               [CREATE]
├── data/
│   └── datasources/qna_datasource.dart              [MODIFY] add answerQuestion()
└── presentation/
    ├── screens/answer_compose_screen.dart            [CREATE]
    ├── widgets/
    │   └── answer_publish_toggle.dart               [CREATE]
    └── providers/qna_providers.dart                 [MODIFY] add answerNotifier

lib/config/router.dart                               [MODIFY] ensure /inbox/answer/:questionId route
```

---

## 7. Key Code Contracts

### Entity: `answer.dart`
```dart
@freezed
class Answer with _$Answer {
  const factory Answer({
    required String answerId,
    required String questionId,
    required String userId,
    required String content,
    required DateTime createdAt,
    @Default(0) int likeCount,
    @Default([]) List<String> likedBy,
    @Default(true) bool isPublished,
    @Default(0) int commentCount,
  }) = _Answer;
}
```

### Use Case: `answer_question.dart`
```dart
class AnswerQuestion {
  const AnswerQuestion(this._repo);
  final IQnaRepository _repo;

  Future<void> call({
    required String questionId,
    required String userId,
    required String content,
    required bool isPublished,
  }) => _repo.answerQuestion(
    questionId: questionId,
    userId: userId,
    content: content,
    isPublished: isPublished,
  );
}
```

### Provider
```dart
@riverpod
class AnswerNotifier extends _$AnswerNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> submit({
    required String questionId,
    required String content,
    required bool isPublished,
  }) async {
    state = const AsyncLoading();
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) {
      state = AsyncError(AuthFailure.unauthenticated(), StackTrace.current);
      return;
    }
    state = await AsyncValue.guard(() =>
        ref.read(answerQuestionProvider).call(
          questionId: questionId,
          userId: uid,
          content: content,
          isPublished: isPublished,
        ),
    );
  }
}
```

---

## 8. AnswerComposeScreen Layout Spec

```
AppBar: "Reply"  [← back]
┌─────────────────────────────────────┐
│  QUESTION                           │
│  ┌───────────────────────────────┐  │
│  │ "What is your major?"         │  │
│  │ Received 2 hours ago          │  │
│  └───────────────────────────────┘  │
│                                     │
│  YOUR ANSWER                        │
│  ┌───────────────────────────────┐  │
│  │ TextField (multiline)         │  │
│  │                               │  │
│  └───────────────────────────────┘  │
│                                     │
│  Publish to Feed        [  Toggle ] │
│                                     │
│  [        Submit Answer          ]  │
└─────────────────────────────────────┘
```

---

## 9. Acceptance Criteria (from SRS FR-04)

- [ ] WriteBatch is ALWAYS used — never two separate writes
- [ ] If batch fails, NEITHER `answers` nor `questions` is modified
- [ ] `answers` document created with `likeCount: 0`, `likedBy: []`, `commentCount: 0`
- [ ] `questions` document updated: `status → 'answered'`
- [ ] Question disappears from "Unanswered" tab and appears in "Answered" tab after submit
- [ ] If `isPublished == true`, answer is visible on Feed (UC-4.1 query will pick it up)
- [ ] Empty answer → submit blocked with inline error
- [ ] Success → navigate back to inbox with snackbar confirmation
