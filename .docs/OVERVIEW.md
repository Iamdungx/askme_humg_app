# AskmeHUMG — Tổng quan dự án

> Đọc file này trước khi bắt đầu làm bất cứ thứ gì.

---

## App này là gì?

Ứng dụng hỏi đáp ẩn danh dành cho sinh viên HUMG.

- **Người gửi câu hỏi:** Không cần đăng nhập, gửi ẩn danh qua link
- **Host (chủ trang):** Sinh viên HUMG đăng nhập bằng email `@humg.edu.vn`, nhận và trả lời câu hỏi
- **Người xem:** Ai cũng có thể xem Feed công khai
- **Admin:** Kiểm duyệt nội dung vi phạm

---

## Trạng thái hiện tại

```
Tổng tiến độ: ~90% █████████░
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
| Trang cá nhân + deep link | ✅ Xong |
| Hộp thư câu hỏi (Inbox) | ✅ Xong |
| Gửi câu hỏi ẩn danh (App Check) | ✅ Xong |
| Feed công khai | ✅ Xong |
| Bottom Navigation Shell (ShellRoute, 4 tabs) | ✅ Xong |
| Settings Screen (theme, language, HUMG verify, sign out) | ✅ Xong |
| Edit Profile Screen (placeholder, full impl v2) | ✅ Xong |
| Kiểm duyệt / báo cáo | ❌ Chưa làm |
| Known issues (qna_repo_impl exception mapping, snackbar context) | ⚠️ Cần sửa |

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
- Cloud Function `submitQuestion` (TypeScript, `functions/`) — **chưa deploy** (xem note bên dưới)

**⚠️ Known limitation — UC-3.1 chưa hoạt động đầy đủ:**
Cloud Function `submitQuestion` chưa được deploy do Firebase project chưa upgrade lên Blaze plan (pay-as-you-go). Khi nào có thẻ tín dụng quốc tế:
1. Upgrade tại: `https://console.firebase.google.com/project/askme-humg-app/usage/details`
2. Chạy: `firebase deploy --only functions`
3. Lấy URL: `https://asia-southeast1-askme-humg-app.cloudfunctions.net`
4. Cập nhật `.env`: `API_BASE_URL=https://asia-southeast1-askme-humg-app.cloudfunctions.net`

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
  - Notifications: placeholder với `// TODO(v2)` — chờ FCM
  - App: Language picker (vi/en/ja), Theme picker (light/dark/system), Clear cache
  - About: Version (PackageInfo), Terms, Privacy
  - Sign out với confirmation dialog
- `EditProfileScreen` (`/me/edit`) — placeholder (avatar + name read-only), `// TODO(v2)` upload
- Profile tab: thêm nút ✏️ Edit trên AppBar của owner

**⚠️ TODO v2 (Version 2):**
- FCM push notifications (cần `firebase_messaging` package)
- Avatar upload lên Firebase Storage
- Lưu `showRealName` vào Firestore `users` doc

### Phase 5 — Kiểm duyệt (UC-5.1, UC-5.2)
Báo cáo nội dung vi phạm, admin xem và xử lý các báo cáo.

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

---

## Bước tiếp theo ngay bây giờ

```
Phase 4 + 4.5 đã xong. Tiến hành Phase 5: Kiểm duyệt
```

### Phase 5 — Kiểm duyệt (UC-5.1, UC-5.2)

1. Đọc `.docs/use_case/UC-5.1_report_content.md`
2. Đọc `.docs/use_case/UC-5.2_admin_moderate.md`
3. Domain layer: `Report` entity + `IReportRepository` + 2 use cases
4. Data layer: `ReportModel` + `FirebaseReportDatasource` + `ReportRepositoryImpl`
5. Presentation:
   - `ReportBottomSheet` — hiển thị từ FeedScreen (3 chấm menu trên mỗi card)
   - `AdminDashboardScreen` (`/admin`) — danh sách reports, approve/reject
6. Security rules đã có trong `firestore.rules`; đảm bảo `reports` chỉ admin đọc được

### Pre-Phase 5 — Fixes đã apply ✅

| File | Fix | Mức độ |
|---|---|---|
| `config/app_routes.dart` | Thêm `/me/edit` vào `protectedLocationPrefixes` | P1-Security ✅ |
| `profile/data/profile_repository_impl.dart` | Thêm try/catch → `FirestoreFailure` / `UnknownFailure` | P1-Architecture ✅ |
| `profile/presentation/screens/profile_screen.dart` | Check `FirestoreFailure` thay vì `FirestoreException` | P1-Architecture ✅ |
| `global_widgets/ui/anonymous_badge.dart` | Label nullable, fallback `l10n.anonymousBadgeLabel` | Minor ✅ |
| `auth/presentation/auth_providers.dart` | `authStateProvider` thêm `keepAlive: true` | Minor ✅ |
| `feed/presentation/feed_providers.dart` | `FeedNotifier.build()` dùng `ref.watch` | Minor ✅ |
| `qna_core/data/qna_repository_impl.dart` | Exception mapping đầy đủ (đã fix Phase 3) | HIGH ✅ |
| `profile/presentation/widgets/ask_question_sheet.dart` | Widget inline — không còn Navigator.pop() issue | MEDIUM ✅ |
| `global_widgets/states/loading_shimmer.dart` | Implement đầy đủ 172 dòng skeleton | MEDIUM ✅ |

**⚠️ Còn tồn đọng (không blocking):**
- UC-3.1 App Check: Cloud Function `submitQuestion` chưa deploy — chờ Blaze plan (thẻ tín dụng)

> **Lưu ý quan trọng trước khi test end-to-end:**
> - UC-3.1 (gửi câu hỏi ẩn danh): Cloud Function `submitQuestion` chưa deploy do chưa upgrade Blaze plan
> - `isHumgVerified` guard (UC-1.3 OTP): chưa implement → Host features chưa bị khóa
> - Settings → "HUMG Verification" hiện là placeholder; cần implement UC-1.3 để hoàn chỉnh
