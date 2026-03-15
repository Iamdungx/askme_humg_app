import * as admin from "firebase-admin";
import { onRequest } from "firebase-functions/v2/https";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { setGlobalOptions } from "firebase-functions/v2";

admin.initializeApp();
setGlobalOptions({ region: "asia-southeast1" });

const db = admin.firestore();

// FCM topic names (phải khớp với client: notification_service.dart)
const topicNewQuestion = (userId: string) => `user_${userId}_questions`;
const topicNewComment = (userId: string) => `user_${userId}_comments`;

// ---------------------------------------------------------------------------
// Rate limiting — 5 questions per device per hour (UC-3.1)
// ---------------------------------------------------------------------------
const RATE_LIMIT = 5;
const WINDOW_MS = 60 * 60 * 1000;

async function checkRateLimit(deviceKey: string): Promise<boolean> {
  const ref = db.collection("rateLimits").doc(deviceKey);
  const now = Date.now();

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) {
      tx.set(ref, { count: 1, windowStart: now });
      return true;
    }
    const data = snap.data()!;
    const elapsed = now - (data.windowStart as number);
    if (elapsed > WINDOW_MS) {
      tx.set(ref, { count: 1, windowStart: now });
      return true;
    }
    if ((data.count as number) >= RATE_LIMIT) {
      return false;
    }
    tx.update(ref, { count: admin.firestore.FieldValue.increment(1) });
    return true;
  });
}

// ---------------------------------------------------------------------------
// UC-3.1: submitQuestion — HTTP POST
// Headers: X-App-Check-Token
// Body: { toUserId: string, content: string }
// ---------------------------------------------------------------------------
export const submitQuestion = onRequest(
  { cors: true },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ error: "Method not allowed" });
      return;
    }

    // Verify App Check token (client sends X-Firebase-AppCheck)
    const appCheckToken = req.headers["x-firebase-appcheck"] as string | undefined;
    if (!appCheckToken) {
      res.status(401).json({ error: "Missing App Check token" });
      return;
    }

    // Parse body early so fid is available for rate limiting
    const body = req.body as { toUserId?: unknown; content?: unknown; fid?: unknown };

    let appId: string;
    try {
      const decoded = await admin.appCheck().verifyToken(appCheckToken);
      appId = decoded.appId;
    } catch {
      res.status(401).json({ error: "Invalid App Check token" });
      return;
    }

    // Rate limiting keyed by appId + Firebase Installations ID (per-device).
    // Falls back to appId alone if client omits fid.
    const fid = typeof body.fid === "string" ? body.fid.trim() : "";
    const rateLimitKey = fid ? `${appId}:${fid}` : appId;
    const allowed = await checkRateLimit(rateLimitKey);
    if (!allowed) {
      res.status(429).json({ error: "rate_limit_exceeded" });
      return;
    }

    // Validate body
    const toUserId = typeof body.toUserId === "string" ? body.toUserId.trim() : "";
    const content = typeof body.content === "string" ? body.content.trim() : "";

    if (!toUserId) {
      res.status(400).json({ error: "toUserId is required" });
      return;
    }
    if (!content) {
      res.status(400).json({ error: "content is required" });
      return;
    }
    if (content.length > 300) {
      res.status(400).json({ error: "content too long (max 300 chars)" });
      return;
    }

    // Write to Firestore
    const docRef = db.collection("questions").doc();
    await docRef.set({
      toUserId,
      content,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: "unanswered",
    });

    res.status(201).json({ questionId: docRef.id });
  }
);

// ---------------------------------------------------------------------------
// FCM: gửi thông báo khi có câu hỏi mới (client subscribe topic user_<uid>_questions)
// ---------------------------------------------------------------------------
export const onQuestionCreated = onDocumentCreated(
  { document: "questions/{questionId}" },
  async (event) => {
    const snap = event?.data;
    if (!snap) return;
    const data = snap.data();
    const toUserId = data?.toUserId as string | undefined;
    const content = (data?.content as string) ?? "";
    if (!toUserId) return;
    const topic = topicNewQuestion(toUserId);
    const title = "Câu hỏi mới";
    const body = content.length > 60 ? content.slice(0, 57) + "..." : content;
    try {
      await admin.messaging().send({
        topic,
        notification: { title, body },
        android: { priority: "high" as const },
        apns: { payload: { aps: { sound: "default" } } },
      });
    } catch (e) {
      console.warn("FCM onQuestionCreated failed", e);
    }
  }
);

// ---------------------------------------------------------------------------
// FCM: gửi thông báo khi có comment mới (client subscribe topic user_<uid>_comments)
// ---------------------------------------------------------------------------
export const onCommentCreated = onDocumentCreated(
  { document: "comments/{commentId}" },
  async (event) => {
    const snap = event?.data;
    if (!snap) return;
    const data = snap.data();
    const answerId = data?.answerId as string | undefined;
    if (!answerId) return;
    const answerSnap = await db.collection("answers").doc(answerId).get();
    const answerData = answerSnap.data();
    const userId = answerData?.userId as string | undefined;
    if (!userId) return;
    const topic = topicNewComment(userId);
    const content = (data?.content as string) ?? "";
    const title = "Bình luận mới";
    const body = content.length > 60 ? content.slice(0, 57) + "..." : content;
    try {
      await admin.messaging().send({
        topic,
        notification: { title, body },
        android: { priority: "high" as const },
        apns: { payload: { aps: { sound: "default" } } },
      });
    } catch (e) {
      console.warn("FCM onCommentCreated failed", e);
    }
  }
);
