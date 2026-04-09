const admin = require('firebase-admin');
const {
  parseBody,
  getFirestore,
  getClientIp,
  createUniqueTrackingCode,
  hashTrackingCode,
  checkSubmitRateLimit,
} = require('./_shared');

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, X-Firebase-AppCheck');
  if (req.method === 'OPTIONS') return res.status(204).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'method_not_allowed' });

  const body = parseBody(req);
  const toUserId = typeof body.toUserId === 'string' ? body.toUserId.trim() : '';
  const content = typeof body.content === 'string' ? body.content.trim() : '';
  const fid = typeof body.fid === 'string' ? body.fid.trim() : '';
  if (!toUserId) return res.status(400).json({ error: 'to_user_required' });
  if (!content) return res.status(400).json({ error: 'content_required' });
  if (content.length > 300) return res.status(400).json({ error: 'content_too_long' });
  // TODO: Verify request origin strongly (App Check or signed nonce)
  // before writing questions to Firestore. Current protection relies on rate limit.

  try {
    const db = getFirestore();
    const ip = getClientIp(req);
    const submitKey = `${ip}:${fid || 'no-fid'}`;
    const allowed = await checkSubmitRateLimit({ db, key: submitKey });
    if (!allowed) return res.status(429).json({ error: 'rate_limit_exceeded' });

    const trackingCode = await createUniqueTrackingCode(db);
    const trackingCodeHash = hashTrackingCode(trackingCode);
    const docRef = db.collection('questions').doc();
    await docRef.set({
      toUserId,
      content,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'unanswered',
      trackingCodeHash,
    });
    return res.status(201).json({
      questionId: docRef.id,
      trackingCode,
    });
  } catch (e) {
    console.error('submitQuestion failed', e);
    return res.status(500).json({ error: 'internal_error' });
  }
};
