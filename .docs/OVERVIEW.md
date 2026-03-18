# AskmeHUMG — Tổng quan dự án

> Đọc file này trước khi bắt đầu làm bất cứ thứ gì.
>
> **🏷️ Tag:** `v1.0.0` — Released 02-03-2026

---

## App này là gì?

Ứng dụng hỏi đáp ẩn danh dành cho sinh viên HUMG.

- **Người gửi câu hỏi:** Không cần đăng nhập, gửi ẩn danh qua link
- **Host (chủ trang):** Sinh viên HUMG đăng nhập bằng email `@humg.edu.vn`, nhận và trả lời câu hỏi
- **Người xem:** Ai cũng có thể xem Feed công khai
- **Admin:** Kiểm duyệt nội dung vi phạm

---

## Trạng thái hiện tại — v1.0.0 ✅ RELEASED

```
Tổng tiến độ: 100% ██████████  (v1.0.0 — 02-03-2026)
```

| Hạng mục | Trạng thái |
|---|---|
| Giao diện (theme, màu sắc, font) | ✅ Xong |
| Các widget dùng chung (button, card, avatar...) | ✅ Xong |
| Cấu hình app (router typed, env, DI, logger) | ✅ Xong |
| Đa ngôn ngữ (vi/en/ja) | ✅ Xong |
| Firebase khởi tạo (`firebase_options.dart`) | ✅ Xong |
| Error classes (`failures.dart`, `exceptions.dart`) | ✅ Xong |
| Riverpod providers cho Firebase (auth/firestore/storage) | ✅ Xong |
| Splash screen (auth-aware, navigate sau 2.8s) | ✅ Xong |
| Đăng nhập Google — UI + domain check + upsert Firestore | ✅ Xong |
| Đăng xuất | ✅ Xong |
| Router guard (auth redirect `/inbox`, `/me/edit`, `/admin`) | ✅ Xong |
| HUMG email OTP verify (UC-1.3) + route guard → `/verify-humg` | ✅ Xong |
| Trang cá nhân + deep link | ✅ Xong |
| Hộp thư câu hỏi (Inbox) | ✅ Xong |
| Gửi câu hỏi ẩn danh (App Check) | ✅ Xong |
| Feed công khai | ✅ Xong |
| Like / Comment + isHumgVerified guard | ✅ Xong |
| Bottom Navigation Shell (ShellRoute, 4 tabs) | ✅ Xong |
| Settings Screen (theme, language, HUMG verify, sign out) | ✅ Xong |
| Edit Profile Screen (avatar upload + display name) | ✅ Xong |
| Kiểm duyệt / báo cáo (UC-5.1, UC-5.2) | ✅ Xong |
| App Check + server-side rate limiting cho submit/tracking (UC-3.1) | ✅ Xong (Vercel API `askme-humg.vercel.app`) |

> **Current implementation note:** Luồng UC-3.1 đang chạy qua Vercel API (`askme-humg.vercel.app/api`) để tránh phụ thuộc Blaze plan.

---

## Thứ tự làm (quan trọng — không được nhảy cóc)

```
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5
```

### Phase 0 — Nền tảng Firebase ✅ XONG
Firebase init, `firebase_options.dart`, error/failure classes, Riverpod providers cho Auth/Firestore/Storage.

### Phase 1 — Đăng nhập (UC-1.1, UC-1.2) ✅ XONG
Google Sign-In, chặn email không phải `@humg.edu.vn`, upsert document `users` trên Firestore, đăng xuất, auth guard router, Splash screen.

### Phase 2 — Trang cá nhân (UC-2.1, UC-2.2) ✅ XONG
ProfileScreen (`/u/:userId`), UserProfile entity, FirebaseProfileDatasource, deep link `askme-humg-app.web.app/user/{userId}`, ShareCardWidget (QR + share image), native config (AndroidManifest + iOS Entitlements), cold-start + warm-start app_links listener.

### Phase 3 — Gửi câu hỏi & Hộp thư (UC-3.1, UC-3.2, UC-3.3) ✅ XONG

**Đã implement:**
- Domain: `Question`, `Answer` entity + `IQnaRepository` + 5 use cases
- Data: `QuestionModel`, `AnswerModel` (fromFirestore, toDomain), `FirebaseQnaDatasource`, `QnaRepositoryImpl`
- Presentation: `InboxScreen` (2 tab + badge đỏ), `AnswerComposeScreen`, `QuestionCard` (swipe-to-delete), `AnswerPublishToggle`
- `AskQuestionSheet` tích hợp vào ProfileScreen (chỉ hiện khi xem profile người khác)
- UC-3.3 WriteBatch atomic: `answers` create + `questions` status update
- Rate limiting per-device: App Check token + Firebase Installations ID (FID)
- Localization: timeago đa ngôn ngữ (vi/en/ja)
- Vercel API `submitQuestion` + `getQuestionTrackingStatus` (`webhook/api/`)

**UC-3.1 hiện trạng triển khai (03/2026):**
1. Submit anonymous question gọi `POST https://askme-humg.vercel.app/api/submitQuestion`
2. API sinh `trackingCode` 6 ký tự chữ+số (ví dụ `AD79HQ`), lưu `trackingCodeHash` vào `questions`
3. Lookup trạng thái gọi `POST https://askme-humg.vercel.app/api/getQuestionTrackingStatus`
4. App/Web đều dùng chung backend Vercel cho tracking

**Lưu ý bảo mật hiện tại:**
- Lookup đang là anonymous theo mã tra cứu (biết mã là tra được)
- Đã có TODO security trong code để harden thêm (verify nguồn submit + chống brute-force lookup)

**Fixes đã apply sau review:**
- `content.trim()` trước validate + submit trong `AskQuestionSheet`
- Swipe dismiss await delete thật, trả `false` nếu Firestore fail (tránh UI desync)
- HTTP 401/403 → `AppCheckException` với l10n message riêng
- `createdAt == null` trong Firestore → throw `FirestoreException` thay vì `DateTime.now()`
- `_ReplyButton` dùng `l10n.inboxReplyButton` thay vì `answerComposeTitle`
- Xóa field `questionId` thừa trong Firestore document write

### Phase 4 — Feed & Tương tác (UC-4.1, UC-4.2, UC-4.3) ✅ XONG
Feed công khai, like/unlike, bình luận đã implement. Composite Firestore indexes đã deploy.

### Phase 4.5 — Navigation Shell & Settings ✅ XONG

**Đã implement:**
- `AppShell` (`lib/app/core/widgets/app_shell.dart`) — 4 tabs: Feed / Inbox / Profile / Settings
- `StatefulShellRoute` trong `router.dart` — tab state persist, scroll-to-top khi tap tab active
- Badge đỏ trên Inbox tab hiển thị số câu hỏi chưa trả lời
- `SettingsScreen` (`/settings`):
  - Account: Edit Profile, HUMG verify status, Show real name toggle
  - Notifications: placeholder — chờ FCM (BACKLOG-05)
  - App: Language picker (vi/en/ja), Theme picker (light/dark/system), Clear cache
  - About: Version (PackageInfo), Terms, Privacy
  - Sign out với confirmation dialog
- `EditProfileScreen` (`/me/edit`) — avatar upload (Firebase Storage, cooldown 7 ngày) + display name edit
- Profile tab: nút ✏️ Edit trên AppBar của owner

### Phase 5 — Kiểm duyệt (UC-5.1, UC-5.2) ✅ XONG

**Đã implement:**
- Domain: `Report` entity (Freezed) + `IModerationRepository` + 3 use cases (`SubmitReport`, `GetPendingReports`, `ResolveReport`)
- Data: `ReportModel` + `FirebaseModerationDatasource` + `ModerationRepositoryImpl`
- Presentation:
  - `ReportReasonSheet` — bottom sheet chọn lý do báo cáo (4 options), tích hợp vào `FeedItemCard`, `CommentTile`, `ProfileScreen`
  - `AdminDashboardScreen` (`/admin`) — danh sách pending reports với `ReportCard` (Dismiss / Remove)
  - `ResolveReportNotifier` — per-report loading state (không block toàn bộ list)
- Router guard `/admin` — yêu cầu Firebase Custom Claim `admin: true`

---

## Cấu trúc thư mục sẽ có

```
lib/
├── config/          ← router, DI, env, bootstrap
├── app/
│   ├── core/        ← màu sắc, font, theme, logger, validator, error classes
│   │   ├── providers/   ← theme_provider, locale_provider (shared_preferences)
│   │   └── widgets/     ← app_shell.dart (bottom nav scaffold)
│   ├── global_widgets/  ← states/ · input/ · layout/ · ui/
│   └── modules/
│       ├── auth/        ← Phase 1
│       ├── profile/     ← Phase 2
│       ├── qna_core/    ← Phase 3
│       ├── feed/        ← Phase 4
│       ├── settings/    ← Phase 4.5
│       └── moderation/  ← Phase 5
```

Mỗi module có 3 lớp:

```
{module}/
├── domain/       ← Entity (dữ liệu thuần), Interface repository, Use case
├── data/         ← Kết nối Firebase thực tế, Model (JSON), Repository impl
└── presentation/ ← Screen, Widget, Provider (Riverpod)
```

> **Quy tắc vàng:** `presentation` chỉ gọi `domain`, KHÔNG bao giờ gọi thẳng `data`.

---

## Cách làm việc với Cursor

### Trước mỗi feature

1. Mở file UC tương ứng trong `.docs/use_case/`
2. Đọc phần **Database Impact** trong UC đó
3. Bắt đầu prompt

### Cấu trúc prompt chuẩn

```
Implement [tên feature] theo UC-X.X
File tham chiếu: .docs/use_case/UC-X.X_xxx.md

Yêu cầu:
- Domain layer trước (entity + repository interface)
- Data layer (model + repository impl với Firebase)
- Presentation layer (screen + provider AsyncNotifier)
- Dùng WriteBatch khi UC yêu cầu
- Handle loading / error / success
```

### Chia nhỏ task — mỗi prompt 1 layer

| Prompt | Làm gì |
|---|---|
| Prompt 1 | Domain layer (entity + interface) |
| Prompt 2 | Data layer (model + repo impl) |
| Prompt 3 | Presentation layer (screen + provider) |

### Sau khi Cursor generate xong

```bash
# Bắt buộc chạy sau khi có file @freezed hoặc @riverpod mới
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Các quy tắc bắt buộc khi code

| Quy tắc | Ví dụ |
|---|---|
| Ghi nhiều collection cùng lúc | Dùng `WriteBatch` (không dùng nhiều `.set()` riêng lẻ) |
| Tăng/giảm số đếm | Dùng `FieldValue.increment(1)` (không đếm `.length`) |
| State bất đồng bộ | Dùng `AsyncNotifier` + `AsyncValue.guard()` |
| Xử lý lỗi | Map `FirebaseException` → `Failure` class, không bỏ qua |
| Text trong UI | Dùng `context.l10n.*`, không hardcode chuỗi |
| Log | Dùng `AppLogger.d/e/w`, không dùng `print()` |
| Màu sắc | Dùng `AppColors.*` hoặc `Theme.of(context).colorScheme.*` |
| `withOpacity` | **Không dùng** — thay bằng `Color.withValues(alpha: x)` |

---

## Các file quan trọng cần biết

| File | Mục đích |
|---|---|
| `.docs/use_case/INDEX.md` | Danh sách tất cả UC |
| `.docs/ARCHITECTURE.md` | Cấu trúc thư mục chi tiết |
| `.docs/TECH_STACK.md` | Phiên bản thư viện + breaking changes |
| `.cursor/rules/` | 5 rule cho Cursor AI |
| `.cursor/plans/askmehumg_implementation_plan_*.md` | Kế hoạch implement chi tiết |
| `lib/app/core/values/app_colors.dart` | Bảng màu |
| `lib/app/core/values/app_theme.dart` | Theme Material 3 |
| `lib/config/router.dart` | Tất cả routes |
| `webhook/api/` | API Vercel cho notify + submitQuestion + getQuestionTrackingStatus |

---

## v1.0.0 — Release Notes (02-03-2026)

```
Tất cả 5 Phase đã hoàn thành. App đã sẵn sàng cho TestFlight / Play Internal Testing.
```

### Tính năng đã ship trong v1.0.0

| Phase | Feature | UC |
|---|---|---|
| 0 | Firebase init, error/failure classes, Riverpod providers | — |
| 1 | Google Sign-In, OTP HUMG verify, Logout, auth guard | UC-1.1, UC-1.2, UC-1.3 |
| 2 | Profile page, deep link, QR share card, avatar upload | UC-2.1, UC-2.2 |
| 3 | Inbox (2 tabs), Answer compose, Question submission | UC-3.1, UC-3.2, UC-3.3 |
| 4 | Public Feed, Like/Unlike, Comments, verified badge | UC-4.1, UC-4.2, UC-4.3 |
| 4.5 | Bottom nav shell, Settings (theme/lang/profile edit) | — |
| 5 | Report content, Admin dashboard, resolve reports | UC-5.1, UC-5.2 |

### Các việc cần làm cho v1.1+

Xem `.docs/BACKLOG.md` để biết chi tiết đầy đủ.

**P1 — cần cho production:** hardening security cho API tracking/submit (xem `BACKLOG.md`)

**P2 — UX quan trọng:** BACKLOG-03 (`showRealName` persist Firestore), BACKLOG-06 (View All Answers)

**P3 — Nice-to-have:** BACKLOG-04 (Feed Share), BACKLOG-05 (Push Notifications / FCM), BACKLOG-07 (Like Optimistic UI)
