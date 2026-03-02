# AskmeHUMG — Backlog

> Các tính năng và cải tiến chưa implement trong v1.0.0, sắp xếp theo mức độ ưu tiên.
>
> **v1.0.0 released:** 02-03-2026

---

## ✅ Đã hoàn thành trong v1.0.0

| Item | Ghi chú |
|---|---|
| Edit Profile (BACKLOG-02) | Avatar upload Firebase Storage (cooldown 7 ngày) + display name edit — ✅ ship |

---

## 🔴 P1 — Cần thiết cho production (v1.1)

### BACKLOG-01: App Check + Cloud Function Rate Limiting (UC-3.1)

**Lý do defer:** Yêu cầu Firebase Blaze plan (pay-as-you-go). Chưa kích hoạt do chưa có phương thức thanh toán.

**Scope:**
- Bật Firebase App Check trên Android (Play Integrity) và iOS (DeviceCheck)
- Deploy Cloud Function `submitQuestion` có:
  - Xác thực App Check token (`X-Firebase-AppCheck` header)
  - Rate limiting: tối đa 5 câu hỏi / device / giờ (lưu counter trong Firestore `rateLimits` collection)
  - Ghi `questions` doc vào Firestore sau khi pass validation
- Client (`qna_repository_impl.dart`): bỏ bypass, gọi Cloud Function thay vì ghi Firestore trực tiếp
- Xoá comment `// TODO(blaze)` sau khi deploy

**Files cần thay đổi:**
- `lib/app/modules/qna_core/data/qna_repository_impl.dart` — đổi Firestore write → Cloud Function call qua `dio`
- `functions/src/index.ts` (hoặc tương đương) — tạo mới Cloud Function
- `firebase.json` — khai báo functions
- `lib/main.dart` — bật `FirebaseAppCheck.activate()` với provider thật (không phải debug)

**Acceptance criteria:**
- [ ] Bot/script gửi quá 5 câu hỏi/giờ → nhận HTTP 429
- [ ] Request không có App Check token hợp lệ → rejected
- [ ] App vẫn hoạt động bình thường trên thiết bị thật

**Prerequisite:** Upgrade Firebase project lên Blaze plan.

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

### BACKLOG-04: Feed Share Button (FR-11)

**Scope:**
- `FeedItemCard._onShare()` hiện chỉ show snackbar
- Implement gọi `share_plus` để share URL `askme-humg-app.web.app/user/{userId}?answer={answerId}`

**Files cần thay đổi:**
- `lib/app/modules/feed/presentation/widgets/feed_item_card.dart`

---

### BACKLOG-05: Push Notifications (FCM)

**Scope:**
- UI placeholder đã có (`settingsNotifComingSoon`)
- Implement FCM topic subscription khi user bật notification trong Settings
- Cloud Function trigger: gửi FCM khi có câu hỏi mới hoặc comment mới
- Lưu preference vào `SharedPreferences`

**Prerequisite:** Blaze plan (BACKLOG-01).

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
