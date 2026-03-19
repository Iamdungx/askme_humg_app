#!/usr/bin/env node

const {
  admin,
  getFirestore,
  getGeminiModel,
  getGeminiFallbackModel,
  normalizeUiSpecColor,
  requestGeminiClassification,
} = require('../api/_shared');

const DEFAULT_CATEGORIES = ['hoc_tap', 'su_kien', 'doi_song', 'tuyen_dung', 'khac'];
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
  if (!Number.isFinite(n) || n <= 0) return 5;
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

async function classifyAnswerDoc({ doc, config, dryRun }) {
  const data = doc.data() || {};
  const questionContent = typeof data.questionContent === 'string' ? data.questionContent.trim() : '';
  const answerContent = typeof data.content === 'string' ? data.content.trim() : '';
  if (!answerContent) return { status: 'skipped', reason: 'empty_content' };

  const input = `Question: ${questionContent || '(empty)'}\nAnswer: ${answerContent}`;
  const primaryModel = getGeminiModel();
  const fallbackModel = getGeminiFallbackModel();
  let result = await requestGeminiClassification({
    content: input,
    categories: config.categories,
    maxTags: config.maxTags,
    promptHint: config.promptHint,
    model: primaryModel,
    allowedTagSlugs: config.allowedTagSlugs,
  });
  let usedModel = primaryModel;

  if (result.confidence < LOW_CONFIDENCE_THRESHOLD && fallbackModel !== primaryModel) {
    result = await requestGeminiClassification({
      content: input,
      categories: config.categories,
      maxTags: config.maxTags,
      promptHint: config.promptHint,
      model: fallbackModel,
      allowedTagSlugs: config.allowedTagSlugs,
    });
    usedModel = fallbackModel;
  }

  const mappedTagRefs = mapClassifiedTagsToCatalog(result.tags, config.tagCatalog);
  const tagRefs = filterTagRefsByContent(mappedTagRefs, input);
  const tagIds = tagRefs.map((tag) => tag.id);
  const tagSlugs = tagRefs.map((tag) => tag.slug);

  if (dryRun) {
    return {
      status: 'dry_run',
      category: result.category,
      tags: tagSlugs,
      tagIds,
      model: usedModel,
    };
  }

  await doc.ref.set(
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
  return { status: 'done', category: result.category, tags: tagSlugs, tagIds, model: usedModel };
}

async function run() {
  const db = getFirestore();
  const dryRun = process.argv.includes('--dry-run');
  const limitArg = process.argv.find((arg) => arg.startsWith('--limit='));
  const limit = limitArg ? Number(limitArg.split('=')[1]) : 100;
  const pageSize = Number.isFinite(limit) && limit > 0 ? Math.min(Math.floor(limit), 500) : 100;

  const config = await getTaxonomyConfig(db);
  if (!config.enabled) {
    console.log('[backfill] ai_classification is disabled; stop.');
    return;
  }

  const snap = await db
    .collection('answers')
    .where('isPublished', '==', true)
    .orderBy('createdAt', 'desc')
    .limit(pageSize)
    .get();

  if (snap.empty) {
    console.log('[backfill] no published answers found.');
    return;
  }

  let processed = 0;
  let skipped = 0;
  let failed = 0;

  for (const doc of snap.docs) {
    const data = doc.data() || {};
    if (data.aiClassificationStatus === 'done' && typeof data.aiCategory === 'string') {
      skipped += 1;
      continue;
    }
    try {
      const result = await classifyAnswerDoc({ doc, config, dryRun });
      processed += 1;
      console.log(`[backfill] ${doc.id}: ${result.status}`);
    } catch (error) {
      failed += 1;
      const message = error instanceof Error ? error.message : String(error);
      console.error(`[backfill] ${doc.id}: failed -> ${message}`);
      if (!dryRun) {
        await doc.ref.set(
          {
            aiClassificationStatus: 'failed',
            aiClassificationError: message.slice(0, 200),
            aiClassifiedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
      }
    }
  }

  console.log(
    `[backfill] done. processed=${processed} skipped=${skipped} failed=${failed} dryRun=${dryRun}`
  );
}

run()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('[backfill] fatal', error);
    process.exit(1);
  });
