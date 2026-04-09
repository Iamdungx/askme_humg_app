---
name: askmehugm-uml-drawio
description: Guides the agent to design and describe UML Use Case, Sequence, and Activity diagrams for the AskmeHUMG system using draw.io, based strictly on the project docs and implementation status. Use when the user asks to draw or refine diagrams in Chapter 2 (analysis/design) for this project.
---

# AskmeHUMG UML Diagrams (draw.io)

This skill defines **how to design and output UML diagrams** (Use Case, Sequence, Activity) for **AskmeHUMG** in **draw.io** format. The agent must **always produce an importable file** (`.drawio` XML) so the user can open it directly in draw.io / diagrams.net.

The agent should never invent new features; diagrams must stay aligned with the **current code + docs**.

---

## 1. Scope & Ground Truth

- **Project only**: This skill applies **only** to the AskmeHUMG app in this repo.
- **Authoritative sources** (in order):
  - `.dart_tool/guide.md`
  - `.docs/SRS.vi.md`
  - `.docs/use_case/UC-*.md`
  - Actual code under `lib/`, `functions/`, and `.docs/OVERVIEW.md`, `.docs/BACKLOG.md`
- **Actors are fixed to 4**:
  - `Anonymous Sender`
  - `Host`
  - `Viewer`
  - `Admin`
- **No feature overclaiming**:
  - Do **not** draw flows that rely on features that are only in BACKLOG or “định hướng” (e.g. App Check + advanced rate limiting) unless code and docs clearly show they are implemented on the current branch.

If anything is unclear, the agent should **ask the user** or **simplify the diagram**, not fabricate steps.

---

## 2. General Rules for All Diagrams

When the user asks for any UML diagram (Use Case / Sequence / Activity) for AskmeHUMG:

1. **Confirm the UC and level**:
   - Identify the relevant **UC code** (e.g. `UC-1.1`, `UC-3.1`, `UC-3.3`), from `.docs/use_case/`.
   - Confirm diagram type: **Use Case**, **Sequence**, or **Activity**.
2. **Stay at high-level blocks**:
   - Use coarse components: `Mobile App (Flutter)`, `Firebase Auth`, `Cloud Functions`, `Firestore`, `FCM/OneSignal`, etc.
   - Do **not** go down to individual widgets, repositories, or specific class names unless the user explicitly wants that.
3. **Naming convention**:
   - Always include **UC code + name** in the diagram title, for example:
     - `Use Case Diagram – UC-3.1 Gửi câu hỏi ẩn danh`
     - `Sequence Diagram – UC-1.1 Đăng nhập bằng Google`
4. **Output – bắt buộc tạo file để import**:
   - **Bắt buộc**: Mỗi khi được yêu cầu vẽ sơ đồ (Use Case / Sequence / Activity), agent phải **tạo ra một file `.drawio`** (định dạng XML của draw.io) mà người dùng có thể mở trực tiếp trong draw.io hoặc diagrams.net.
   - **Vị trí lưu file**: Lưu vào `.docs/use_case/diagrams/` với tên có ý nghĩa, ví dụ: `UC-3.1_submit_question.drawio`, `actors_askmehumg.drawio`, `sequence_UC-1.1.drawio`. Nếu thư mục chưa có thì tạo mới.
   - **Nội dung file**: XML hợp lệ theo cấu trúc draw.io (root `<mxfile>`, `<diagram>`, `<mxGraphModel>`, các `<mxCell>` cho shape và edge). Có thể tham khảo format mẫu trong skill hoặc tài liệu draw.io XML.
   - **Bổ sung**: Ngoài file .drawio, agent có thể gửi kèm mô tả ngắn từng bước hoặc checklist để người dùng chỉnh sửa trong draw.io nếu cần; không thay thế việc phải có file.
   - **Không** dùng PlantUML/Mermaid làm đầu ra chính; đầu ra chính là **file .drawio**.

---

## 3. Use Case Diagrams (draw.io)

### 3.1 Use Case – System Overview

When the user wants a **tổng quát** use case diagram:

- **Kích thước ô use case (chuẩn, tránh phải sửa tay)**:
  - Mặc định **bắt buộc** mọi ellipse use case dùng **width=140, height=60** (như file `use_case_overview.drawio` chuẩn).
  - Nếu label quá dài, **ưu tiên xuống dòng** thay vì tăng width; chỉ tăng width khi thật cần thiết.
- **Bố cục 2 cột (để “ngay ngắn” và ít rối dây)**:
  - Use case xếp thành **2 cột** với `x` cố định theo cột (ví dụ: cột trái `x=420`, cột phải `x=650`).
  - `y` tăng theo lưới (gridSize=10), khuyến nghị bước **80** hoặc **90** để các hàng thẳng.
  - Cột trái: nhóm `Anonymous Sender` + các UC của `Host`.
  - Cột phải: nhóm UC của `Viewer` + `Admin` (moderation).
- **System boundary**:
  - Draw a big rectangle labelled `Hệ thống AskmeHUMG`.
- **Actors** (outside boundary), always these four:
  - `Anonymous Sender`
  - `Host`
  - `Viewer`
  - `Admin`
- **Vị trí actor (không vi phạm UML)**:
  - Actor có thể đặt **bên trái hoặc bên phải** biên hệ thống (hoặc chia 2 bên) miễn là **nằm ngoài boundary** và association nối đúng use case. UML không bắt buộc actor phải ở bên trái.
- **Group để kéo dễ**:
  - Mỗi actor **bắt buộc** được **group** cùng label (actor + text) để khi di chuyển không bị lệch tên.
- **Dây nối chụm/bundle để đỡ rối**:
  - **Quy tắc entry/exit theo phía actor** (giúp dây ngắn và không cắt):
    - Actor **bên trái** → use case: dùng `exitX=1; exitY=0.5` và `entryX=0; entryY=0.5`.
    - Actor **bên phải** → use case: dùng `exitX=0; exitY=0.5` và `entryX=1; entryY=0.5`.
  - Với 1 actor nối nhiều use case, ưu tiên **chụm dây** bằng cách dùng **cùng exit point** và chỉ khác `entryY` (hoặc ngược lại), hạn chế dây cắt nhau.
  - Nếu draw.io auto-route làm rối, dùng edge style **orthogonal/elbow** (đường gấp khúc) để dây chạy song song.
- **Main use cases inside the boundary** (names + UC codes from docs, examples):
  - `UC-1.1 Đăng nhập bằng Google`
  - `UC-1.3 Xác minh email HUMG bằng OTP`
  - `UC-2.1 Tạo link chia sẻ hồ sơ`
  - `UC-3.1 Gửi câu hỏi ẩn danh`
  - `UC-3.2 Quản lý hộp thư câu hỏi`
  - `UC-3.3 Trả lời và công bố câu hỏi`
  - `UC-4.1 Xem bảng tin`
  - `UC-4.2 Thích / bỏ thích`
  - `UC-4.3 Bình luận`
  - `UC-5.1 Báo cáo nội dung`
  - `UC-5.2 Quản trị xử lý báo cáo`
- **Connections**:
  - Connect each actor to the use cases it participates in, following the use-case docs and SRS.
  - Do **not** introduce extra use cases that are not documented.

### 3.2 Use Case – Single UC Detail

When drawing a **detailed use case diagram for one UC-x.y**:

1. Draw the system boundary: `Hệ thống AskmeHUMG` hoặc `AskmeHUMG – Module <tên>` (ví dụ: `AskmeHUMG – Module Quản trị`).
2. Place only the actors actually involved in this UC (subset of the 4 core actors).
3. Inside, draw a single ellipse with the name `UC-x.y <Tên use case>` from the relevant `.md` file.
4. If the UC explicitly describes `include` / `extend` relationships in docs, draw them; otherwise, **do not invent them**.

**Layout chuẩn (đẹp mắt, hạn chế sửa tay):**

- **Kích thước ô use case (mặc định)**: mọi ellipse use case dùng **width=140, height=60**. Không tùy tiện đổi size để đồng bộ giữa các sơ đồ.
- **System boundary**: width ≥ 650, height đủ chứa tất cả use case. Tránh boundary quá nhỏ.
- **Use case chính**: đặt giữa boundary (x ~330, y ~130).
- **Include chain**: xếp dọc dưới use case chính (y tăng dần: 260, 400…), cùng cột giữa.
- **Extend use cases**: đặt bên trái (Action A) và bên phải (Action B, alternative) của use case chính để mũi tên «extend» nối gọn, không chồng chéo.
- **Actor**:
  - Actor có thể đặt **bên trái hoặc bên phải**. Khuyến nghị: **actor chính** một bên, **tác nhân hệ thống ngoài** (Firebase Auth / Firestore / Cloud Functions nếu có trong use case diagram) bên còn lại.
  - **Bắt buộc group actor + label** (shape + text) để kéo không bị lệch.
- **Màu sắc**: chỉ dùng trung tính (`fillColor=#f5f5f5`, `strokeColor=#666666` cho boundary). Use case và actor không tô màu (để mặc định).
- **Note SRS**: có thể bỏ hoặc đặt nhỏ gọn nếu không cần thiết; tránh chiếm nhiều không gian.
- **Dây nối chụm/bundle**:
  - Khi 1 actor có nhiều association, đặt các use case theo **cụm** gần actor đó (cột/trục riêng) và dùng **đường orthogonal** để dây đi song song.
  - Dùng chung `exitX/exitY` cho actor và tinh chỉnh `entryY` ở use case để dây “chụm” và ít cắt nhau.

The agent should:

- First restate: **UC code, name, main actor(s), goal**.
- Then list **step-by-step instructions**: what to create in draw.io, where to place it, and what to label.

---

## 4. Sequence Diagrams (khối lớn)

Sequence diagrams must stay ở **mức hệ thống / service**, không xuống tới widget hay repository cụ thể.

> **Khuyến nghị**: Khi tập trung vẽ Sequence “chuẩn report” (layout cố định, xuống dòng, tránh chụm chữ), dùng skill riêng:  
> `.cursor/skills/askmehugm-sequence-drawio/SKILL.md`

### 4.1 Lifeline pattern (sắp xếp và chọn đối tượng)

Cho đa số UC, dùng một tập con các lifeline sau, từ trái sang phải:

1. `Actor` – ví dụ `Host`, `Anonymous Sender`, `Viewer`, `Admin`
2. `Mobile App (AskmeHUMG – Flutter)`
3. `Firebase Auth` (UC-1.1, UC-1.3)
4. `Cloud Functions` (khi có HTTP / Firestore trigger)
5. `Cloud Firestore`
6. `Firebase Storage` (upload avatar/media)
7. `FCM / OneSignal` (chỉ khi nhánh hiện tại **đã** gửi push thực sự)

- Chỉ chọn **3–5 lifeline quan trọng nhất** để sơ đồ không bị loãng.
- Xác định lifeline dựa trên UC doc + implementation (`lib/`, `functions/`), **không bịa thêm backend** chưa có thật.

### 4.2 Layout chuẩn trong draw.io (rất quan trọng)

Khi vẽ sequence trong draw.io, luôn làm theo layout sau để **dễ đọc và ít phải chỉnh tay**:

- **Header lifeline**:
  - Mỗi lifeline là **một hình chữ nhật** (header) nằm cùng một hàng (y ≈ 80–100), width ~140–160.
  - Text header ngắn gọn: `Host`, `App`, `Google Sign-In`, `Firebase Auth`, `Cloud Firestore`…
- **Đường sống (lifeline)**:
  - Dùng shape `line` dọc, nét đứt, `strokeColor=#666666`, đặt **ngay giữa** mỗi header.
  - Chiều cao khoảng từ y ≈ 130 đến gần đáy trang; **không** dùng edge nối header → điểm ảo (tránh auto‑route).
- **Activation (bắt buộc với lifeline chính)**:
  - Với các lifeline chính (thường là `App` + backend như `Firebase Auth`, `Cloud Firestore`, `Cloud Functions`), luôn vẽ **thanh dọc hẹp** (rectangle):
    - width ≈ 10–14, `strokeColor=#666666`, `fillColor=#f5f5f5` (xám rất nhạt, không dùng màu sặc sỡ).
    - Đặt đè lên lifeline, kéo từ khi bắt đầu nhận/gửi message đến khi kết thúc cụm xử lý.
  - Lifeline vẫn là nét đứt xám nhìn thấy **trên/dưới** activation (giống ví dụ UML chuẩn), không cần màu xanh/đỏ.
  - Không để activation che kín text; nếu cần, **dịch message/snippet sang trái/phải** để mọi label đều đọc được.

### 4.3 Messages – cách đặt mũi tên + text

- **Mỗi bước = 1 mũi tên ngang + label ngay trên nó**:
  - Dùng `endArrow=open`, `strokeColor=#666666`, từ lifeline nguồn tới lifeline đích (không dùng màu xanh dương).
  - Đặt y theo **bước nhảy đều** (ví dụ: 150, 190, 230, 270, …) để các mũi tên **song song, không đè nhau**.
  - Text message **ngắn gọn**, tối đa ~40 ký tự, mô tả động từ chính:
    - `1) Bấm "Đăng nhập bằng Google"`
    - `2) App → Google: mở chọn tài khoản`
    - `3) Google → App: trả credential`
    - `4) App → Firebase Auth: signInWithCredential()`
  - Ưu tiên đặt label **trực tiếp trên edge**; chỉ dùng text rời (vertex riêng) khi cần xuống dòng nhiều hơn.
- **Reply / return**:
  - Use dashed arrow (`dashed=1`) khi thể hiện response, ví dụ:
    - `Firebase Auth → App: Firebase User + ID token`
- **Nguyên tắc “đọc được ngay”**:
  - Tuyệt đối **tránh chồng chữ** (label đè lên nhau hoặc đè lên activation).
  - Nếu bị chật, ưu tiên:
    - Tăng khoảng cách y giữa hai message kế tiếp.
    - Dịch label nhẹ sang trái/phải (trong cùng hàng) thay vì để trùng vị trí.
  - Khi nhìn sơ đồ lần đầu, người đọc có thể **đọc liền từ 1 → n** mà không phải “đoán” bước.
- Không vẽ từng call nhỏ nội bộ (repository, provider); chỉ giữ các **bước “business” lớn** giống mô tả trong file report.

### 4.4 Khung `loop` / `alt` / `opt` (Combined Fragment)

- **Hình dạng chuẩn UML**:
  - Dùng **hình chữ nhật** bao toàn bộ các message liên quan.
  - Góc trên‑trái có **“tai” bo ngang** để ghi operator (`loop`, `alt`, `opt`) – giống ví dụ UML chuẩn bạn gửi.
  - Bên trong, guard (điều kiện) có thể ghi dạng `[cond]` ở dòng đầu.
- **Khi nào NÊN dùng fragment**:
  - Khi file `.md` hoặc UC mô tả **rõ ràng nhánh A1/A2/A3 hoặc điều kiện lặp** (ví dụ hủy, lỗi Auth, lỗi Firestore, retry tối đa 3 lần).
  - Khi nhánh đó **là một phần quan trọng của luồng nghiệp vụ** mà người đọc báo cáo cần nhìn thấy ngay.
- **Khi nào CÓ THỂ BỎ fragment cho đỡ rối**:
  - Nếu `.md` chỉ nhắc nhanh “có thể xảy ra lỗi mạng” mà không phân tích luồng, và việc vẽ alt/loop làm sơ đồ quá nặng, có thể **không vẽ fragment**, chỉ mô tả trong text hoặc comment ngoài sơ đồ.
  - Nguyên tắc: **ưu tiên sơ đồ dễ đọc**; nếu fragment không giúp hiểu thêm đáng kể, có thể bỏ.
- **Alt cho A1/A2/A3**:
  - Operator: `alt`.
  - Chia thành **các lane ngang** bằng 1–2 đường line nét đứt bên trong:
    - Lane 1: A1 – điều kiện và kết quả ngắn gọn (1–2 câu).
    - Lane 2: A2 – tương tự.
    - Lane 3: A3 – tương tự.
  - Không nhồi cả đoạn văn dài; nếu cần mô tả chi tiết, đưa vào phần text của file `.md`, trong sơ đồ chỉ ghi tóm tắt:
    - `A1 – User hủy chọn tài khoản → dừng tại màn hình Login`
    - `A2 – Lỗi xác thực → hiển thị thông báo, cho thử lại`
    - `A3 – Lỗi Firestore → hiển thị lỗi, không vào Feed`
- **Loop**:
  - Chỉ dùng khi UC thực sự có lặp (ví dụ: retry nhiều lần, duyệt danh sách).
  - Operator: `loop`, guard ghi dạng `[each question]`, `[retry <= 3]`… ở dòng đầu fragment.

### 4.5 Ví dụ flow (UC-3.1 Gửi câu hỏi ẩn danh)

Ở mức logic (trước khi vẽ XML), luôn liệt kê flow dạng numbered list ngắn gọn rồi mới map sang mũi tên:

1. `Anonymous Sender` → `App`: *Nhập nội dung + nhấn Gửi*.
2. `App` → `Cloud Function submitQuestion`: *Gửi request chứa nội dung + toUserId*.
3. `Cloud Function` → `Firestore`: *Tạo document mới trong `questions`*.
4. (Nếu đã triển khai FCM/OneSignal) `Cloud Function` → `FCM / OneSignal`: *Push "Câu hỏi mới" cho Host*.
5. `Cloud Function` → `App`: *Trả về kết quả thành công / thất bại*.
6. `App` → `Anonymous Sender`: *Hiển thị snackbar thành công hoặc lỗi*.

Khi chuyển sang draw.io:

- Mỗi dòng trên tương ứng **một message arrow** như mô tả ở 4.3.
- Chỉ bổ sung alt‑frame nếu file report có A1/A2/A3 tương ứng.

---

## 5. Activity Diagrams (khối lớn)

Activity diagrams describe the **business flow** with decisions and loops, still at the “use-case step” level.

### 5.1 Shape conventions (for draw.io)

- **Start**: solid black circle.
- **End**: circle with a black border and inner black dot, or a labelled “End” state.
- **Activity**: rounded rectangle with 1 concise action (e.g. “Nhập nội dung câu hỏi”).
- **Decision**: diamond shape with yes/no (or equivalent) outgoing edges.

### 5.2 Example pattern (UC-3.1 Gửi câu hỏi ẩn danh)

The agent should describe the diagram as a linear list:

1. Start node → `Người dùng mở màn hình hồ sơ Host`.
2. → Activity: `Nhập nội dung câu hỏi`.
3. → Decision: `Nội dung trống hoặc vượt quá 300 ký tự?`
   - **Yes** → Activity: `Hiển thị thông báo lỗi / yêu cầu nhập lại` → quay lại `Nhập nội dung câu hỏi`.
   - **No** → tiếp tục.
4. → Activity: `Gửi request tới Cloud Function submitQuestion`.
5. → Decision: `Gửi thành công?`
   - **Yes** → Activity: `Hiển thị thông báo gửi thành công`.
   - **No** → Activity: `Hiển thị thông báo lỗi hệ thống`.
6. → End node.

The agent should:

- Emphasize **validation rules** that are clearly implemented (e.g. 300 chars, email domain, verified HUMG).
- Avoid mentioning checks that are not in code or SRS.

### 5.3 Layout “thẳng hàng” cho Activity (kinh nghiệm từ UC-1.1)

Khi vẽ activity diagram cho các UC khác, **luôn áp dụng layout sau** (đã chỉnh tay đẹp trong `activity_UC-1.1_google_sign_in.drawio`):

- **Một trục dọc chính cho main flow**  
  - Chọn trước một cột trung tâm (ví dụ `x ≈ 150–200`) rồi đặt **Start → các Activity chính → các Decision → Activity → End thành công** đều bám theo cột này.  
  - Tất cả hình `rounded rectangle` và `diamond` trong “happy path” phải căn tâm gần cùng `x` để nhìn như một đường thẳng từ trên xuống.

- **Một cột phải cho các nhánh lỗi / hủy**  
  - Các activity “Hiển thị lỗi…”, “Hiển thị lại màn hình đăng nhập”… và end-state lỗi đặt ở **cột bên phải** (ví dụ `x ≈ 400–520`), thẳng hàng với nhau.  
  - Mỗi decision nhánh **Yes (thành công)** tiếp tục đi thẳng xuống cột giữa, **No (lỗi/hủy)** đi ngang sang cột phải rồi xuống.

- **Khoảng cách dọc đều nhau**  
  - Dùng bước `y` cố định (60–80px) giữa các node cùng luồng để đồ thị “thở đều”: ví dụ 90 → 150 → 210 → 275 → 390 → 450 → 570 → 660 → 780…  
  - Tránh chỗ dày chỗ thưa; nếu cần chèn thêm node, đẩy cả cụm bên dưới xuống, giữ nguyên “lưới” khoảng cách.

- **Edge luôn orthogonal, nối vào tâm cạnh**  
  - Mọi cạnh dùng `edgeStyle=orthogonalEdgeStyle; rounded=0` để đường đi gấp khúc 90°, không xiên chéo.  
  - Main flow: cạnh đi theo trục dọc, xuất phát từ cạnh dưới của node phía trên, vào cạnh trên của node phía dưới (`entryX=0.5; entryY=0`).  
  - Nhánh rẽ sang phải: đi ngang từ cạnh phải decision, sau đó gập xuống activity ở cột phải, rồi thẳng xuống end-state.

- **Decision nhỏ gọn, text xuống dòng**  
  - Diamond thường dùng `width ≈ 80–90`, `height ≈ 80`, text chia 2 dòng bằng `<br>` và có thể giảm `fontSize` (9–11) để không tràn ra ngoài.  
  - Nhãn cạnh dùng cụm ngắn: “Có”, “Không / Hủy”, “Thành công”, “Thất bại”, “Có lỗi”, “Không lỗi”.

- **Start/End thống nhất style**  
  - Start: hình tròn đặc `ellipse` fill đen.  
  - End: dùng `shape=endState` (vòng tròn hai lớp) cho **tất cả** điểm kết thúc (thành công và thất bại) để sơ đồ nhất quán.

Áp dụng đúng các quy tắc này để mọi activity diagram khác (OTP, gửi câu hỏi ẩn danh, trả lời & xuất bản, like/comment, báo cáo & kiểm duyệt) đều có **layout thẳng hàng, ít dây xiên và thống nhất giữa các chương**.

---

## 6. Quick Checklists per Diagram Type

### 6.1 Use Case checklist

Before finalizing guidance for a use case diagram, verify:

- [ ] All actors are chosen from `{Anonymous Sender, Host, Viewer, Admin}`.
- [ ] Each use case has a UC code and name matching `.docs/use_case/*.md`.
- [ ] Relationships actor ↔ use case are backed by UC docs and SRS.
- [ ] No undocumented features or future backlog items are introduced.

### 6.2 Sequence checklist

- [ ] Lifelines are high-level components (App, Firebase Auth, Cloud Functions, Firestore, FCM/OneSignal).
- [ ] Steps follow the main success scenario in the UC description.
- [ ] Optional flows (error cases) are included only if described in UC or visible in code.

### 6.3 Activity checklist

- [ ] There is a clear Start and End.
- [ ] Activities reflect business steps, not low-level code.
- [ ] Decisions reflect real validation / branching implemented in the system.
- [ ] Loops (e.g. re-enter invalid input) are modelled where they make sense and are described in UC or UI behaviour.

When in doubt, the agent should **simplify** the diagram and clearly state assumptions so the student can adjust in draw.io.

---

## 7. Bắt buộc: Đầu ra phải là file .drawio

Khi user yêu cầu vẽ bất kỳ sơ đồ nào (Use Case, Sequence, Activity hoặc sơ đồ tác nhân):

1. **Tạo và ghi file** có đuôi `.drawio` (nội dung là XML draw.io), lưu tại `.docs/use_case/diagrams/` (tạo thư mục nếu chưa có).
2. **Tên file** gợi ý: `actors_askmehumg.drawio`, `UC-1.1_google_sign_in.drawio`, `sequence_UC-3.1.drawio`, `activity_UC-3.1.drawio`, v.v.
3. **Nội dung**: Cấu trúc XML chuẩn draw.io (`<mxfile>`, `<mxGraphModel>`, `<root>`, các `<mxCell>` với `vertex`/`edge`), đủ shapes và đường nối để khi mở bằng draw.io sẽ hiển thị đúng sơ đồ.
4. **Không** chỉ mô tả bằng chữ hoặc chỉ đưa đoạn XML trong chat mà không ghi thành file; phải **dùng Write tool** (hoặc tương đương) để tạo file trong repo.

