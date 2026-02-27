# UC-3.1 – Submit Anonymous Question

> **Module:** Core Q&A
> **SRS Reference:** FR-01, NFR-01 (Anonymity), NFR-03 (Security)
> **Actor:** Anonymous Sender, Host, Viewer (anyone)
> **Priority:** Critical

---

## 1. Pre-conditions

- User is on a Host's Profile screen (`/u/:userId`)
- The target Host's `userId` is known
- Internet connection is available

## 2. Main Flow

```
1. User taps "Ask me something" → AskQuestionSheet (bottom sheet) appears
2. User types a question (text input, max 300 characters)
3. Character counter updates in real-time (e.g., "247/300")
4. User taps "Send Anonymously"
5. Client validates:
   a. Content length: 1–300 characters (not empty, not over limit)
   b. Basic profanity filter (client-side keyword check)
   → If validation fails: show inline error, do NOT call Firebase
6. System obtains a Firebase App Check token
   → If App Check fails: show error l10n.errorAppCheckFailed
7. System calls Cloud Function `submitQuestion` with:
   { toUserId, content, appCheckToken }
8. Cloud Function enforces:
   a. Rate limit: max 5 questions per device per hour
   b. Server-side profanity filter
   c. Saves document to `questions` collection
9. On success:
   a. Close bottom sheet
   b. Play success animation (lottie confetti or flutter_animate)
   c. Show snackbar: l10n.questionSentSuccess
10. On rate limit exceeded: show error l10n.errorRateLimitExceeded
```

## 3. Alternative Flow A – Validation Error

```
A1. Content is empty → show l10n.errorQuestionEmpty
A2. Content > 300 chars → character counter turns red, send button disabled
A3. Profanity detected → show l10n.errorInappropriateContent
```

## 4. Alternative Flow B – Rate Limit Exceeded

```
B1. Cloud Function returns HTTP 429
B2. Show error: l10n.errorRateLimitExceeded ("You've sent 5 questions this hour. Try again later.")
```

## 5. Alternative Flow C – App Check Failure

```
C1. App Check token cannot be obtained (emulator without debug token)
C2. Cloud Function rejects with HTTP 403
C3. Show error: l10n.errorAppCheckFailed
```

---

## 6. Database Impact

### Collection: `questions`

| Operation | Fields Written |
|---|---|
| `add` (via Cloud Function) | `toUserId`, `content`, `createdAt: serverTimestamp()`, `status: 'unanswered'` |

> **Privacy note (SRS NFR-01):** No sender identity, device ID, or IP address is stored in the `questions` document. App Check token is ephemeral and NOT persisted.

---

## 7. Files to Create / Modify

```
lib/app/modules/qna_core/
├── domain/
│   ├── entities/question.dart                       [CREATE] @freezed
│   ├── repositories/i_qna_repository.dart           [CREATE]
│   └── use_cases/submit_anonymous_question.dart     [CREATE]
├── data/
│   ├── datasources/qna_datasource.dart              [CREATE]
│   ├── models/question_model.dart                   [CREATE] @freezed
│   └── repositories/qna_repository_impl.dart        [CREATE]
└── presentation/
    └── providers/qna_providers.dart                 [CREATE]

lib/app/modules/profile/presentation/widgets/
    └── ask_question_sheet.dart                      [CREATE or MODIFY]

lib/app/core/utils/validator.dart                    [MODIFY] add question validation
lib/app/core/network/firebase_providers.dart         [MODIFY] add AppCheck provider
```

---

## 8. Key Code Contracts

### Entity: `question.dart`
```dart
@freezed
class Question with _$Question {
  const factory Question({
    required String questionId,
    required String toUserId,
    required String content,
    required DateTime createdAt,
    required String status, // 'unanswered' | 'answered'
  }) = _Question;
}
```

### Validation (validator.dart)
```dart
// Returns null if valid, error string if invalid
String? validateQuestion(String content) {
  if (content.trim().isEmpty) return 'Question cannot be empty';
  if (content.length > 300) return 'Maximum 300 characters';
  if (_containsProfanity(content)) return 'Inappropriate content detected';
  return null;
}
```

### Use Case: `submit_anonymous_question.dart`
```dart
class SubmitAnonymousQuestion {
  const SubmitAnonymousQuestion(this._repo);
  final IQnaRepository _repo;

  Future<void> call({required String toUserId, required String content}) =>
      _repo.submitAnonymousQuestion(toUserId: toUserId, content: content);
}
```

### Data Layer – App Check + Cloud Function call
```dart
// In qna_datasource.dart
Future<void> submitAnonymousQuestion({
  required String toUserId,
  required String content,
}) async {
  // Obtain App Check token
  final appCheckToken = await FirebaseAppCheck.instance.getToken(false);

  // Call Cloud Function via Dio
  await _dio.post('/submitQuestion', data: {
    'toUserId': toUserId,
    'content': content,
  }, options: Options(headers: {
    'X-Firebase-AppCheck': appCheckToken,
  }));
}
```

### Provider
```dart
@riverpod
class SubmitQuestionNotifier extends _$SubmitQuestionNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> submit({required String toUserId, required String content}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
        ref.read(submitAnonymousQuestionProvider).call(
          toUserId: toUserId,
          content: content,
        ),
    );
  }
}
```

---

## 9. AskQuestionSheet Widget Spec

```
Bottom sheet layout:
┌─────────────────────────────────┐
│  Ask [HostName] something...    │
│  ┌─────────────────────────┐   │
│  │  TextField (multiline)  │   │
│  │  maxLength: 300         │   │
│  └─────────────────────────┘   │
│            247/300              │
│  [   Send Anonymously   ]       │
│  🔒 Your identity is hidden     │
└─────────────────────────────────┘
```

---

## 10. Acceptance Criteria (from SRS FR-01, NFR-01, NFR-03)

- [ ] Empty question → send button disabled or shows inline error
- [ ] Question > 300 chars → character counter turns red, cannot submit
- [ ] Client profanity check blocks obvious violations before any Firebase call
- [ ] App Check token is attached to every submission request
- [ ] Cloud Function rate limit: 6th question within 1 hour → HTTP 429 → error shown
- [ ] On success: bottom sheet closes, success animation plays
- [ ] No sender identity stored in `questions` collection
- [ ] `status` field is always `'unanswered'` on creation
