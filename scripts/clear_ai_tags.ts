import * as admin from "firebase-admin";
import { existsSync } from "node:fs";

function getServiceAccountPath(): string {
  const cliArg = process.argv.find((arg) =>
    arg.startsWith("--service-account=")
  );
  const fromCli = cliArg?.split("=")[1]?.trim();
  const fromEnv =
    process.env.FIREBASE_SERVICE_ACCOUNT_PATH?.trim() ??
    process.env.GOOGLE_APPLICATION_CREDENTIALS?.trim();
  const resolvedPath = fromCli || fromEnv;

  if (!resolvedPath) {
    throw new Error(
      [
        "Missing Firebase service account path.",
        "Provide one of:",
        "  - --service-account=/absolute/path/to/service-account.json",
        "  - FIREBASE_SERVICE_ACCOUNT_PATH=/absolute/path/to/service-account.json",
        "  - GOOGLE_APPLICATION_CREDENTIALS=/absolute/path/to/service-account.json",
      ].join("\n")
    );
  }

  if (!existsSync(resolvedPath)) {
    throw new Error(`Service account file not found: ${resolvedPath}`);
  }

  return resolvedPath;
}

const serviceAccountPath = getServiceAccountPath();
const projectId = process.env.FIREBASE_PROJECT_ID?.trim() || "askme-humg-app";

const app = admin.initializeApp({
  credential: admin.credential.cert(serviceAccountPath),
  projectId,
});
const db = admin.firestore(app);

async function main() {
  console.log("🧹 Clearing AI classification fields on answers...");

  const pageSize = 200;
  let totalUpdated = 0;
  let lastDoc: FirebaseFirestore.QueryDocumentSnapshot | null = null;

  while (true) {
    let query = db.collection("answers").orderBy("__name__").limit(pageSize);
    if (lastDoc) query = query.startAfter(lastDoc);

    const snap = await query.get();
    if (snap.empty) break;

    const batch = db.batch();
    for (const doc of snap.docs) {
      batch.update(doc.ref, {
        aiCategory: admin.firestore.FieldValue.delete(),
        aiTags: admin.firestore.FieldValue.delete(),
        aiTagIds: admin.firestore.FieldValue.delete(),
        aiTagRefs: admin.firestore.FieldValue.delete(),
        aiConfidence: admin.firestore.FieldValue.delete(),
        aiClassifiedAt: admin.firestore.FieldValue.delete(),
        aiClassificationVersion: admin.firestore.FieldValue.delete(),
        aiClassificationModel: admin.firestore.FieldValue.delete(),
        aiClassificationStatus: admin.firestore.FieldValue.delete(),
        aiClassificationError: admin.firestore.FieldValue.delete(),
      });
    }
    await batch.commit();

    totalUpdated += snap.size;
    lastDoc = snap.docs[snap.docs.length - 1];
    process.stdout.write(`\r  ✅ cleared ${totalUpdated} answers...`);
  }

  console.log(`\n✓ Done. Cleared AI fields for ${totalUpdated} answers.`);
  process.exit(0);
}

main().catch((e) => {
  console.error("\n❌ clear_ai_tags failed:", e);
  process.exit(1);
});
