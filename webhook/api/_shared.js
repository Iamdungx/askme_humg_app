const admin = require('firebase-admin');
const crypto = require('crypto');

const TRACKING_CODE_LENGTH = 6;
const TRACKING_CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const TRACKING_CODE_MAX_GENERATE_ATTEMPTS = 20;

const SUBMIT_LIMIT = 5;
const SUBMIT_WINDOW_MS = 60 * 60 * 1000; // 1 hour

const LOOKUP_LIMIT = 8;
const LOOKUP_WINDOW_MS = 10 * 60 * 1000; // 10 mins
const LOOKUP_COOLDOWN_MS = 15 * 60 * 1000; // 15 mins

function getFirestore() {
  if (!admin.apps.length) {
    const sa = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
    if (sa) {
      const cred = JSON.parse(sa);
      admin.initializeApp({ credential: admin.credential.cert(cred) });
    } else {
      admin.initializeApp();
    }
  }
  return admin.firestore();
}

function parseBody(req) {
  if (typeof req.body === 'string') {
    try {
      return JSON.parse(req.body);
    } catch {
      return {};
    }
  }
  return req.body || {};
}

function getClientIp(req) {
  const forwarded = req.headers['x-forwarded-for'];
  if (Array.isArray(forwarded) && forwarded.length > 0) {
    return forwarded[0].split(',')[0].trim();
  }
  if (typeof forwarded === 'string' && forwarded.length > 0) {
    return forwarded.split(',')[0].trim();
  }
  return req.socket?.remoteAddress || 'unknown';
}

function getTrackingPepper() {
  const pepper = (process.env.TRACKING_CODE_PEPPER || '').trim();
  if (!pepper) {
    throw new Error('Missing TRACKING_CODE_PEPPER environment variable');
  }
  return pepper;
}

function hashTrackingCode(code) {
  return crypto
    .createHash('sha256')
    .update(`${code}:${getTrackingPepper()}`)
    .digest('hex');
}

function generateTrackingCode() {
  let code = '';
  for (let i = 0; i < TRACKING_CODE_LENGTH; i += 1) {
    const idx = crypto.randomInt(0, TRACKING_CODE_ALPHABET.length);
    code += TRACKING_CODE_ALPHABET[idx];
  }
  return code;
}

async function createUniqueTrackingCode(db) {
  for (let i = 0; i < TRACKING_CODE_MAX_GENERATE_ATTEMPTS; i += 1) {
    const code = generateTrackingCode();
    const hash = hashTrackingCode(code);
    const snap = await db
      .collection('questions')
      .where('trackingCodeHash', '==', hash)
      .limit(1)
      .get();
    if (snap.empty) return code;
  }
  throw new Error('tracking_code_generation_failed');
}

async function checkWindowedRateLimit({
  db,
  collectionName,
  key,
  limit,
  windowMs,
  cooldownMs = 0,
}) {
  const ref = db.collection(collectionName).doc(key);
  const now = Date.now();
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) {
      tx.set(ref, { count: 1, windowStart: now, blockedUntil: 0 });
      return true;
    }
    const data = snap.data() || {};
    const blockedUntil = Number(data.blockedUntil || 0);
    if (blockedUntil > now) return false;

    const windowStart = Number(data.windowStart || now);
    const count = Number(data.count || 0);
    if (now - windowStart > windowMs) {
      tx.set(ref, { count: 1, windowStart: now, blockedUntil: 0 }, { merge: true });
      return true;
    }
    if (count >= limit) {
      if (cooldownMs > 0) {
        tx.set(ref, { blockedUntil: now + cooldownMs, count, windowStart }, { merge: true });
      }
      return false;
    }
    tx.update(ref, { count: admin.firestore.FieldValue.increment(1) });
    return true;
  });
}

async function checkSubmitRateLimit({ db, key }) {
  return checkWindowedRateLimit({
    db,
    collectionName: 'rateLimits',
    key,
    limit: SUBMIT_LIMIT,
    windowMs: SUBMIT_WINDOW_MS,
  });
}

async function checkLookupRateLimit({ db, key }) {
  return checkWindowedRateLimit({
    db,
    collectionName: 'trackingLookups',
    key,
    limit: LOOKUP_LIMIT,
    windowMs: LOOKUP_WINDOW_MS,
    cooldownMs: LOOKUP_COOLDOWN_MS,
  });
}

module.exports = {
  admin,
  parseBody,
  getFirestore,
  getClientIp,
  hashTrackingCode,
  createUniqueTrackingCode,
  checkSubmitRateLimit,
  checkLookupRateLimit,
};
