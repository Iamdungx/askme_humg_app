const {
  admin,
  parseBody,
  getFirestore,
  getAuthTokenFromReq,
  verifyFirebaseIdToken,
  getClientIp,
  checkClassifyRateLimit,
  getGeminiModel,
  getGeminiFallbackModel,
  normalizeUiSpecColor,
  requestGeminiClassification,
} = require('./_shared');

const DEFAULT_CATEGORIES = ['hoc_tap', 'su_kien', 'doi_song', 'tuyen_dung', 'khac'];
const DEFAULT_MAX_TAGS = 5;
const LOW_CONFIDENCE_THRESHOLD = 0.45;
const DEFAULT_TAG_COLOR = '#9AA0A6';

function normalizeCategories(categories) {
  if (!Array.isArray(categories)) return DEFAULT_CATEGORIES;
  const normalized = [
    ...new Set(
      categories
        .map((item) => (typeof item === 'string' ? item.trim().toLowerCase() : ''))
        .filter(Boolean)
        .map((item) => item.replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, ''))
        .filter(Boolean)
    ),
  ];
  if (!normalized.length) return DEFAULT_CATEGORIES;
  if (!normalized.includes('khac')) normalized.push('khac');
  return normalized;
}

function parseMaxTags(value) {
  const n = Number(value);
  if (!Number.isFinite(n) || n <= 0) return DEFAULT_MAX_TAGS;
  return Math.min(Math.floor(n), 10);
}

function normalizeTagSlug(value) {
  if (typeof value !== 'string') return '';
  return value.trim().toLowerCase().replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, '');
}

function normalizeTagCatalog(tags) {
  if (!Array.isArray(tags)) return [];
  const normalized = [];
  const seenIds = new Set();
  const seenSlugs = new Set();
  for (const tag of tags) {
    if (!tag || typeof tag !== 'object') continue;
    const rawId = typeof tag.id === 'string' ? tag.id.trim() : '';
    const slug = normalizeTagSlug(tag.slug);
    if (!rawId || !slug) continue;
    if (seenIds.has(rawId) || seenSlugs.has(slug)) continue;
    seenIds.add(rawId);
    seenSlugs.add(slug);
    normalized.push({
      id: rawId,
      slug,
      label:
        typeof tag.label === 'string' && tag.label.trim().length > 0
          ? tag.label.trim()
          : slug,
      color:
        normalizeUiSpecColor(tag.color, DEFAULT_TAG_COLOR),
      category: typeof tag.category === 'string' ? tag.category.trim().toLowerCase() : null,
    });
  }
  return normalized;
}

function mapClassifiedTagsToCatalog(tags, tagCatalog) {
  const bySlug = new Map(tagCatalog.map((item) => [item.slug, item]));
  const refs = [];
  const seen = new Set();
  for (const rawTag of tags) {
    const slug = normalizeTagSlug(rawTag);
    if (!slug || seen.has(slug)) continue;
    seen.add(slug);
    const fromCatalog = bySlug.get(slug);
    if (fromCatalog) {
      refs.push({
        id: fromCatalog.id,
        slug: fromCatalog.slug,
        label: fromCatalog.label,
        color: fromCatalog.color,
      });
      continue;
    }
    refs.push({
      id: slug,
      slug,
      label: slug,
      color: DEFAULT_TAG_COLOR,
    });
  }
  return refs;
}

function filterTagRefsByContent(tagRefs, content) {
  const source = typeof content === 'string' ? content.toLowerCase() : '';
  const containsAny = (keywords) => keywords.some((keyword) => source.includes(keyword));
  return tagRefs.filter((tag) => {
    if (tag.slug === 'diem_ren_luyen') {
      return containsAny([
        'điểm rèn luyện',
        'diem ren luyen',
        'rèn luyện',
        'ren luyen',
      ]);
    }
    return true;
  });
}

async function getTaxonomyConfig(db) {
  const snap = await db.collection('app_config').doc('ai_classification').get();
  const data = snap.exists ? snap.data() || {} : {};
  const tagCatalog = normalizeTagCatalog(data.tags);
  return {
    enabled: data.enabled !== false,
    version:
      typeof data.version === 'string' && data.version.trim().length > 0
        ? data.version.trim()
        : 'v1',
    categories: normalizeCategories(data.categories),
    maxTags: parseMaxTags(data.maxTags),
    promptHint: typeof data.promptHint === 'string' ? data.promptHint.trim() : '',
    tagCatalog,
    allowedTagSlugs: tagCatalog.map((item) => item.slug),
  };
}

function isAdminUser(decoded) {
  return decoded?.admin === true || decoded?.role === 'admin';
}

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') return res.status(204).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'method_not_allowed' });

  const body = parseBody(req);
  const answerId = typeof body.answerId === 'string' ? body.answerId.trim() : '';
  if (!answerId) return res.status(400).json({ error: 'answer_id_required' });

  let decoded;
  try {
    const idToken = getAuthTokenFromReq(req, body);
    decoded = await verifyFirebaseIdToken(idToken);
    if (!decoded?.uid) return res.status(401).json({ error: 'invalid_or_missing_token' });
  } catch {
    return res.status(401).json({ error: 'invalid_or_missing_token' });
  }

  const db = getFirestore();
  const callerUid = decoded.uid;
  const clientIp = getClientIp(req);
  const rateKey = `${clientIp}:${callerUid}`;
  const allowed = await checkClassifyRateLimit({ db, key: rateKey });
  if (!allowed) return res.status(429).json({ error: 'rate_limit_exceeded' });

  const answerRef = db.collection('answers').doc(answerId);
  const answerSnap = await answerRef.get();
  if (!answerSnap.exists) return res.status(404).json({ error: 'answer_not_found' });
  const answerData = answerSnap.data() || {};

  const ownerUid = typeof answerData.userId === 'string' ? answerData.userId : '';
  if (!ownerUid) return res.status(400).json({ error: 'invalid_answer_owner' });
  if (!isAdminUser(decoded) && ownerUid !== callerUid) {
    return res.status(403).json({ error: 'forbidden' });
  }

  if (answerData.isPublished !== true) {
    return res.status(409).json({ error: 'answer_not_published' });
  }

  if (
    answerData.aiClassificationStatus === 'done' &&
    typeof answerData.aiCategory === 'string' &&
    answerData.aiCategory.length > 0
  ) {
    return res.status(200).json({
      status: 'done',
      answerId,
      category: answerData.aiCategory,
      tags: Array.isArray(answerData.aiTags) ? answerData.aiTags : [],
      tagIds: Array.isArray(answerData.aiTagIds) ? answerData.aiTagIds : [],
      tagRefs: Array.isArray(answerData.aiTagRefs) ? answerData.aiTagRefs : [],
      model: answerData.aiClassificationModel || null,
      version: answerData.aiClassificationVersion || null,
      cached: true,
    });
  }

  const config = await getTaxonomyConfig(db);
  if (!config.enabled) {
    return res.status(200).json({ status: 'disabled', answerId, cached: false });
  }

  const questionContent =
    typeof answerData.questionContent === 'string' ? answerData.questionContent.trim() : '';
  const answerContent =
    typeof answerData.content === 'string' ? answerData.content.trim() : '';
  if (!answerContent) {
    return res.status(400).json({ error: 'empty_answer_content' });
  }
  const aiInput = `Question: ${questionContent || '(empty)'}\nAnswer: ${answerContent}`;

  await answerRef.set(
    {
      aiClassificationStatus: 'pending',
      aiClassificationVersion: config.version,
    },
    { merge: true }
  );

  const primaryModel = getGeminiModel();
  const fallbackModel = getGeminiFallbackModel();
  let result;
  let usedModel = primaryModel;
  try {
    result = await requestGeminiClassification({
      content: aiInput,
      categories: config.categories,
      maxTags: config.maxTags,
      promptHint: config.promptHint,
      model: primaryModel,
      allowedTagSlugs: config.allowedTagSlugs,
    });
    if (result.confidence < LOW_CONFIDENCE_THRESHOLD && fallbackModel !== primaryModel) {
      result = await requestGeminiClassification({
        content: aiInput,
        categories: config.categories,
        maxTags: config.maxTags,
        promptHint: config.promptHint,
        model: fallbackModel,
        allowedTagSlugs: config.allowedTagSlugs,
      });
      usedModel = fallbackModel;
    }
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    await answerRef.set(
      {
        aiClassificationStatus: 'failed',
        aiClassificationError: message.slice(0, 200),
        aiClassificationModel: usedModel,
        aiClassifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
    return res.status(502).json({ error: 'classification_failed', detail: message.slice(0, 120) });
  }

  const mappedTagRefs = mapClassifiedTagsToCatalog(result.tags, config.tagCatalog);
  const tagRefs = filterTagRefsByContent(mappedTagRefs, aiInput);
  const tagIds = tagRefs.map((tag) => tag.id);
  const tagSlugs = tagRefs.map((tag) => tag.slug);

  await answerRef.set(
    {
      aiCategory: result.category,
      aiTags: tagSlugs,
      aiTagIds: tagIds,
      aiTagRefs: tagRefs,
      aiConfidence: result.confidence,
      aiClassificationStatus: 'done',
      aiClassificationModel: usedModel,
      aiClassificationVersion: config.version,
      aiClassifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      aiClassificationError: admin.firestore.FieldValue.delete(),
    },
    { merge: true }
  );

  return res.status(200).json({
    status: 'done',
    answerId,
    category: result.category,
    tags: tagSlugs,
    tagIds,
    tagRefs,
    confidence: result.confidence,
    model: usedModel,
    version: config.version,
    cached: false,
  });
};
