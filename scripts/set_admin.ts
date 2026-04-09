import * as admin from "firebase-admin";
import * as fs from "node:fs";
import * as path from "node:path";
import dotenv from "dotenv";

dotenv.config({ path: path.join(__dirname, "..", ".env") });

const localKeyPath = path.join(__dirname, "serviceAccount.json");
const SERVICE_ACCOUNT_PATH =
  process.env.GOOGLE_APPLICATION_CREDENTIALS ||
  (fs.existsSync(localKeyPath) ? localKeyPath : undefined);

function readServiceAccountFromEnv() {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!raw) return undefined;
  try {
    return JSON.parse(raw);
  } catch {
    return undefined;
  }
}

const serviceAccountFromEnv = readServiceAccountFromEnv();

if (!serviceAccountFromEnv && !SERVICE_ACCOUNT_PATH) {
  console.error(
    [
      "Missing GOOGLE_APPLICATION_CREDENTIALS.",
      "",
      "Set it to your Firebase Admin SDK service account JSON path, e.g.:",
      "  export GOOGLE_APPLICATION_CREDENTIALS=\"/path/to/serviceAccount.json\"",
      "",
      "Or set FIREBASE_SERVICE_ACCOUNT_JSON to the JSON string (see .env.example).",
      "",
      "Or place a key at:",
      `  ${localKeyPath}`,
      "",
      "Then run:",
      "  npx ts-node set_admin.ts <uid> <true|false>",
    ].join("\n")
  );
  process.exit(2);
}

const app = admin.initializeApp({
  credential: serviceAccountFromEnv
    ? admin.credential.cert(serviceAccountFromEnv)
    : admin.credential.cert(SERVICE_ACCOUNT_PATH!),
  projectId: "askme-humg-app",
});

async function main() {
  const identifier = process.argv[2];
  const enabledRaw = process.argv[3];

  if (!identifier || enabledRaw == null) {
    console.error("Usage: ts-node set_admin.ts <uid|email> <true|false>");
    process.exit(2);
  }

  const enabled = enabledRaw === "true";

  const auth = admin.auth(app);
  const isEmail = identifier.includes("@");
  const userRecord = isEmail
    ? await auth.getUserByEmail(identifier)
    : await auth.getUser(identifier);

  await auth.setCustomUserClaims(userRecord.uid, { admin: enabled });
  console.log(
    `✓ Set custom claim admin=${enabled} for uid=${userRecord.uid}${
      isEmail ? ` (email=${identifier})` : ""
    }`
  );
  console.log("→ User must refresh ID token (sign out/in) to take effect.");
}

main().catch((e) => {
  console.error("❌ set_admin failed:", e);
  process.exit(1);
});

