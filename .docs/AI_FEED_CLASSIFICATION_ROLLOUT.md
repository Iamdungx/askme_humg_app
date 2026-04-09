# AI Feed Classification — Test Matrix & Rollout

Tài liệu này dùng cho rollout tính năng phân loại AI cho feed theo luồng:

- App publish answer
- App gọi `POST /api/classifyAnswer`
- Vercel gọi Gemini
- Ghi label/tags vào `answers`

## 1) Chuẩn bị trước rollout

- Đã deploy endpoint `webhook/api/classifyAnswer.js`
- Đã cấu hình Vercel env:
  - `FIREBASE_SERVICE_ACCOUNT_JSON`
  - `GEMINI_API_KEY`
  - `GEMINI_MODEL` (khuyến nghị `gemini-2.5-flash-lite`)
  - `GEMINI_FALLBACK_MODEL` (khuyến nghị `gemini-2.5-flash`)
- Đã tạo Firestore config: `app_config/ai_classification`
  - Co the seed nhanh qua app script: `make seed` (hoac `cd scripts && npx ts-node seed.ts`)

Ví dụ config:

```json
{
  "enabled": true,
  "version": "v1",
  "categories": ["hoc_tap", "su_kien", "doi_song", "tuyen_dung", "khac"],
  "maxTags": 5,
  "promptHint": "uu tien context sinh vien HUMG",
  "tags": [
    { "id": "tag_hoc_bong", "slug": "hoc_bong", "label": "Hoc bong", "color": "#2E7D32", "category": "hoc_tap" },
    { "id": "tag_lich_thi", "slug": "lich_thi", "label": "Lich thi", "color": "#1565C0", "category": "hoc_tap" },
    { "id": "tag_tuyen_thuc_tap", "slug": "tuyen_thuc_tap", "label": "Tuyen thuc tap", "color": "#6A1B9A", "category": "tuyen_dung" }
  ]
}
```

## 2) Test matrix (bắt buộc)

### A. Endpoint auth/authz

- **A1 - missing token**
  - Input: gọi `/api/classifyAnswer` không có token
  - Expect: `401 invalid_or_missing_token`
- **A2 - token không hợp lệ**
  - Input: bearer token giả
  - Expect: `401 invalid_or_missing_token`
- **A3 - không phải chủ answer**
  - Input: user A gọi classify answer của user B
  - Expect: `403 forbidden`

### B. Luồng nghiệp vụ classify

- **B1 - answer chưa publish**
  - Input: `isPublished=false`
  - Expect: `409 answer_not_published`
- **B2 - classify thành công**
  - Expect:
    - `aiClassificationStatus = done`
    - có `aiCategory`, `aiTags`, `aiTagIds`, `aiTagRefs`, `aiClassifiedAt`
- **B3 - idempotent**
  - Gọi lại cùng `answerId`
  - Expect: trả `cached: true`, không classify lặp
- **B4 - AI lỗi/timeout**
  - Expect:
    - API trả `502 classification_failed`
    - Firestore set `aiClassificationStatus = failed`

### C. Luồng app publish callback

- **C1 - answer compose publish ngay**
  - Publish xong, app không treo
  - Sau vài giây doc `answers` có nhãn AI
- **C2 - publish saved answer từ inbox**
  - Publish xong, app vẫn refresh feed bình thường
  - Doc answer được classify
- **C3 - classify fail**
  - Publish vẫn thành công, chỉ classify fail non-blocking

### D. UI feed

- **D1 - answer có label/tags**
  - `FeedItemCard` hiển thị chip category + tối đa 3 tags
- **D2 - answer chưa classify**
  - UI không crash, không hiện chip rác

## 3) Backfill dữ liệu cũ

Chạy trên thư mục `webhook/`:

```bash
node scripts/backfillClassifyAnswers.js --limit=100 --dry-run
node scripts/backfillClassifyAnswers.js --limit=100
```

Khuyến nghị:

- Chạy nhiều batch nhỏ (100-200)
- Theo dõi log failed để retry
- Màu tag trong config luôn bám palette `.docs/UI_UX_SPECS.md` để đảm bảo hiển thị nhất quán dark/light

## 4) Rollout theo 2 pha

### Phase 1 — Silent write

- Bật classify endpoint + publish callback
- Chưa bắt buộc hiển thị quá nhiều ở UI (đã có chip nhẹ)
- Quan sát 24-48h:
  - `done/fail ratio`
  - latency endpoint
  - số lượng request 429/502

### Phase 2 — Full rollout

- Chạy backfill cho dữ liệu cũ
- Bật hiển thị label rộng rãi (nếu muốn thêm filter ở tương lai)
- Theo dõi chi phí Gemini theo ngày

## 5) Rollback plan

Nếu có sự cố:

- Set `app_config/ai_classification.enabled = false`
- Endpoint trả `status: disabled` và dừng classify
- Luồng publish feed vẫn hoạt động bình thường
