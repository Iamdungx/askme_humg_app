# UC-5.2 – Admin: Manage Reports (Content Moderation)

> **Module:** Moderation
> **SRS Reference:** FR-09
> **Actor:** Admin
> **Priority:** Medium

---

## 1. Pre-conditions

- User is logged in with Admin privileges:
  - `users/{uid}.role == 'admin'` in Firestore, OR
  - Firebase Custom Claim: `admin: true` (preferred for Security Rules)
- User navigates to `/admin`

## 2. Main Flow

```
1. AdminDashboardScreen loads
2. Admin role is verified client-side (router guard checks claim/role)
3. reportsProvider streams reports where status == 'pending', orderBy createdAt desc
4. Each ReportCard displays:
   - Reported content preview (answer or comment text)
   - Report reason
   - Reporter (reportedBy uid, can show anonymized)
   - Submission timestamp
5. Admin selects a report
6. Admin sees the full reported content and context
7. Admin chooses an action:

   Action A – REMOVE:
   a. Set reports/{reportId}.status = 'resolved_removed'
   b. Set reports/{reportId}.resolvedAt = serverTimestamp()
   c. If targetType == 'answer':
      → Set answers/{targetId}.isPublished = false
      → OR delete answers/{targetId} (admin decision)
   d. If targetType == 'comment':
      → Delete comments/{targetId}
      → Decrement answers/{answerId}.commentCount by 1

   Action B – DISMISS:
   a. Set reports/{reportId}.status = 'resolved_dismissed'
   b. Set reports/{reportId}.resolvedAt = serverTimestamp()
   c. Content remains unchanged

8. Report disappears from the 'pending' list
9. Show snackbar: l10n.reportResolved
```

## 3. Alternative Flow – Unauthorized Access

```
A1. User navigates to /admin without admin privileges
A2. GoRouter redirect detects non-admin user
A3. Redirect to / (Feed) or show 403 error screen
```

---

## 5. Database Impact

### Action: REMOVE (answer)

```dart
final batch = firestore.batch();

// Mark report as resolved
batch.update(reportsRef.doc(reportId), {
  'status': 'resolved_removed',
  'resolvedAt': FieldValue.serverTimestamp(),
});

// Hide or delete the answer
batch.update(answersRef.doc(targetId), {'isPublished': false});
// OR: batch.delete(answersRef.doc(targetId));

await batch.commit();
```

### Action: REMOVE (comment)

```dart
final batch = firestore.batch();

batch.update(reportsRef.doc(reportId), {
  'status': 'resolved_removed',
  'resolvedAt': FieldValue.serverTimestamp(),
});

// Delete comment
batch.delete(commentsRef.doc(targetId));

// Decrement commentCount on parent answer
batch.update(answersRef.doc(parentAnswerId), {
  'commentCount': FieldValue.increment(-1),
});

await batch.commit();
```

### Action: DISMISS

```dart
await firestore.collection('reports').doc(reportId).update({
  'status': 'resolved_dismissed',
  'resolvedAt': FieldValue.serverTimestamp(),
});
```

---

## 6. Files to Create / Modify

```
lib/app/modules/moderation/
├── domain/
│   └── use_cases/resolve_report.dart               [CREATE]
├── data/
│   └── datasources/moderation_datasource.dart      [MODIFY] add getPendingReports(), resolveReport()
└── presentation/
    ├── screens/admin_dashboard_screen.dart          [CREATE]
    ├── widgets/report_card.dart                     [CREATE]
    └── providers/moderation_providers.dart         [MODIFY] add pendingReportsProvider, resolveReportNotifier

lib/config/router.dart                               [MODIFY] admin route guard
```

---

## 7. Key Code Contracts

### Admin Route Guard (router.dart)
```dart
GoRoute(
  path: '/admin',
  redirect: (context, state) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return '/login';

    // Check admin claim
    final idTokenResult = await FirebaseAuth.instance.currentUser?.getIdTokenResult();
    final isAdmin = idTokenResult?.claims?['admin'] == true;
    if (!isAdmin) return '/'; // redirect non-admin to Feed
    return null;
  },
  builder: (_, __) => const AdminDashboardScreen(),
),
```

### Use Case: `resolve_report.dart`
```dart
class ResolveReport {
  const ResolveReport(this._repo);
  final IModerationRepository _repo;

  Future<void> call({
    required String reportId,
    required String targetId,
    required String targetType,
    required ResolveAction action,  // enum: remove | dismiss
    String? parentAnswerId,         // required when targetType == 'comment' and action == remove
  }) => _repo.resolveReport(
    reportId: reportId,
    targetId: targetId,
    targetType: targetType,
    action: action,
    parentAnswerId: parentAnswerId,
  );
}

enum ResolveAction { remove, dismiss }
```

### Pending Reports Provider
```dart
@riverpod
Stream<List<Report>> pendingReports(PendingReportsRef ref) {
  return ref.read(moderationDatasourceProvider)
      .getPendingReports()
      .map((snap) => snap.docs
          .map((d) => ReportModel.fromFirestore(d).toDomain())
          .toList());
}
```

---

## 8. AdminDashboardScreen Layout Spec

```
AppBar: "Admin Dashboard"
┌──────────────────────────────────────┐
│  Pending Reports (3)                 │
│  ┌────────────────────────────────┐  │
│  │ ANSWER • Spam                  │  │
│  │ "This is totally spam content" │  │
│  │ Reported 1h ago                │  │
│  │   [Remove]        [Dismiss]    │  │
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │ COMMENT • Inappropriate lang.  │  │
│  │ "Some offensive comment here"  │  │
│  │ Reported 3h ago                │  │
│  │   [Remove]        [Dismiss]    │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```

---

## 9. Firestore Security Rule

```javascript
match /reports/{reportId} {
  allow read, update: if request.auth.token.admin == true;
}
match /answers/{answerId} {
  // Admin can update isPublished or delete
  allow update, delete: if request.auth.token.admin == true;
}
match /comments/{commentId} {
  allow delete: if request.auth.token.admin == true;
}
```

---

## 10. Acceptance Criteria (from SRS FR-09)

- [ ] `/admin` route: non-admin users redirected away
- [ ] Only reports with `status == 'pending'` shown in dashboard
- [ ] "Remove" action on answer: sets `isPublished: false` AND updates report status atomically (WriteBatch)
- [ ] "Remove" action on comment: deletes comment AND decrements `commentCount` AND updates report status (WriteBatch)
- [ ] "Dismiss" action: updates report status only, content unchanged
- [ ] `resolvedAt` timestamp set on both remove and dismiss
- [ ] Resolved report disappears from pending list immediately (stream update)
- [ ] Admin sees content preview to make informed decision
