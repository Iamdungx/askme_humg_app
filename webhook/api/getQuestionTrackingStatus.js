const {
  parseBody,
  getFirestore,
  getClientIp,
  hashTrackingCode,
  checkLookupRateLimit,
} = require('./_shared');

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.status(204).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'method_not_allowed' });

  const body = parseBody(req);
  const trackingCodeRaw = typeof body.trackingCode === 'string' ? body.trackingCode : '';
  const trackingCode = trackingCodeRaw.replace(/[^a-zA-Z0-9]/g, '').trim().toUpperCase();
  if (!/^[A-Z0-9]{6}$/.test(trackingCode)) {
    return res.status(400).json({ error: 'invalid_code' });
  }
  // TODO(security): Do not trust clientKey for primary throttling key.
  // Enforce stricter IP-based / subnet-based limits to reduce brute-force bypass.
  const clientKey = typeof body.clientKey === 'string' ? body.clientKey.trim() : 'anonymous';

  try {
    const db = getFirestore();
    const ip = getClientIp(req);
    const lookupKey = `${ip}:${clientKey || 'anonymous'}`;
    const allowed = await checkLookupRateLimit({ db, key: lookupKey });
    if (!allowed) return res.status(429).json({ error: 'too_many_requests' });

    const trackingCodeHash = hashTrackingCode(trackingCode);
    const questionSnap = await db
      .collection('questions')
      .where('trackingCodeHash', '==', trackingCodeHash)
      .limit(1)
      .get();
    if (questionSnap.empty) {
      return res.status(404).json({ error: 'not_found' });
    }

    const questionDoc = questionSnap.docs[0];
    const questionData = questionDoc.data() || {};
    const questionStatus = typeof questionData.status === 'string'
      ? questionData.status
      : 'unanswered';
    const questionCreatedAt = questionData.createdAt;
    let createdAtMs = 0;
    if (typeof questionCreatedAt?.toDate === 'function') {
      createdAtMs = questionCreatedAt.toDate().getTime();
    } else if (typeof questionCreatedAt === 'number') {
      createdAtMs = questionCreatedAt;
    }

    let answeredAtMs = null;
    let isPublished = false;
    let answerId = null;

    const answerSnap = await db
      .collection('answers')
      .where('questionId', '==', questionDoc.id)
      .limit(1)
      .get();
    if (!answerSnap.empty) {
      const answerDoc = answerSnap.docs[0];
      const answerData = answerDoc.data() || {};
      const createdAt = answerData.createdAt;
      if (typeof createdAt?.toDate === 'function') {
        answeredAtMs = createdAt.toDate().getTime();
      } else if (typeof createdAt === 'number') {
        answeredAtMs = createdAt;
      }
      isPublished = answerData.isPublished === true;
      answerId = isPublished ? answerDoc.id : null;
    }

    return res.status(200).json({
      status: questionStatus,
      createdAt: createdAtMs > 0 ? new Date(createdAtMs).toISOString() : null,
      answeredAt: answeredAtMs ? new Date(answeredAtMs).toISOString() : null,
      isPublished,
      answerId,
    });
  } catch (e) {
    console.error('getQuestionTrackingStatus failed', e);
    return res.status(500).json({ error: 'internal_error' });
  }
};
