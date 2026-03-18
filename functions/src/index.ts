import * as admin from "firebase-admin";
import { onRequest } from "firebase-functions/v2/https";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { setGlobalOptions } from "firebase-functions/v2";
import { createHash, randomInt } from "crypto";

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
const TRACKING_LOOKUP_LIMIT = 8;
const TRACKING_LOOKUP_WINDOW_MS = 10 * 60 * 1000;
const TRACKING_LOOKUP_COOLDOWN_MS = 15 * 60 * 1000;
const TRACKING_CODE_LENGTH = 6;
const TRACKING_CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
const TRACKING_CODE_MAX_GENERATE_ATTEMPTS = 15;

function getTrackingCodePepper(): string {
  const pepper = process.env.TRACKING_CODE_PEPPER?.trim();
  if (!pepper) {
    throw new Error("Missing TRACKING_CODE_PEPPER environment variable");
  }
  return pepper;
}

function hashTrackingCode(trackingCode: string): string {
  return createHash("sha256")
    .update(`${trackingCode}:${getTrackingCodePepper()}`)
    .digest("hex");
}

function normalizeTrackingCode(input: unknown): string {
  if (typeof input !== "string") return "";
  return input.replace(/[^a-zA-Z0-9]/g, "").trim().toUpperCase();
}

function generateTrackingCode(): string {
  let code = "";
  for (let i = 0; i < TRACKING_CODE_LENGTH; i += 1) {
    const idx = randomInt(0, TRACKING_CODE_ALPHABET.length);
    code += TRACKING_CODE_ALPHABET[idx];
  }
  return code;
}

function getClientIp(req: {
  headers: Record<string, string | string[] | undefined>;
  ip?: string;
}): string {
  const forwarded = req.headers["x-forwarded-for"];
  if (Array.isArray(forwarded) && forwarded.length > 0) {
    return forwarded[0].split(",")[0].trim();
  }
  if (typeof forwarded === "string" && forwarded.length > 0) {
    return forwarded.split(",")[0].trim();
  }
  const fallback = req.ip;
  return typeof fallback === "string" && fallback.length > 0
    ? fallback
    : "unknown";
}

async function createUniqueTrackingCode(): Promise<string> {
  for (let i = 0; i < TRACKING_CODE_MAX_GENERATE_ATTEMPTS; i += 1) {
    const trackingCode = generateTrackingCode();
    const trackingCodeHash = hashTrackingCode(trackingCode);
    const collisionSnap = await db
      .collection("questions")
      .where("trackingCodeHash", "==", trackingCodeHash)
      .limit(1)
      .get();
    if (collisionSnap.empty) return trackingCode;
  }
  throw new Error("tracking_code_generation_failed");
}

async function checkTrackingLookupRateLimit(key: string): Promise<boolean> {
  const ref = db.collection("trackingLookups").doc(key);
  const now = Date.now();
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) {
      tx.set(ref, {
        count: 1,
        windowStart: now,
        blockedUntil: 0,
      });
      return true;
    }
    const data = snap.data()!;
    const blockedUntil = Number(data.blockedUntil ?? 0);
    if (blockedUntil > now) return false;

    const windowStart = Number(data.windowStart ?? now);
    const count = Number(data.count ?? 0);
    const elapsed = now - windowStart;
    if (elapsed > TRACKING_LOOKUP_WINDOW_MS) {
      tx.set(
        ref,
        {
          count: 1,
          windowStart: now,
          blockedUntil: 0,
        },
        { merge: true }
      );
      return true;
    }

    if (count >= TRACKING_LOOKUP_LIMIT) {
      tx.set(
        ref,
        {
          blockedUntil: now + TRACKING_LOOKUP_COOLDOWN_MS,
          count,
          windowStart,
        },
        { merge: true }
      );
      return false;
    }

    tx.update(ref, { count: admin.firestore.FieldValue.increment(1) });
    return true;
  });
}

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

    const trackingCode = await createUniqueTrackingCode();
    const trackingCodeHash = hashTrackingCode(trackingCode);

    // Write to Firestore
    const docRef = db.collection("questions").doc();
    await docRef.set({
      toUserId,
      content,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: "unanswered",
      trackingCodeHash,
    });

    res.status(201).json({ questionId: docRef.id, trackingCode });
  }
);

// ---------------------------------------------------------------------------
// Anonymous tracking: getQuestionTrackingStatus — HTTP POST
// Body: { trackingCode: string, clientKey?: string }
// ---------------------------------------------------------------------------
export const getQuestionTrackingStatus = onRequest(
  { cors: true },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ error: "method_not_allowed" });
      return;
    }

    const body = req.body as { trackingCode?: unknown; clientKey?: unknown };
    const trackingCode = normalizeTrackingCode(body.trackingCode);
    if (!/^[A-Z0-9]{6}$/.test(trackingCode)) {
      res.status(400).json({ error: "invalid_code" });
      return;
    }

    const clientKeyInput =
      typeof body.clientKey === "string" ? body.clientKey.trim() : "";
    const clientKey = clientKeyInput.length > 0 ? clientKeyInput : "anonymous";
    const ip = getClientIp(req);
    const lookupKey = `${ip}:${clientKey}`;
    const allowed = await checkTrackingLookupRateLimit(lookupKey);
    if (!allowed) {
      res.status(429).json({ error: "too_many_requests" });
      return;
    }

    const trackingCodeHash = hashTrackingCode(trackingCode);
    const questionSnap = await db
      .collection("questions")
      .where("trackingCodeHash", "==", trackingCodeHash)
      .limit(1)
      .get();

    if (questionSnap.empty) {
      res.status(404).json({ error: "not_found" });
      return;
    }

    const questionDoc = questionSnap.docs[0];
    const questionData = questionDoc.data();
    const questionStatus = (questionData.status as string | undefined) ?? "unanswered";
    const createdAt = questionData.createdAt as admin.firestore.Timestamp | undefined;

    let answeredAt: admin.firestore.Timestamp | null = null;
    let isPublished = false;
    let answerId: string | null = null;

    const answerSnap = await db
      .collection("answers")
      .where("questionId", "==", questionDoc.id)
      .limit(1)
      .get();
    if (!answerSnap.empty) {
      const answerDoc = answerSnap.docs[0];
      const answerData = answerDoc.data();
      answeredAt = (answerData.createdAt as admin.firestore.Timestamp | undefined) ?? null;
      isPublished = (answerData.isPublished as boolean | undefined) ?? false;
      answerId = isPublished ? answerDoc.id : null;
    }

    res.status(200).json({
      status: questionStatus,
      createdAt: createdAt?.toDate().toISOString() ?? null,
      answeredAt: answeredAt?.toDate().toISOString() ?? null,
      isPublished,
      answerId,
    });
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
