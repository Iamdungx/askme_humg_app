import * as admin from "firebase-admin";
import { Timestamp } from "firebase-admin/firestore";

const TARGET_USER_ID = "XgXrmq7QjpMnDArpgef9dCfhvim2";
const PROJECT_ID = "askme-humg-app";
const SERVICE_ACCOUNT_PATH =
  process.env.GOOGLE_APPLICATION_CREDENTIALS ||
  "/Users/buivietdung/Downloads/Image/asset/askme-humg-app-firebase-adminsdk-fbsvc-d8b4957f7e.json";

const app = admin.initializeApp({
  credential: admin.credential.cert(SERVICE_ACCOUNT_PATH),
  projectId: PROJECT_ID,
});
const db = admin.firestore(app);

type SeedQuestion = {
  topic: "hoc_tap" | "su_kien" | "doi_song" | "tuyen_dung" | "khac";
  content: string;
};

const QUESTIONS: SeedQuestion[] = [
  {
    topic: "hoc_tap",
    content:
      "Bạn có cách nào ôn môn Cấu trúc dữ liệu hiệu quả để qua kỳ thi cuối kỳ không?",
  },
  {
    topic: "su_kien",
    content:
      "Sắp tới trường mình có workshop hoặc talkshow nào đáng tham gia cho sinh viên năm 2 không?",
  },
  {
    topic: "doi_song",
    content:
      "Nếu ở khu Cổ Nhuế thì lịch học dày nên sắp xếp ăn uống và di chuyển thế nào cho đỡ mệt?",
  },
  {
    topic: "tuyen_dung",
    content:
      "Theo bạn sinh viên HUMG nên chuẩn bị CV và portfolio ra sao để xin thực tập hè thuận lợi?",
  },
  {
    topic: "khac",
    content:
      "Bạn có thể chia sẻ một lời khuyên quan trọng nhất cho tân sinh viên HUMG để không bị sốc năm nhất không?",
  },
];

async function main() {
  console.log("🌱 Seed 5 câu hỏi theo chủ đề");
  console.log(`📦 Project: ${PROJECT_ID}`);
  console.log(`🎯 toUserId: ${TARGET_USER_ID}`);

  const batch = db.batch();
  const now = Date.now();

  for (let i = 0; i < QUESTIONS.length; i += 1) {
    const q = QUESTIONS[i];
    const ref = db.collection("questions").doc();
    batch.set(ref, {
      toUserId: TARGET_USER_ID,
      content: q.content,
      status: "unanswered",
      topic: q.topic,
      createdAt: Timestamp.fromDate(new Date(now - i * 60_000)),
    });
    console.log(`  ✅ [${q.topic}] ${q.content}`);
  }

  await batch.commit();
  console.log(`🎉 Done: đã seed ${QUESTIONS.length} câu hỏi vào ${TARGET_USER_ID}`);
  process.exit(0);
}

main().catch((error) => {
  console.error("❌ Seed failed:", error);
  process.exit(1);
});
