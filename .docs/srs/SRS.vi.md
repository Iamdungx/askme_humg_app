# AskmeHUMG – Đặc Tả Yêu Cầu Phần Mềm (SRS)

> **Phiên bản:** 2.1 | **Cập nhật lần cuối:** 01-03-2026

---

## Mục Lục

1. [Giới thiệu](#1-giới-thiệu)
   - 1.1 [Mục đích](#11-mục-đích)
   - 1.2 [Phạm vi](#12-phạm-vi)
   - 1.3 [Định nghĩa thuật ngữ](#13-định-nghĩa-thuật-ngữ)
2. [Mô tả tổng quan](#2-mô-tả-tổng-quan)
   - 2.1 [Tổng quan sản phẩm](#21-tổng-quan-sản-phẩm)
   - 2.2 [Các loại người dùng](#22-các-loại-người-dùng)
   - 2.3 [Môi trường hoạt động](#23-môi-trường-hoạt-động)
3. [Yêu cầu chức năng](#3-yêu-cầu-chức-năng)
4. [Yêu cầu phi chức năng](#4-yêu-cầu-phi-chức-năng)
5. [Kiến trúc hệ thống](#5-kiến-trúc-hệ-thống)
6. [Mô hình dữ liệu](#6-mô-hình-dữ-liệu)
7. [Ràng buộc hệ thống](#7-ràng-buộc-hệ-thống)
8. [Hướng phát triển tương lai](#8-hướng-phát-triển-tương-lai)
9. [Kết luận](#9-kết-luận)

---

## 1. Giới thiệu

### 1.1 Mục đích

Tài liệu này mô tả Đặc Tả Yêu Cầu Phần Mềm (SRS) cho **AskmeHUMG** – một ứng dụng di động cho phép sinh viên trường Đại học Mỏ – Địa chất (HUMG) tương tác hỏi đáp theo hình thức ẩn danh.

Mục tiêu của hệ thống là tạo ra một nền tảng an toàn, bảo mật danh tính và tương tác cao, giúp sinh viên tự do đặt câu hỏi, chia sẻ phản hồi và kinh nghiệm học tập.

### 1.2 Phạm vi

AskmeHUMG là ứng dụng di động được phát triển bằng **Flutter**, hỗ trợ các tính năng:

- Gửi câu hỏi ẩn danh đến bất kỳ sinh viên nào đã đăng ký
- Sinh viên đăng nhập để nhận và trả lời câu hỏi
- Tương tác cộng đồng (thích, bình luận)
- Kiểm duyệt nội dung để duy trì môi trường lành mạnh
- Chia sẻ deep link để nhận câu hỏi ẩn danh qua mạng xã hội

Hệ thống được thiết kế **chỉ dành cho sinh viên nội bộ HUMG** và không thay thế các hệ thống thông tin học thuật chính thức.

### 1.3 Định nghĩa thuật ngữ

| Thuật ngữ | Ý nghĩa |
|---|---|
| Người gửi ẩn danh | Người dùng gửi câu hỏi mà không tiết lộ danh tính |
| Host (Người chủ) | Sinh viên đã đăng nhập bằng tài khoản `@humg.edu.vn`, nhận và trả lời câu hỏi |
| Feed (Bảng tin) | Danh sách công khai các câu hỏi đã được trả lời và công bố |
| Kiểm duyệt | Quá trình lọc hoặc gỡ bỏ nội dung không phù hợp |
| Deep Link | Đường dẫn URL duy nhất mở thẳng vào trang hồ sơ của Host trong ứng dụng |
| Rate Limiting | Cơ chế giới hạn số lượng yêu cầu mà một thiết bị có thể thực hiện trong một khung thời gian |
| App Check | Dịch vụ Firebase xác minh rằng yêu cầu xuất phát từ một phiên bản ứng dụng hợp lệ |

---

## 2. Mô tả tổng quan

### 2.1 Tổng quan sản phẩm

AskmeHUMG là ứng dụng di động độc lập sử dụng:

- **Flutter** (Giao diện người dùng)
- **Firebase** (Dịch vụ backend)

Hệ thống theo mô hình **client-server** với cơ sở dữ liệu thời gian thực. Các yêu cầu gửi câu hỏi ẩn danh được bảo vệ bởi Firebase App Check nhằm ngăn chặn tấn công từ bot tự động.

### 2.2 Các loại người dùng

| Loại người dùng | Mô tả |
|---|---|
| Người gửi ẩn danh | Gửi câu hỏi mà không cần đăng nhập |
| Sinh viên (Host) | Đăng nhập bằng tài khoản `@humg.edu.vn`, nhận và trả lời câu hỏi |
| Người xem | Xem bảng tin công khai và tương tác với nội dung |
| Quản trị viên | Quản lý báo cáo và kiểm duyệt nội dung vi phạm |

### 2.3 Môi trường hoạt động

- Android 8.0 trở lên
- iOS 13 trở lên
- Yêu cầu kết nối Internet
- Backend: Firebase Cloud

---

## 3. Yêu cầu chức năng

### FR-01: Gửi câu hỏi ẩn danh

**Mô tả:** Bất kỳ người dùng nào (không cần đăng nhập) đều có thể gửi câu hỏi ẩn danh đến một sinh viên Host đã đăng ký.

**Đầu vào:**
- Nội dung câu hỏi (tối đa 300 ký tự)

**Xử lý:**
1. Kiểm tra độ dài và định dạng nội dung
2. Lọc từ ngữ không phù hợp qua danh sách từ khóa cấm
3. Xác minh tính hợp lệ của yêu cầu bằng **Firebase App Check** (chặn bot và các lời gọi từ emulator)
4. Áp dụng **rate limiting**: tối đa **5 câu hỏi mỗi thiết bị mỗi giờ**, thực thi qua Cloud Functions
5. Lưu câu hỏi vào collection `questions`

**Đầu ra:**
- Thông báo xác nhận gửi thành công

**Lưu ý bảo mật:** Không lưu trữ danh tính hay dấu vân tay thiết bị. Token App Check là tạm thời và không liên kết với bất kỳ dữ liệu cá nhân nào.

---

### FR-02: Xác thực người dùng

**Mô tả:** Bất kỳ tài khoản Google nào cũng có thể đăng nhập vào ứng dụng. Các tính năng Host đầy đủ (nhận câu hỏi, trả lời, đăng lên Feed) yêu cầu xác minh danh tính HUMG bổ sung.

**Mô hình xác thực hai tầng:**
- **Tầng 1 — Đăng nhập Google:** Bất kỳ tài khoản Google nào đều có thể đăng nhập. Document `users` được tạo khi đăng nhập lần đầu. Người dùng có thể xem Feed và tương tác (thích, bình luận).
- **Tầng 2 — Xác minh HUMG:** Để mở khóa tính năng Host, người dùng phải xác minh quyền sở hữu địa chỉ email `@humg.edu.vn`. Sau khi xác minh thành công, `isHumgVerified: true` và `humgEmail` được lưu vào document `users`.

**Xử lý (Tầng 1):**
1. Người dùng khởi tạo đăng nhập bằng Google
2. Firebase Auth trả về tài khoản Google đã xác thực
3. Lần đầu đăng nhập → tạo document mới trong collection `users` với `isHumgVerified: false`
4. Phiên đăng nhập được thiết lập, chuyển hướng đến màn hình chính

**Xử lý (Tầng 2 — Xác minh HUMG):**
1. Người dùng nhập địa chỉ email `@humg.edu.vn` trong màn hình Cài đặt
2. Hệ thống gửi OTP đến email đó qua Cloud Functions (Resend API)
3. Người dùng nhập OTP; hệ thống kiểm tra so với collection `otpRequests`
4. Thành công → ghi `isHumgVerified: true` và `humgEmail` vào document `users`

---

### FR-03: Xem câu hỏi đã nhận

**Mô tả:** Người dùng đã đăng nhập có thể xem danh sách câu hỏi ẩn danh gửi đến mình.

**Hiển thị:**
- Nội dung câu hỏi
- Thời gian gửi
- Trạng thái (`đã trả lời` / `chưa trả lời`)

---

### FR-04: Trả lời câu hỏi

**Mô tả:** Host có thể viết câu trả lời cho câu hỏi nhận được.

**Xử lý:**
1. Lưu câu trả lời vào collection `answers`
2. Tùy chọn đăng công khai lên bảng tin Feed

---

### FR-05: Bảng tin công khai

**Mô tả:** Hiển thị tất cả câu trả lời đã được công bố từ các sinh viên.

**Hiển thị:**
- Tên & ảnh đại diện của Host
- Nội dung câu hỏi
- Nội dung câu trả lời
- Số lượt thích
- Số lượng bình luận

---

### FR-06: Hệ thống thích (Like)

**Mô tả:** Người dùng đã đăng nhập có thể thích một câu trả lời đã được công bố.

**Ràng buộc:**
- Mỗi người dùng chỉ được thích một lần cho mỗi câu trả lời, được kiểm soát bằng cách lưu `userId` của người dùng vào trường mảng `likedBy` trong document answer
- Giao diện phản ánh trạng thái thích hiện tại của người dùng (active/inactive) khi tải

---

### FR-07: Hệ thống bình luận

**Mô tả:** Người dùng có thể bình luận vào câu trả lời, có thể ẩn danh hoặc công khai danh tính.

---

### FR-08: Báo cáo nội dung

**Mô tả:** Người dùng đã đăng nhập có thể báo cáo câu trả lời hoặc bình luận có nội dung không phù hợp để Admin xem xét. Mỗi báo cáo được lưu thành một document riêng trong collection `reports` với trạng thái `pending`.

---

### FR-09: Kiểm duyệt nội dung

**Mô tả:** Hệ thống lọc nội dung không phù hợp thông qua:
- Lọc từ khóa tự động (kiểm tra phía client kết hợp Cloud Functions phía server)
- Hệ thống xét duyệt thủ công của Admin thông qua collection `reports`

---

### FR-10: Hồ sơ người dùng

**Mô tả:** Hiển thị thông tin công khai của Host:
- Tên hiển thị (hoặc danh xưng ẩn danh nếu người dùng tắt hiển thị tên thật)
- Ảnh đại diện
- Số câu hỏi đã trả lời và công bố
- Tổng số lượt thích nhận được

**Kiểm soát quyền riêng tư:** Host có thể bật/tắt "Hiển thị tên thật trên hồ sơ" trong Cài đặt. Khi tắt, tên thật được thay bằng tên định danh chung trên Feed công khai và trang hồ sơ. Tùy chọn này được lưu trong document `users` (trường `showRealName`).

---

### FR-11: Deep Link có thể chia sẻ

**Mô tả:** Mỗi Host có thể tạo và chia sẻ một đường dẫn duy nhất – khi mở ra sẽ điều hướng thẳng đến trang hồ sơ của họ, nơi người khác có thể gửi câu hỏi ẩn danh.

**Xử lý:**
1. Hệ thống tạo URL duy nhất cho Host: `https://askme-humg-app.web.app/user/{userId}`
2. Host có thể chia sẻ link này hoặc xuất ra dạng ảnh card QR trực quan để đăng lên mạng xã hội (Facebook, Instagram Stories, v.v.)
3. Khi người nhận mở link trên thiết bị đã cài ứng dụng, app sẽ mở thẳng đến trang hồ sơ của Host (xử lý bởi `app_links` + Android App Links / iOS Universal Links)
4. Nếu chưa cài ứng dụng, link chuyển hướng đến trang tải ứng dụng hoặc trang web di động dự phòng

**Đầu ra:**
- URL được sao chép vào clipboard
- Tùy chọn xuất ra ảnh card có thể chia sẻ

---

## 4. Yêu cầu phi chức năng

### NFR-01: Ẩn danh

- Không lưu trữ hoặc hiển thị danh tính người gửi
- Không theo dõi địa chỉ IP hay dấu vân tay thiết bị công khai
- Token App Check dùng để xác minh là tạm thời và không liên kết với bất kỳ định danh cá nhân nào

### NFR-02: Hiệu năng

- Thời gian phản hồi dưới **2 giây** cho các thao tác chính
- Bảng tin tải mượt mà, hỗ trợ phân trang dựa trên con trỏ (cursor-based pagination) của Firestore

### NFR-03: Bảo mật

- **Firebase Authentication** với ràng buộc tên miền `@humg.edu.vn`
- **Firebase App Check** (dùng DeviceCheck trên iOS, Play Integrity trên Android) để xác thực tất cả yêu cầu gửi câu hỏi ẩn danh
- **Rate limiting qua Cloud Functions**: tối đa 5 lượt gửi ẩn danh mỗi thiết bị mỗi giờ
- Quy tắc bảo mật Firestore ngăn chặn đọc/ghi trái phép
- Toàn bộ giao tiếp client-server bắt buộc sử dụng **HTTPS**

### NFR-04: Khả năng sử dụng

- Giao diện đơn giản, trực quan
- Số bước thao tác tối thiểu cho mỗi hành động
- Thiết kế thân thiện với người dùng mới

### NFR-05: Khả năng mở rộng

- Hỗ trợ nhiều người dùng đồng thời mà không giảm hiệu năng
- Cấu trúc Firestore được thiết kế để mở rộng theo chiều ngang

---

## 5. Kiến trúc hệ thống

### Giao diện người dùng (Frontend)

- **Framework:** Flutter (Dart)
- **Quản lý trạng thái:** **Riverpod** (flutter_riverpod)

> Riverpod được lựa chọn vì đảm bảo an toàn kiểu dữ liệu tại compile-time, dễ kiểm thử và hỗ trợ tốt cho các stream bất đồng bộ từ Firebase. GetX không được sử dụng trong dự án này.

### Backend

| Dịch vụ | Vai trò |
|---|---|
| **Firebase Authentication** | Đăng nhập và xác thực danh tính |
| **Cloud Firestore** | Cơ sở dữ liệu NoSQL thời gian thực |
| **Firebase Storage** | Lưu trữ ảnh đại diện và media |
| **Cloud Functions** | Rate limiting cho gửi ẩn danh, gửi OTP (Resend API), kiểm duyệt nội dung phía server |
| **Firebase App Check** | Xác thực phiên bản ứng dụng hợp lệ cho các endpoint ẩn danh |
| **Package `app_links`** | Xử lý deep link `askme-humg-app.web.app/user/{userId}` — thay thế Firebase Dynamic Links đã bị deprecated |

> **Lưu ý:** Firebase Dynamic Links đã bị Google ngừng hỗ trợ từ tháng 8/2025. Ứng dụng dùng package `app_links` kết hợp cấu hình native (Android App Links / iOS Universal Links) trỏ đến `askme-humg-app.web.app`.

### Sơ đồ kiến trúc (Tổng quan)

```
Ứng dụng Flutter (Riverpod)
    │
    ├── Firebase Auth          (Đăng nhập · bất kỳ tài khoản Google nào)
    ├── Firebase App Check     (Chống bot · gửi câu hỏi ẩn danh)
    ├── Cloud Firestore        (Lưu trữ dữ liệu · đồng bộ thời gian thực)
    ├── Firebase Storage       (Ảnh đại diện · media)
    ├── Cloud Functions        (Rate limiting · OTP · kiểm duyệt server)
    └── app_links + native     (Deep link routing: askme-humg-app.web.app/user/{userId})
```

---

## 6. Mô hình dữ liệu

### Collection: `users` (Người dùng)

| Trường | Kiểu dữ liệu | Mô tả |
|---|---|---|
| `userId` | String | Mã định danh người dùng (Firebase Auth UID) |
| `name` | String | Tên hiển thị (lấy từ tài khoản Google) |
| `avatar` | String (URL) | Đường dẫn ảnh đại diện |
| `email` | String | Email tài khoản Google (bất kỳ tên miền nào) |
| `role` | String | `user` (mặc định) hoặc `admin` |
| `createdAt` | Timestamp | Thời điểm tạo tài khoản |
| `isBlocked` | Boolean | Tài khoản có bị Admin khóa không |
| `isHumgVerified` | Boolean | Người dùng đã xác minh email `@humg.edu.vn` chưa |
| `humgEmail` | String (nullable) | Địa chỉ email HUMG đã được xác minh |
| `showRealName` | Boolean | Có hiển thị tên thật công khai không (mặc định: `true`) |

### Collection: `questions` (Câu hỏi)

| Trường | Kiểu dữ liệu | Mô tả |
|---|---|---|
| `questionId` | String | Mã định danh câu hỏi |
| `toUserId` | String | Mã người nhận câu hỏi (Host) |
| `content` | String | Nội dung câu hỏi (tối đa 300 ký tự) |
| `createdAt` | Timestamp | Thời điểm gửi |
| `status` | String | `unanswered` hoặc `answered` |

### Collection: `answers` (Câu trả lời)

| Trường | Kiểu dữ liệu | Mô tả |
|---|---|---|
| `answerId` | String | Mã định danh câu trả lời |
| `questionId` | String | Tham chiếu đến câu hỏi |
| `userId` | String | Mã Host đã trả lời |
| `content` | String | Nội dung câu trả lời |
| `createdAt` | Timestamp | Thời điểm trả lời |
| `likeCount` | Number | Tổng số lượt thích (bộ đệm denormalized để hiển thị nhanh) |
| `likedBy` | Array\<String\> | Danh sách `userId` đã thích – đảm bảo quy tắc một lượt thích mỗi người |
| `commentCount` | Number | Tổng số bình luận (bộ đệm denormalized để hiển thị nhanh) |
| `isPublished` | Boolean | Câu trả lời có được hiển thị công khai trên Feed không |

> **Ghi chú thiết kế:** Cả `likeCount` và `commentCount` đều là bộ đệm denormalized được cập nhật nguyên tử qua `FieldValue.increment()`. Với lượt thích, mảng `likedBy` được cập nhật trong cùng thao tác. Cách này tránh việc đọc sub-collection để lấy số đếm mỗi khi render item trên Feed. Cả hai cập nhật đều dùng `WriteBatch` để đảm bảo tính nguyên tử.

### Collection: `comments` (Bình luận)

| Trường | Kiểu dữ liệu | Mô tả |
|---|---|---|
| `commentId` | String | Mã định danh bình luận |
| `answerId` | String | Tham chiếu đến câu trả lời |
| `userId` | String (nullable) | Mã người bình luận; `null` nếu ẩn danh |
| `content` | String | Nội dung bình luận |
| `isAnonymous` | Boolean | Bình luận ẩn danh hay công khai |
| `createdAt` | Timestamp | Thời điểm bình luận |

### Collection: `reports` (Báo cáo)

| Trường | Kiểu dữ liệu | Mô tả |
|---|---|---|
| `reportId` | String | Mã định danh báo cáo |
| `targetId` | String | ID của nội dung bị báo cáo (ID của answer hoặc comment) |
| `targetType` | String | Loại nội dung bị báo cáo: `answer` hoặc `comment` |
| `reportedBy` | String | `userId` của người gửi báo cáo |
| `reason` | String | Lý do báo cáo: `inappropriate_language`, `spam`, `misinformation`, `other` |
| `status` | String | `pending`, `resolved_removed` hoặc `resolved_dismissed` |
| `createdAt` | Timestamp | Thời điểm gửi báo cáo |
| `resolvedAt` | Timestamp (nullable) | Thời điểm Admin xử lý báo cáo |

### Collection: `otpRequests` (Yêu cầu OTP)

Được quản lý hoàn toàn bởi Cloud Functions. Client không có quyền đọc/ghi trực tiếp.

| Trường | Kiểu dữ liệu | Mô tả |
|---|---|---|
| `email` | String | Địa chỉ email `@humg.edu.vn` được gửi OTP |
| `otpHash` | String | Bcrypt hash của OTP (không lưu OTP dạng plaintext) |
| `expiresAt` | Timestamp | Thời điểm hết hạn OTP (10 phút kể từ khi tạo) |
| `attempts` | Number | Số lần nhập sai (tối đa 5 lần trước khi khóa) |

---

## 7. Ràng buộc hệ thống

- Yêu cầu kết nối Internet để sử dụng ứng dụng
- Chỉ tài khoản Google có đuôi `@humg.edu.vn` mới được đăng ký làm Host
- Không có tính năng nhắn tin trực tiếp giữa các người dùng
- Không có hệ thống chat thời gian thực
- Gửi câu hỏi ẩn danh bị giới hạn tốc độ ở mức **5 lần mỗi thiết bị mỗi giờ**

---

## 8. Hướng phát triển tương lai

### Phiên bản 2 (Đã lên kế hoạch)

- **Thông báo đẩy (Push notification)** khi nhận câu hỏi mới và khi có bình luận mới vào câu trả lời — qua Firebase Cloud Messaging (FCM). Giao diện placeholder đã có trong màn hình Cài đặt; implement backend chờ đến v2.
- **Chỉnh sửa ảnh đại diện & tên hiển thị** — tải ảnh mới lên Firebase Storage và cập nhật `name` trong document `users`. Màn hình Edit Profile hiện là placeholder.
- **Lưu `showRealName` vào Firestore** — hiện tại chỉ lưu trong bộ nhớ; v2 sẽ persist vào `users.showRealName`.

### Phiên bản 3+ (Định hướng dài hạn)

- Gợi ý câu trả lời bằng AI (tích hợp LLM API)
- Bảng phân tích thống kê câu hỏi phổ biến và xu hướng nổi bật
- Phân tích xu hướng theo khoa/bộ môn
- Tích hợp với hệ thống thông tin sinh viên chính thức của HUMG

---

## 9. Kết luận

AskmeHUMG hướng đến việc xây dựng một nền tảng giao tiếp an toàn, chống spam và bảo mật danh tính dành riêng cho sinh viên HUMG. Bằng cách kết hợp xác thực email tổ chức, Firebase App Check, rate limiting và hệ thống kiểm duyệt nội dung có cấu trúc, ứng dụng cân bằng giữa sự cởi mở trong tương tác và các đảm bảo bảo mật, quyền riêng tư thực chất.
