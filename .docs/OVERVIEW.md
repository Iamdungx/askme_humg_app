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
Tổng tiến độ: ~70% ███████░░░
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
| Router guard (auth redirect `/inbox`, `/admin`) | ✅ Xong |
| Trang cá nhân + deep link | ✅ Xong |
| Hộp thư câu hỏi (Inbox) | ✅ Xong |
| Gửi câu hỏi ẩn danh (App Check) | ✅ Xong |
| Feed công khai | ❌ Chưa làm |
| Kiểm duyệt / báo cáo | ❌ Chưa làm |

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
ProfileScreen (`/u/:userId`), UserProfile entity, FirebaseProfileDatasource, deep link `askme.humg.edu.vn/u/{userId}`, ShareCardWidget (QR + share image), native config (AndroidManifest + iOS Entitlements), cold-start + warm-start app_links listener.

### Phase 3 — Gửi câu hỏi & Hộp thư (UC-3.1, UC-3.2, UC-3.3) ✅ XONG
Gửi câu hỏi ẩn danh (tối đa 300 ký tự, có App Check chống bot), xem hộp thư 2 tab (chưa trả lời / đã trả lời), viết và đăng câu trả lời.

### Phase 4 — Feed & Tương tác (UC-4.1, UC-4.2, UC-4.3)
Xem feed công khai (phân trang 20 bài), like/unlike câu trả lời, bình luận.

### Phase 5 — Kiểm duyệt (UC-5.1, UC-5.2)
Báo cáo nội dung vi phạm, admin xem và xử lý các báo cáo.

---

## Cấu trúc thư mục sẽ có

```
lib/
├── config/          ← router, DI, env, bootstrap
├── app/
│   ├── core/        ← màu sắc, font, theme, logger, validator, error classes
│   ├── global_widgets/  ← button, card, avatar, badge, shimmer...
│   └── modules/
│       ├── auth/        ← Phase 1
│       ├── profile/     ← Phase 2
│       ├── qna_core/    ← Phase 3
│       ├── feed/        ← Phase 4
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
Bắt đầu Phase 4: Feed & Tương tác

1. Đọc .docs/use_case/UC-4.1_view_feed.md
2. Đọc .docs/use_case/UC-4.2_like_unlike.md
3. Đọc .docs/use_case/UC-4.3_comment.md
4. Domain layer: FeedItem entity + IFeedRepository + use cases
5. Data layer: AnswerFeedModel + FeedDatasource + FeedRepositoryImpl
6. Presentation: FeedScreen (cursor pagination, limit 20) + feedProviders
7. LikeButton widget (arrayUnion/arrayRemove + increment)
8. CommentSheet + WriteBatch (comments + commentCount)
```
