import * as admin from "firebase-admin";

const app = admin.initializeApp({
  credential: admin.credential.cert(
    "/Users/buivietdung/Downloads/Image/asset/askme-humg-app-firebase-adminsdk-fbsvc-d8b4957f7e.json"
  ),
  projectId: "askme-humg-app",
});
const db = admin.firestore(app);

async function main() {
  const snap = await db.collection("answers").limit(2).get();
  snap.docs.forEach(d => {
    console.log("=== answer doc ===");
    console.log(JSON.stringify(d.data(), null, 2));
  });
  process.exit(0);
}
main().catch(e => { console.error(e); process.exit(1); });
