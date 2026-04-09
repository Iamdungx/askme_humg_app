# AskmeHUMG — Backlog

> Các tính năng và cải tiến chưa implement trong v1.0.0, sắp xếp theo mức độ ưu tiên.
>
> **v1.0.0 released:** 02-03-2026

---

## ✅ Đã hoàn thành trong v1.0.0

| Item | Ghi chú |
|---|---|
| Edit Profile (BACKLOG-02) | Avatar upload Firebase Storage (cooldown 7 ngày) + display name edit — ✅ ship |
| Feed Share Button (BACKLOG-04) | Share bài trả lời qua `share_plus` + deep link `/answer/:answerId` + màn `AnswerDetailScreen` — ✅ ship |

---

## 🔴 P1 — Cần thiết cho production (v1.1)

### BACKLOG-01: Harden Vercel API security cho UC-3.1/Tracking

**Bối cảnh hiện tại:** Luồng submit/tracking đã chạy production qua Vercel API `askme-humg.vercel.app/api`.

**Scope:**
- `submitQuestion`:
  - Verify nguồn request mạnh hơn (App Check equivalent / signed nonce / idToken policy)
  - Không chỉ dựa vào rate-limit theo IP/fid
- `getQuestionTrackingStatus`:
  - Siết rate-limit theo IP/subnet làm khóa chính (không tin `clientKey` từ client)
  - Cân nhắc thêm delay/captcha sau nhiều lần sai
- Secret management:
  - Bắt buộc `TRACKING_CODE_PEPPER` trên Vercel (fail-fast nếu thiếu ở production)

**Files cần thay đổi:**
- `webhook/api/submitQuestion.js`
- `webhook/api/getQuestionTrackingStatus.js`
- `webhook/api/_shared.js`

**Acceptance criteria:**
- [ ] Submit endpoint từ script không hợp lệ bị reject theo cơ chế verify mới
- [ ] Lookup brute-force khó bypass bằng thay đổi `clientKey`
- [ ] Không chạy production nếu thiếu secret env quan trọng (`TRACKING_CODE_PEPPER`)

---

## 🟡 P2 — Quan trọng cho UX (v1.1)

### BACKLOG-03: `showRealName` persist lên Firestore (FR-10)

**Scope:**
- Toggle "Hiển thị tên thật" trong Settings hiện chỉ lưu local qua `SharedPreferences`
- Cần persist lên `users.showRealName` Firestore field để đồng bộ đa thiết bị
- Feed (`FeedItemCard`) và Profile (`ProfileHeader`) cần đọc field này để ẩn/hiện tên thật

**Files cần thay đổi:**
- `lib/app/modules/settings/presentation/settings_screen.dart` — gọi repository update khi toggle
- `lib/app/modules/profile/data/profile_repository_impl.dart` — thêm `updateShowRealName()`
- `lib/app/modules/feed/presentation/widgets/feed_item_card.dart` — đọc `hostShowRealName`

---

### BACKLOG-06: "View All Answers" trên Profile (FR-10)

**Scope:**
- Button "Xem tất cả" trong `_RecentAnswersSection` hiện `onPressed: () {}`
- Tạo màn hình `UserAnswersScreen` hiển thị toàn bộ published answers của một user với cursor pagination

**Files cần thay đổi:**
- `lib/app/modules/profile/presentation/screens/` — thêm `user_answers_screen.dart`
- `lib/config/router.dart` — thêm route `/user/:userId/answers`

---

## 🟢 P3 — Nice-to-have (v2.0)

### BACKLOG-04: Feed Share Button (FR-11) — ✅ Done

**Scope:**
- `FeedItemCard._onShare()` trước đây chỉ show snackbar
- Implement gọi `share_plus` để share **deep link bài trả lời**: `askme-humg-app.web.app/answer/{answerId}`
- Thêm màn `AnswerDetailScreen` + route `/answer/:answerId` để mở bài từ link (chỉ load `isPublished == true`)
- Onboarding redirect không chặn deep link `/answer/:answerId` (giống `/user/:id`)

**Files cần thay đổi:**
- `lib/app/modules/feed/presentation/widgets/feed_item_card.dart`
- `lib/app/modules/feed/presentation/screens/answer_detail_screen.dart`
- `lib/config/app_routes.dart`
- `lib/config/router.dart`
- `lib/app/modules/feed/data/firebase_feed_datasource.dart`
- `lib/app/modules/feed/data/feed_repository_impl.dart`
- `lib/app/modules/feed/domain/i_feed_repository.dart`
- `lib/app/modules/feed/domain/feed_use_cases.dart`
- `lib/app/modules/feed/presentation/feed_providers.dart`

---

### BACKLOG-05: Push Notifications (FCM / hoặc OneSignal full migration)

**Scope:**
- UI placeholder đã có (`settingsNotifComingSoon`)
- Implement FCM topic subscription khi user bật notification trong Settings
- Cloud Function trigger: gửi FCM khi có câu hỏi mới hoặc comment mới
- Lưu preference vào `SharedPreferences`

**Prerequisite:** Chốt chiến lược push dài hạn (giữ OneSignal qua Vercel hoặc quay lại Firebase Functions khi có Blaze).

---

### BACKLOG-07: Like Optimistic UI (FR-06)

**Scope:**
- Hiện tại like button chờ Firestore stream cập nhật → có độ trễ nhỏ
- Implement optimistic update: toggle icon/count ngay lập tức, revert nếu Firestore trả lỗi

---

## 📋 Đã defer có lý do rõ ràng

| Item | Lý do |
|---|---|
| Firebase Dynamic Links | Deprecated bởi Google 08/2025 → đã thay bằng `app_links` |
| Server-side keyword moderation (Cloud Function) | Pending Blaze plan |
| Inbox pagination | Data volume hiện tại nhỏ, không cần thiết cho v1 |
