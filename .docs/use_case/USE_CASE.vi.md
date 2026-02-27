# AskmeHUMG - Use Cases Specification

> **Tài liệu dành cho AI Assistant (Cursor/Copilot)**
> Khi thực hiện code một tính năng, hãy tham chiếu đến mã Use Case (Ví dụ: UC-1.1) tương ứng trong tài liệu này để đảm bảo đúng luồng nghiệp vụ (Business Logic) và thao tác Database.

---

## 1. Danh sách Tác nhân (Actors)

1. **Anonymous Sender:** Người dùng không đăng nhập, truy cập qua Deep Link.
2. **Host (Student):** Sinh viên HUMG đăng nhập bằng email `@humg.edu.vn`. Có trang cá nhân để nhận câu hỏi.
3. **Viewer:** Người dùng duyệt Public Feed. Chia làm 2 loại:
   - *Logged-in Viewer:* Sinh viên đã đăng nhập (chính là các Host khi đi lướt Feed).
   - *Guest Viewer:* Khách vãng lai, chưa đăng nhập.
4. **Admin (Quản trị viên):** Người được cấp quyền Admin thông qua Firebase Custom Claims (`admin: true`) hoặc có trường `role: 'admin'` trong collection `users`.

---

## 2. Chi tiết Use Cases theo Module

### MODULE 1: XÁC THỰC (AUTHENTICATION)

#### UC-1.1: Đăng nhập bằng Google (Google Sign-In)
* **Actor:** Host
* **Pre-condition:** App đã cài đặt, có kết nối mạng.
* **Main Flow:**
  1. Người dùng nhấn nút "Đăng nhập bằng Google".
  2. Hệ thống gọi Firebase Auth Google Sign-in.
  3. Lấy thông tin email trả về.
  4. Kiểm tra: `email.endsWith('@humg.edu.vn')`.
  5. Nếu sai: Hủy session đăng nhập, hiển thị thông báo lỗi "Chỉ chấp nhận email sinh viên HUMG".
  6. Nếu đúng: Cho phép đăng nhập.
* **Database Impact:** * Collection `users`: Cập nhật/Tạo mới document với ID là UID của Firebase Auth. Lưu các field: `name`, `email`, `avatar`, `role: 'user'`, `createdAt`.

#### UC-1.2: Đăng xuất (Logout)
* **Actor:** Host, Logged-in Viewer
* **Main Flow:** Xóa session Firebase Auth hiện tại và điều hướng về màn hình Đăng nhập.

---

### MODULE 2: HỒ SƠ & CHIA SẺ (PROFILE & SHARING)

#### UC-2.1: Tạo và chia sẻ Deep Link (Generate Shareable Link)
* **Actor:** Host
* **Pre-condition:** Đã đăng nhập.
* **Main Flow:**
  1. Người dùng vào màn hình Profile.
  2. Hệ thống tạo một link duy nhất (qua Firebase Dynamic Links hoặc custom URL scheme) có dạng `askme.humg.edu.vn/u/{userId}`.
  3. Người dùng nhấn "Copy Link" hoặc "Share to Instagram/Facebook Story".
  4. Hệ thống tạo một ảnh thẻ (Card Image) chứa link/QR code để chia sẻ.
* **Alternative Flow (Fallback):** Khi người khác bấm vào link:
  * Nếu thiết bị ĐÃ cài app: Mở trực tiếp app và điều hướng thẳng vào màn hình Profile của Host đó.
  * Nếu thiết bị CHƯA cài app: Redirect người dùng đến App Store/Google Play hoặc trang Web fallback.

#### UC-2.2: Xem Hồ sơ người dùng (View User Profile)
* **Actor:** Viewer, Host, Anonymous Sender
* **Main Flow:**
  1. Người dùng truy cập vào Profile của một Host (qua Avatar trên Feed hoặc đi từ Deep Link).
  2. Hệ thống tải thông tin người dùng.
  3. Hiển thị: Tên hiển thị, Avatar, Tổng số câu hỏi đã trả lời, Tổng lượt thích nhận được.
* **Database Impact:**
  * Collection `users`: Truy vấn `GET` document có `userId` tương ứng.
  * Collection `answers`: Truy vấn các answers của user đó để đếm tổng số câu trả lời và tổng số likes (có thể tối ưu bằng cách denormalize các chỉ số này thẳng vào document của `users` trong tương lai nếu cần).

---

### MODULE 3: HỎI ĐÁP CỐT LÕI (CORE Q&A)

#### UC-3.1: Gửi câu hỏi ẩn danh (Submit Anonymous Question)
* **Actor:** Anonymous Sender, Host, Viewer
* **Pre-condition:** Đang ở màn hình Profile của một Host (vào qua Deep Link hoặc qua điều hướng trong app).
* **Main Flow:**
  1. Người dùng nhập nội dung câu hỏi (tối đa 300 ký tự).
  2. Nhấn "Gửi ẩn danh".
  3. Client check độ dài và lọc từ ngữ thô tục cơ bản.
  4. Gắn token **Firebase App Check** vào request để chứng minh không phải bot.
  5. Gọi Cloud Functions / Firestore để gửi dữ liệu. Cloud Functions kiểm tra Rate Limit (Tối đa 5 câu/thiết bị/giờ).
  6. Thành công: Hiển thị hiệu ứng gửi thành công.
* **Database Impact:**
  * Collection `questions`: Tạo document mới (`toUserId`, `content`, `createdAt`, `status: 'unanswered'`).

#### UC-3.2: Quản lý hộp thư đến (Manage Inbox)
* **Actor:** Host
* **Pre-condition:** Đã đăng nhập.
* **Main Flow:**
  1. Host mở tab Inbox.
  2. Hệ thống truy vấn collection `questions` nơi `toUserId == currentUser.uid`.
  3. Hiển thị danh sách phân loại: "Chưa trả lời" (`status == 'unanswered'`) và "Đã trả lời" (`status == 'answered'`).

#### UC-3.3: Trả lời câu hỏi & Đăng bảng tin (Answer & Publish)
* **Actor:** Host
* **Main Flow:**
  1. Host chọn một câu hỏi `unanswered` trong Inbox.
  2. Nhập câu trả lời.
  3. Bật/Tắt toggle "Công khai lên Bảng tin" (`isPublished`).
  4. Nhấn "Gửi".
* **Database Impact:** *(Cần dùng Batch Write để đảm bảo tính toàn vẹn dữ liệu)*
  * Collection `answers`: Tạo document mới (`questionId`, `userId`, `content`, `isPublished`, `likedBy: []`, `likeCount: 0`, `commentCount: 0`).
  * Collection `questions`: Cập nhật document tương ứng thành `status: 'answered'`.

---

### MODULE 4: BẢNG TIN TƯƠNG TÁC (FEED & INTERACTION)

#### UC-4.1: Xem bảng tin công khai (View Public Feed)
* **Actor:** Viewer (Cả Guest và Logged-in)
* **Main Flow:**
  1. Mở tab Feed.
  2. Hệ thống truy vấn collection `answers` với điều kiện `isPublished == true`, sắp xếp theo `createdAt` giảm dần.
  3. Load dữ liệu theo dạng phân trang (Pagination).
  4. Hiển thị: Avatar Host, Câu hỏi, Câu trả lời, Số lượng Like (`likeCount`), Số lượng Comment (`commentCount`).

#### UC-4.2: Thả tim (Like Answer)
* **Actor:** Logged-in Viewer / Host
* **Pre-condition:** Bắt buộc phải đăng nhập.
* **Main Flow:**
  1. Người dùng nhấn nút Like trên một câu trả lời.
  2. Hệ thống kiểm tra xem `currentUser.uid` đã có trong mảng `likedBy` của answer đó chưa.
  3. Nếu chưa: Thêm UID vào `likedBy`, tăng `likeCount` lên 1. UI cập nhật icon màu đỏ.
  4. Nếu đã có: Xóa UID khỏi `likedBy`, giảm `likeCount` đi 1. UI cập nhật icon viền trắng.
* **Database Impact:**
  * Collection `answers`: Update mảng `likedBy` (arrayUnion/arrayRemove) và `likeCount` (increment 1 hoặc -1).

#### UC-4.3: Bình luận (Comment)
* **Actor:** Logged-in Viewer / Host
* **Pre-condition:** Bắt buộc phải đăng nhập.
* **Main Flow:**
  1. Người dùng nhấn vào icon Bình luận dưới một Answer.
  2. Nhập nội dung. Tùy chọn bật "Bình luận ẩn danh".
  3. Nhấn "Gửi".
* **Database Impact:**
  *(Dùng Batch Write)*
  * Collection `comments`: Tạo document mới (`answerId`, `userId` (null nếu ẩn danh), `content`, `isAnonymous`, `createdAt`).
  * Collection `answers`: Update trường `commentCount` (increment 1) của answer tương ứng.

---

### MODULE 5: KIỂM DUYỆT (MODERATION)

#### UC-5.1: Báo cáo vi phạm (Report)
* **Actor:** Logged-in Viewer / Host
* **Pre-condition:** Đã đăng nhập.
* **Main Flow:**
  1. Nhấn nút 3 chấm (...) trên một câu trả lời hoặc bình luận.
  2. Chọn "Báo cáo nội dung xấu".
  3. Chọn lý do (Spam, Ngôn từ thô tục, v.v.).
  4. Nhấn "Gửi báo cáo".
* **Database Impact:**
  * Collection `reports`: Tạo document mới (`targetId`, `targetType`, `reportedBy`, `reason`, `status: 'pending'`, `createdAt`).

#### UC-5.2: Xử lý báo cáo (Manage Reports)
* **Actor:** Admin
* **Pre-condition:** Đăng nhập bằng tài khoản có quyền Admin (được xác định qua Firebase Custom Claims hoặc trường `role: 'admin'` trong document thuộc collection `users`).
* **Main Flow:**
  1. Admin mở trang quản trị (Dashboard).
  2. Xem danh sách các reports có `status: 'pending'`.
  3. Admin đối chiếu nội dung bị báo cáo.
  4. Quyết định:
     - *Gỡ bỏ:* Chuyển status thành `resolved_removed`. Xóa/Ẩn document bị báo cáo.
     - *Bỏ qua:* Chuyển status thành `resolved_dismissed`. Giữ nguyên nội dung.
* **Database Impact:**
  * Collection `reports`: Update `status` và `resolvedAt`.
  * Collection `answers`/`comments`: Xóa hoặc update `isPublished = false` (nếu Admin chọn Gỡ bỏ).