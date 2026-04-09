---
name: askmehugm-sequence-drawio
description: Draw clean, report-ready UML Sequence Diagrams for AskmeHUMG in draw.io (.drawio XML). Uses the hand-edited Sequence-01 as the golden layout template and enforces readable spacing, wrapped labels, activation bars, and combined fragments (alt/loop/opt) with a tab ("tai").
---

# AskmeHUMG – Sequence Diagrams (draw.io)

Skill này **chỉ** dùng để vẽ **UML Sequence Diagram** cho AskmeHUMG bằng **file `.drawio` XML**.  
Mục tiêu: **đọc được ngay**, **không chụm chữ**, **không đè lên nhau**, style **đơn sắc** (stroke `#666666`, activation `#f5f5f5`).

**Golden template (bắt buộc bám theo):**
- `.docs/use_case/diagrams/Sequence-01_dang_nhap_google_report.drawio`

Nguồn quy tắc UML chuẩn + draw.io:
- draw.io blog “Create a sequence diagram” (lifeline dotted, activation, solid/dashed messages, frame fragments)
- uml-diagrams.org “Combined Fragment” (alt/opt/loop semantics + guard)

---

## 1) Ground truth & scope

- Diagram phải bám theo `.docs/report_sequence_diagrams/*.md` và `.docs/use_case/UC-*.md`.
- Lifelines là **khối hệ thống/service**, không xuống tới widget/repository.
- Chỉ chọn **3–5 lifeline** quan trọng nhất (Actor + App + backend).

---

## 2) Layout template (chuẩn số học – dùng y như `Sequence-01`)

### 2.1 Page & title
- `pageWidth=827`, `pageHeight=1169`.
- Title cell:
  - `x=60, y=30, w=780, h=30`
  - `fontSize=14`, `fontStyle=1`, align center.

### 2.2 Lifeline headers (rectangles)

Mặc định header:
- `width=140`, `height=40`, `y=90`
- `strokeColor=#666666; fillColor=none; fontSize=11; fontStyle=1; align=center; whiteSpace=wrap`

X positions (5 lifeline như template):
- L1: `x=60`
- L2: `x=220`
- L3: `x=380`
- L4: `x=540`
- L5: `x=700`

Nếu ít hơn 5 lifeline:
- Dùng subset các `x` trên, giữ khoảng cách đều 160px.

### 2.3 Lifeline vertical lines (dashed)

Lifeline line:
- vertex `shape=line; dashed=1; strokeColor=#666666`
- `y=130`, `height=900`

Centers tương ứng header (template):
- L1: `x=130`
- L2: `x=290`
- L3: `x=450`
- L4: `x=610`
- L5: `x=770`

### 2.4 “Stub” nối header → lifeline/activation (khuyến nghị)

Để nhìn “chuẩn” như tool UML:
- Thêm một edge nét đứt ngắn `dashed=1; endArrow=none` nối từ **lifeline line** xuống **header** (hoặc ngược lại) như trong `Sequence-01` (`jqn_* -256`, `-252`).
- Mục tiêu: header không “lơ lửng”, dễ nhận ra trục dọc.

### 2.5 Activation bars

Activation rectangle:
- `width=12`
- `strokeColor=#666666; fillColor=#f5f5f5; rounded=0`
- X đặt lệch trái 6px so với center lifeline:
  - Ví dụ center 290 → activation `x=284`
- Activation **không được che chữ**. Nếu bị chật: dịch text box, không đổi style.

Nguyên tắc độ dài:
- Bắt đầu ngay trước message đầu tiên liên quan, kết thúc ngay sau message cuối cùng liên quan.

---

## 3) Messages & labels (để không chụm chữ)

### 3.1 Mỗi bước = 1 mũi tên riêng (edge)

Edge style:
- `endArrow=open; strokeColor=#666666; rounded=0; html=1`
- Return/response: `dashed=1`

Y spacing:
- Bắt đầu khoảng `y=160`
- Mỗi message cách nhau **~60px** (tham chiếu `Sequence-01`: 160, 230, 290, 350, 410, 500, 560, 620…)
- Nếu text dài / nhiều lifeline → tăng spacing (70–90px), không để chồng.

### 3.2 Label KHÔNG đặt trực tiếp trên edge khi dài

Quy tắc quan trọng (rút ra từ file bạn sửa tay):
- **Ưu tiên dùng text vertex riêng** cho label như `Sequence-01` (`jqn_* -229`, `-231`, `-233`…).
- Mũi tên chỉ là mũi tên (edge), label là text vertex nằm phía trên/giữa mũi tên.

Text vertex style:
- `text; html=1; strokeColor=none; fillColor=none; whiteSpace=wrap; fontSize=10`
- `align=center` hoặc `align=left` tùy vị trí (giống template).

Kích thước textbox:
- Hãy đặt `width` theo độ dài message để tự wrap:
  - ngắn: 120–180
  - trung bình: 220–320
  - dài: 360–420

### 3.3 Nếu text dài → bắt buộc xuống dòng

Khi label dài:
- Chèn newline ngay trong value bằng `&#xa;` (XML) để xuống dòng thủ công.
- Không để một câu chạy xuyên qua nhiều lifeline.

Ví dụ value:
- `4) App → Firestore: tạo otpRequests/{uid}&#xa;(email, otpHash, expiresAt, attempts=0)`

---

## 4) Combined fragments (alt/opt/loop) – khung + “tai”

### 4.1 Frame shape

- Dùng rectangle bao quanh nhóm message.
- Stroke `#666666`, fill `none`.

### 4.2 “Tai” (tab) ở góc trái trên

- Thêm rectangle nhỏ ở góc trên trái frame:
  - `fillColor=#f5f5f5; strokeColor=#666666; fontSize=10`
  - value: `alt`, `loop`, `opt`

### 4.3 Alt lanes

- Alt có nhiều operand:
  - Chia lane bằng line nét đứt ngang (`shape=line; dashed=1; strokeColor=#666666`)
  - Guard/điều kiện ghi dạng `[cond]` ở đầu từng lane (text vertex).

### 4.4 Loop guard

- Ghi guard kiểu `[retry <= 3]`, `[for each item]`… (text vertex trong frame).

### 4.5 Khi nào vẽ fragment (tóm tắt)

- **Nên vẽ** nếu `.md` mô tả rõ A1/A2/A3… hoặc loop/retry.
- **Có thể bỏ** nếu chỉ là lỗi chung chung và vẽ vào làm rối (ưu tiên dễ đọc).

---

## 5) Checklist trước khi xuất file `.drawio`

- [ ] Lifeline header + lifeline dashed line rõ ràng, thẳng hàng.
- [ ] Có activation cho `App` và backend chính.
- [ ] Mỗi message một dòng, y spacing đều, không chồng chữ.
- [ ] Label dài đã wrap (`whiteSpace=wrap`) và có newline `&#xa;` khi cần.
- [ ] Return message dùng dashed.
- [ ] Alt/loop/opt có frame + “tai” + lane separators (nếu alt).
- [ ] Toàn sơ đồ đơn sắc (`#666666`, `#f5f5f5`), không màu mè.

