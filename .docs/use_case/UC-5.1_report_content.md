# UC-5.1 – Report Inappropriate Content

> **Module:** Moderation
> **SRS Reference:** FR-08, FR-09
> **Actor:** Logged-in Viewer / Host
> **Priority:** Medium

---

## 1. Pre-conditions

- User is logged in
- User is viewing a FeedItemCard (answer) or a CommentTile (comment)

## 2. Main Flow

```
1. User taps "..." (3-dot menu) on a FeedItemCard or CommentTile
2. A ContextMenu or BottomSheet appears with action: "Report"
3. User taps "Report"
4. ReportReasonSheet (bottom sheet) appears with reason options:
   - Inappropriate language
   - Spam
   - Misinformation
   - Other
5. User selects a reason
6. User taps "Submit Report"
7. System creates a new document in reports collection:
   { targetId, targetType, reportedBy, reason, status: 'pending', createdAt }
8. On success:
   - Sheet dismisses
   - Show snackbar: l10n.reportSubmitted
9. Report is now visible to Admin in UC-5.2
```

## 3. Alternative Flow A – Already Reported

```
A1. Optionally check if reports already contains a doc where
    reportedBy == currentUser.uid && targetId == targetId
A2. If found: show info message l10n.alreadyReported
A3. Do NOT create a duplicate report
```

## 4. Alternative Flow B – Network Error

```
B1. FirebaseException during Firestore write
B2. Mapped to FirestoreFailure
B3. Show error snackbar + log via logger.e()
```

---

## 5. Database Impact

### Collection: `reports`

| Operation | Fields Written |
|---|---|
| `add` | `targetId`, `targetType` ('answer' or 'comment'), `reportedBy: currentUser.uid`, `reason`, `status: 'pending'`, `createdAt: serverTimestamp()`, `resolvedAt: null` |

```dart
await firestore.collection('reports').add({
  'targetId': targetId,
  'targetType': targetType, // 'answer' | 'comment'
  'reportedBy': currentUser.uid,
  'reason': reason, // 'inappropriate_language' | 'spam' | 'misinformation' | 'other'
  'status': 'pending',
  'createdAt': FieldValue.serverTimestamp(),
  'resolvedAt': null,
});
```

---

## 6. Files to Create / Modify

```
lib/app/modules/moderation/
├── domain/
│   ├── entities/report.dart                        [CREATE] @freezed
│   ├── repositories/i_moderation_repository.dart   [CREATE]
│   └── use_cases/submit_report.dart                [CREATE]
├── data/
│   ├── datasources/moderation_datasource.dart      [CREATE]
│   ├── models/report_model.dart                    [CREATE] @freezed
│   └── repositories/moderation_repository_impl.dart [CREATE]
└── presentation/
    ├── widgets/
    │   └── report_reason_sheet.dart                [CREATE] bottom sheet
    └── providers/moderation_providers.dart         [CREATE]

lib/app/modules/feed/presentation/widgets/
    └── feed_item_card.dart                         [MODIFY] add "..." menu → report action
```

---

## 7. Key Code Contracts

### Entity: `report.dart`
```dart
@freezed
class Report with _$Report {
  const factory Report({
    required String reportId,
    required String targetId,
    required String targetType,   // 'answer' | 'comment'
    required String reportedBy,
    required String reason,
    required String status,       // 'pending' | 'resolved_removed' | 'resolved_dismissed'
    required DateTime createdAt,
    DateTime? resolvedAt,
  }) = _Report;
}
```

### Use Case: `submit_report.dart`
```dart
class SubmitReport {
  const SubmitReport(this._repo);
  final IModerationRepository _repo;

  Future<void> call({
    required String targetId,
    required String targetType,
    required String reportedBy,
    required String reason,
  }) => _repo.submitReport(
    targetId: targetId,
    targetType: targetType,
    reportedBy: reportedBy,
    reason: reason,
  );
}
```

### Provider
```dart
@riverpod
class ReportNotifier extends _$ReportNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> submit({
    required String targetId,
    required String targetType,
    required String reason,
  }) async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
        ref.read(submitReportProvider).call(
          targetId: targetId,
          targetType: targetType,
          reportedBy: uid,
          reason: reason,
        ),
    );
  }
}
```

---

## 8. ReportReasonSheet Layout Spec

```
Bottom Sheet: "Report Content"
┌────────────────────────────────────┐
│  Why are you reporting this?       │
│                                    │
│  ○ Inappropriate language          │
│  ○ Spam                            │
│  ○ Misinformation                  │
│  ○ Other                           │
│                                    │
│  [        Submit Report         ]  │
│  [           Cancel             ]  │
└────────────────────────────────────┘
```

---

## 9. Firestore Security Rule

```javascript
match /reports/{reportId} {
  // Only authenticated users can create reports
  allow create: if request.auth != null
    && request.resource.data.reportedBy == request.auth.uid
    && request.resource.data.status == 'pending';
  // Only admins can read/update reports
  allow read, update: if request.auth.token.admin == true;
}
```

---

## 10. Acceptance Criteria (from SRS FR-08)

- [ ] Unauthenticated user cannot access report action (hidden or prompts login)
- [ ] Report document created with correct `targetType` ('answer' or 'comment')
- [ ] `status` is always `'pending'` on creation
- [ ] `reportedBy` matches `currentUser.uid` — cannot spoof
- [ ] Reason must be one of the 4 valid values
- [ ] Success snackbar shown after submit
- [ ] No duplicate UI blocking (can report multiple times, de-dup is optional)
