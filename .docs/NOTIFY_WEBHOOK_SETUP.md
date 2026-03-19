# Webhook thông báo OneSignal (khi chưa có Blaze)

App gửi thông báo qua OneSignal bằng cách gọi webhook sau khi tạo câu hỏi/comment. Webhook xác thực Firebase idToken, đọc preference từ Firestore, rồi gọi OneSignal REST API.

## 1. OneSignal

- Tạo app tại [onesignal.com](https://onesignal.com), cấu hình Android (FCM) / iOS (APNs).
- Lấy **OneSignal App ID** và **REST API Key** (Settings > Keys & IDs).

## 2. Flutter (.env)

```env
ONESIGNAL_APP_ID=your-onesignal-app-id
NOTIFY_WEBHOOK_URL=https://askme-humg.vercel.app/api
API_BASE_URL=https://askme-humg.vercel.app/api
```

- `NOTIFY_WEBHOOK_URL`: URL gốc tới project Vercel (không ghi thêm `/notify` — client tự thêm).
- `API_BASE_URL`: URL gốc API cho submit question + tracking status.

## 3. Deploy webhook (Vercel)

Dùng thư mục `webhook/` (chỉ ~10 file) để tránh lỗi "files > 15000" khi deploy từ root Flutter.

- Cài Vercel CLI: `npm i -g vercel`
- Deploy từ thư mục `webhook/`:

```bash
cd webhook
npm install
vercel
```

- Thêm Environment Variables trong Vercel Dashboard (hoặc `vercel env add`):

| Name | Mô tả |
|------|--------|
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Nội dung JSON của service account (Firebase Console > Project Settings > Service accounts > Generate new private key). Copy toàn bộ JSON dán vào (một dòng). |
| `TRACKING_CODE_PEPPER` | Secret dùng để hash tracking code (khuyên dùng chuỗi random dài). |
| `ONESIGNAL_REST_API_KEY` | REST API Key từ OneSignal. |
| `ONESIGNAL_APP_ID` | OneSignal App ID. |
| `GEMINI_API_KEY` | API key để classify answer. |
| `GEMINI_MODEL` | Model mặc định (gợi ý: `gemini-2.5-flash-lite`). |
| `GEMINI_FALLBACK_MODEL` | Model fallback khi confidence thấp/lỗi parse (gợi ý: `gemini-2.5-flash`). |

- Redeploy sau khi thêm env.

## 4. Luồng

- User bật toggle thông báo trong Cài đặt → app ghi `notifNewQuestion` / `notifNewComment` lên Firestore `users/{uid}` và đồng bộ OneSignal (login/tag).
- Khi có câu hỏi mới: client sau khi ghi Firestore gọi `POST {NOTIFY_WEBHOOK_URL}/notify` với `idToken`, `type: 'new_question'`, `toUserId`, `content`. Webhook kiểm tra `users/{toUserId}.notifNewQuestion` rồi gửi OneSignal tới `external_id = toUserId`.
- Khi có comment mới: client gọi với `type: 'new_comment'`, `answerId`, `content`. Webhook đọc `answers/{answerId}.userId`, kiểm tra `users/{userId}.notifNewComment` rồi gửi OneSignal.

### Bổ sung (Tracking + Submit API)

- Submit câu hỏi ẩn danh:
  - `POST {API_BASE_URL}/submitQuestion`
  - Body: `{ toUserId, content, fid }`
  - Response: `{ questionId, trackingCode }`
- Tra cứu trạng thái:
  - `POST {API_BASE_URL}/getQuestionTrackingStatus`
  - Body: `{ trackingCode, clientKey }`
  - Response: `{ status, createdAt, answeredAt, isPublished, answerId }`
- Tracking code hiện dùng format 6 ký tự chữ+số (ví dụ `AD79HQ`).

### Bổ sung (Answer AI Classification)

- Endpoint:
  - `POST {API_BASE_URL}/classifyAnswer`
  - Header: `Authorization: Bearer <Firebase ID token>`
  - Body: `{ answerId }`
- Hành vi:
  - Chỉ classify khi answer đã `isPublished == true`
  - Nếu đã classify xong (`aiClassificationStatus == done`) thì trả dữ liệu cache (idempotent)
  - Ghi field vào `answers`: `aiCategory`, `aiTags`, `aiTagIds`, `aiTagRefs`, `aiClassificationStatus`, `aiClassifiedAt`, ...
- Taxonomy config:
  - Firestore doc: `app_config/ai_classification`
  - Ví dụ fields: `enabled`, `version`, `categories`, `maxTags`, `promptHint`, `tags[]`
  - `tags[]` nên có cấu trúc: `{ id, slug, label, color, category }`
  - `color` sẽ được backend chuẩn hóa theo palette trong `.docs/UI_UX_SPECS.md`; màu ngoài palette sẽ fallback về màu neutral.

#### Backfill answer cũ

```bash
cd webhook
node scripts/backfillClassifyAnswers.js --limit=100
# dry run:
node scripts/backfillClassifyAnswers.js --limit=100 --dry-run
```

## 5. Khi đã có Blaze

Có thể tắt OneSignal + Vercel webhook API, bật lại Firebase Functions cho toàn bộ luồng notification/submit nếu muốn thống nhất hạ tầng.
