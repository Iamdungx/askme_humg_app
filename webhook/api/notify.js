/**
 * Webhook OneSignal — gửi thông báo khi có câu hỏi mới / comment mới (không cần Blaze).
 *
 * Deploy: cd webhook && vercel
 * Env (Vercel Dashboard): FIREBASE_SERVICE_ACCOUNT_JSON, ONESIGNAL_REST_API_KEY, ONESIGNAL_APP_ID
 *
 * Client: POST /api/notify
 * Body: { idToken, type: 'new_question'|'new_comment', toUserId?, answerId?, content }
 */

const admin = require('firebase-admin');

function getFirestore() {
  if (!admin.apps.length) {
    const sa = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
    if (sa) {
      try {
        const cred = JSON.parse(sa);
        admin.initializeApp({ credential: admin.credential.cert(cred) });
      } catch (e) {
        console.error('Firebase init failed', e);
        return null;
      }
    } else {
      admin.initializeApp();
    }
  }
  return admin.firestore();
}

async function sendOneSignal(toExternalUserId, title, body) {
  const apiKey = process.env.ONESIGNAL_REST_API_KEY;
  const appId = process.env.ONESIGNAL_APP_ID;
  if (!apiKey || !appId) {
    console.warn('OneSignal keys missing');
    return;
  }
  const res = await fetch('https://api.onesignal.com/notifications', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Basic ${apiKey}`,
    },
    body: JSON.stringify({
      app_id: appId,
      include_aliases: { external_id: [toExternalUserId] },
      target_channel: 'push',
      headings: { en: title },
      contents: { en: body.length > 100 ? body.slice(0, 97) + '...' : body },
    }),
  });
  if (!res.ok) {
    const text = await res.text();
    console.warn('OneSignal send failed', res.status, text);
  }
}

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') {
    return res.status(204).end();
  }
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { idToken, type, toUserId, answerId, content } = req.body || {};
  if (!idToken || !type || typeof content !== 'string') {
    return res.status(400).json({ error: 'idToken, type, content required' });
  }

  const db = getFirestore();
  if (!db) {
    return res.status(500).json({ error: 'Firebase not configured' });
  }

  try {
    const decoded = await admin.auth().verifyIdToken(idToken);
    if (!decoded.uid) {
      return res.status(401).json({ error: 'Invalid token' });
    }
  } catch (e) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }

  if (type === 'new_question') {
    if (!toUserId) return res.status(400).json({ error: 'toUserId required' });
    const userSnap = await db.collection('users').doc(toUserId).get();
    const prefs = userSnap.data() || {};
    if (prefs.notifNewQuestion !== true) return res.status(200).json({ sent: false });
    await sendOneSignal(toUserId, 'Câu hỏi mới', content);
    return res.status(200).json({ sent: true });
  }

  if (type === 'new_comment') {
    if (!answerId) return res.status(400).json({ error: 'answerId required' });
    const answerSnap = await db.collection('answers').doc(answerId).get();
    const answerData = answerSnap.data();
    const userId = answerData?.userId;
    if (!userId) return res.status(200).json({ sent: false });
    const userSnap = await db.collection('users').doc(userId).get();
    const prefs = userSnap.data() || {};
    if (prefs.notifNewComment !== true) return res.status(200).json({ sent: false });
    await sendOneSignal(userId, 'Bình luận mới', content);
    return res.status(200).json({ sent: true });
  }

  return res.status(400).json({ error: 'Invalid type' });
};
