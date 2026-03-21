# Changelog

Tất cả thay đổi đáng chú ý của dự án AskmeHUMG được ghi lại ở đây.

Format dựa trên [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [1.0.0] — 2026-03-02

### ✨ Tính năng mới

#### Phase 0 — Nền tảng
- Firebase init (`firebase_options.dart`), error/failure class hierarchy (`Failure`, `Exception`)
- Riverpod providers cho FirebaseAuth, Firestore, Firebase Storage
- Splash screen: auth-aware, tự động navigate sau 2.8s

#### Phase 1 — Xác thực (UC-1.1, UC-1.2, UC-1.3)
- Đăng nhập Google với kiểm tra domain `@humg.edu.vn`; upsert document `users` Firestore
- Đăng xuất có confirmation dialog
- Router guard: `/inbox`, `/me/edit`, `/admin` redirect về `/login` khi chưa xác thực
- Xác minh email HUMG qua OTP 6 chữ số (SHA-256 hash lưu `otpRequests/{uid}`, TTL 10 phút, max 3 lần)
- Gửi email OTP qua Gmail SMTP (`mailer` package) — plain-text (tránh bộ lọc Microsoft 365 của HUMG)
- Route guard: người dùng chưa verify bị redirect về `/verify-humg`

#### Phase 2 — Trang cá nhân (UC-2.1, UC-2.2)
- `ProfileScreen` (`/u/:userId`): hiển thị tên, avatar, số câu trả lời, tổng lượt thích
- `VerifiedBadge` — icon xác minh HUMG trên tên (2 chế độ: inline icon / icon + label)
- Deep link `askme-humg-app.web.app/user/{userId}` (cold-start + warm-start via `app_links`)
- `ShareCardWidget`: QR code + chia sẻ ảnh card qua `share_plus`
- Native config: AndroidManifest intent-filter + iOS Entitlements cho deep link

#### Phase 3 — Gửi câu hỏi & Hộp thư (UC-3.1, UC-3.2, UC-3.3)
- `AskQuestionSheet`: gửi câu hỏi ẩn danh (300 ký tự, trim + validate), tích hợp vào ProfileScreen
- `InboxScreen`: 2 tab (chưa trả lời / đã trả lời), badge đỏ số câu hỏi pending
- `AnswerComposeScreen`: soạn câu trả lời, toggle publish/unpublish
- Batch Write atomic: `answers` create + `questions.status = 'answered'` (UC-3.3)
- Swipe-to-delete câu hỏi trong Inbox
- Localization `timeago` đa ngôn ngữ (vi/en/ja)

#### Phase 4 — Feed & Tương tác (UC-4.1, UC-4.2, UC-4.3)
- Feed công khai: `isPublished == true`, sort `createdAt desc`, cursor pagination limit 20
- Like / Unlike: `arrayUnion/arrayRemove` + `FieldValue.increment(±1)` — yêu cầu `isHumgVerified`
- Bình luận: Batch Write `comments` + `answers.commentCount++` — yêu cầu `isHumgVerified`
- Guard cho Like/Comment: snackbar `verifyRequiredToLike` / `verifyRequiredToComment`
- `VerifiedBadge` trên `FeedItemCard` và `CommentTile`
- Composite Firestore index đã deploy (`isPublished ASC, createdAt DESC, __name__ DESC`)

#### Phase 4.5 — Navigation Shell & Settings
- `AppShell` (`StatefulShellRoute`): 4 tab — Feed / Inbox / Profile / Settings
- Tab state persist, scroll-to-top khi tap tab active
- Badge đỏ trên Inbox tab
- `SettingsScreen`: theme picker (light/dark/system), language picker (vi/en/ja), HUMG verify status, sign out
- `EditProfileScreen`: đổi display name + upload avatar mới lên Firebase Storage (cooldown 7 ngày)

#### Phase 5 — Kiểm duyệt (UC-5.1, UC-5.2)
- `ReportReasonSheet`: báo cáo answer/comment/profile với 4 lý do
- `AdminDashboardScreen` (`/admin`): danh sách pending reports, per-report Dismiss / Remove
- Router guard `/admin`: yêu cầu Firebase Custom Claim `admin: true`
- `ResolveReportNotifier`: loading state per-report (không block toàn bộ list)

### 🐛 Bug Fixes (trong quá trình phát triển)

- `content.trim()` trước validate + submit trong `AskQuestionSheet`
- Swipe dismiss await delete thật, trả `false` nếu Firestore fail
- HTTP 401/403 → `AppCheckException` với l10n message riêng
- `createdAt == null` trong Firestore → throw `FirestoreException`
- `authStateProvider` thêm `keepAlive: true` tránh dispose sớm
- `FeedNotifier.build()` dùng `ref.watch` thay vì `ref.read`
- Exception mapping đầy đủ trong `qna_repository_impl.dart`
- `/me/edit` thêm vào `protectedLocationPrefixes` (security fix)
- `ProfileScreen`: check `FirestoreFailure` thay vì `FirestoreException`
- `loading_shimmer.dart`: implement đầy đủ skeleton UI

### ⚠️ Known Limitations

- **UC-3.1 App Check:** Cloud Function `submitQuestion` chưa deploy — Firebase project chưa upgrade Blaze plan. Client hiện ghi thẳng Firestore. Xem `BACKLOG.md` → BACKLOG-01.
- **showRealName:** Toggle "Hiển thị tên thật" lưu `SharedPreferences` (local), chưa sync Firestore. Xem BACKLOG-03.
- **Push Notifications:** UI placeholder có sẵn, FCM chưa active. Xem BACKLOG-05.

### 🔧 Tech

- Flutter 3.35.7 / Dart >=3.10.3
- Riverpod 3.x (`AsyncNotifier`, codegen)
- GoRouter 17.x (`StatefulShellRoute`, typed routes)
- Freezed 3.x (`abstract class` requirement)
- Material 3 (`CardThemeData`, `WidgetStateProperty`, `color.withValues(alpha:)`)
- Đa ngôn ngữ: vi / en / ja (ARB + `flutter gen-l10n`)

---

## [Unreleased] — v1.1 (kế hoạch)

### Added (develop — 2026-03-22)

- **QR quét profile (UC-2.1):** màn `ProfileQrScanScreen`, route `/scan-profile-qr` (full-screen, yêu cầu đăng nhập), dependency `mobile_scanner`; nút quét trên `ProfileScreen` khi platform hỗ trợ (`mobile_scanner_support.dart`).
- **Deep link:** helper `parseProfileDeepLinkToPath` cho chuỗi quét được (HTTPS hoặc custom scheme `askme://user/{userId}`); redirect router: user đã đăng nhập mở `/user/{ownUid}` → `/me` (có bottom nav).
- **Shell:** `AppShellTabController` + `AppShellTab` để chuyển tab programmatic (cùng animation với tap bottom bar).
- **Chia sẻ / lưu ảnh:** `ShareAnswerCardWidget` và `ShareCardWidget` — lưu card PNG vào thư viện ảnh (`gal`); iOS `NSPhotoLibraryAddUsageDescription`; nút tải/xuất thay cho một số luồng chỉ copy link.
- **Hosting:** meta Open Graph / Twitter Card trên `hosting/public/index.html` (preview link Zalo/Facebook/iMessage).
- **Firestore / API:** xóa câu hỏi trong Inbox — batch: xóa `questions` + `isPublished: false` trên các `answers` cùng `questionId`; submit ẩn danh — nếu App Check token lỗi thì vẫn gọi API (không gửi header), tránh chặn hoàn toàn khi App Check không lấy được token.

### Changed (develop — 2026-03-22)

- **Android:** `JavaCompile` 11 toàn subproject; `release` tắt minify/shrink tạm thời; `android.javaCompile.suppressSourceTargetDeprecationWarning=true`.
- **iOS:** mô tả camera mở rộng (avatar + quét QR).

### Added
- UC-3.1 moved to Vercel backend (`askme-humg.vercel.app/api`) for production without Firebase Blaze plan.
- New endpoints:
  - `POST /api/submitQuestion` (server-side rate limiting + returns tracking code)
  - `POST /api/getQuestionTrackingStatus` (lookup by tracking code)
- Anonymous tracking flow on app + web:
  - Tracking screen in app (`/track-question`)
  - Tracking section on hosting page (`askme-humg-app.web.app`)
- Tracking code format upgraded from `6 digits` to `6 alphanumeric chars` (example: `AD79HQ`).

### Changed
- Submit success UX now shows tracking code dialog + copy action.
- Web tracking input now accepts alphanumeric codes and normalizes uppercase input.
- `qna` datasource defaults to Vercel API base (`https://askme-humg.vercel.app/api`) when env is absent.

### Security Notes
- Added `// TODO(security)` markers for:
  - stronger submit request verification
  - stricter lookup brute-force protection independent from client-provided key

### Planned
- BACKLOG-01: Harden Vercel API security for submit/tracking
- BACKLOG-03: `showRealName` persist lên Firestore
- BACKLOG-06: "View All Answers" screen với pagination

### Future (v2.0)
- BACKLOG-04: Feed Share Button (share URL per answer)
- BACKLOG-05: Push Notifications (FCM)
- BACKLOG-07: Like Optimistic UI
