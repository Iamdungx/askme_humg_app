# Use Case Index – AskmeHUMG

> Mỗi file UC là một đơn vị triển khai độc lập. Đọc file UC trước khi implement feature tương ứng.
> SRS Reference: [SRS.en.md](../srs/SRS.en.md)

---

## Thứ tự triển khai

```
Phase 0 – Hạ tầng (không có UC riêng)
Phase 1 – UC-1.1 → UC-1.3 → UC-1.2
Phase 2 – UC-2.2 → UC-2.1
Phase 3 – UC-3.1 → UC-3.2 → UC-3.3
Phase 4 – UC-4.1 → UC-4.2 → UC-4.3
Phase 5 – UC-5.1 → UC-5.2
```

---

## MODULE 1: Authentication

| UC | File | SRS FR | Priority | Trạng thái |
|---|---|---|---|---|
| UC-1.1 | [UC-1.1_google_sign_in.md](./UC-1.1_google_sign_in.md) | FR-02, NFR-03 | Critical | Pending |
| UC-1.2 | [UC-1.2_logout.md](./UC-1.2_logout.md) | FR-02 | High | Pending |
| UC-1.3 | [UC-1.3_verify_humg_email.md](./UC-1.3_verify_humg_email.md) | FR-02 | High | Pending |

**Dependency:** UC-1.1 phải hoàn thành trước tất cả UC còn lại (auth guard). UC-1.3 phụ thuộc UC-1.1.

---

## MODULE 2: Profile & Sharing

| UC | File | SRS FR | Priority | Trạng thái |
|---|---|---|---|---|
| UC-2.2 | [UC-2.2_view_profile.md](./UC-2.2_view_profile.md) | FR-10 | High | Pending |
| UC-2.1 | [UC-2.1_generate_deep_link.md](./UC-2.1_generate_deep_link.md) | FR-11 | High | Pending |

**Dependency:** UC-2.2 trước UC-2.1 (profile screen là landing page cho deep link).

---

## MODULE 3: Core Q&A

| UC | File | SRS FR | Priority | Trạng thái |
|---|---|---|---|---|
| UC-3.1 | [UC-3.1_submit_anonymous_question.md](./UC-3.1_submit_anonymous_question.md) | FR-01, NFR-01, NFR-03 | Critical | Pending |
| UC-3.2 | [UC-3.2_manage_inbox.md](./UC-3.2_manage_inbox.md) | FR-03 | High | Pending |
| UC-3.3 | [UC-3.3_answer_question.md](./UC-3.3_answer_question.md) | FR-04 | Critical | Pending |

**Dependency:** UC-3.2 và UC-3.3 require UC-1.1 (auth). UC-3.3 output feeds UC-4.1.

---

## MODULE 4: Feed & Interaction

| UC | File | SRS FR | Priority | Trạng thái |
|---|---|---|---|---|
| UC-4.1 | [UC-4.1_view_public_feed.md](./UC-4.1_view_public_feed.md) | FR-05, NFR-02 | High | Pending |
| UC-4.2 | [UC-4.2_like_answer.md](./UC-4.2_like_answer.md) | FR-06 | Medium | Pending |
| UC-4.3 | [UC-4.3_comment_on_answer.md](./UC-4.3_comment_on_answer.md) | FR-07 | Medium | Pending |

**Dependency:** UC-4.1 trước UC-4.2 và UC-4.3. UC-4.2 và UC-4.3 require UC-1.1 (auth).

---

## MODULE 5: Moderation

| UC | File | SRS FR | Priority | Trạng thái |
|---|---|---|---|---|
| UC-5.1 | [UC-5.1_report_content.md](./UC-5.1_report_content.md) | FR-08, FR-09 | Medium | Pending |
| UC-5.2 | [UC-5.2_admin_moderate.md](./UC-5.2_admin_moderate.md) | FR-09 | Medium | Pending |

**Dependency:** UC-5.1 require UC-1.1. UC-5.2 requires Admin Custom Claim setup.

---

## Bản đồ phụ thuộc

```
UC-1.1 (Auth)
    │
    ├──→ UC-1.3 (Verify HUMG Email OTP)
    ├──→ UC-1.2 (Logout)
    ├──→ UC-2.2 (View Profile)
    │       └──→ UC-2.1 (Deep Link)
    │               └──→ UC-3.1 (Submit Question)
    ├──→ UC-3.2 (Inbox)
    │       └──→ UC-3.3 (Answer) ──→ UC-4.1 (Feed)
    │                                     ├──→ UC-4.2 (Like)
    │                                     └──→ UC-4.3 (Comment)
    └──→ UC-5.1 (Report) ──→ UC-5.2 (Admin Moderate)
```

---

## Checklist tổng cho mỗi UC

Trước khi đánh dấu UC hoàn thành:
- [ ] Domain layer: entity (Freezed), repository interface, use case
- [ ] Data layer: model (Freezed + fromFirestore), datasource, repository impl
- [ ] Presentation layer: screen, widgets, provider (AsyncNotifier)
- [ ] Riverpod providers dùng `@riverpod` annotation
- [ ] Multi-collection write dùng `WriteBatch`
- [ ] Counter update dùng `FieldValue.increment()`
- [ ] `FirebaseException` map sang `Failure` sealed class
- [ ] Tất cả string qua `context.l10n.*`
- [ ] Không dùng `print()` — chỉ dùng `logger.d/e/w`
- [ ] Acceptance Criteria trong file UC đều pass
