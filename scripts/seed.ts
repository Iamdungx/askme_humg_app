/**
 * Firestore Seeder — AskMeHUMG
 *
 * Chạy: cd scripts && npx ts-node seed.ts
 * Cần: GOOGLE_APPLICATION_CREDENTIALS hoặc firebase-admin credential tự động từ env
 *
 * Dữ liệu dựa trên thực tế đời sống sinh viên Đại học Mỏ - Địa chất (HUMG):
 *  - Khuôn viên: Khu A (Đức Thắng), Khu B (Cổ Nhuế 2), KTX D1-D4
 *  - Ngành hot: CNTT, Dầu khí, Khai thác mỏ, Trắc địa, Xây dựng, KTQT, Tự động hóa
 *  - Câu hỏi từ ngl.link / askfm Việt Nam phong cách gen Z
 */

import * as admin from "firebase-admin";
import { Timestamp } from "firebase-admin/firestore";

// ─── Init ───────────────────────────────────────────────────────────────────
const SERVICE_ACCOUNT_PATH =
  process.env.GOOGLE_APPLICATION_CREDENTIALS ||
  "/Users/buivietdung/Downloads/Image/asset/askme-humg-app-firebase-adminsdk-fbsvc-d8b4957f7e.json";

const app = admin.initializeApp({
  credential: admin.credential.cert(SERVICE_ACCOUNT_PATH),
  projectId: "askme-humg-app",
});
const db = admin.firestore(app);

// ─── Helpers ────────────────────────────────────────────────────────────────
function randomId() {
  return db.collection("_").doc().id;
}

function daysAgo(n: number) {
  return Timestamp.fromDate(new Date(Date.now() - n * 86_400_000));
}

function hoursAgo(n: number) {
  return Timestamp.fromDate(new Date(Date.now() - n * 3_600_000));
}

// dicebear initials avatar — consistent, dễ nhận diện
function avatar(name: string, bg = "0ea5e9") {
  const initials = name
    .split(" ")
    .slice(-2)
    .map((s) => s[0])
    .join("")
    .toUpperCase();
  return `https://api.dicebear.com/9.x/initials/svg?seed=${encodeURIComponent(name)}&backgroundColor=${bg}&fontSize=40&fontWeight=600`;
}

// ─── Seed Data ───────────────────────────────────────────────────────────────

/**
 * 8 users thực tế với tên Việt Nam + ngành học HUMG
 * isHumgVerified = true cho host có huy hiệu xanh
 */
const USERS = [
  {
    uid: "uid_nguyen_bao_long",
    name: "Nguyễn Bảo Long",
    email: "long.nguyen@gmail.com",
    humgEmail: "long.nguyen.k66cntt@humg.edu.vn",
    isHumgVerified: true,
    major: "Công nghệ phần mềm K66",
    avatarBg: "6366f1",
  },
  {
    uid: "uid_tran_minh_hieu",
    name: "Trần Minh Hiếu",
    email: "hieu.tran@gmail.com",
    humgEmail: "hieu.tran.k65dk@humg.edu.vn",
    isHumgVerified: true,
    major: "Khoan khai thác Dầu khí K65",
    avatarBg: "f59e0b",
  },
  {
    uid: "uid_le_thu_huong",
    name: "Lê Thu Hương",
    email: "huong.le@gmail.com",
    humgEmail: "huong.le.k66kt@humg.edu.vn",
    isHumgVerified: true,
    major: "Kế toán doanh nghiệp K66",
    avatarBg: "ec4899",
  },
  {
    uid: "uid_pham_duc_anh",
    name: "Phạm Đức Anh",
    email: "ducanh@gmail.com",
    humgEmail: "ducanh.pham.k67mo@humg.edu.vn",
    isHumgVerified: true,
    major: "Khai thác mỏ hầm lò K67",
    avatarBg: "10b981",
  },
  {
    uid: "uid_vo_thi_mai_linh",
    name: "Võ Thị Mai Linh",
    email: "mailinh.vo@gmail.com",
    humgEmail: "mailinh.vo.k66td@humg.edu.vn",
    isHumgVerified: true,
    major: "Trắc địa công trình K66",
    avatarBg: "8b5cf6",
  },
  {
    uid: "uid_nguyen_tuan_kiet",
    name: "Nguyễn Tuấn Kiệt",
    email: "kietnguyen@gmail.com",
    humgEmail: "kiet.nguyen.k65xd@humg.edu.vn",
    isHumgVerified: true,
    major: "Xây dựng công trình ngầm K65",
    avatarBg: "0891b2",
  },
  {
    uid: "uid_hoang_phuong_anh",
    name: "Hoàng Phương Anh",
    email: "phuonganh@gmail.com",
    humgEmail: "phuonganh.hoang.k67mt@humg.edu.vn",
    isHumgVerified: true,
    major: "Kỹ thuật môi trường K67",
    avatarBg: "059669",
  },
  {
    uid: "uid_bui_van_thanh",
    name: "Bùi Văn Thành",
    email: "thanh.bui@gmail.com",
    humgEmail: "thanh.bui.k66ta@humg.edu.vn",
    isHumgVerified: true,
    major: "Tự động hóa xí nghiệp mỏ K66",
    avatarBg: "dc2626",
  },
];

/**
 * Q&A data — 12 cặp hỏi-đáp
 * Nội dung thực tế: ký túc xá HUMG, điểm thi, thực tập mỏ,
 * crush lớp, ăn canteen, xin việc dầu khí, học tín chỉ...
 */
const QA_DATA = [
  // ── Bảo Long (CNTT) ─────────────────────────────────────────────────────────
  {
    hostUid: "uid_nguyen_bao_long",
    question:
      "Bạn học CNTT HUMG thì tìm việc như nào? Ngành này ra trường có dễ xin việc không hay phải đi Hà Nội hết?",
    answer:
      "Nói thật nhé, CNTT HUMG không hot bằng Bách Khoa hay ĐHQG về brand name nhưng cơ hội việc làm thực ra khá tốt nếu bạn tự học thêm. Mình intern từ năm 3 tại FPT Software, xin qua LinkedIn. Bạn bè cùng khóa ra trường hầu hết có việc trong 2–3 tháng, lương fresher dao động 10–15tr ở HN. Bí kíp: học lập trình thật vững, làm 2–3 project cá nhân lên GitHub trước khi ra trường.",
    likes: 47,
    publishedDaysAgo: 3,
    comments: [
      { author: "uid_bui_van_thanh", text: "Chuẩn, mình cũng intern FPT từ năm 3, khuyến khích ae nên đi sớm" },
      { author: "uid_le_thu_huong", text: "Cho hỏi lúc xin internship có cần điểm GPA cao không hay chỉ cần skill?" },
      { author: "uid_nguyen_bao_long", text: "@Thu Hương: GPA ít quan trọng hơn project thực tế, 2.5+ là ổn rồi bạn" },
    ],
  },
  {
    hostUid: "uid_nguyen_bao_long",
    question:
      "Ký túc xá D3, D4 HUMG sống thế nào? Có nên ở KTX không hay thuê trọ ngoài?",
    answer:
      "KTX D3 mình ở 2 năm đầu — phòng 8 người hơi đông nhưng giá 300k/tháng thì rẻ không đâu bằng. Wifi tầm được, điều hòa có nhưng hay hỏng mùa hè. KTX D4 mới hơn, phòng 4 người, sạch hơn nhưng đắt hơn chút. Năm 3–4 mình ra ngoài thuê trọ khu Cổ Nhuế 2 giá ~1.5tr/tháng/người 3–4 bạn ở chung, thoải mái hơn nhiều. Tùy ngân sách bạn nhé!",
    likes: 89,
    publishedDaysAgo: 7,
    comments: [
      { author: "uid_pham_duc_anh", text: "D4 phòng điều hòa có ổn định hơn rồi, upgrade hồi năm ngoái" },
      { author: "uid_vo_thi_mai_linh", text: "Khu Cổ Nhuế giá hiện tại tăng lên ~2tr rồi nhé, lạm phát 😅" },
    ],
  },
  {
    hostUid: "uid_nguyen_bao_long",
    question: "Bạn thấy canteen khu B ăn được không? Hay mang cơm từ nhà?",
    answer:
      "Canteen khu B mình hay ăn buổi trưa, giá tầm 25–35k một suất ổn cho sinh viên. Có ngày ngon có ngày hên xui 😂 Cơm chiên dương châu và bún bò là tương đối ổn định. Nếu chán thì ra cổng trường phía Đức Thắng có hàng xôi bà Lan ngon vãi, hay sang đường cơm bình dân giá 30–40k đủ no. Mang cơm thì tiết kiệm nhất nhưng mình lười lắm.",
    likes: 34,
    publishedDaysAgo: 1,
    comments: [
      { author: "uid_hoang_phuong_anh", text: "Hàng xôi bà Lan ĐỈNH, sáng nào mình cũng ghé 🤤" },
      { author: "uid_nguyen_tuan_kiet", text: "Mưa thì khổ lắm, đi từ D sang B bị ướt hết mới đến canteen 💀" },
    ],
  },

  // ── Minh Hiếu (Dầu khí) ────────────────────────────────────────────────────
  {
    hostUid: "uid_tran_minh_hieu",
    question:
      "Ngành Khoan khai thác dầu khí HUMG học nặng không? Cơ hội ra làm dầu khí có thực sự cao không?",
    answer:
      "Nặng thật sự đó bạn ơi, đặc biệt từ năm 2 khi vào chuyên ngành: Địa chất dầu khí, Cơ học chất lỏng, Thiết bị giếng khoan... môn nào cũng cần nền toán lý vững. Nhưng đổi lại cơ hội việc làm tốt: PVN, PVEP, Vietsovpetro, Schlumberger VN đều tuyển HUMG. Lương kỹ sư dầu khí khởi điểm 15–20tr, ra ngoài giàn khoan có phụ cấp thêm. Nhược điểm: phải chấp nhận đi công tác dài ngày, xa nhà.",
    likes: 72,
    publishedDaysAgo: 5,
    comments: [
      { author: "uid_pham_duc_anh", text: "Bên khai thác mỏ cũng tương tự, xa nhà nhưng lương bù lại xứng đáng" },
      { author: "uid_le_thu_huong", text: "Ui xa nhà dài ngày thì chịu không nổi 😭 respect mấy bạn dầu khí" },
      { author: "uid_tran_minh_hieu", text: "Đổi lại tích lũy nhanh lắm, 5 năm tiết kiệm mua được nhà bình thường 😄" },
    ],
  },
  {
    hostUid: "uid_tran_minh_hieu",
    question:
      "Thực tập tốt nghiệp ngành dầu khí HUMG thực tập ở đâu? Có phải ra Vũng Tàu không?",
    answer:
      "Đa số đi Vũng Tàu, một số ra Quảng Ninh hoặc Hà Nội tùy đề tài. Mình thực tập tại Vietsovpetro Vũng Tàu 3 tháng — kinh nghiệm xịn nhưng chi phí đắt. Trường hỗ trợ một phần nhưng không đủ, nên chuẩn bị thêm khoảng 3–4tr/tháng tiền thuê trọ + ăn uống. Nếu siêng thì xin việc bán thời gian phụ việc văn phòng tại các công ty dầu khí VT buổi tối cũng được ~5–6tr/tháng.",
    likes: 55,
    publishedDaysAgo: 14,
    comments: [
      { author: "uid_nguyen_bao_long", text: "Nghe bạn kể thực tập vừa vui vừa tốn 😆 nhưng kinh nghiệm xịn vậy đáng đấy" },
    ],
  },

  // ── Thu Hương (Kế toán) ───────────────────────────────────────────────────
  {
    hostUid: "uid_le_thu_huong",
    question:
      "Kế toán HUMG khác gì với kế toán NEU hay TMU? Lựa chọn HUMG có đúng không?",
    answer:
      "Mình thi cả 3 rồi chọn HUMG vì điểm đầu vào tầm hơn và học bổng tốt. Thực ra chương trình kế toán HUMG khá chuẩn, học IFRS song song chuẩn quốc tế. Điểm khác biệt là nhiều bạn cùng lớp sau ra làm kế toán cho các tập đoàn mỏ, dầu khí — lĩnh vực chuyên biệt, cạnh tranh ít hơn. Nhược điểm thật sự là thư viện tài liệu kế toán HUMG ít hơn NEU. Nhưng nếu tự học thêm ACCA/CPA thì không có trường nào quan trọng hơn chứng chỉ.",
    likes: 61,
    publishedDaysAgo: 10,
    comments: [
      { author: "uid_bui_van_thanh", text: "Mình cũng nghĩ vậy, cert quan trọng hơn trường 👍" },
      { author: "uid_hoang_phuong_anh", text: "Bạn đang học thêm ACCA không? Bên môi trường mình cũng muốn lấy CPA" },
      { author: "uid_le_thu_huong", text: "@Phương Anh: Đang học ACCA F1-F3, khó nhưng xứng đáng bạn ơi" },
    ],
  },
  {
    hostUid: "uid_le_thu_huong",
    question: "Có bí kíp gì để vượt qua kỳ thi cuối kỳ môn Kế toán quản trị không? Mình thấy khó hiểu quá 😭",
    answer:
      "Môn này mình học lại 1 lần mới qua được đó 😅 Bí kíp: (1) Làm đề cương cô cho — bám sát 100%, thầy cô ra đề HUMG ít ra ngoài syllabus. (2) Làm bài tập trong sách bài tập từ chương 4 đến 8, những phần phân tích biến phí-định phí. (3) Học nhóm với 3–4 bạn, giải thích lẫn nhau — hiệu quả hơn đọc sách một mình nhiều. (4) Xem thêm YouTube kênh 'Kế toán Lê Ánh' giải thích dễ hiểu hơn sách giáo trình.",
    likes: 93,
    publishedDaysAgo: 2,
    comments: [
      { author: "uid_nguyen_bao_long", text: "Tip học nhóm này đúng với mọi môn, mình luôn học tốt hơn khi giải thích cho người khác" },
      { author: "uid_nguyen_tuan_kiet", text: "Cứu mình với, thi tuần sau rồi mà vẫn chưa hiểu phân tích CVP 😭" },
      { author: "uid_le_thu_huong", text: "@Tuấn Kiệt: Nhắn mình, mình gửi note tóm tắt CVP cho" },
    ],
  },

  // ── Đức Anh (Khai thác mỏ) ────────────────────────────────────────────────
  {
    hostUid: "uid_pham_duc_anh",
    question:
      "Ngành khai thác mỏ hầm lò HUMG có nguy hiểm không? Bố mẹ mình phản đối không cho học ngành này 😞",
    answer:
      "Mình hiểu cảm giác đó, bố mẹ mình ban đầu cũng vậy. Thực tế là ngành mỏ hầm lò có rủi ro nhất định, nhưng kỹ sư mỏ không phải thợ lò — chúng ta thiết kế quy trình an toàn, giám sát kỹ thuật chứ không trực tiếp làm việc dưới hầm sâu. Thực tập ở mỏ Mạo Khê, Vàng Danh (Quảng Ninh) thì phải xuống mỏ thực tế, nhưng có đầy đủ thiết bị bảo hộ. Lương kỹ sư mỏ ra trường 12–18tr, có phụ cấp độc hại. Nếu bạn thích kỹ thuật thì ngành này không tệ đâu.",
    likes: 118,
    publishedDaysAgo: 8,
    comments: [
      { author: "uid_tran_minh_hieu", text: "Bên dầu khí cũng vậy, kỹ sư thiết kế khác hẳn với người làm hiện trường" },
      { author: "uid_vo_thi_mai_linh", text: "Bạn thuyết phục bố mẹ kiểu gì vậy? Cho mình xin bí kíp 🙏" },
      { author: "uid_pham_duc_anh", text: "@Mai Linh: Dắt bố mẹ đi buổi tư vấn tuyển sinh, thầy cô giải thích chuyên nghiệp hơn mình nhiều 😄" },
    ],
  },

  // ── Mai Linh (Trắc địa) ────────────────────────────────────────────────────
  {
    hostUid: "uid_vo_thi_mai_linh",
    question:
      "Trắc địa HUMG ra làm gì? Mình thấy ít người biết ngành này nên lo ngại về cơ hội việc làm",
    answer:
      "Trắc địa là một trong những ngành 'ẩn' nhất nhưng cơ hội tốt nhất HUMG đó bạn! Kỹ sư trắc địa làm: đo đạc địa chính (sổ đỏ), quy hoạch đô thị, thi công xây dựng, GIS bản đồ số, ảnh viễn thám vệ tinh... Hiện nay công nghệ UAV drone + laser scanning tạo ra nhu cầu trắc địa số rất lớn. Lương fresher 10–14tr, nhiều anh chị khóa trên lên 20–30tr sau 3–4 năm kinh nghiệm. Điểm đầu vào không cao bằng CNTT nhưng tiềm năng không kém!",
    likes: 76,
    publishedDaysAgo: 6,
    comments: [
      { author: "uid_nguyen_bao_long", text: "Mình vừa làm project drone mapping cho một công ty xây dựng, confirm nhu cầu trắc địa số đang cực hot" },
      { author: "uid_hoang_phuong_anh", text: "Bên môi trường cũng dùng GIS nhiều, anh chị trắc địa hay được mời hợp tác" },
    ],
  },

  // ── Tuấn Kiệt (Xây dựng) ─────────────────────────────────────────────────
  {
    hostUid: "uid_nguyen_tuan_kiet",
    question:
      "Mình học Xây dựng công trình ngầm HUMG, nghe nói ra công trường nắng mưa rất cực. Thực tế như nào?",
    answer:
      "Thật ra năm 1–3 toàn ngồi phòng máy tính và lớp học bình thường. Đến năm 4–5 thực tập mới xuống công trường nhiều hơn. Mình thực tập tại dự án metro Hà Nội tuyến 3 đoạn Nhổn–ga Hà Nội: nóng, bụi, mệt nhưng học được cực kỳ nhiều. Kỹ sư giám sát thì không phải làm tay chân, nhưng cần đứng ngoài trời nhiều và hiểu quy trình thực tế. Sau 5–7 năm kinh nghiệm, lên PM (project manager) thì ngồi văn phòng nhiều hơn. Ngành xây dựng cần tính kiên nhẫn và chịu được áp lực tiến độ.",
    likes: 44,
    publishedDaysAgo: 12,
    comments: [
      { author: "uid_pham_duc_anh", text: "Metro HN là công trình đỉnh, thực tập ở đó chắc học được cực nhiều!" },
      { author: "uid_tran_minh_hieu", text: "Kỹ sư xây dựng hầm ngầm và kỹ sư hầm lò đâu đó có điểm tương đồng thú vị 😄" },
    ],
  },

  // ── Phương Anh (Môi trường) ────────────────────────────────────────────────
  {
    hostUid: "uid_hoang_phuong_anh",
    question:
      "Kỹ thuật môi trường HUMG thì liên quan gì đến khai thác mỏ? Mình nghĩ ngành môi trường phải làm về rừng núi?",
    answer:
      "Hahaha câu này mình được hỏi hoài 😆 HUMG đào tạo môi trường thiên về môi trường mỏ và công nghiệp nặng: xử lý nước thải mỏ, phục hồi đất sau khai thác, quan trắc không khí xung quanh nhà máy, đánh giá tác động môi trường (EIA) cho dự án khai thác khoáng sản. Có những môn đặc thù như 'Kỹ thuật môi trường mỏ' không có ở trường khác. Ra trường làm tư vấn EIA, Sở TN&MT, các công ty khai thác cần bộ phận HSSE. Lương ổn, không cực bằng địa chất thực địa.",
    likes: 38,
    publishedDaysAgo: 9,
    comments: [
      { author: "uid_vo_thi_mai_linh", text: "Bây giờ ESG (Environmental, Social, Governance) đang hot, các công ty niêm yết cần người chuyên về môi trường nhiều lắm!" },
      { author: "uid_le_thu_huong", text: "Bên kế toán cũng đang học kế toán xanh (green accounting), thú vị quá!" },
    ],
  },

  // ── Văn Thành (Tự động hóa) ───────────────────────────────────────────────
  {
    hostUid: "uid_bui_van_thanh",
    question:
      "Tự động hóa xí nghiệp mỏ HUMG thì học gì? Khác gì Tự động hóa bên Bách Khoa không?",
    answer:
      "Cốt lõi giống nhau: PLC, SCADA, điều khiển quá trình, điện công nghiệp. Điểm khác là HUMG thêm các môn ứng dụng đặc thù cho mỏ và dầu khí: điều khiển băng tải, hệ thống thông gió hầm lò tự động, giám sát khí mêtan... nên chuyên sâu cho lĩnh vực đó. Bách Khoa brand mạnh hơn nhưng cũng khó vào hơn. Còn nếu bạn muốn làm tự động hóa cho nhà máy thông thường thì HUMG hoàn toàn đủ năng lực, cơ hội việc làm ở Samsung, LG, Foxconn các KCN Bắc Ninh, Thái Nguyên rất nhiều.",
    likes: 52,
    publishedDaysAgo: 4,
    comments: [
      { author: "uid_nguyen_bao_long", text: "IoT đang hội tụ với tự động hóa, bạn học thêm Python + MQTT thì combo xịn lắm đó" },
      { author: "uid_bui_van_thanh", text: "Đang học ROS (Robot Operating System) để mở rộng hướng robotics 😎" },
      { author: "uid_nguyen_bao_long", text: "Quá đỉnh, nếu bạn ổn về lập trình nhúng thì freelance trên Upwork cũng ngon lắm" },
    ],
  },
];

// ─── Seeder Functions ─────────────────────────────────────────────────────────

async function seedUsers() {
  console.log("\n📋 Seeding users...");
  const batch = db.batch();

  for (const u of USERS) {
    const ref = db.collection("users").doc(u.uid);
    batch.set(ref, {
      uid: u.uid,
      name: u.name,
      email: u.email,
      avatar: avatar(u.name, u.avatarBg),
      role: "user",
      createdAt: daysAgo(Math.floor(Math.random() * 180) + 30),
      isBlocked: false,
      isHumgVerified: u.isHumgVerified,
      humgEmail: u.isHumgVerified ? u.humgEmail : null,
      major: u.major,
      // answerCount và totalLikes sẽ được tính sau khi seed answers
      answerCount: 0,
      totalLikes: 0,
    });
    console.log(`  ✅ ${u.name} (${u.major})`);
  }

  await batch.commit();
  console.log("✓ Users seeded");
}

async function seedQA() {
  console.log("\n💬 Seeding questions, answers & comments...");

  let totalAnswers = 0;
  const userLikeCounts: Record<string, number> = {};
  const userAnswerCounts: Record<string, number> = {};

  for (const qa of QA_DATA) {
    const publishedAt = daysAgo(qa.publishedDaysAgo);
    const questionCreatedAt = Timestamp.fromDate(
      new Date(publishedAt.toDate().getTime() - 3_600_000 * Math.floor(Math.random() * 24 + 1))
    );

    // 1. Question
    const questionRef = db.collection("questions").doc();
    await questionRef.set({
      toUserId: qa.hostUid,
      content: qa.question,
      createdAt: questionCreatedAt,
      status: "answered",
    });

    // 2. Answer — batch write questions + answers
    const answerRef = db.collection("answers").doc();
    const host = USERS.find((u) => u.uid === qa.hostUid)!;

    // Danh sách user đã like (ngẫu nhiên trong USERS)
    const likedBy = USERS.filter((u) => u.uid !== qa.hostUid)
      .sort(() => Math.random() - 0.5)
      .slice(0, qa.likes % USERS.length)
      .map((u) => u.uid);

    const answerBatch = db.batch();
    answerBatch.set(answerRef, {
      questionId: questionRef.id,
      questionContent: qa.question,   // denormalized for feed display
      userId: qa.hostUid,
      content: qa.answer,
      createdAt: publishedAt,
      likeCount: qa.likes,
      likedBy,
      isPublished: true,
      commentCount: qa.comments.length,
      // Denormalized host fields (UC-3.3)
      hostName: host.name,
      hostAvatar: avatar(host.name, host.avatarBg),
      hostIsHumgVerified: host.isHumgVerified,
    });
    answerBatch.update(questionRef, { status: "answered", answerId: answerRef.id });
    await answerBatch.commit();

    // 3. Comments
    for (let i = 0; i < qa.comments.length; i++) {
      const c = qa.comments[i];
      const commenter = USERS.find((u) => u.uid === c.author)!;
      const commentRef = db.collection("comments").doc();
      await commentRef.set({
        answerId: answerRef.id,
        userId: c.author,
        content: c.text,
        isAnonymous: false,
        createdAt: Timestamp.fromDate(
          new Date(publishedAt.toDate().getTime() + (i + 1) * 3_600_000)
        ),
        // Denormalized author fields (UC-4.3)
        authorName: commenter.name,
        authorAvatar: avatar(commenter.name, commenter.avatarBg),
        authorIsHumgVerified: commenter.isHumgVerified,
      });
    }

    // Track stats
    userAnswerCounts[qa.hostUid] = (userAnswerCounts[qa.hostUid] || 0) + 1;
    userLikeCounts[qa.hostUid] = (userLikeCounts[qa.hostUid] || 0) + qa.likes;
    totalAnswers++;

    console.log(
      `  ✅ [${host.name}] "${qa.question.substring(0, 50)}..." → ${qa.likes} likes, ${qa.comments.length} comments`
    );
  }

  // 4. Update answerCount + totalLikes for each user
  console.log("\n📊 Updating user stats...");
  const statsBatch = db.batch();
  for (const uid of Object.keys(userAnswerCounts)) {
    const ref = db.collection("users").doc(uid);
    statsBatch.update(ref, {
      answerCount: userAnswerCounts[uid],
      totalLikes: userLikeCounts[uid] || 0,
    });
  }
  await statsBatch.commit();

  console.log(`✓ ${totalAnswers} Q&A pairs seeded`);
}

async function seedUnansweredQuestions() {
  console.log("\n📥 Seeding unanswered questions for inbox...");

  const unanswered = [
    {
      toUid: "uid_nguyen_bao_long",
      content: "Bạn học Flutter không? Theo bạn học Flutter hay React Native tốt hơn cho mobile dev?",
    },
    {
      toUid: "uid_nguyen_bao_long",
      content: "Mình muốn biết bạn có dùng AI (Cursor, Copilot) để code không? Có sợ bị thay thế không?",
    },
    {
      toUid: "uid_tran_minh_hieu",
      content: "Ngành dầu khí có bị ảnh hưởng bởi năng lượng tái tạo không? Tương lai 10 năm nữa còn cơ hội không?",
    },
    {
      toUid: "uid_le_thu_huong",
      content: "Con gái học kế toán thì có bị áp lực deadline mùa quyết toán không? Nghe nói tháng 3 tháng 4 căng lắm",
    },
    {
      toUid: "uid_pham_duc_anh",
      content: "Thi điểm rèn luyện học kỳ này bạn được bao nhiêu? Có bí quyết gì để đạt xuất sắc không?",
    },
    {
      toUid: "uid_vo_thi_mai_linh",
      content: "Nghe nói bạn vừa thực tập đo đạc bằng drone? Thiết bị đó trường cho mượn hay tự mua?",
    },
    {
      toUid: "uid_hoang_phuong_anh",
      content: "Môn Đánh giá tác động môi trường (EIA) HUMG khó không? Mình sắp học rồi mà chưa biết chuẩn bị gì",
    },
    {
      toUid: "uid_bui_van_thanh",
      content: "Bạn hay học ở đâu trong trường? Phòng tự học khu A hay thư viện? Hỏi ngu tí nhưng mình mới lên Hà Nội chưa quen 😅",
    },
  ];

  const batch = db.batch();
  for (const q of unanswered) {
    const ref = db.collection("questions").doc();
    batch.set(ref, {
      toUserId: q.toUid,
      content: q.content,
      createdAt: hoursAgo(Math.floor(Math.random() * 48) + 1),
      status: "unanswered",
    });
    console.log(`  📨 → ${USERS.find((u) => u.uid === q.toUid)?.name}: "${q.content.substring(0, 50)}..."`);
  }
  await batch.commit();
  console.log("✓ Unanswered questions seeded");
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log("🌱 AskMeHUMG Seeder");
  console.log("📦 Project: askme-humg-app");
  console.log("━".repeat(60));

  try {
    await seedUsers();
    await seedQA();
    await seedUnansweredQuestions();

    console.log("\n" + "━".repeat(60));
    console.log("🎉 Seeding complete!");
    console.log(`   - ${USERS.length} users (tất cả isHumgVerified=true)`);
    console.log(`   - ${QA_DATA.length} answered Q&A (published to feed)`);
    console.log(`   - ${QA_DATA.reduce((s, q) => s + q.comments.length, 0)} comments`);
    console.log(`   - 8 unanswered questions (inbox)`);
  } catch (err) {
    console.error("\n❌ Seeding failed:", err);
    process.exit(1);
  }

  process.exit(0);
}

main();
